"""Machine-local test settings shared with the other test launchers."""
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONFIG = Path(os.environ.get("RGSS_TEST_PATHS_FILE", ROOT / ".test-paths.local.json")).resolve()

def repo_path(relative: str = "") -> Path:
    return ROOT / relative

def setting(key: str) -> str:
    values = json.loads(CONFIG.read_text(encoding="utf-8-sig")) if CONFIG.exists() else {}
    value = values.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"Missing test setting '{key}' in {CONFIG}. Copy .test-paths.example.json and configure this input.")
    return value

def path(key: str) -> Path:
    value = Path(setting(key))
    return value if value.is_absolute() else CONFIG.parent / value
