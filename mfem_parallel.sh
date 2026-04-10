#!/bin/bash

# ---------------------------------------------------------
# Set the number of parallel build jobs.
# This uses the first argument passed to the script (e.g., ./mfem_parallel.sh 10).
# If no argument is passed, it defaults to 8).
# ---------------------------------------------------------
NJOBS=${1:-8}

DEV=$HOME/dev
PETSC_DIR=$DEV/petsc-install
PETSC_BIN=$PETSC_DIR/bin

BUILD=$DEV/mfem_parallel_build

# 1. Nuke the old cache 
rm -rf $BUILD

# 2. Configure Parallel MFEM
cmake -S $DEV/mfem -B $BUILD                       \
      -DCMAKE_C_COMPILER=$PETSC_BIN/mpicc          \
      -DCMAKE_CXX_COMPILER=$PETSC_BIN/mpic++       \
      -DCMAKE_BUILD_TYPE=RELEASE                   \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON         \
      -DMFEM_USE_MPI=ON                            \
      -DMFEM_USE_PETSC=ON                          \
      -DHYPRE_DIR=$PETSC_DIR                       \
      -DMETIS_DIR=$PETSC_DIR                       \
      -DPETSC_DIR=$PETSC_DIR                       \
      -DPETSC_ARCH=""

# 3. Build the library, examples, miniapps, and tests using $NJOBS
cmake --build $BUILD -j $NJOBS
cmake --build $BUILD -t examples -j $NJOBS
cmake --build $BUILD -t miniapps -j $NJOBS
cmake --build $BUILD -t tests -j $NJOBS
