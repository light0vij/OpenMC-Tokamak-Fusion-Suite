#!/usr/bin/env bash
# OpenMC-Tokamak-Fusion-Suite.sh
# Builds the image (first run only) and starts the container.
#
#   ./OpenMC-Tokamak-Fusion-Suite.sh
#
# Then open http://localhost:8888

# -----------------------------------------------------
# EDIT THIS LINE: the folder that contains fendl-3.2-hdf5/ (downloaded separately).
# Optional libraries (endfb-viii.0-hdf5, endfb-vii.1-hdf5) are also mounted if they are in the same folder.
DATA_DIR="/YOUR/PATH/openmc_data"
# ---------------------------------------------------------------

set -eu
cd "$(dirname "$0")"

NAME="OpenMC-Tokamak-Fusion-Suite"
IMAGE="openmc-tokamak-fusion-suite:latest"      # image names must be lower case

# The container already exists: just start it again.
if docker ps -a --format '{{.Names}}' | grep -qx "$NAME"; then
  docker start "$NAME"
  echo "Started. Open http://localhost:8888"
  exit 0
fi

# Check the nuclear data.
if [ ! -f "$DATA_DIR/fendl-3.2-hdf5/cross_sections.xml" ]; then
  echo "ERROR: $DATA_DIR/fendl-3.2-hdf5/cross_sections.xml not found."
  echo "Download FENDL-3.2 (see README.md) or edit DATA_DIR in this script."
  exit 1
fi

# Check the depletion chain (part of the repository, used by the depletion and SDDR notebooks).
CHAIN="$PWD/chain/chain_fendl30_fusion_complete.xml"
if [ ! -f "$CHAIN" ] || [ "$(wc -c < "$CHAIN" | tr -d ' ')" -lt 1000 ]; then
  echo "WARNING: chain/chain_fendl30_fusion_complete.xml is missing or incomplete."
  echo "The depletion and SDDR notebooks need the full file."
fi

# Build the image if it is not there yet (compiles OpenMC; takes a while).
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  docker build --build-arg COMPILE_CORES="${COMPILE_CORES:-4}" -t "$IMAGE" .
fi

# Mount every nuclear data library that exists in DATA_DIR (read-only).
DATA_MOUNTS=()
for lib in fendl-3.2-hdf5 endfb-viii.0-hdf5 endfb-vii.1-hdf5; do
  if [ -d "$DATA_DIR/$lib" ]; then
    DATA_MOUNTS+=(-v "$DATA_DIR/$lib:/nuclear_data/$lib:ro")
  fi
done

docker run -d \
  --name "$NAME" \
  -p 127.0.0.1:8888:8888 \
  --shm-size=2gb \
  -v "$PWD/notebooks:/workspace/notebooks" \
  -v "$PWD/chain:/workspace/chain" \
  "${DATA_MOUNTS[@]}" \
  -e JUPYTER_ENABLE_LAB=yes \
  "$IMAGE"

echo "Started. Open http://localhost:8888"
