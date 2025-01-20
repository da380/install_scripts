#!/bin/bash

DEV=$HOME/dev
PETSC_DIR=$DEV/petsc-install


cmake -S $DEV/mfem -B mfem_parallel_build \
      -DCMAKE_BUILD_TYPE=RELEASE          \
      -DMFEM_USE_MPI=ON                   \
      -DHYPRE_DIR=$PETSC_DIR              \
      -DMETIS_DIR=$PETSC_DIR          


cmake --build mfem_parallel_build -j 20

cmake --build mfem_parallel_build -t examples -j 20

cmake --build mfem_parallel_build -t tests -j 20

cmake --build mfem_parallel_build -t miniapps -j 20


