#!/bin/bash
#
# Configure and build MFEM, serial or parallel.
#
#   build_mfem.sh serial   [options] [-- extra cmake args]
#   build_mfem.sh parallel [options] [-- extra cmake args]
#
# The serial build uses $SERIAL_CC/$SERIAL_CXX and also builds GLVis
# when $DEV/glvis exists. The parallel build uses the MPI wrappers from
# the PETSc install together with its hypre and metis; MFEM's own PETSc
# interface is not enabled (PETSc is used purely as a dependency
# provider here).
# mfem_serial.sh and mfem_parallel.sh are thin wrappers that pick the mode.

set -euo pipefail

source "$(dirname "$(readlink -f "$0")")/common.sh"

usage() {
    cat <<USAGE
Usage: $(basename "$0") serial|parallel [options] [-- extra cmake args]

Options (the examples, miniapps and unit tests are built by default;
GLVis is built in serial mode when \$DEV/glvis exists):
  -j, --jobs N        parallel build jobs (default: all cores, $(nproc))
      --no-examples   skip the examples
      --no-miniapps   skip the miniapps
      --no-tests      skip the unit tests
      --no-glvis      serial mode: do not build GLVis
  -g, --debug         Debug build type (default: Release)
  -k, --keep          keep the existing build directory (incremental build)
  -h, --help          this message

Paths and compilers come from common.sh and can be overridden from the
environment or local.env (DEV, PETSC_INSTALL, MPICC, MPICXX, ...).

Anything after -- is passed to cmake unchanged.
USAGE
}

NJOBS=$(nproc)
BUILD_EXAMPLES=1
BUILD_MINIAPPS=1
BUILD_TESTS=1
BUILD_GLVIS=1
BUILD_TYPE=Release
KEEP=0
EXTRA_ARGS=()

if [[ $# -eq 0 ]]; then usage; exit 1; fi
MODE=$1; shift
case $MODE in
    serial)
        BUILD_DIR=$MFEM_SERIAL_BUILD
        MODE_ARGS=(
            -DCMAKE_C_COMPILER="$SERIAL_CC"
            -DCMAKE_CXX_COMPILER="$SERIAL_CXX"
        )
        ;;
    parallel)
        BUILD_DIR=$MFEM_PARALLEL_BUILD
        MODE_ARGS=(
            -DCMAKE_C_COMPILER="$MPICC"
            -DCMAKE_CXX_COMPILER="$MPICXX"
            -DMFEM_USE_MPI=ON
            -DMFEM_USE_PETSC=OFF
            -DHYPRE_DIR="$PETSC_INSTALL"
            -DMETIS_DIR="$PETSC_INSTALL"
        )
        ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: first argument must be 'serial' or 'parallel', got '$MODE'" >&2; usage; exit 1 ;;
esac

while [[ $# -gt 0 ]]; do
    case $1 in
        -j|--jobs)      NJOBS=$2; shift ;;
        --no-examples)  BUILD_EXAMPLES=0 ;;
        --no-miniapps)  BUILD_MINIAPPS=0 ;;
        --no-tests)     BUILD_TESTS=0 ;;
        --no-glvis)     BUILD_GLVIS=0 ;;
        -g|--debug)     BUILD_TYPE=Debug ;;
        -k|--keep)      KEEP=1 ;;
        -h|--help)      usage; exit 0 ;;
        --)             shift; EXTRA_ARGS=("$@"); break ;;
        *) echo "error: unknown option '$1'" >&2; usage; exit 1 ;;
    esac
    shift
done

if [[ ! -d $DEV/mfem ]]; then
    echo "error: no MFEM source at $DEV/mfem (clone it there first)" >&2
    exit 1
fi
if [[ $MODE == parallel && ! -x $MPICXX ]]; then
    echo "error: MPI compiler wrapper $MPICXX not found (build PETSc first," >&2
    echo "       or point MPICC/MPICXX at a system MPI)" >&2
    exit 1
fi

echo "========================================================"
echo " MFEM ($MODE, $BUILD_TYPE)"
echo " jobs $NJOBS | examples $BUILD_EXAMPLES | miniapps $BUILD_MINIAPPS | tests $BUILD_TESTS"
echo " build dir: $BUILD_DIR$( [[ $KEEP -eq 1 ]] && echo ' (kept)' || echo ' (fresh)')"
echo "========================================================"

if [[ $KEEP -eq 0 ]]; then
    rm -rf "$BUILD_DIR"
fi

cmake -S "$DEV/mfem" -B "$BUILD_DIR" \
      -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      "${MODE_ARGS[@]}" \
      "${EXTRA_ARGS[@]}"

cmake --build "$BUILD_DIR" -j "$NJOBS"
[[ $BUILD_EXAMPLES -eq 1 ]] && cmake --build "$BUILD_DIR" -t examples -j "$NJOBS"
[[ $BUILD_MINIAPPS -eq 1 ]] && cmake --build "$BUILD_DIR" -t miniapps -j "$NJOBS"
[[ $BUILD_TESTS    -eq 1 ]] && cmake --build "$BUILD_DIR" -t tests    -j "$NJOBS"

if [[ $MODE == serial && $BUILD_GLVIS -eq 1 ]]; then
    if [[ -d $DEV/glvis ]]; then
        GLVIS_BUILD=$DEV/glvis_build
        echo "========================================================"
        echo " GLVis"
        echo " build dir: $GLVIS_BUILD$( [[ $KEEP -eq 1 ]] && echo ' (kept)' || echo ' (fresh)')"
        echo "========================================================"
        if [[ $KEEP -eq 0 ]]; then
            rm -rf "$GLVIS_BUILD"
        fi
        cmake -S "$DEV/glvis" -B "$GLVIS_BUILD" \
              -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
              -DMFEM_DIR="$BUILD_DIR"
        cmake --build "$GLVIS_BUILD" -j "$NJOBS"
    else
        echo "note: no GLVis source at $DEV/glvis, skipping GLVis"
    fi
fi

echo "Done. Build files are in $BUILD_DIR"
