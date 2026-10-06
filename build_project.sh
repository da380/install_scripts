#!/bin/bash
#
# Configure and build an MFEM-based project (AdGIA, mfemElasticity)
# against a serial or a parallel MFEM.
#
#   build_project.sh <project> serial   [options] [-- extra cmake args]
#   build_project.sh <project> parallel [options] [-- extra cmake args]
#
# <project> is the directory name under $DEV. The serial build uses
# $SERIAL_CC/$SERIAL_CXX and $MFEM_SERIAL_BUILD; the parallel build uses
# the MPI wrappers and $MFEM_PARALLEL_BUILD (see build_mfem.sh).
# build_adgia.sh and build_elasticity.sh are thin wrappers that pick the
# project, and build_*_serial.sh / build_*_parallel.sh also pick the mode.

set -euo pipefail

source "$(dirname "$(readlink -f "$0")")/common.sh"

usage() {
    cat <<USAGE
Usage: $(basename "$0") <project> serial|parallel [options] [-- extra cmake args]

Options (examples and tests are on by default; the benchmarks are on
for the parallel build — they are MPI-only — and off for the serial one):
  -j, --jobs N        parallel build jobs (default: all cores, $(nproc))
  -d, --docs          also build the Doxygen documentation
  -l, --lib-only      library only: no examples, no tests, no benchmarks
      --no-examples   skip the examples
      --no-tests      skip the tests
      --no-benchmarks skip the benchmarks (parallel mode)
  -g, --debug         Debug build type (default: Release)
  -k, --keep          keep the existing build directory (incremental build)
  -r, --run-tests     run ctest after a successful build
      --no-meshes     do not generate the gmsh meshes (GENERATE_MESHES=OFF)
  -n, --dry-run       print the resolved configuration and the cmake
                      command, build nothing
  -h, --help          this message

The meshes are generated with the poetry environment of <project>/meshes
when it exists (MESHES_PYTHON), so no venv is created inside the build tree.
The benchmarks discover the poetry environment of <project>/benchmarks
on their own (BENCHMARKS_PYTHON overrides via the extra cmake args).

Paths and compilers come from common.sh and can be overridden from the
environment or local.env (DEV, PETSC_INSTALL, MPICC, MPICXX, ...).

Anything after -- is passed to cmake unchanged, e.g. -- -DCMAKE_CXX_FLAGS=-march=native
USAGE
}

NJOBS=$(nproc)
BUILD_EXAMPLES=ON
BUILD_TESTS=ON
BUILD_DOCS=OFF
BUILD_TYPE=Release
KEEP=0
RUN_TESTS=0
DRY_RUN=0
GENERATE_MESHES=ON
EXTRA_ARGS=()

if [[ $# -eq 0 ]]; then usage; exit 1; fi
PROJECT=$1; shift
case $PROJECT in
    -h|--help) usage; exit 0 ;;
esac
PROJECT_DIR=$DEV/$PROJECT

if [[ $# -eq 0 ]]; then usage; exit 1; fi
MODE=$1; shift
case $MODE in
    serial)
        USE_MPI=OFF
        BUILD_BENCHMARKS=OFF
        MFEM_DIR=$MFEM_SERIAL_BUILD
        BUILD_DIR=$PROJECT_DIR/build_serial
        C_COMPILER=$SERIAL_CC
        CXX_COMPILER=$SERIAL_CXX
        ;;
    parallel)
        USE_MPI=ON
        BUILD_BENCHMARKS=ON
        MFEM_DIR=$MFEM_PARALLEL_BUILD
        BUILD_DIR=$PROJECT_DIR/build_parallel
        C_COMPILER=$MPICC
        CXX_COMPILER=$MPICXX
        ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: second argument must be 'serial' or 'parallel', got '$MODE'" >&2; usage; exit 1 ;;
esac

while [[ $# -gt 0 ]]; do
    case $1 in
        -j|--jobs)      NJOBS=$2; shift ;;
        -d|--docs)      BUILD_DOCS=ON ;;
        -l|--lib-only)  BUILD_EXAMPLES=OFF; BUILD_TESTS=OFF; BUILD_BENCHMARKS=OFF ;;
        --no-examples)  BUILD_EXAMPLES=OFF ;;
        --no-tests)     BUILD_TESTS=OFF ;;
        --no-benchmarks) BUILD_BENCHMARKS=OFF ;;
        -g|--debug)     BUILD_TYPE=Debug ;;
        -k|--keep)      KEEP=1 ;;
        -r|--run-tests) RUN_TESTS=1 ;;
        --no-meshes)    GENERATE_MESHES=OFF ;;
        -n|--dry-run)   DRY_RUN=1 ;;
        -h|--help)      usage; exit 0 ;;
        --)             shift; EXTRA_ARGS=("$@"); break ;;
        *) echo "error: unknown option '$1'" >&2; usage; exit 1 ;;
    esac
    shift
