"""Rebuilds proposal.pdf (one continuous document) from docs/proposal.html.
Usage (from the repo root):  python docs/build_proposal.py
Needs Google Chrome."""
import os, subprocess, tempfile

CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
html = os.path.join(ROOT, "docs", "proposal.html")
out = os.path.join(ROOT, "proposal.pdf")
subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
                f"--user-data-dir={tempfile.mkdtemp()}", f"--print-to-pdf={out}", "file:///" + html.replace("\\", "/")],
               check=True, capture_output=True)
print("wrote", out)
