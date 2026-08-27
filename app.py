from flask import Flask, jsonify, send_from_directory, Response
from flask_cors import CORS
from flask_socketio import SocketIO
import threading
import datetime
import time
import cv2
import os

app = Flask(__name__, static_folder='build/web')
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")

# Global System State
system_state = {
    "status": "AKTİF (Çalışıyor)",
    "durum": "AKTİF (Çalışıyor)",
    "worker_name": "Kadir Kaya",
    "kisi_sayisi": 2,
    "person_count": 2,
    "station": "Istasyon-2",
    "istasyon": "Istasyon-2",
    "renk": "#10B981",
    "running": True,
    "camera_status": "Kamera Çalışıyor",
    "camera_id": "0",
    "fps": 30.0,
    "worker_confidence": 100.0,
    "phone_detected": False,
    "zaman": datetime.datetime.now().strftime("%H:%M:%S"),
    "last_update": datetime.datetime.now().strftime("%H:%M:%S")
}

def camera_loop():
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Camera index 0 not accessible, running simulated camera loop.")

    while True:
        now_str = datetime.datetime.now().strftime("%H:%M:%S")
        system_state["zaman"] = now_str
        system_state["last_update"] = now_str
        
        if cap.isOpened():
            ret, frame = cap.read()
            if ret:
                system_state["camera_status"] = "Kamera Çalışıyor"
            else:
                system_state["camera_status"] = "Kamera Akışı Bekleniyor"
        
        # Broadcast real-time update over WebSockets
        try:
            socketio.emit("onStatusUpdate", system_state)
        except Exception:
            pass
        
        time.sleep(1)

@app.route('/')
def root():
    return send_from_directory('build/web', 'index.html')

@app.route('/mobile/')
@app.route('/mobile/<path:path>')
def serve_mobile(path='index.html'):
    if not os.path.exists(os.path.join('build/web', path)):
        return send_from_directory('build/web', 'index.html')
    return send_from_directory('build/web', path)

@app.route('/api/status', methods=['GET'])
def get_status():
    return jsonify(system_state)

def generate_frames():
    cap = cv2.VideoCapture(0)
    while True:
        if cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                time.sleep(0.1)
                continue
            ret, buffer = cv2.imencode('.jpg', frame)
            frame_bytes = buffer.tobytes()
            yield (b'--frame\r\n'
                   b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')
        else:
            time.sleep(0.5)

@app.route('/video_feed')
def video_feed():
    return Response(generate_frames(), mimetype='multipart/x-mixed-replace; boundary=frame')

if __name__ == '__main__':
    t = threading.Thread(target=camera_loop, daemon=True)
    t.start()
    print("Starting Windows Flask Server on http://0.0.0.0:5000...")
    socketio.run(app, host='0.0.0.0', port=5000, allow_unsafe_werkzeug=True)