done

if [[ $DRY_RUN -eq 0 ]]; then
    if [[ ! -d $PROJECT_DIR ]]; then
        echo "error: no project at $PROJECT_DIR" >&2
        exit 1
    fi
    if [[ ! -f $MFEM_DIR/MFEMConfig.cmake ]]; then
        echo "error: no MFEM build at $MFEM_DIR (run build_mfem.sh $MODE first)" >&2
        exit 1
    fi
    if [[ $MODE == parallel && ! -x $CXX_COMPILER ]]; then
        echo "error: MPI compiler wrapper $CXX_COMPILER not found" >&2
        exit 1
    fi
fi
if [[ $RUN_TESTS -eq 1 && $BUILD_TESTS == OFF ]]; then
    echo "error: --run-tests needs the tests to be built" >&2
    exit 1
fi

# Reuse the poetry environment of meshes/ for the mesh generation if it
# exists; otherwise CMake makes a venv inside the build directory.
MESHES_ARGS=()
if [[ $GENERATE_MESHES == ON ]] && command -v poetry >/dev/null; then
    if venv=$(poetry -C "$PROJECT_DIR/meshes" env info -p 2>/dev/null) && [[ -x $venv/bin/python ]]; then
        MESHES_ARGS=(-DMESHES_PYTHON="$venv/bin/python")
    fi
fi

CMAKE_ARGS=(
    -S "$PROJECT_DIR" -B "$BUILD_DIR"
    -DCMAKE_C_COMPILER="$C_COMPILER"
    -DCMAKE_CXX_COMPILER="$CXX_COMPILER"
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
    -DMFEM_DIR="$MFEM_DIR"
    -DUSE_MPI="$USE_MPI"
    -DBUILD_EXAMPLES="$BUILD_EXAMPLES"
    -DBUILD_TESTS="$BUILD_TESTS"
    -DBUILD_BENCHMARKS="$BUILD_BENCHMARKS"
    -DBUILD_DOCS="$BUILD_DOCS"
    -DGENERATE_MESHES="$GENERATE_MESHES"
    "${MESHES_ARGS[@]}"
    "${EXTRA_ARGS[@]}"
)

echo "========================================================"
echo " $PROJECT ($MODE, $BUILD_TYPE)"
echo " jobs $NJOBS | examples $BUILD_EXAMPLES | tests $BUILD_TESTS | benchmarks $BUILD_BENCHMARKS | docs $BUILD_DOCS | meshes $GENERATE_MESHES"
echo " compilers: $C_COMPILER / $CXX_COMPILER"
echo " MFEM: $MFEM_DIR"
echo " build dir: $BUILD_DIR$( [[ $KEEP -eq 1 ]] && echo ' (kept)' || echo ' (fresh)')"
echo "========================================================"

if [[ $DRY_RUN -eq 1 ]]; then
    echo "cmake configure command:"
    printf '  cmake'; printf ' %q' "${CMAKE_ARGS[@]}"; printf '\n'
    echo "(dry run: nothing built)"
    exit 0
fi

if [[ $KEEP -eq 0 ]]; then
    rm -rf "$BUILD_DIR"
fi

cmake "${CMAKE_ARGS[@]}"

cmake --build "$BUILD_DIR" -j "$NJOBS"

if [[ $RUN_TESTS -eq 1 ]]; then
    echo "========================================================"
    echo " Running the tests"
    echo "========================================================"
    ctest --test-dir "$BUILD_DIR" --output-on-failure
fi

echo "Done. Build files are in $BUILD_DIR"
