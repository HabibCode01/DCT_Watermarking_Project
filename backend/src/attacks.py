import cv2
import numpy as np

def attack_jpeg_compression(image_path, output_path, quality=60):
    image = cv2.imread(image_path)
    if image is None: return None
    cv2.imwrite(output_path, image, [int(cv2.IMWRITE_JPEG_QUALITY), quality])
    return cv2.imread(output_path)

def attack_gaussian_noise(image_path, output_path, mean=0, var=10):
    image = cv2.imread(image_path)
    if image is None: return None
    sigma = var ** 0.5
    gaussian = np.random.normal(mean, sigma, image.shape).astype(np.float32)
    noisy_image = cv2.add(image.astype(np.float32), gaussian)
    noisy_image = np.clip(noisy_image, 0, 255).astype(np.uint8)
    cv2.imwrite(output_path, noisy_image)
    return noisy_image

def attack_cropping(input_path, output_path, crop_ratio=0.25):
    img = cv2.imread(input_path)
    if img is None: return None
    h, w = img.shape[:2]
    
    # PROPER CROP: Create a black canvas of the exact same size
    cropped_img = np.zeros_like(img)
    
    start_y, end_y = int(h * crop_ratio), int(h * (1 - crop_ratio))
    start_x, end_x = int(w * crop_ratio), int(w * (1 - crop_ratio))
    
    # Paste only the uncropped center back into its EXACT original coordinates
    cropped_img[start_y:end_y, start_x:end_x] = img[start_y:end_y, start_x:end_x]
    
    cv2.imwrite(output_path, cropped_img)
    return cropped_img

def attack_scaling(input_path, output_path, scale_factor=0.5):
    img = cv2.imread(input_path)
    if img is None: return None
    h, w = img.shape[:2]
    
    # PROPER SCALE: Shrink it to cause data loss, then stretch it back to original size
    small = cv2.resize(img, (int(w * scale_factor), int(h * scale_factor)))
    scaled_img = cv2.resize(small, (w, h))
    
    cv2.imwrite(output_path, scaled_img)
    return scaled_img