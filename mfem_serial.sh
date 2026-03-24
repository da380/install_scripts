#!/bin/bash

# Build MFEM
cmake -S $HOME/dev/mfem -B mfem_serial_build \
      -DCMAKE_C_COMPILER=gcc-14.1.0          \
      -DCMAKE_CXX_COMPILER=g++-14.1.0        \
      -DCMAKE_BUILD_TYPE=RELEASE             \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON

cmake --build mfem_serial_build -j 10
cmake --build mfem_serial_build -t tests -j 10
cmake --build mfem_serial_build -t examples -j 10
cmake --build mfem_serial_build -t miniapps -j 10

# Build GLVis
cmake -S $HOME/dev/glvis -B glvis_build      \
      -DCMAKE_C_COMPILER=gcc-14.1.0          \
      -DCMAKE_CXX_COMPILER=g++-14.1.0        \
      -DMFEM_DIR=$HOME/dev/mfem_serial_build \
      -DMFEM_DIR=mfem_serial_build           \
      -DCMAKE_BUILD_TYPE=RELEASE

cmake --build glvis_build -j 10
