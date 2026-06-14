import traceback
from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, PlainTextResponse
import shutil
import os
import cv2
from src.watermarker import BlockDCTWatermarker
import src.attacks as attacks
from src.metrics import calculate_psnr, calculate_mse

app = FastAPI(title="SecureMark API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["X-MSE", "X-PSNR"] 
)

os.makedirs("data/output", exist_ok=True)

# =====================================================================
# 1. EMBED ROUTE (Now accepts dynamic settings from Flutter)
# =====================================================================
@app.post("/embed")
async def embed_watermark(
    host_image: UploadFile = File(...), 
    watermark: UploadFile = File(...),
    alpha: float = Form(0.5),          # Default to 0.5 if not provided
    tiling_factor: int = Form(4)       # Default to 4x if not provided
):
    host_path = f"data/output/temp_{host_image.filename}"
    wm_path = f"data/output/temp_{watermark.filename}"
    output_path = "data/output/watermarked_output.png"
    
    with open(host_path, "wb") as f: shutil.copyfileobj(host_image.file, f)
    with open(wm_path, "wb") as f: shutil.copyfileobj(watermark.file, f)
        
    # Initialize the watermarker DYNAMICALLY with the user's settings
    watermarker = BlockDCTWatermarker(block_size=8, alpha_float=alpha, tiling_factor=tiling_factor)
    watermarker.embed(host_path, wm_path, output_path)
    
    return FileResponse(output_path, media_type="image/png")

# =====================================================================
# 2. EXTRACT ROUTE (Must know the settings to reconstruct the grid!)
# =====================================================================
@app.post("/extract")
async def extract_watermark(
    watermarked_image: UploadFile = File(...),
    tiling_factor: int = Form(4),      # Must match what was embedded
    heavy_voting: bool = Form(True)    # Toggles advanced variance checks
):
    watermarked_path = f"data/output/temp_{watermarked_image.filename}"
    output_path = "data/output/extracted_output.png"
    
    with open(watermarked_path, "wb") as f: shutil.copyfileobj(watermarked_image.file, f)
        
    image = cv2.imread(watermarked_path)
    if image is None: return {"error": "Could not read the uploaded image."}
        
    # Re-initialize the engine with the exact extraction settings
    watermarker = BlockDCTWatermarker(block_size=8, alpha_float=0.5, tiling_factor=tiling_factor, heavy_voting=heavy_voting)
    watermarker.extract(watermarked_path, output_path, image.shape)
    
    return FileResponse(output_path, media_type="image/png")

# =====================================================================
# 3. ATTACK ROUTE (Unchanged)
# =====================================================================
@app.post("/attack/{attack_type}")
async def apply_attack(attack_type: str, file: UploadFile = File(...)):
    try:
        input_path = f"data/output/temp_attack_{file.filename}"
        output_path = f"data/output/attacked_result.png"
        
        with open(input_path, "wb") as f: shutil.copyfileobj(file.file, f)
            
        if attack_type == "jpeg":
            attacks.attack_jpeg_compression(input_path, output_path, quality=60)
        elif attack_type == "noise":
            attacks.attack_gaussian_noise(input_path, output_path, var=50)
        elif attack_type == "crop":
            attacks.attack_cropping(input_path, output_path, crop_ratio=0.25)
        elif attack_type == "scale":
            attacks.attack_scaling(input_path, output_path, scale_factor=0.5)
        else:
            return PlainTextResponse("Invalid attack type", status_code=400)
            
        img_original = cv2.imread(input_path)
        img_attacked = cv2.imread(output_path)
            
        if img_original is None: return PlainTextResponse("Failed to read original.", status_code=500)
        if img_attacked is None: return PlainTextResponse("Failed to read attacked.", status_code=500)
            
        mse_val = calculate_mse(img_original, img_attacked)
        psnr_val = calculate_psnr(img_original, img_attacked)
            
        response = FileResponse(output_path)
        response.headers["X-MSE"] = f"{mse_val:.2f}"
        response.headers["X-PSNR"] = f"{psnr_val:.2f}"
            
        return response

    except Exception as e:
        error_trace = traceback.format_exc()
        print(error_trace) 
        return PlainTextResponse(f"Python Bug: {str(e)}", status_code=500)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)