from fastapi.testclient import TestClient
import os
import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from app import app
import numpy as np
import cv2

client = TestClient(app)

def create_dummy_images():
    os.makedirs("data/test", exist_ok=True)
    host = np.ones((512, 512, 3), dtype=np.uint8) * 128 
    cv2.imwrite("data/test/dummy_host.jpg", host)
    wm = np.zeros((64, 64), dtype=np.uint8)
    cv2.rectangle(wm, (10, 10), (50, 50), 255, -1)
    cv2.imwrite("data/test/dummy_wm.png", wm)

def test_embed_api():
    create_dummy_images()
    with open("data/test/dummy_host.jpg", "rb") as host_file, open("data/test/dummy_wm.png", "rb") as wm_file:
        response = client.post(
            "/embed",
            files={
                "host_image": ("dummy_host.jpg", host_file, "image/jpeg"),
                "watermark": ("dummy_wm.png", wm_file, "image/png")
            }
        )
    assert response.status_code == 200
    assert response.headers["content-type"] == "image/png"