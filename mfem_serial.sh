#!/bin/bash

# Build MFEM
cmake -S $HOME/dev/mfem -B mfem_serial_build \
      -DCMAKE_BUILD_TYPE=RELEASE             \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON

cmake --build mfem_serial_build -j 10
cmake --build mfem_serial_build -t tests -j 10
cmake --build mfem_serial_build -t examples -j 10
cmake --build mfem_serial_build -t miniapps -j 10

# Build GLVis
cmake -S $HOME/dev/glvis -B glvis_build      \
      -DMFEM_DIR=$HOME/dev/mfem_serial_build \
      -DMFEM_DIR=mfem_serial_build           \
      -DCMAKE_BUILD_TYPE=RELEASE

cmake --build glvis_build -j 10
