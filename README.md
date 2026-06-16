# 🛡️ SecureMark: Robust Multimedia Security Dashboard & Watermarking Engine

![Flutter](https://img.shields.io/badge/FLUTTER-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/DART-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![FastAPI](https://img.shields.io/badge/FASTAPI-%23009688.svg?style=for-the-badge&logo=fastapi&logoColor=white)
![OpenCV](https://img.shields.io/badge/OPENCV-%235C3EE8.svg?style=for-the-badge&logo=opencv&logoColor=white)
![Gemini AI](https://img.shields.io/badge/GEMINI%20AI-%238E75B2.svg?style=for-the-badge&logo=googlegemini&logoColor=white)
![Render](https://img.shields.io/badge/CLOUD_DEPLOYMENT-%2346E3B7.svg?style=for-the-badge&logo=render&logoColor=white)

SecureMark is an advanced cross-platform application developed to provide robust multimedia copyright protection and security auditing. By bridging the gap between low-level computer vision algorithms and modern web technology, SecureMark offers a secure, resilient, and interactive dashboard tailored specifically for digital creators, researchers, and security analysts.

---

## 📌 Project Overview
**SecureMark** leverages **Discrete Cosine Transform (DCT)** block-based digital watermarking combined with advanced robustness countermeasures (**Redundant Tiling** and a **Majority Voting System**). 

The system provides a sleek desktop/mobile dashboard (Flutter) seamlessly connected to a robust **cloud web services** architecture. By offloading heavy computational lifting to a high-performance image processing engine (FastAPI/OpenCV via Render.com), SecureMark allows users to rapidly embed secure identifiers into host media, simulate aggressive geometric and signal attacks, and utilize an integrated **Gemini AI** agent for instant mathematical security analytics.

---

## 🚀 Key Features & Architecture

### Core Cryptographic Engine
* **Advanced DCT Watermarking:** Injects binary watermarks into the mid-frequency coefficients of the luminance channel via 8x8 pixel block partitioning.
* **Redundant Tiling Architecture:** Automatically forces watermarks into fixed arrays and tiles them seamlessly across the entire image to defend against structural loss.
* **Majority Voting Extraction System:** Recovers damaged watermarks by checking surviving blocks post-attack and calculating pixel-state probabilities to filter out mathematical noise.

### Enterprise App Features
* **Asynchronous Batch Processing Engine:** Protect multiple assets simultaneously without freezing the UI. Implements automated I/O streams to pipe API responses directly to native device storage.
* **Dual-Layer Secure Vault:** Assets are exported to the public gallery while a locked backup is simultaneously written to the hidden `path_provider` Application Documents directory for local auditing.
* **Dynamic Algorithmic Configuration (Pro Settings):** Users can directly manipulate the Python backend's underlying math (Alpha Payload Strength and Redundancy Tiling Factors) via the Flutter UI, persisting via `shared_preferences`.
* **Attack Simulator Workstation:** Real-time simulation of industry-standard security threats (JPEG Compression, Gaussian Noise, Center Cropping, Resolution Scaling).
* **Real-time Analytical Auditing:** Computes **Mean Squared Error (MSE)** and **Peak Signal-to-Noise Ratio (PSNR)** on-the-fly.
* **Secure Environment Variables:** LLM AI API keys are strictly protected using `flutter_dotenv` isolation.

---

## 📱 User Interface Previews

### 1. Embed Watermark (Security Workflow)
*Select a high-resolution host image, choose your core security watermark, and invoke the cloud DCT embedding engine to secretly bind the payload.*
<br>
<img src="screenshots/embed.jpg" width="200" height="400" alt="Embed Watermark Screen">

### 2. Batch Processing Engine
*Select multiple images and watch the asynchronous queue interact with the cloud server to process and save assets in bulk.*
<br>
<img src="screenshots/batch.jpg" width="200" height="400" alt="Batch Engine Screen">

### 3. Secure Vault Gallery
*A dedicated storage interface that reads from the hidden application directory, rendering a secure history of all protected assets.*
<br>
<img src="screenshots/vault.jpg" width="200" height="400" alt="Secure Vault Screen">

### 4. Robustness Testing & Extraction
*Simulate signal corruption and run extraction. Features Gemini AI integration to analyze real-time changes in MSE and PSNR metrics.*
<br>
<img src="screenshots/testing.jpg" width="200" height="400" alt="Testing Screen">

---

## ☁️ Cloud Web Service Setup (Render.com)

The FastAPI computer vision engine is designed to be hosted via cloud web services to offload heavy processing from the user's local device.

### 1. Prepare the Backend Repository
Ensure your Python backend code contains a `requirements.txt` file listing all dependencies (e.g., `fastapi`, `uvicorn`, `opencv-python-headless`, `numpy`, `python-multipart`).

### 2. Deploy to Render
1. Create a free account on [Render.com](https://render.com).
2. Click **New +** and select **Web Service**.
3. Connect your GitHub account and select your backend repository.
4. Configure the following build settings:
   * **Runtime:** `Python 3`
   * **Build Command:** `pip install -r requirements.txt`
   * **Start Command:** `uvicorn app:app --host 0.0.0.0 --port $PORT`
5. Click **Create Web Service**. Render will automatically provision a cloud server and deploy your OpenCV API.

---

## 🔒 Local Setup & Installation

To run this application locally, you must provide your own Google Gemini API key. The key is protected via environment variables.

1. Clone the repository and navigate to the frontend directory:
   ```bash
   git clone [https://github.com/HabibCode01/DCT_Watermarking_Project.git](https://github.com/HabibCode01/DCT_Watermarking_Project.git)
   cd DCT_Watermarking_Project/frontend
