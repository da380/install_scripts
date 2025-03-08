#!/bin/bash

DEV=$HOME/dev
PETSC_DIR=$DEV/petsc-install
PETSC_BIN=$PETSC_DIR/bin

BUILD=mfem_parallel_build


cmake -S $DEV/mfem -B $BUILD                   \
      -DMPI_C_COMPILER=$PETSC_BIN/mpicc        \
      -DMPI_CXX_COMPILER=$PETSC_BIN/mpic++     \
      -DCMAKE_BUILD_TYPE=RELEASE               \
      -DMFEM_USE_MPI=ON                        \
      -DHYPRE_DIR=$PETSC_DIR                   \
      -DMETIS_DIR=$PETSC_DIR                   \
      -DMFEM_USE_PETSC=ON                      \
      -DPETSC_DIR=$PETSC_DIR                   \
      -DPETSC_ARCH=""


cmake --build $BUILD -j 20

cmake --build $BUILD -t examples -j 20

cmake --build $BUILD -t miniapps -j 20

cmake --build $BUILD -t tests -j 20




