import cv2
import numpy as np

class BlockDCTWatermarker:
    def __init__(self, block_size=8, alpha_float=0.5, tiling_factor=4, heavy_voting=True):
        self.block_size = block_size
        self.heavy_voting = heavy_voting
        
        # 1. Map Flutter's 0.1 - 1.0 slider to Python's 10 - 100 math strength
        self.alpha = int(alpha_float * 100) 
        
        # 2. Map Flutter's dropdown (2x, 4x, 8x) to the physical watermark pixel size
        # 2x Tiling = 128px logo. 4x Tiling = 64px logo. 8x Tiling = 32px logo.
        self.wm_size = int(256 / tiling_factor)

    def _embed_block(self, dct_block, watermark_bit):
        u1, v1 = 4, 5
        u2, v2 = 5, 4
        
        if watermark_bit == 1:
            if dct_block[u1, v1] < dct_block[u2, v2]:
                dct_block[u1, v1], dct_block[u2, v2] = dct_block[u2, v2], dct_block[u1, v1]
            dct_block[u1, v1] += self.alpha
        else:
            if dct_block[u1, v1] >= dct_block[u2, v2]:
                dct_block[u1, v1], dct_block[u2, v2] = dct_block[u2, v2], dct_block[u1, v1]
            dct_block[u2, v2] += self.alpha
            
        return dct_block

    def embed(self, image_path, watermark_path, output_path):
        image = cv2.imread(image_path)
        watermark = cv2.imread(watermark_path, cv2.IMREAD_GRAYSCALE)
        
        ycrcb = cv2.cvtColor(image, cv2.COLOR_BGR2YCrCb)
        y_channel = ycrcb[:, :, 0].astype(np.float32)
        h, w = y_channel.shape
        
        # Resize dynamically based on user settings
        watermark = cv2.resize(watermark, (self.wm_size, self.wm_size))
        _, watermark_bin = cv2.threshold(watermark, 127, 1, cv2.THRESH_BINARY)
        
        for i in range(0, h, self.block_size):
            for j in range(0, w, self.block_size):
                block = y_channel[i:i+self.block_size, j:j+self.block_size]
                if block.shape == (self.block_size, self.block_size):
                    dct_block = cv2.dct(block)
                    
                    wm_i = (i // self.block_size) % self.wm_size
                    wm_j = (j // self.block_size) % self.wm_size
                    watermark_bit = watermark_bin[wm_i, wm_j]
                    
                    embedded_dct = self._embed_block(dct_block, watermark_bit)
                    y_channel[i:i+self.block_size, j:j+self.block_size] = cv2.idct(embedded_dct)
                    
        ycrcb[:, :, 0] = np.clip(y_channel, 0, 255).astype(np.uint8)
        watermarked_img = cv2.cvtColor(ycrcb, cv2.COLOR_YCrCb2BGR)
        
        cv2.imwrite(output_path, watermarked_img)
        return image, watermarked_img

    def extract(self, watermarked_path, extracted_wm_path, original_shape):
        watermarked_img = cv2.imread(watermarked_path)
        ycrcb = cv2.cvtColor(watermarked_img, cv2.COLOR_BGR2YCrCb)
        y_channel = ycrcb[:, :, 0].astype(np.float32)
        
        h, w = original_shape[:2]
        
        votes_1 = np.zeros((self.wm_size, self.wm_size), dtype=np.int32)
        votes_total = np.zeros((self.wm_size, self.wm_size), dtype=np.int32)
        
        u1, v1, u2, v2 = 4, 5, 5, 4
        
        for i in range(0, h, self.block_size):
            for j in range(0, w, self.block_size):
                block = y_channel[i:i+self.block_size, j:j+self.block_size]
                
                if block.shape == (self.block_size, self.block_size):
                    # Flutter "Heavy Voting" toggle applied here!
                    if self.heavy_voting and np.var(block) < 1.0:
                        continue
                        
                    dct_block = cv2.dct(block)
                    wm_i = (i // self.block_size) % self.wm_size
                    wm_j = (j // self.block_size) % self.wm_size
                    
                    votes_total[wm_i, wm_j] += 1
                    
                    if dct_block[u1, v1] >= dct_block[u2, v2]:
                        votes_1[wm_i, wm_j] += 1
                        
        extracted_wm = np.zeros((self.wm_size, self.wm_size), dtype=np.uint8)
        for i in range(self.wm_size):
            for j in range(self.wm_size):
                if votes_total[i, j] > 0:
                    if votes_1[i, j] > votes_total[i, j] / 2:
                        extracted_wm[i, j] = 255
                    else:
                        extracted_wm[i, j] = 0
                        
        cv2.imwrite(extracted_wm_path, extracted_wm)
        return extracted_wm