import socketserver
import socket
import threading
import subprocess
import time
import re
import os

LISTEN_PORT = 5007
TARGET_HOST = "192.168.30.245"
TARGET_PORT = 5000

class TCPProxyHandler(socketserver.BaseRequestHandler):
    def handle(self):
        try:
            target = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            target.settimeout(10)
            target.connect((TARGET_HOST, TARGET_PORT))

            def pipe(src, dst):
                try:
                    while True:
                        data = src.recv(8192)
                        if not data:
                            break
                        dst.sendall(data)
                except Exception:
                    pass

            t1 = threading.Thread(target=pipe, args=(self.request, target), daemon=True)
            t2 = threading.Thread(target=pipe, args=(target, self.request), daemon=True)
            t1.start()
            t2.start()
            
            while t1.is_alive() and t2.is_alive():
                time.sleep(0.05)
        except Exception:
            pass

class ThreadedTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    allow_reuse_address = True

def start_server():
    server = ThreadedTCPServer(('0.0.0.0', LISTEN_PORT), TCPProxyHandler)
    server.serve_forever()

def run_tunnel():
    log_file = r"C:\temp_cf\serveo_runner.log"
    url_file = r"C:\temp_cf\active_url.txt"
    os.makedirs(r"C:\temp_cf", exist_ok=True)

    while True:
        try:
            cmd = ["ssh", "-o", "StrictHostKeyChecking=no", "-o", "ServerAliveInterval=15", "-R", f"80:127.0.0.1:{LISTEN_PORT}", "serveo.net"]
            with open(log_file, "w") as f:
                p = subprocess.Popen(cmd, stdout=f, stderr=f)
                for _ in range(15):
                    time.sleep(2)
                    if os.path.exists(log_file):
                        with open(log_file, "r") as lf:
                            txt = lf.read()
                            urls = re.findall(r'https://[a-zA-Z0-9-]+\.serveousercontent\.com', txt)
                            if urls:
                                with open(url_file, "w") as uf:
                                    uf.write(urls[-1] + "/mobile/\n")
                                break
                p.wait()
        except Exception:
            pass
        time.sleep(3)

if __name__ == "__main__":
    t1 = threading.Thread(target=start_server, daemon=True)
    t1.start()
    run_tunnel()
