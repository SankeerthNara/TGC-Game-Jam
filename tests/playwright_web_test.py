import os
import sys
import time
import threading
from http.server import HTTPServer, SimpleHTTPRequestHandler
from playwright.sync_api import sync_playwright

class CORSRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        super().end_headers()

def run_server(port, directory):
    def handler(*args, **kwargs):
        return CORSRequestHandler(*args, directory=directory, **kwargs)
    httpd = HTTPServer(("127.0.0.1", port), handler)
    httpd.serve_forever()

def main():
    web_dir = os.path.abspath("build/web")
    if not os.path.exists(web_dir):
        print(f"Error: {web_dir} does not exist.")
        sys.exit(1)

    port = 8060
    server_thread = threading.Thread(target=run_server, args=(port, web_dir), daemon=True)
    server_thread.start()
    print(f"Local server started on http://127.0.0.1:{port} serving {web_dir}")

    # Calculate export size
    total_size = sum(os.path.getsize(os.path.join(web_dir, f)) for f in os.listdir(web_dir) if os.path.isfile(os.path.join(web_dir, f)))
    pck_size = os.path.getsize(os.path.join(web_dir, "index.pck")) if os.path.exists(os.path.join(web_dir, "index.pck")) else 0
    wasm_size = os.path.getsize(os.path.join(web_dir, "index.wasm")) if os.path.exists(os.path.join(web_dir, "index.wasm")) else 0

    print(f"Build Statistics:")
    print(f"  Total Web Build Size: {total_size / (1024*1024):.2f} MB")
    print(f"  Game PCK Size: {pck_size / 1024:.1f} KB")
    print(f"  WASM Engine Size: {wasm_size / (1024*1024):.2f} MB")

    console_logs = []
    errors = []

    with sync_playwright() as p:
        chrome_path = r"C:\Users\sanke\AppData\Local\ms-playwright\chromium-1243\chrome-win64\chrome.exe"
        launch_kwargs = {
            "headless": True,
            "args": [
                "--enable-webgl",
                "--ignore-gpu-blocklist",
                "--use-gl=angle",
                "--no-sandbox"
            ]
        }
        if os.path.exists(chrome_path):
            launch_kwargs["executable_path"] = chrome_path
        browser = p.chromium.launch(**launch_kwargs)
        context = browser.new_context(viewport={"width": 1280, "height": 720})
        page = context.new_page()

        page.on("console", lambda msg: console_logs.append(f"[{msg.type}] {msg.text}"))
        page.on("pageerror", lambda exc: errors.append(f"PAGE ERROR: {exc}"))

        print("Navigating to web build...")
        page.goto(f"http://127.0.0.1:{port}/index.html", wait_until="networkidle", timeout=30000)

        # Wait for Godot canvas
        page.wait_for_selector("#canvas", timeout=15000)
        print("Canvas element detected. Waiting for engine loop to initialize...")
        time.sleep(6) # Allow WASM initialization, asset decompression and first frame rendering

        screenshot_path = os.path.abspath("build/web_screenshot.png")
        page.screenshot(path=screenshot_path)
        print(f"Screenshot captured: {screenshot_path}")

        browser.close()

    print("\n--- Browser Console Output ---")
    for log in console_logs:
        print(" ", log)

    if errors:
        print("\n--- JavaScript Page Errors ---")
        for err in errors:
            print(" ", err)
        print("\nPLAYWRIGHT TEST: FAILED with errors")
        sys.exit(1)
    else:
        print("\nPLAYWRIGHT TEST: SUCCESS (0 errors)")

if __name__ == "__main__":
    main()
