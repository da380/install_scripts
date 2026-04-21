#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "========================================="
echo " Installing Gmsh from Source (with OCC/FLTK) "
echo "========================================="

# 1. Define Paths
DEV_DIR="$HOME/dev"
GMSH_SRC_DIR="$DEV_DIR/gmsh"
mkdir -p "$DEV_DIR"

# 2. Clean up existing system Gmsh to avoid conflicts
echo "--> Removing existing system gmsh packages..."
sudo apt remove -y gmsh libgmsh-dev || true

# 3. Install Dependencies
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

# 4. Clone Repository
if [ -d "$GMSH_SRC_DIR" ]; then
    echo "--> Updating existing Gmsh repository..."
    cd "$GMSH_SRC_DIR"
    git pull
else
    echo "--> Cloning Gmsh from GitLab..."
    cd "$DEV_DIR"
    git clone https://gitlab.onelab.info/gmsh/gmsh.git
    cd gmsh
fi

# 5. Configure and Build
echo "--> Configuring with FLTK and OCC..."
mkdir -p build
cd build

# Clear old cache to ensure a fresh scan for the new libraries
rm -f CMakeCache.txt

cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_FLTK=ON \
    -DENABLE_OCC=ON \
    -DENABLE_BUILD_DYNAMIC=ON \
    -DENABLE_PRIVATE_API=ON

echo "--> Compiling..."
make -j$(nproc)

# 6. Install
echo "--> Installing to /usr/local..."
sudo make install

echo "========================================="
echo " Gmsh Source Build Complete! "
echo "========================================="
