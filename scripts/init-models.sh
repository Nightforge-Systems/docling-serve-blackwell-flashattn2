#!/bin/bash

# init-models.sh - Initialize and download required models for Docling-Serve
# This script ensures all models are properly downloaded before starting the service

# Use less strict error handling to prevent infinite loops
set +e  # Don't exit on errors - handle them gracefully

echo "[INIT] Starting comprehensive model initialization..."

# Check if we're in a retry loop (prevent infinite restarts)
RETRY_COUNT_FILE="/tmp/init_retry_count"
if [ -f "$RETRY_COUNT_FILE" ]; then
    RETRY_COUNT=$(cat "$RETRY_COUNT_FILE")
    RETRY_COUNT=$((RETRY_COUNT + 1))
else
    RETRY_COUNT=1
fi
echo "$RETRY_COUNT" > "$RETRY_COUNT_FILE"

if [ "$RETRY_COUNT" -gt 3 ]; then
    echo "[INIT] ⚠️  Maximum retry attempts (3) reached"
    echo "[INIT] Continuing with available models..."
    rm -f "$RETRY_COUNT_FILE"
fi

# Ensure models directory exists and has correct permissions
mkdir -p /models/.hf_cache
mkdir -p /models/EasyOcr
mkdir -p /models/models--IBM--DocLayNet-base
mkdir -p /models/models--unstructured-io--detectron2-layout-base-VGT
mkdir -p /models/docling_models
chown -R root:root /models

# Set environment variables for model downloads
export HF_HOME="/models/.hf_cache"
export HUGGINGFACE_HUB_CACHE="/models/.hf_cache"
export EASYOCR_MODULE_PATH="/models/EasyOcr"
export DOCLING_ARTIFACTS_PATH="/models"
export DOCLING_SERVE_ARTIFACTS_PATH="/models"
export HF_HUB_OFFLINE=0
export DOCLING_DISABLE_MODEL_DOWNLOADS=false

echo "[INIT] Environment variables set:"
echo "  HF_HOME: $HF_HOME"
echo "  HUGGINGFACE_HUB_CACHE: $HUGGINGFACE_HUB_CACHE"
echo "  EASYOCR_MODULE_PATH: $EASYOCR_MODULE_PATH"
echo "  DOCLING_ARTIFACTS_PATH: $DOCLING_ARTIFACTS_PATH"
echo "  DOCLING_SERVE_ARTIFACTS_PATH: $DOCLING_SERVE_ARTIFACTS_PATH"

# Test if Python can import required packages
echo "[INIT] Testing Python imports..."
python3 -c "import docling_serve; print('✓ docling_serve imported successfully')" || echo "⚠️  docling_serve import failed"
python3 -c "import docling; print('✓ docling imported successfully')" || echo "⚠️  docling import failed"

# Download models using comprehensive approach
echo "[INIT] Starting comprehensive model downloads..."
python3 -c "
import os
print('[INIT] Method 1: Docling model downloader...')
try:
    import docling.utils.model_downloader as downloader
    downloader.download_models()
    print('[INIT] ✓ Docling model downloader completed')
except ImportError as e:
    print(f'[INIT] ⚠️  Could not import model downloader: {e}')
except Exception as e:
    print(f'[INIT] ⚠️  Docling model downloader failed: {e}')

print('[INIT] Method 2: Direct HuggingFace comprehensive download...')
try:
    from huggingface_hub import hf_hub_download, list_repo_files
    
    # Download all model artifacts comprehensively
    repo_id = 'ds4sd/docling-models'
    print('[INIT] Getting complete file list from HuggingFace...')
    
    try:
        all_files = list_repo_files(repo_id)
        model_files = [f for f in all_files if f.startswith('model_artifacts/')]
        
        print(f'[INIT] Found {len(model_files)} model artifacts to download')
        
        for file_path in model_files:
            try:
                print(f'[INIT] Downloading {file_path}...')
                downloaded_path = hf_hub_download(
                    repo_id=repo_id,
                    filename=file_path,
                    cache_dir='/models/.hf_cache'
                )
                print(f'[INIT] ✓ Downloaded: {os.path.basename(file_path)}')
            except Exception as e:
                print(f'[INIT] ⚠️  Failed to download {file_path}: {e}')
        
        print('[INIT] ✓ Comprehensive model download completed')
        
    except Exception as e:
        print(f'[INIT] ⚠️  Could not get file list: {e}')
        print('[INIT] Falling back to essential files...')
        
        # Fallback to essential files
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
                print(f'[INIT] Downloading {file_path}...')
                downloaded_path = hf_hub_download(
                    repo_id=repo_id,
                    filename=file_path,
                    cache_dir='/models/.hf_cache'
                )
                print(f'[INIT] ✓ Downloaded: {os.path.basename(file_path)}')
            except Exception as e:
                print(f'[INIT] ⚠️  Failed to download {file_path}: {e}')
        
