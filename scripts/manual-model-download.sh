#!/bin/bash

# manual-model-download.sh - Manual fallback for model downloads

echo "[MANUAL] Starting comprehensive manual model download..."

# Set environment variables
export HF_HOME="/models/.hf_cache"
export HUGGINGFACE_HUB_CACHE="/models/.hf_cache"
export DOCLING_ARTIFACTS_PATH="/models"
export DOCLING_SERVE_ARTIFACTS_PATH="/models"

# Try alternative model download methods
echo "[MANUAL] Attempting direct HuggingFace download..."

python3 -c "
import os
from huggingface_hub import hf_hub_download, list_repo_files
import traceback

# Set up paths
os.makedirs('/models/.hf_cache', exist_ok=True)

# Get complete list of model artifacts from repository
repo_id = 'ds4sd/docling-models'
print('[MANUAL] Getting complete file list from repository...')

try:
    all_files = list_repo_files(repo_id)
    model_files = [f for f in all_files if f.startswith('model_artifacts/')]
    
    print(f'[MANUAL] Found {len(model_files)} model artifact files to download:')
    for f in sorted(model_files):
        print(f'  - {f}')
    
    print('[MANUAL] Starting downloads...')
    
    for file_path in model_files:
        try:
            print(f'[MANUAL] Downloading {file_path}...')
            downloaded_path = hf_hub_download(
                repo_id=repo_id,
                filename=file_path,
                cache_dir='/models/.hf_cache'
            )
            print(f'[MANUAL] ✓ Downloaded: {os.path.basename(file_path)}')
        except Exception as e:
            print(f'[MANUAL] ⚠️  Failed to download {file_path}: {e}')
    
    print('[MANUAL] All model artifact downloads completed')
    
except Exception as e:
    print(f'[MANUAL] ❌ Error getting file list: {e}')
    print('[MANUAL] Falling back to known essential files...')
    
    # Fallback to known essential files
    essential_files = [
        'model_artifacts/layout/model.safetensors',
        'model_artifacts/layout/config.json',
        'model_artifacts/layout/preprocessor_config.json',
        'model_artifacts/tableformer/accurate/tableformer_accurate.safetensors',
        'model_artifacts/tableformer/accurate/tm_config.json',
        'model_artifacts/tableformer/fast/tableformer_fast.safetensors',
        'model_artifacts/tableformer/fast/tm_config.json'
    ]
    
    for file_path in essential_files:
        try:
            print(f'[MANUAL] Downloading {file_path}...')
            downloaded_path = hf_hub_download(
                repo_id=repo_id,
                filename=file_path,
                cache_dir='/models/.hf_cache'
            )
            print(f'[MANUAL] ✓ Downloaded: {os.path.basename(file_path)}')
        except Exception as e:
            print(f'[MANUAL] ⚠️  Failed to download {file_path}: {e}')

print('[MANUAL] Manual download attempt completed')
"

echo "[MANUAL] Attempting to create symlinks after manual download..."
/usr/local/bin/fix-model-links.sh

echo "[MANUAL] Manual model download script completed" 