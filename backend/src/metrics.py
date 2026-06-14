import numpy as np
import cv2

def calculate_mse(original_image, attacked_image):
    """
    Calculates the Mean Squared Error (MSE) between two image arrays.
    """
    # Step 1: Ensure both images have the exact same dimensions
    if original_image.shape != attacked_image.shape:
        raise ValueError("Images must have the same dimensions for MSE calculation.")

    # Step 2: Convert to Float to prevent uint8 overflow/underflow
    # This is critical! If you subtract uint8 arrays, negatives wrap around (e.g., 10 - 20 = 246 instead of -10)
    img1_float = original_image.astype(np.float64)
    img2_float = attacked_image.astype(np.float64)

    # Step 3: Apply the MSE mathematical formula
    # 1. Subtract the matrices (I - K)
    # 2. Square the differences (...)^2
    # 3. Calculate the average across the entire matrix (1/mn * Sum)
    mse_value = np.mean((img1_float - img2_float) ** 2)

    return float(mse_value)

def calculate_psnr(original_image, attacked_image):
    """
    Calculates the Peak Signal-to-Noise Ratio (PSNR) using the MSE.
    """
    mse = calculate_mse(original_image, attacked_image)
    
    # If MSE is 0, the images are identical. PSNR is technically infinite.
    if mse == 0:
        return 100.0 
        
    # Standard max pixel value for 8-bit images is 255
    max_pixel_value = 255.0
    
    # Apply the PSNR formula: 10 * log10((MAX^2) / MSE)
    psnr_value = 10 * np.log10((max_pixel_value ** 2) / mse)
    
    return float(psnr_value)