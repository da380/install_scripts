#!/bin/bash

cmake -S $HOME/dev/mfem -B mfem_serial_build -DCMAKE_BUILD_TYPE=RELEASE
cmake --build mfem_serial_build -j 20

cmake -S $HOME/dev/glvis -B glvis_build -DMFEM_DIR=mfem_serial_build -DCMAKE_BUILD_TYPE=RELEASE
cmake --build glvis_build -j 20
