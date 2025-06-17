#!/bin/bash

# download-vision-models.sh - Download vision models for image description functionality
# This script downloads models needed for the "Describe Pictures in Documents" feature

echo "[VISION] Starting vision model downloads for image description..."

# Set environment variables
export HF_HOME="/models/.hf_cache"
export HUGGINGFACE_HUB_CACHE="/models/.hf_cache"
export DOCLING_ARTIFACTS_PATH="/models"
export DOCLING_SERVE_ARTIFACTS_PATH="/models"

# Ensure models directory exists
mkdir -p /models/models--HuggingFaceTB--SmolVLM-256M-Instruct
chown -R root:root /models

echo "[VISION] Downloading SmolVLM-256M-Instruct model..."
python3 -c "
import os
from huggingface_hub import snapshot_download
import warnings
warnings.filterwarnings('ignore')

try:
    print('[VISION] Downloading SmolVLM-256M-Instruct model...')
    model_path = snapshot_download(
        repo_id='HuggingFaceTB/SmolVLM-256M-Instruct',
        cache_dir='/models/.hf_cache',
        local_dir='/models/models--HuggingFaceTB--SmolVLM-256M-Instruct',
        local_dir_use_symlinks=False
    )
    print(f'[VISION] ✓ SmolVLM model downloaded to: {model_path}')
    
    # Verify the model files
    import os
    model_files = os.listdir('/models/models--HuggingFaceTB--SmolVLM-256M-Instruct')
    print(f'[VISION] Model files: {model_files}')
    
except Exception as e:
    print(f'[VISION] ❌ SmolVLM model download failed: {e}')
    print('[VISION] Image description feature will not work properly')
    exit(1)
"

# Create symlink for easier access
echo "[VISION] Creating symlink for SmolVLM model..."
if [ -d "/models/models--HuggingFaceTB--SmolVLM-256M-Instruct" ]; then
    ln -sf /models/models--HuggingFaceTB--SmolVLM-256M-Instruct /models/smolvlm
    echo "[VISION] ✓ Created symlink: /models/smolvlm -> /models/models--HuggingFaceTB--SmolVLM-256M-Instruct"
else
    echo "[VISION] ⚠️  SmolVLM model directory not found - symlink not created"
fi

echo "[VISION] ==================================="
echo "[VISION] Vision model downloads completed!"
echo "[VISION] ==================================="

# Set final permissions
chown -R root:root /models
echo "[VISION] Permissions set - vision models ready for use" 