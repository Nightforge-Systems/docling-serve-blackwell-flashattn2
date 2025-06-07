#!/bin/bash

# debug-models.sh - Comprehensive model debugging script for Docling-Serve

echo "======================================================================"
echo "Docling-Serve Model Debug Tool"
echo "======================================================================"

echo ""
echo "1. ENVIRONMENT VARIABLES"
echo "----------------------------------------------------------------------"
echo "DOCLING_ARTIFACTS_PATH: ${DOCLING_ARTIFACTS_PATH:-'NOT SET'}"
echo "DOCLING_SERVE_ARTIFACTS_PATH: ${DOCLING_SERVE_ARTIFACTS_PATH:-'NOT SET'}"
echo "HF_HOME: ${HF_HOME:-'NOT SET'}"
echo "HUGGINGFACE_HUB_CACHE: ${HUGGINGFACE_HUB_CACHE:-'NOT SET'}"
echo "EASYOCR_MODULE_PATH: ${EASYOCR_MODULE_PATH:-'NOT SET'}"
echo "DOCLING_DISABLE_MODEL_DOWNLOADS: ${DOCLING_DISABLE_MODEL_DOWNLOADS:-'NOT SET'}"
echo "HF_HUB_OFFLINE: ${HF_HUB_OFFLINE:-'NOT SET'}"
echo "DOCLING_CUDA_USE_FLASH_ATTENTION2: ${DOCLING_CUDA_USE_FLASH_ATTENTION2:-'NOT SET'}"

echo ""
echo "2. DIRECTORY STRUCTURE"
echo "----------------------------------------------------------------------"
if [ -d "/models" ]; then
    echo "📁 /models directory exists"
    du -sh /models/* 2>/dev/null | head -20 || echo "  (empty or no readable files)"
else
    echo "❌ /models directory does not exist"
fi

echo ""
echo "3. HF CACHE STRUCTURE"
echo "----------------------------------------------------------------------"
if [ -d "/models/.hf_cache" ]; then
    echo "📁 HF cache exists:"
    find /models/.hf_cache -type f -name "*.safetensors" -o -name "*.bin" -o -name "*.pt" 2>/dev/null | head -10
else
    echo "❌ HF cache does not exist"
fi

echo ""
echo "4. PYTHON PACKAGE VERSIONS"
echo "----------------------------------------------------------------------"
python3 -c "
import sys
packages = ['torch', 'transformers', 'docling', 'docling_serve', 'huggingface_hub']
for pkg in packages:
    try:
        mod = __import__(pkg)
        version = getattr(mod, '__version__', 'Unknown')
        print(f'{pkg}: {version}')
    except ImportError:
        print(f'{pkg}: NOT INSTALLED')
"

echo ""
echo "5. MODEL DOWNLOAD TEST"
echo "----------------------------------------------------------------------"
python3 -c "
import os
import warnings
warnings.filterwarnings('ignore')

# Set environment variables
os.environ['HF_HOME'] = '/models/.hf_cache'
os.environ['DOCLING_ARTIFACTS_PATH'] = '/models'
os.environ['DOCLING_SERVE_ARTIFACTS_PATH'] = '/models'
os.environ['HF_HUB_OFFLINE'] = '0'

print('Testing model download capabilities...')

try:
    import docling.utils.model_downloader as downloader
    print('✓ Model downloader imported successfully')
    
    # Try to download models
    downloader.download_models()
    print('✓ Model download completed successfully')
    
except ImportError as e:
    print(f'❌ Could not import model downloader: {e}')
    print('  This is expected if docling.utils.model_downloader is not available')
except Exception as e:
    print(f'❌ Model download failed: {e}')

print('')
print('Testing DocumentConverter initialization...')
try:
    from docling.document_converter import DocumentConverter
    converter = DocumentConverter()
    print('✓ DocumentConverter created successfully')
except Exception as e:
    print(f'❌ DocumentConverter creation failed: {e}')
    import traceback
    traceback.print_exc()
"

echo ""
echo "6. DISK SPACE"
echo "----------------------------------------------------------------------"
df -h /models 2>/dev/null || df -h /

echo ""
echo "7. NETWORK CONNECTIVITY"
echo "----------------------------------------------------------------------"
if command -v curl >/dev/null 2>&1; then
    echo "Testing HuggingFace Hub connectivity:"
    curl -s --max-time 10 https://huggingface.co > /dev/null && echo "✓ HuggingFace Hub accessible" || echo "❌ HuggingFace Hub not accessible"
else
    echo "curl not available - cannot test network connectivity"
fi

echo ""
echo "8. DOCLING-SERVE HEALTH"
echo "----------------------------------------------------------------------"
if pgrep -f "docling-serve" > /dev/null; then
    echo "✓ Docling-Serve process is running"
    if command -v curl >/dev/null 2>&1; then
        curl -s http://localhost:5001/health > /dev/null && echo "✓ Health endpoint accessible" || echo "❌ Health endpoint not accessible"
    fi
else
    echo "❌ Docling-Serve process not running"
fi

echo ""
echo "======================================================================"
echo "Debug completed. If issues persist, check the logs above for errors."
echo "======================================================================" 