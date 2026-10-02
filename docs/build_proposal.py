"""Rebuilds proposal.pdf (concept proposal + implementation plan) from the two HTML files.
Usage (from the repo root):  python docs/build_proposal.py
Needs Google Chrome and `pip install pypdf`."""
import os, subprocess, tempfile
from pypdf import PdfWriter, PdfReader

CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PARTS = [("proposal", "Concept proposal"), ("implementation_plan", "Implementation plan (Hours 12 to 100)")]

os.makedirs(os.path.join(ROOT, "docs", "pdf_parts"), exist_ok=True)
writer = PdfWriter()
for i, (name, title) in enumerate(PARTS, 1):
    out = os.path.join(ROOT, "docs", "pdf_parts", f"{i}_{name}.pdf")
    html = os.path.join(ROOT, "docs", f"{name}.html")
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
                    f"--user-data-dir={tempfile.mkdtemp()}", f"--print-to-pdf={out}", "file:///" + html.replace("\\", "/")],
                   check=True, capture_output=True)
    start = len(writer.pages)
    for page in PdfReader(out).pages:
        writer.add_page(page)
    writer.add_outline_item(title, start)
writer.add_metadata({"/Title": "Mirror Page - Proposal and Implementation Plan", "/Author": "Sankeerth Nara"})
writer.write(os.path.join(ROOT, "proposal.pdf"))
print("proposal.pdf:", len(writer.pages), "pages")
