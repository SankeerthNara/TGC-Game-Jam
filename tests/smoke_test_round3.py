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

    port = 8065
    server_thread = threading.Thread(target=run_server, args=(port, web_dir), daemon=True)
    server_thread.start()
    print(f"Server started on http://127.0.0.1:{port}")

    # Build statistics
    total_size = sum(os.path.getsize(os.path.join(web_dir, f)) for f in os.listdir(web_dir) if os.path.isfile(os.path.join(web_dir, f)))
    pck_size = os.path.getsize(os.path.join(web_dir, "index.pck")) if os.path.exists(os.path.join(web_dir, "index.pck")) else 0
    wasm_size = os.path.getsize(os.path.join(web_dir, "index.wasm")) if os.path.exists(os.path.join(web_dir, "index.wasm")) else 0

    print("=== Build Statistics ===")
    print(f"  Total Web Build Size: {total_size / (1024*1024):.2f} MB")
    print(f"  Game PCK Size: {pck_size / 1024:.1f} KB ({pck_size} bytes)")
    print(f"  WASM Engine Size: {wasm_size / (1024*1024):.2f} MB ({wasm_size} bytes)")

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

        print("Loading game...")
        page.goto(f"http://127.0.0.1:{port}/index.html", wait_until="networkidle", timeout=35000)
        page.wait_for_selector("#canvas", timeout=15000)
        print("Canvas detected. Waiting 7s for engine boot and main menu...")
        time.sleep(7)

        # Inject FPS monitor
        page.evaluate("""() => {
            window.__fps = [];
            let last = performance.now();
            function f(now) {
                let dt = now - last;
                last = now;
                if (dt > 0) window.__fps.push(1000 / dt);
                requestAnimationFrame(f);
            }
            requestAnimationFrame(f);
        }""")

        menu_screenshot = os.path.abspath("build/menu_screenshot.png")
        page.screenshot(path=menu_screenshot)
        print(f"Menu screenshot saved: {menu_screenshot}")

        print("Pressing Enter/Z to start reading...")
        # Click on canvas center-right where Start button is, and press Z
        page.mouse.click(1030, 447)
        page.keyboard.press("KeyZ")
        time.sleep(1.0)
        page.keyboard.press("Enter")

        print("Skipping opening cutscene (pressing Z)...")
        for _ in range(8):
            page.keyboard.press("KeyZ")
            time.sleep(0.6)

        print("Walking around in level for 30s...")
        walk_start = time.time()
        directions = ["ArrowRight", "ArrowDown", "ArrowLeft", "ArrowUp"]
        d_idx = 0
        while time.time() - walk_start < 30.0:
            key = directions[d_idx % len(directions)]
            page.keyboard.down(key)
            time.sleep(1.5)
            page.keyboard.up(key)
            d_idx += 1
            time.sleep(0.2)

        walk_screenshot = os.path.abspath("build/level_walk_screenshot.png")
        page.screenshot(path=walk_screenshot)
        print(f"Walk screenshot saved: {walk_screenshot}")

        fps_list = page.evaluate("() => window.__fps || []")
        browser.close()

    # Calculate FPS metrics
    avg_fps = sum(fps_list) / len(fps_list) if fps_list else 0.0
    # Trim first few frames for stable FPS
    stable_fps = fps_list[60:] if len(fps_list) > 60 else fps_list
    stable_avg = sum(stable_fps) / len(stable_fps) if stable_fps else 0.0

    print("\n=== Playtest Performance Results ===")
    print(f"  Samples recorded: {len(fps_list)}")
    print(f"  Overall Average FPS: {avg_fps:.1f}")
    print(f"  Sustained Gameplay FPS: {stable_avg:.1f}")
    if stable_fps:
        print(f"  Min FPS: {min(stable_fps):.1f} | Max FPS: {max(stable_fps):.1f}")

    print("\n=== Console Logs Summary ===")
    err_logs = [l for l in console_logs if "[error]" in l or "ERROR" in l]
    print(f"  Total console logs: {len(console_logs)}")
    print(f"  Console error logs: {len(err_logs)}")
    for l in err_logs[:10]:
        print("    ", l)

    if errors:
        print("\n=== Page Errors ===")
        for e in errors:
            print("  ", e)
        print("\nTEST RESULT: FAIL (Page errors)")
        sys.exit(1)
    else:
        print("\nTEST RESULT: SUCCESS (0 page errors)")

if __name__ == "__main__":
    main()
