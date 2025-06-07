#!/bin/bash

# Build Docling-Serve with Blackwell (SM 120) FlashAttention-2 optimization
# Add --progress=plain for verbose logging

# Default build (quiet)
if [ "$1" = "-v" ] || [ "$1" = "--verbose" ]; then
    echo "Building with verbose output..."
    DOCKER_BUILDKIT=1 docker build . -f dockerfile -t docling-serve:blackwell-fa2 \
      --build-arg TORCH_CUDA_ARCH_LIST="12.0;12.1" \
      --build-arg MAX_JOBS=6 \
      --progress=plain
else
    echo "Building with standard output (use -v for verbose)..."
    DOCKER_BUILDKIT=1 docker build . -f dockerfile -t docling-serve:blackwell-fa2 \
      --build-arg TORCH_CUDA_ARCH_LIST="12.0;12.1" \
      --build-arg MAX_JOBS=6
fi 