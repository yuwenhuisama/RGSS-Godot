import json
import math
import os
import shutil
import subprocess
import sys
import time
import wave
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import test_paths

ROOT = test_paths.repo_path()
SOURCE_GAME = test_paths.path("game_project")
WORK = ROOT / ".omo" / "compatibility-run-tmp" / "e08-se-original"
FIXTURE = WORK / "fixture"
FIXTURE_SCRIPT = ROOT / "tools" / "se-original-capture" / "se_signal_reference.rb"
PREPARE_SCRIPT = ROOT / "tools" / "prepare_original_fixture.rb"
CAPTURE = WORK / "se_signal_capture.wav"
ANALYSIS = WORK / "se_signal_analysis.json"
GAME_STDOUT = WORK / "game_stdout.log"
GAME_STDERR = WORK / "game_stderr.log"
FFMPEG = test_paths.path("ffmpeg")
DEVICE = test_paths.setting("audio_device")
CAPTURE_SECONDS = 12.0
SE_WINDOW = 0.18
BAND_FLOOR = 0.001
SILENCE_FLOOR = 0.001


def run(command, **kwargs):
    print("RUN:", " ".join(str(part) for part in command), flush=True)
    return subprocess.run(command, check=True, **kwargs)


def prepare_fixture():
    if FIXTURE.exists():
        resolved = FIXTURE.resolve()
        if WORK.resolve() not in resolved.parents:
            raise SystemExit(f"refusing to remove fixture outside owned work dir: {resolved}")
        shutil.rmtree(FIXTURE)
    run(
        [
            "ruby",
            str(PREPARE_SCRIPT),
            str(SOURCE_GAME),
            str(FIXTURE),
            str(FIXTURE_SCRIPT),
        ],
        cwd=ROOT,
    )
    for relative in ["Game.exe", "System/RGSS300.dll", "Data/Scripts.rvdata2"]:
        path = FIXTURE / relative
        if not path.is_file():
            raise SystemExit(f"prepared fixture missing {path}")
        print(f"FIXTURE_FILE: {path} ({path.stat().st_size} bytes)", flush=True)


def start_capture():
    if CAPTURE.exists():
        CAPTURE.unlink()
    command = [
        str(FFMPEG),
        "-hide_banner",
        "-loglevel",
        "info",
        "-f",
        "dshow",
        "-audio_buffer_size",
        "50",
        "-i",
        f"audio={DEVICE}",
        "-t",
        f"{CAPTURE_SECONDS:.1f}",
        "-ac",
        "2",
        "-ar",
        "48000",
        "-y",
        str(CAPTURE),
    ]
    print("CAPTURE_COMMAND:", " ".join(command), flush=True)
    process = subprocess.Popen(
        command,
        stdin=subprocess.PIPE,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
        text=True,
        errors="replace",
        bufsize=1,
    )
    lines = []
    opened_at = None
    deadline = time.time() + 10.0
    while time.time() < deadline:
        line = process.stderr.readline()
        if not line:
            if process.poll() is not None:
                break
            time.sleep(0.02)
            continue
        lines.append(line.rstrip())
        if "Successfully opened the file" in line or "Press [q] to stop" in line:
            opened_at = time.time()
            break
    if opened_at is None:
        process.kill()
        tail = "\n".join(lines[-30:])
        raise SystemExit(f"ffmpeg did not open {DEVICE}:\n{tail}")
    print(f"CAPTURE_OPENED: {opened_at:.6f}", flush=True)
    return process, opened_at, lines


def stop_capture(process, lines):
    try:
        if process.poll() is None and process.stdin is not None:
            process.stdin.write("q\n")
            process.stdin.flush()
            process.stdin.close()
    except OSError:
        pass
    try:
        remainder = process.stderr.read()
        if remainder:
            lines.extend(remainder.splitlines())
    except Exception:
        pass
    try:
        process.wait(timeout=10)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait(timeout=5)
    print("CAPTURE_EXIT:", process.returncode, flush=True)
    if process.returncode not in (0, 255):
        raise SystemExit("ffmpeg capture failed:\n" + "\n".join(lines[-30:]))


