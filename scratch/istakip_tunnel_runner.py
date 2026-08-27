import socket
import threading
import subprocess
import time
import re
import os

LISTEN_PORT = 5010
TARGET_HOST = "192.168.30.176"
TARGET_PORT = 5000

def pipe(src, dst):
    try:
        while True:
            data = src.recv(8192)
            if not data:
                break
            dst.sendall(data)
    except Exception:
        pass
    finally:
        try:
            src.close()
        except:
            pass
        try:
            dst.close()
        except:
            pass

def handle_client(client_sock):
    try:
        remote_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        remote_sock.settimeout(10)
        remote_sock.connect((TARGET_HOST, TARGET_PORT))
        t1 = threading.Thread(target=pipe, args=(client_sock, remote_sock), daemon=True)
        t2 = threading.Thread(target=pipe, args=(remote_sock, client_sock), daemon=True)
        t1.start()
        t2.start()
    except Exception:
        try:
            client_sock.close()
        except:
            pass

def start_tcp_listener():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(("127.0.0.1", LISTEN_PORT))
    server.listen(100)
    while True:
        client_sock, _ = server.accept()
        threading.Thread(target=handle_client, args=(client_sock,), daemon=True).start()

def run_tunnel():
    log_file = r"C:\temp_cf\lh_permanent.log"
    url_file = r"C:\temp_cf\active_url.txt"
    os.makedirs(r"C:\temp_cf", exist_ok=True)

    while True:
        try:
            cmd = ["ssh", "-o", "StrictHostKeyChecking=no", "-o", "ServerAliveInterval=15", "-R", f"80:127.0.0.1:{LISTEN_PORT}", "nokey@localhost.run"]
            with open(log_file, "w") as f:
                p = subprocess.Popen(cmd, stdout=f, stderr=f)
                for _ in range(15):
                    time.sleep(2)
                    if os.path.exists(log_file):
                        with open(log_file, "r") as lf:
                            txt = lf.read()
                            urls = re.findall(r'https://[a-zA-Z0-9-]+\.lhr\.life', txt)
                            if urls:
                                with open(url_file, "w") as uf:
                                    uf.write(urls[-1] + "/mobile/\n")
                                break
                p.wait()
        except Exception:
            pass
        time.sleep(3)

if __name__ == "__main__":
    t1 = threading.Thread(target=start_tcp_listener, daemon=True)
    t1.start()
    run_tunnel()
