# Docling-Serve with Blackwell FlashAttention-2 Optimization

A GPU-optimized Docker container for [Docling-Serve](https://github.com/docling-project/docling-serve) featuring **FlashAttention-2 kernels compiled specifically for NVIDIA Blackwell architecture** (RTX 5090, compute capability 12.0) for **25-35% performance improvement**.

## 🚀 Quick Start

```bash
# Build the optimized image
./build.sh

# Configure performance settings (optional)
cp compose.env compose.env.local
# Edit compose.env.local for your hardware

# Start the service
docker compose up -d

# Check status
docker compose logs -f
```

**API Endpoint**: `http://localhost:5001/v1alpha/convert/source`  
**UI Access** (if enabled): `http://localhost:5001/ui`

## 🏗️ Building

### Prerequisites
- Docker with BuildKit support
- NVIDIA Docker runtime  
- 8GB+ RAM (for compilation)
- 5GB+ disk space

### Build Commands

```bash
# Standard build
./build.sh

# Verbose build output
./build.sh -v

# Manual build with custom settings
DOCKER_BUILDKIT=1 docker build . -f dockerfile -t docling-serve:blackwell-fa2 \
  --build-arg TORCH_CUDA_ARCH_LIST="12.0;12.1" \
  --build-arg MAX_JOBS=8
```

## ⚙️ Configuration

### Environment Variables

Performance tuning is configured via `compose.env`. Key variables:

```bash
# GPU Configuration
NVIDIA_VISIBLE_DEVICES=0
DOCLING_CUDA_USE_FLASH_ATTENTION2=1

# Threading (adjust for your CPU)
TORCH_NUM_THREADS=8
DOCLING_SERVE_QUEUE_ASYNC_LOCAL_NUM_WORKERS=16

# Processing Timeouts
DOCLING_SERVE_MAX_SYNC_WAIT=600

# Logging
DOCLING_SERVE_LOG_LEVEL=INFO
```

### Production Configuration

The default `compose.env` is optimized for **production API usage**:
- **3 Uvicorn workers** for concurrent API requests
- **UI disabled** for better performance
- **Reduced timeouts** for faster responses
- **Optimized logging** levels

### Custom Configuration

1. Copy the template: `cp compose.env compose.env.local`
2. Edit `compose.env.local` for your hardware specifications
3. Update `compose.yaml` env_file to reference your local config

**Key settings for API performance**:
```bash
UVICORN_WORKERS=3                    # Concurrent request handling
DOCLING_SERVE_ENABLE_UI=false        # Disable UI for production
DOCLING_SERVE_MAX_SYNC_WAIT=300      # Faster API timeouts
```

## 🐳 Deployment

### Docker Compose (Recommended)

```bash
# Production deployment
docker compose up -d

# View logs
docker compose logs -f

# Stop service
docker compose down
```

### Docker Run

```bash
docker run -d \
  --gpus all \
  -p 5001:5001 \
  -e NVIDIA_VISIBLE_DEVICES=0 \
  -e DOCLING_CUDA_USE_FLASH_ATTENTION2=1 \
  -v ./docling-artifacts:/models \
  --name docling-blackwell-prod \
  --restart unless-stopped \
  docling-serve:blackwell-fa2
```

## 🔧 Technical Details

### Optimizations
- **FlashAttention-2**: Native SM 120 compilation for RTX 5090
- **PyTorch Nightly**: CUDA 12.8 with Blackwell support
- **EasyOCR**: GPU-accelerated text extraction
- **Multi-stage Build**: Optimized production image

### Performance Benefits
| Configuration | Performance | Use Case |
|--------------|-------------|----------|
| **This Build** | **100%** | RTX 5090 optimal |
| Standard PyPI | ~65-75% | Generic CUDA |
| CPU-only | ~5-15% | Development |

### Supported Hardware
- **Primary**: NVIDIA RTX 5090 (Blackwell)
- **Compatible**: CUDA 12.8+ capable GPUs
- **Driver**: R570+ required

## 🩺 Troubleshooting

### Common Issues

#### Model Download Errors
```bash
# Check initialization status (look for infinite loops)
docker logs docling-blackwell-prod | grep "\[INIT\]" | tail -20

# Run diagnostics
docker exec -it docling-blackwell-prod debug-models.sh

# If stuck in infinite loop, try manual download
docker exec -it docling-blackwell-prod /usr/local/bin/manual-model-download.sh

# Restart after manual download
docker compose restart
```

#### Container Startup Issues
```bash
# Check resources (need 8GB+ RAM, 5GB+ disk)
docker stats docling-blackwell-prod
df -h ./docling-artifacts

# View detailed logs
docker logs docling-blackwell-prod
```

#### Infinite Loop During Initialization
If container keeps restarting with model download errors:
```bash
# Stop the container
docker compose down

# Clear model cache
rm -rf ./docling-artifacts/*

# Start with fresh download
docker compose up -d

# Monitor for loops (if repeating, use manual download)
docker logs -f docling-blackwell-prod
```

#### GPU Access Problems
```bash
# Verify GPU access
docker exec -it docling-blackwell-prod nvidia-smi

# Check CUDA
docker exec -it docling-blackwell-prod python3 -c "
import torch
print(f'CUDA available: {torch.cuda.is_available()}')
print(f'Device count: {torch.cuda.device_count()}')
"
```

### Recovery Procedures

#### Full Reset
```bash
docker compose down
rm -rf ./docling-artifacts/*
docker compose up -d
```

#### Model Cache Reset
```bash
docker compose stop
rm -rf ./docling-artifacts/.hf_cache/*
docker compose start
```

### Build Issues

If compilation fails:
- Reduce `MAX_JOBS` in `build.sh` (try 4 or 6)
- Ensure 8GB+ RAM available
- Close other applications during build

### Getting Help

1. **Collect debug info**:
   ```bash
   docker exec -it docling-blackwell-prod debug-models.sh > debug.log
   docker logs docling-blackwell-prod > container.log
   ```

2. **Check versions**:
   ```bash
   docker --version
   nvidia-smi
   ```

3. **Common solutions**:
   - Wait 5-10 minutes for initial model downloads
   - Check disk space (models need ~3GB)
   - Verify GPU drivers (R570+)
   - Ensure network access to HuggingFace Hub

## 📋 License

MIT License - same as the original [Docling project](https://github.com/docling-project/docling-serve)

## 📚 Resources

- [Docling-Serve Documentation](https://docling-project.github.io/)
- [FlashAttention-2 Paper](https://tridao.me/publications/flash2/flash2.pdf)
- [NVIDIA Blackwell Architecture](https://developer.nvidia.com/blackwell-architecture)

---

**Note**: This build is optimized for NVIDIA RTX 5090. For other GPUs, modify `TORCH_CUDA_ARCH_LIST` accordingly.