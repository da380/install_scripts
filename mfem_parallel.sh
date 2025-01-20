#!/bin/bash

DEV=$HOME/dev
PETSC_DIR=$DEV/petsc-install


cmake -S $DEV/mfem -B mfem_parallel_build \
      -DCMAKE_BUILD_TYPE=RELEASE               \
      -DMFEM_USE_MPI=ON                        \
      -DMPI_CXX_COMPILER=$PETSC_DIR/mpicxx