def run_game():
    events = FIXTURE / "se_signal_events.tsv"
    if events.exists():
        events.unlink()
    started = time.time()
    with GAME_STDOUT.open("w", encoding="utf-8") as stdout, GAME_STDERR.open(
        "w", encoding="utf-8"
    ) as stderr:
        process = subprocess.Popen(
            [str(FIXTURE / "Game.exe")],
            cwd=FIXTURE,
            stdout=stdout,
            stderr=stderr,
        )
        try:
            code = process.wait(timeout=30)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)
            raise SystemExit("Game.exe did not exit within 30 seconds")
    print(f"GAME_EXIT: {code} after {time.time() - started:.3f}s", flush=True)
    if not events.is_file():
        raise SystemExit("fixture did not write se_signal_events.tsv")
    return events


def parse_events(path):
    events = {}
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            fields = line.rstrip("\n").split("\t")
            if len(fields) < 2:
                continue
            events[fields[0]] = {
                "time": float(fields[1]),
                "extra": fields[2] if len(fields) > 2 else "",
            }
    print("EVENTS:", json.dumps(events, sort_keys=True), flush=True)
    return events


def read_wav(path):
    with wave.open(str(path), "rb") as handle:
        channels = handle.getnchannels()
        width = handle.getsampwidth()
        rate = handle.getframerate()
        frames = handle.readframes(handle.getnframes())
    if width != 2:
        raise SystemExit(f"capture sample width is {width}, expected 16-bit")
    data = np.frombuffer(frames, dtype="<i2").astype(np.float64) / 32768.0
    data = data.reshape(-1, channels).mean(axis=1)
    return data, rate


def band_amplitude(samples, rate, frequency):
    if len(samples) == 0:
        return 0.0
    window = np.hanning(len(samples))
    index = np.arange(len(samples), dtype=np.float64)
    phase = 2.0 * math.pi * frequency * index / rate
    real = float(np.dot(samples * window, np.cos(phase)))
    imaginary = float(np.dot(samples * window, np.sin(phase)))
    scale = float(window.sum())
    if scale == 0.0:
        return 0.0
    return 2.0 * math.sqrt(real * real + imaginary * imaginary) / scale


def scan(data, rate, begin, end, window=SE_WINDOW, hop=0.03):
    window_frames = max(1, int(rate * window))
    hop_frames = max(1, int(rate * hop))
    first = max(0, int(begin * rate))
    last = min(len(data), int(end * rate))
    rows = []
    for start in range(first, max(first + 1, last - window_frames + 1), hop_frames):
        chunk = data[start:start + window_frames]
        if len(chunk) < window_frames:
            break
        rows.append(
            {
                "t": start / rate,
                "440": band_amplitude(chunk, rate, 440.0),
                "660": band_amplitude(chunk, rate, 660.0),
                "peak": float(np.max(np.abs(chunk))),
            }
        )
    return rows


def summarize(rows):
    if not rows:
        return None
    joint = max(rows, key=lambda row: min(row["440"], row["660"]))
    return {
        "windows": len(rows),
        "best_440": max(row["440"] for row in rows),
        "best_660": max(row["660"] for row in rows),
        "joint_440": joint["440"],
        "joint_660": joint["660"],
        "joint_time": joint["t"],
        "peak": max(row["peak"] for row in rows),
    }


