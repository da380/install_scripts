#!/bin/bash

# Default values
NJOBS=8
BUILD_EXAMPLES="OFF"
BUILD_TESTS="OFF"
BUILD_GMSH="OFF"
BUILD_DOCS="OFF"

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -j|--jobs) NJOBS="$2"; shift ;;
        -e|--examples) BUILD_EXAMPLES="ON" ;;
        -t|--tests) BUILD_TESTS="ON" ;;
        -m|--meshing) BUILD_GMSH="ON" ;;
        -d|--docs) BUILD_DOCS="ON" ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "  -j, --jobs <N>   Number of parallel build jobs (default: 8)"
            echo "  -e, --examples   Build examples (BUILD_EXAMPLES)"
            echo "  -t, --tests      Build tests (BUILD_TESTS)"
            echo "  -m, --meshing    Build gmsh meshing programs (BUILD_GMSH)"
            echo "  -d, --docs       Build Doxygen documentation (BUILD_DOCS)"
            exit 0
            ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

DEV=$HOME/dev
PROJECT_DIR=$DEV/mfemElasticity
MFEM_DIR=$DEV/mfem_serial_build
BUILD_DIR=$PROJECT_DIR/build_serial

echo "========================================================"
echo " Building mfemElasticity (SERIAL)"
echo " Jobs: $NJOBS | Examples: $BUILD_EXAMPLES | Tests: $BUILD_TESTS | Meshing: $BUILD_GMSH | Docs: $BUILD_DOCS"
echo "========================================================"

rm -rf $BUILD_DIR

cmake -S $PROJECT_DIR -B $BUILD_DIR \
      -DCMAKE_C_COMPILER=gcc-14.1.0 \
      -DCMAKE_CXX_COMPILER=g++-14.1.0 \
      -DCMAKE_BUILD_TYPE=RELEASE \
      -DMFEM_DIR=$MFEM_DIR \
      -DUSE_MPI=OFF \
      -DBUILD_EXAMPLES=$BUILD_EXAMPLES \
      -DBUILD_TESTS=$BUILD_TESTS \
      -DBUILD_GMSH=$BUILD_GMSH \
      -DBUILD_DOCS=$BUILD_DOCS

# Build everything that was enabled
cmake --build $BUILD_DIR -j $NJOBS

echo "Done! Build files are in $BUILD_DIR"
