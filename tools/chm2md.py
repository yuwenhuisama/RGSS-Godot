#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Convert the decompiled RPG Maker VX Ace help (Shift_JIS HTML) into UTF-8 Markdown.

- Decodes each .html as cp932 (Shift_JIS).
- Maps the help's limited tag set (h1-h6, dl/dt/dd, p, a, var, pre, table, lists,
  inline emphasis) to Markdown, preserving API structure (method signatures in <dt>,
  descriptions in <dd>).
- Rewrites internal .html links to .md (keeps #anchors and relative subdirs).
- Copies the img/ tree as-is.
- Generates README.md from the .hhc table of contents.
Japanese prose is preserved verbatim (no translation).
"""

import html
import os
import re
import shutil
import sys
from html.parser import HTMLParser

SRC = sys.argv[1] if len(sys.argv) > 1 else r"C:\Users\yuwen\AppData\Local\Temp\opencode\chm_extract"
DST = sys.argv[2] if len(sys.argv) > 2 else r"E:\Projects\RGSS-Godot\docs\rgss-reference"

BLOCK_TAGS = {"p", "h1", "h2", "h3", "h4", "h5", "h6", "dt", "dd", "li", "tr", "pre",
              "ul", "ol", "dl", "table", "div", "hr", "br", "caption", "thead", "tbody"}


class MdConverter(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.out = []          # list of text fragments
        self.list_stack = []   # 'ul' / 'ol' nesting, with counters for ol
        self.in_pre = 0
        self.pre_buf = []
        self.cur_dt = False    # inside <dt> -> render as bold "### " term line
        self.table = None      # current table rows
        self.row = None
        self.cell = None
        self.cell_is_header = False
        self.skip_depth = 0    # skip <head>, <script>, <style>
        self.suppress_text = False

    # ---- helpers -------------------------------------------------------
    def emit(self, s):
        if self.in_pre:
            self.pre_buf.append(s)
        else:
            self.out.append(s)

    def newline(self, n=1):
        if self.in_pre:
            return
        self.out.append("\n" * n)

    @staticmethod
    def fix_link(href):
        # rewrite internal .html -> .md, keep anchors & relative dirs; leave http(s) & img
        if not href:
            return href
        if href.startswith(("http://", "https://", "mailto:")):
            return href
        m = re.match(r"^([^#]*)(#.*)?$", href)
        path, anchor = m.group(1), m.group(2) or ""
        if path.lower().endswith(".html"):
            path = path[:-5] + ".md"
        return path + anchor

    # ---- tag handlers --------------------------------------------------
    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag in ("head", "script", "style"):
            self.skip_depth += 1
            return
        if self.skip_depth:
            return

        if tag in ("h1", "h2", "h3", "h4", "h5", "h6"):
            self.newline(2)
            self.emit("#" * int(tag[1]) + " ")
        elif tag == "p":
            self.newline(2)
        elif tag == "br":
            self.newline(1)
        elif tag == "hr":
            self.newline(2); self.emit("---"); self.newline(2)
        elif tag == "dl":
            self.newline(1)
        elif tag == "dt":
            self.newline(2); self.emit("### "); self.cur_dt = True
        elif tag == "dd":
            self.newline(1)
        elif tag in ("ul", "ol"):
            self.list_stack.append([tag, 0])
            self.newline(1)
        elif tag == "li":
            self.newline(1)
            depth = len(self.list_stack) - 1
            indent = "  " * max(0, depth)
            if self.list_stack and self.list_stack[-1][0] == "ol":
                self.list_stack[-1][1] += 1
                self.emit(f"{indent}{self.list_stack[-1][1]}. ")
            else:
                self.emit(f"{indent}- ")
        elif tag in ("strong", "b"):
            self.emit("**")
        elif tag in ("em", "i"):
            self.emit("*")
        elif tag == "var":
            self.emit("*")
        elif tag == "code":
            self.emit("`")
        elif tag == "pre":
            self.newline(2); self.in_pre = 1; self.pre_buf = []
        elif tag == "a":
            href = self.fix_link(a.get("href", ""))
            if href and not a.get("name"):
                self.emit("[")
                self._pending_href = href
            else:
                self._pending_href = None
        elif tag == "img":
            src = a.get("src", "")
            alt = a.get("alt", "")
            self.emit(f"![{alt}]({src})")
        elif tag == "table":
            self.table = []
        elif tag == "tr":
            self.row = []
        elif tag in ("td", "th"):
            if self.cell is not None:
                return  # ignore nested/malformed cell open
            self.cell = []
            self.cell_is_header = (tag == "th")
            self._saved_out = self.out
            self.out = self.cell

    def handle_endtag(self, tag):
        if tag in ("head", "script", "style"):
            if self.skip_depth:
                self.skip_depth -= 1
            return
        if self.skip_depth:
            return

        if tag in ("h1", "h2", "h3", "h4", "h5", "h6"):
            self.newline(1)
        elif tag == "dt":
            self.cur_dt = False; self.newline(1)
        elif tag in ("ul", "ol"):
            if self.list_stack:
                self.list_stack.pop()
            self.newline(1)
        elif tag in ("strong", "b"):
            self.emit("**")
        elif tag in ("em", "i"):
            self.emit("*")
        elif tag == "var":
            self.emit("*")
        elif tag == "code":
            self.emit("`")
        elif tag == "pre":
            code = "".join(self.pre_buf)
            self.in_pre = 0
            self.out.append("```\n" + code.strip("\n") + "\n```")
            self.newline(2)
        elif tag == "a":
            if getattr(self, "_pending_href", None):
                self.emit(f"]({self._pending_href})")
                self._pending_href = None
        elif tag in ("td", "th"):
            if self.cell is None:
                return
            text = "".join(self.cell).strip().replace("\n", " ")
            self.out = self._saved_out
            if self.row is not None:
                self.row.append((text, self.cell_is_header))
            self.cell = None
        elif tag == "tr":
            if self.table is not None and self.row:
                self.table.append(self.row)
            self.row = None
        elif tag == "table":
            self._flush_table()
            self.table = None

    def handle_data(self, data):
        if self.skip_depth:
            return
        if self.in_pre:
            self.pre_buf.append(data)
            return
        # collapse whitespace in normal flow
        text = re.sub(r"[ \t\r\n]+", " ", data)
        if text:
            self.emit(text)

    def _flush_table(self):
        if not self.table:
            return
        self.newline(2)
        rows = self.table
        # header = first row; if no th, still treat first row as header
        header = rows[0]
        ncol = max(len(r) for r in rows)
        def fmt(r):
            cells = [c[0].replace("|", "\\|") for c in r] + [""] * (ncol - len(r))
            return "| " + " | ".join(cells) + " |"
        self.out.append(fmt(header)); self.newline(1)
        self.out.append("| " + " | ".join(["---"] * ncol) + " |"); self.newline(1)
        for r in rows[1:]:
            self.out.append(fmt(r)); self.newline(1)
        self.newline(1)

    def result(self):
        text = "".join(self.out)
        text = re.sub(r"\n{3,}", "\n\n", text)      # collapse blank runs
        text = re.sub(r"[ \t]+\n", "\n", text)       # trailing ws
        text = re.sub(r"[ \t]{2,}", " ", text)       # inner runs
        return text.strip() + "\n"


def convert_file(src_path):
    raw = open(src_path, "rb").read()
    htmltext = raw.decode("cp932", errors="replace")
    conv = MdConverter()
    conv.feed(htmltext)
    return conv.result()


def parse_toc(hhc_path):
    """Parse .hhc sitemap into a nested list of {name, local, children}."""
    raw = open(hhc_path, "rb").read().decode("cp932", errors="replace")
    root = []
    stack = [root]
    name = None
    for m in re.finditer(
            r"(<UL>)|(</UL>)|<param\s+name=\"Name\"\s+value=\"(.*?)\">|<param\s+name=\"Local\"\s+value=\"(.*?)\">",
            raw, re.IGNORECASE | re.DOTALL):
        if m.group(1):  # <UL> : descend into the most recent sibling's children
            if stack[-1]:
                stack.append(stack[-1][-1]["children"])
            else:
                node = {"name": "", "local": "", "children": []}
                stack[-1].append(node)
                stack.append(node["children"])
        elif m.group(2):  # </UL>
            if len(stack) > 1:
                stack.pop()
        elif m.group(3) is not None:  # Name -> open a new node
            name = html.unescape(m.group(3))
            stack[-1].append({"name": name, "local": "", "children": []})
        elif m.group(4) is not None:  # Local -> attach to the open node
            if stack[-1]:
                stack[-1][-1]["local"] = html.unescape(m.group(4))
    return root


def main():
    if os.path.exists(DST):
        shutil.rmtree(DST)
    os.makedirs(DST, exist_ok=True)

    # copy all non-html assets (images live in img/ AND some subdirs like rpgvxace/010/)
    SKIP_EXT = {".html", ".css", ".hhc", ".hhk", ".hhp"}
    for dirpath, _, files in os.walk(SRC):
        for fn in files:
            ext = os.path.splitext(fn)[1].lower()
            if ext in SKIP_EXT:
                continue
            rel = os.path.relpath(os.path.join(dirpath, fn), SRC)
            dest = os.path.join(DST, rel)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            shutil.copy2(os.path.join(dirpath, fn), dest)

    # convert all html
    count = 0
    for dirpath, _, files in os.walk(SRC):
        for fn in files:
            if not fn.lower().endswith(".html"):
                continue
            rel = os.path.relpath(os.path.join(dirpath, fn), SRC)
            md_rel = rel[:-5] + ".md"
            md_path = os.path.join(DST, md_rel)
            os.makedirs(os.path.dirname(md_path), exist_ok=True)
            md = convert_file(os.path.join(dirpath, fn))
            open(md_path, "w", encoding="utf-8", newline="\n").write(md)
            count += 1

    # build README from TOC
    hhc = None
    for fn in os.listdir(SRC):
        if fn.lower().endswith(".hhc"):
            hhc = os.path.join(SRC, fn)
            break
    readme = ["# RPG Maker VX Ace \u30ea\u30d5\u30a1\u30ec\u30f3\u30b9 (RGSS3)\n",
              "\u516c\u5f0f\u30d8\u30eb\u30d7 `RPGVXAce.chm` \u3092 Markdown \u5316\u3057\u305f\u3082\u306e\u3002\u539f\u6587\u306f\u65e5\u672c\u8a9e\u3002\n",
              "\n> Source: `RMProject/RPGVXAce.chm` (Shift_JIS HTML) -> UTF-8 Markdown.\n"]
    if hhc:
        toc = parse_toc(hhc)
        def render(nodes, depth=0):
            for n in nodes:
                name = n.get("name") or ""
                local = n.get("local") or ""
                if not name and not local:
                    # empty container node (e.g. sitemap root) -> render children at same depth
                    if n.get("children"):
                        render(n["children"], depth)
                    continue
                md_link = MdConverter.fix_link(local) if local else ""
                indent = "  " * depth
                if md_link:
                    readme.append(f"{indent}- [{name}]({md_link})\n")
                else:
                    readme.append(f"{indent}- **{name}**\n")
                if n.get("children"):
                    render(n["children"], depth + 1)
        readme.append("\n## \u76ee\u6b21\n\n")
        render(toc)
    open(os.path.join(DST, "README.md"), "w", encoding="utf-8", newline="\n").write("".join(readme))

    print(f"CONVERTED {count} html -> md")
    print(f"OUTPUT {DST}")


if __name__ == "__main__":
    main()