def analyze(events_path, opened_at):
    data, rate = read_wav(CAPTURE)
    duration = len(data) / rate
    events = parse_events(events_path)
    for name in ("SE_START", "SE_STOP", "EXIT"):
        if name not in events:
            raise SystemExit(f"missing event {name}")
    offsets = {
        name: events[name]["time"] - opened_at for name in ("BEGIN", "SE_START", "SE_STOP", "EXIT")
    }
    print("CAPTURE_OFFSETS:", json.dumps(offsets, sort_keys=True), flush=True)

    baseline = scan(
        data,
        rate,
        max(0.0, offsets["BEGIN"] + 0.1),
        max(0.0, offsets["SE_START"] - 0.05),
    )
    coexistence = scan(
        data,
        rate,
        max(0.0, offsets["SE_START"]),
        max(0.0, min(duration, offsets["SE_STOP"] + 1.2)),
    )
    silence = scan(
        data,
        rate,
        max(0.0, offsets["SE_STOP"] + 1.5),
        max(0.0, min(duration, offsets["EXIT"] - 0.1)),
    )
    late_silence = scan(
        data,
        rate,
        max(0.0, offsets["SE_STOP"] + 2.2),
        max(0.0, min(duration, offsets["EXIT"] - 0.1)),
    )
    baseline_summary = summarize(baseline)
    coexistence_summary = summarize(coexistence)
    silence_summary = summarize(silence)
    late_summary = summarize(late_silence)
    print("ANALYSIS_BASELINE:", json.dumps(baseline_summary), flush=True)
    print("ANALYSIS_COEXISTENCE:", json.dumps(coexistence_summary), flush=True)
    print("ANALYSIS_SILENCE:", json.dumps(silence_summary), flush=True)
    print("ANALYSIS_LATE_SILENCE:", json.dumps(late_summary), flush=True)

    result = {
        "device": DEVICE,
        "ffmpeg": str(FFMPEG),
        "capture_seconds": duration,
        "events": events,
        "capture_offsets": offsets,
        "baseline": baseline_summary,
        "coexistence": coexistence_summary,
        "silence": silence_summary,
        "late_silence": late_summary,
    }
    if not coexistence_summary or not silence_summary:
        print("SE_SIGNAL_VERDICT: coexistence=INSUFFICIENT_WINDOW silence=INSUFFICIENT_WINDOW")
        ANALYSIS.write_text(json.dumps(result, indent=2), encoding="utf-8")
        raise SystemExit(1)

    baseline_peak = baseline_summary["peak"] if baseline_summary else 0.0
    coexistence_ok = (
        coexistence_summary["joint_440"] >= BAND_FLOOR
        and coexistence_summary["joint_660"] >= BAND_FLOOR
        and coexistence_summary["joint_440"] >= baseline_peak * 5.0
        and coexistence_summary["joint_660"] >= baseline_peak * 5.0
    )
    silence_ok = (
        silence_summary["peak"] <= SILENCE_FLOOR
        and silence_summary["best_440"] <= SILENCE_FLOOR
        and silence_summary["best_660"] <= SILENCE_FLOOR
    )
    baseline_clean = baseline_peak <= SILENCE_FLOOR
    result["baseline_clean"] = baseline_clean
    result["coexistence_ok"] = coexistence_ok
    result["silence_ok"] = silence_ok
    ANALYSIS.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(
        "SE_SIGNAL_VERDICT: "
        f"coexistence={'PASS' if coexistence_ok else 'FAIL'} "
        f"440={coexistence_summary['joint_440']:.6f} "
        f"660={coexistence_summary['joint_660']:.6f} "
        f"silence={'PASS' if silence_ok else 'FAIL'} "
        f"post_peak={silence_summary['peak']:.6f} "
        f"baseline_clean={baseline_clean}"
    )
    return 0 if (coexistence_ok and silence_ok and baseline_clean) else 1


def main():
    WORK.mkdir(parents=True, exist_ok=True)
    prepare_fixture()
    capture, opened_at, lines = start_capture()
    try:
        events = run_game()
    finally:
        stop_capture(capture, lines)
    return analyze(events, opened_at)


if __name__ == "__main__":
    sys.exit(main())
