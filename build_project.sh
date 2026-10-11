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
  -p, --poetry-install  make or update the project's poetry environment
                      (the root project) with \$POETRY_PYTHON before
                      configuring
      --no-meshes     do not generate the gmsh meshes (GENERATE_MESHES=OFF)
  -s, --mesh-scale X  factor on every generated mesh's element sizes
                      (smaller is finer; AdGIA only, MESHES_SCALE=X)
  -n, --dry-run       print the resolved configuration and the cmake
                      command, build nothing
  -h, --help          this message

The project's poetry environment (one root project covering meshes,
benchmarks and earth_data, AdGIA's layout) is discovered here and passed
to CMake (MESHES_PYTHON, BENCHMARKS_PYTHON, EARTH_DATA_PYTHON; the extra
cmake args override), so no venv is created inside the build tree and
CMake needs no poetry of its own. --poetry-install makes or updates it
first, with \$POETRY_PYTHON (poetry needs a Python >= 3.12 and does not
pick one up by itself; on a machine whose python3 is older, set
POETRY_PYTHON=python3.12 in local.env). Without an environment the
benchmark and earth-data launchers fall back on python3 and refuse to
run. A project without a root pyproject.toml is left to its own CMake
discovery.

Paths and compilers come from common.sh and can be overridden from the
environment or local.env (DEV, PETSC_INSTALL, MPICC, MPICXX,
POETRY_PYTHON, ...).

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
POETRY_INSTALL=0
DRY_RUN=0
GENERATE_MESHES=ON
MESH_SCALE=
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
        -p|--poetry-install) POETRY_INSTALL=1 ;;
        --no-meshes)    GENERATE_MESHES=OFF ;;
        -s|--mesh-scale) MESH_SCALE=$2; shift ;;
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
if [[ -n $MESH_SCALE && $GENERATE_MESHES == OFF ]]; then
    echo "error: --mesh-scale has no effect with --no-meshes" >&2
    exit 1
fi

# The poetry environment of the project's Python tooling: one project
# at the repository root (AdGIA's layout). --poetry-install makes or
# updates it with $POETRY_PYTHON; the configure below is then pointed at
# it, so CMake needs no poetry of its own. Without the environment, mesh
# generation makes a venv inside the build directory, and the benchmark
# and earth-data launchers fall back on python3 and refuse to run. A
# project without a root pyproject.toml (mfemElasticity) is left to its
# own CMake discovery.
poetry_env() {  # poetry_env <dir>: the environment's python, if any
    local venv
    command -v poetry >/dev/null || return 1
    venv=$(poetry -C "$1" env info -p 2>/dev/null) \
        && [[ -x $venv/bin/python ]] && echo "$venv/bin/python"
}

PYTHON_ARGS=()
if [[ -f $PROJECT_DIR/pyproject.toml ]]; then
    if [[ $POETRY_INSTALL -eq 1 && $DRY_RUN -eq 0 ]]; then
        if ! command -v poetry >/dev/null; then
            echo "error: --poetry-install needs poetry on the PATH" >&2
            exit 1
        fi
        echo "--- poetry install in $PROJECT_DIR (python: $POETRY_PYTHON)"
        poetry -C "$PROJECT_DIR" env use "$POETRY_PYTHON"
        poetry -C "$PROJECT_DIR" install
    fi
    if PY_ROOT=$(poetry_env "$PROJECT_DIR"); then
        PY_SUMMARY=$PY_ROOT
        [[ $GENERATE_MESHES == ON ]] && PYTHON_ARGS+=(-DMESHES_PYTHON="$PY_ROOT")
        [[ $BUILD_BENCHMARKS == ON ]] && PYTHON_ARGS+=(-DBENCHMARKS_PYTHON="$PY_ROOT")
        [[ -d $PROJECT_DIR/earth_data ]] && PYTHON_ARGS+=(-DEARTH_DATA_PYTHON="$PY_ROOT")
    else
        PY_SUMMARY="NOT FOUND"
        echo "warning: no poetry environment for $PROJECT_DIR —" >&2
        echo "  the benchmark and earth-data launchers will refuse to run;" >&2
        echo "  re-run with --poetry-install (POETRY_PYTHON=python3.12 in" >&2
        echo "  local.env if python3 is older than 3.12)" >&2
    fi
else
    PY_SUMMARY="(no root pyproject.toml; left to the project's CMake)"
fi
# MESHES_SCALE exists only in AdGIA's CMake; pass it only when asked for,
# so the other projects see no unused-variable warning.
if [[ -n $MESH_SCALE ]]; then
    PYTHON_ARGS+=(-DMESHES_SCALE="$MESH_SCALE")
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
    "${PYTHON_ARGS[@]}"
    "${EXTRA_ARGS[@]}"
)

echo "========================================================"
echo " $PROJECT ($MODE, $BUILD_TYPE)"
echo " jobs $NJOBS | examples $BUILD_EXAMPLES | tests $BUILD_TESTS | benchmarks $BUILD_BENCHMARKS | docs $BUILD_DOCS | meshes $GENERATE_MESHES$( [[ -n $MESH_SCALE ]] && echo " (scale $MESH_SCALE)")"
echo " python env: $PY_SUMMARY"
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
