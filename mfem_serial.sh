#!/bin/bash

cmake -S $HOME/dev/mfem -B mfem_serial_build \
      -DCMAKE_CXX_COMPILER=g++-13            \
      -DCMAKE_BUILD_TYPE=RELEASE

cmake --build mfem_serial_build -j 20
cmake --build mfem_serial_build -t tests -j 20
cmake --build mfem_serial_build -t examples -j 20
cmake --build mfem_serial_build -t miniapps -j 20



cmake -S $HOME/dev/glvis -B glvis_build  \
      -DCMAKE_CXX_COMPILER=g++-13        \
      -DMFEM_DIR=mfem_serial_build       \
      -DCMAKE_BUILD_TYPE=RELEASE

cmake --build glvis_build -j 20