except ImportError as e:
    print(f'[INIT] ⚠️  HuggingFace Hub not available: {e}')
except Exception as e:
    print(f'[INIT] ⚠️  Direct download failed: {e}')
"

# Initialize Docling to trigger any remaining model downloads
echo "[INIT] Initializing Docling converter to verify model setup..."
python3 -c "
import os
import sys
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

# Ensure critical environment variables are set
os.environ['HF_HOME'] = '/models/.hf_cache'
os.environ['HUGGINGFACE_HUB_CACHE'] = '/models/.hf_cache'
os.environ['EASYOCR_MODULE_PATH'] = '/models/EasyOcr'
os.environ['DOCLING_ARTIFACTS_PATH'] = '/models'
os.environ['DOCLING_SERVE_ARTIFACTS_PATH'] = '/models'

try:
    from docling.document_converter import DocumentConverter
    from docling.datamodel.base_models import InputFormat
    from docling.datamodel.pipeline_options import PdfPipelineOptions
    from docling.document_converter import PdfFormatOption
    
    print('[INIT] Setting up DocumentConverter with artifacts path...')
    
    # Initialize with specific artifacts path
    pipeline_options = PdfPipelineOptions(artifacts_path='/models')
    converter = DocumentConverter(
        format_options={
            InputFormat.PDF: PdfFormatOption(pipeline_options=pipeline_options)
        }
    )
    
    print('[INIT] ✓ DocumentConverter initialized successfully')
    print('[INIT] ✓ All models appear to be properly configured')
    
except Exception as e:
    print(f'[INIT] ⚠️  DocumentConverter initialization failed: {e}')
    print('[INIT] This may be normal on first run - continuing...')
"

# Download EasyOCR models explicitly if needed
echo "[INIT] Ensuring EasyOCR models are available..."
python3 -c "
import os
os.environ['EASYOCR_MODULE_PATH'] = '/models/EasyOcr'

try:
    import easyocr
    print('[INIT] Initializing EasyOCR to download models...')
    reader = easyocr.Reader(['en'], model_storage_directory='/models/EasyOcr', download_enabled=True)
    print('[INIT] ✓ EasyOCR models downloaded successfully')
except Exception as e:
    print(f'[INIT] ⚠️  EasyOCR initialization failed: {e}')
    print('[INIT] Continuing without EasyOCR models...')
"

# Verify what models were downloaded
echo "[INIT] Checking downloaded models..."
python3 -c "
from pathlib import Path
import os

models_dir = Path('/models')
print('[INIT] Contents of /models directory:')
if models_dir.exists():
    for item in sorted(models_dir.rglob('*')):
        if item.is_file() and item.stat().st_size > 1024*1024:  # Show files > 1MB
            size_mb = item.stat().st_size / (1024*1024)
            print(f'  📦 {item.relative_to(models_dir)} ({size_mb:.1f} MB)')
        elif item.is_dir():
            print(f'  📁 {item.relative_to(models_dir)}/')
else:
    print('  ❌ /models directory does not exist')

# Check for specific model files
critical_paths = [
    '/models/.hf_cache',
    '/models/EasyOcr',
    '/models/models--IBM--DocLayNet-base',
    '/models/models--unstructured-io--detectron2-layout-base-VGT'
]

print('[INIT] Checking critical model paths:')
for path in critical_paths:
    if Path(path).exists():
        print(f'  ✓ {path}')
    else:
        print(f'  ❌ {path} - missing')
"

# Create symlinks for Docling-Serve to find models at expected paths (non-critical)
echo "[INIT] Creating model symlinks..."
/usr/local/bin/fix-model-links.sh || echo "[INIT] ⚠️  Symlink creation failed - will retry later"

# Final verification - try to create a simple DocumentConverter to ensure models work
echo "[INIT] Final verification - testing model loading..."
python3 -c "
import os
import warnings
warnings.filterwarnings('ignore')

os.environ['DOCLING_ARTIFACTS_PATH'] = '/models'
os.environ['DOCLING_SERVE_ARTIFACTS_PATH'] = '/models'

try:
    from docling.document_converter import DocumentConverter
    print('[INIT] Creating DocumentConverter for final test...')
    converter = DocumentConverter()
    print('[INIT] ✓ DocumentConverter created successfully')
    print('[INIT] ✓ Models appear to be properly initialized')
    
    # Clear retry counter on success
    import os
    try:
        os.remove('/tmp/init_retry_count')
    except:
        pass
        
except Exception as e:
    print(f'[INIT] ⚠️  Final verification failed: {e}')
    print('[INIT] Service will start anyway - models may download on first use')
"

echo "[INIT] ==================================="
echo "[INIT] Model initialization completed!"
echo "[INIT] ==================================="

# Set final permissions
chown -R root:root /models
echo "[INIT] Permissions set - ready to start docling-serve" 