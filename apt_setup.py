#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "========================================="
echo " Setting up Ubuntu 24.04 Dev Environment "
echo "========================================="

echo "--> Updating package lists..."
sudo apt update

echo "--> Installing Core Build Tools & Version Control..."
sudo apt install -y \
    build-essential \
    cmake \
    pkg-config \
    git \
    autoconf \
    libtool \
    doxygen \
    gfortran \
    clangd \
    clang-format

# Uncomment the next two lines if you decide you absolutely need GCC 14
echo "--> Installing GCC 14..."
sudo apt install -y gcc-14 g++-14

echo "--> Installing Python environment (needed for PETSc configure)..."
# Ubuntu 24.04 uses Python 3.12 by default
sudo apt install -y \
    python3 \
    python3-dev \
    python3-venv

echo "--> Installing Graphics, Windowing, and Font libraries (for GLVis)..."
sudo apt install -y \
    libgl1-mesa-dev \
    libglew-dev \
    libsdl2-dev \
    libfontconfig1-dev \
    libfreetype-dev    \
    libglm-dev



echo "========================================="
echo " Setup complete! "
echo " Reminder: MPI, HYPRE, and METIS are omitted here so PETSc can build them."
echo "========================================="
