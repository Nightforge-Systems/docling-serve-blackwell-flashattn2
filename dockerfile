# ── Stage 1: Build Environment ───────────────────────────────────────────
ARG UBUNTU_VERSION=22.04
FROM nvidia/cuda:12.8.0-devel-ubuntu${UBUNTU_VERSION} AS builder

# Build arguments for GPU architecture targeting
ARG TORCH_CUDA_ARCH_LIST="12.0;12.1"
ARG MAX_JOBS=8

# Environment setup
ENV DEBIAN_FRONTEND=noninteractive \
    TORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST} \
    MAX_JOBS=${MAX_JOBS}

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.11 \
        python3.11-venv \
        python3.11-dev \
        python3-pip \
        git \
        build-essential \
        cmake \
        ninja-build \
        pkg-config \
        && rm -rf /var/lib/apt/lists/*

# Create and activate Python virtual environment
RUN python3.11 -m venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

# Upgrade pip and install build tools
RUN pip install --upgrade pip wheel setuptools

# Install PyTorch nightly with CUDA 12.8 support (includes SM 120 kernels)
RUN pip install --no-cache-dir --pre \
    --index-url https://download.pytorch.org/whl/nightly/cu128 \
    torch torchvision torchaudio

# Build FlashAttention-2 from source with Blackwell SM 120 optimization
# This ensures FA2 kernels are compiled specifically for compute capability 12.0
RUN git clone --depth 1 https://github.com/Dao-AILab/flash-attention.git && \
    cd flash-attention && \
    pip install packaging ninja && \
    # Build with explicit SM 120 support for Blackwell architecture
    TORCH_CUDA_ARCH_LIST="12.0;12.1" \
    MAX_JOBS=${MAX_JOBS} \
    python setup.py bdist_wheel && \
    pip install dist/*.whl && \
    cd .. && rm -rf flash-attention

# Clone and install Docling-Serve from source 
# This ensures it links against our locally built FlashAttention-2
RUN git clone --depth 1 https://github.com/docling-project/docling-serve.git && \
    cd docling-serve && \
    pip install .[ui] && \
    cd .. && rm -rf docling-serve

# Additional OCR dependencies will be handled by EasyOCR (GPU-accelerated)

# ── Stage 2: Runtime Environment ────────────────────────────────────────
FROM nvidia/cuda:12.8.0-runtime-ubuntu${UBUNTU_VERSION}

# Runtime environment variables
ENV PATH="/opt/venv/bin:${PATH}" \
    DOCLING_CUDA_USE_FLASH_ATTENTION2="1" \
    PYTHONUNBUFFERED=1 \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Copy the built Python environment from builder stage
COPY --from=builder /opt/venv /opt/venv

# Copy initialization, debug, and fix scripts
COPY scripts/init-models.sh /usr/local/bin/init-models.sh
COPY scripts/debug-models.sh /usr/local/bin/debug-models.sh
COPY scripts/fix-model-links.sh /usr/local/bin/fix-model-links.sh
COPY scripts/manual-model-download.sh /usr/local/bin/manual-model-download.sh
COPY scripts/download-vision-models.sh /usr/local/bin/download-vision-models.sh
RUN chmod +x /usr/local/bin/init-models.sh /usr/local/bin/debug-models.sh /usr/local/bin/fix-model-links.sh /usr/local/bin/manual-model-download.sh /usr/local/bin/download-vision-models.sh

# Install minimal runtime dependencies (EasyOCR is primary OCR engine)
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.11 \
        curl \
        && rm -rf /var/lib/apt/lists/*

# Expose Docling-Serve port
EXPOSE 5001

# Health check to verify the service is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:5001/health || exit 1

# Set entrypoint to run Docling-Serve (UI controlled via environment variables)
ENTRYPOINT ["docling-serve", "run"] 