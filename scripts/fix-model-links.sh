#!/bin/bash

# fix-model-links.sh - Create symlinks for Docling-Serve to find models

echo "[FIX] Creating model symlinks for Docling-Serve..."

# Check if snapshots directory exists first
SNAPSHOTS_BASE="/models/.hf_cache/models--ds4sd--docling-models/snapshots"
if [ ! -d "$SNAPSHOTS_BASE" ]; then
    echo "[FIX] ⚠️  Snapshots directory not found: $SNAPSHOTS_BASE"
    echo "[FIX] This is normal on first run - models may still be downloading"
    echo "[FIX] Skipping symlink creation for now"
    return 0 2>/dev/null || exit 0
fi

# Find the actual model snapshot directory
SNAPSHOT_DIR=$(find "$SNAPSHOTS_BASE" -name "model_artifacts" -type d 2>/dev/null | head -1)

if [ -z "$SNAPSHOT_DIR" ]; then
    echo "[FIX] ⚠️  Could not find model_artifacts directory in snapshots"
    echo "[FIX] Available snapshots:"
    ls -la "$SNAPSHOTS_BASE" 2>/dev/null || echo "[FIX]   (no snapshots found)"
    echo "[FIX] Skipping symlink creation - models may still be downloading"
    return 0 2>/dev/null || exit 0
fi

SNAPSHOT_BASE=$(dirname "$SNAPSHOT_DIR")
echo "[FIX] Found models at: $SNAPSHOT_BASE"

# Create the main model.safetensors symlink (layout model)
LAYOUT_MODEL="$SNAPSHOT_DIR/layout/model.safetensors"
if [ -f "$LAYOUT_MODEL" ]; then
    echo "[FIX] Creating symlink: /models/model.safetensors -> $LAYOUT_MODEL"
    ln -sf "$LAYOUT_MODEL" /models/model.safetensors
else
    echo "[FIX] ⚠️  Layout model not found at $LAYOUT_MODEL"
fi

# Create symlinks for TableFormer models
TABLEFORMER_ACCURATE="$SNAPSHOT_DIR/tableformer/accurate/tableformer_accurate.safetensors"
TABLEFORMER_FAST="$SNAPSHOT_DIR/tableformer/fast/tableformer_fast.safetensors"

if [ -f "$TABLEFORMER_ACCURATE" ]; then
    echo "[FIX] Creating symlink: /models/tableformer_accurate.safetensors -> $TABLEFORMER_ACCURATE"
    ln -sf "$TABLEFORMER_ACCURATE" /models/tableformer_accurate.safetensors
else
    echo "[FIX] ⚠️  TableFormer accurate model not found"
fi

if [ -f "$TABLEFORMER_FAST" ]; then
    echo "[FIX] Creating symlink: /models/tableformer_fast.safetensors -> $TABLEFORMER_FAST"
    ln -sf "$TABLEFORMER_FAST" /models/tableformer_fast.safetensors
else
    echo "[FIX] ⚠️  TableFormer fast model not found"
fi

# Create a model_artifacts symlink for compatibility
echo "[FIX] Creating model_artifacts symlink: /models/model_artifacts -> $SNAPSHOT_DIR"
ln -sf "$SNAPSHOT_DIR" /models/model_artifacts

# List created symlinks
echo "[FIX] Created symlinks:"
ls -la /models/*.safetensors 2>/dev/null || echo "  No .safetensors symlinks found"
ls -la /models/model_artifacts 2>/dev/null || echo "  No model_artifacts symlink found"

echo "[FIX] Model symlinks created successfully!" 