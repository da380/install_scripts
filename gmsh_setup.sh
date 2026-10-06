#!/bin/bash
#
# Build and install Gmsh from source (with OCC and FLTK), into /usr/local.

set -euo pipefail

source "$(dirname "$(readlink -f "$0")")/common.sh"

echo "========================================="
echo " Installing Gmsh from Source (with OCC/FLTK) "
echo "========================================="

GMSH_SRC_DIR=$DEV/gmsh
GMSH_BUILD_DIR=$GMSH_SRC_DIR/build
mkdir -p "$DEV"

# 1. Clean up existing system Gmsh to avoid conflicts
echo "--> Removing existing system gmsh packages..."
sudo apt remove -y gmsh libgmsh-dev || true

# 2. Install Dependencies
echo "--> Installing Build Dependencies..."
sudo apt update
sudo apt install -y \
    build-essential \
    cmake \
    git \
    libfltk1.3-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libx11-dev \
    libxext-dev \
    libxft-dev \
    libxinerama-dev \
    libxcursor-dev \
    libocct-modeling-algorithms-dev \
    libocct-modeling-data-dev \
    libocct-ocaf-dev \
    libocct-data-exchange-dev \
    libocct-visualization-dev \
    libocct-foundation-dev

# 3. Clone or update the repository
if [ -d "$GMSH_SRC_DIR" ]; then
    echo "--> Updating existing Gmsh repository..."
    git -C "$GMSH_SRC_DIR" pull
else
    echo "--> Cloning Gmsh from GitLab..."
    git clone https://gitlab.onelab.info/gmsh/gmsh.git "$GMSH_SRC_DIR"
fi

# 4. Configure and build (fresh configure: clear any old cache so the
# newly installed libraries are picked up)
echo "--> Configuring with FLTK and OCC..."
rm -f "$GMSH_BUILD_DIR/CMakeCache.txt"

cmake -S "$GMSH_SRC_DIR" -B "$GMSH_BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_FLTK=ON \
    -DENABLE_OCC=ON \
    -DENABLE_BUILD_DYNAMIC=ON \
    -DENABLE_PRIVATE_API=ON

echo "--> Compiling..."
cmake --build "$GMSH_BUILD_DIR" -j "$(nproc)"

# 5. Install
echo "--> Installing to /usr/local..."
sudo cmake --install "$GMSH_BUILD_DIR"

echo "========================================="
echo " Gmsh Source Build Complete! "
echo "========================================="
