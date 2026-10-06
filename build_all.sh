#!/bin/bash
#
# Build the whole stack from scratch, in order:
#
#   1. PETSc          configure + make + make install into $PETSC_INSTALL
#                     (provides MPI, hypre, metis, parmetis)
#   2. MFEM serial    (+ GLVis when $DEV/glvis exists)
#   3. MFEM parallel
#   4. AdGIA serial
#   5. AdGIA parallel
#
# Sources are expected under $DEV: petsc/, mfem/, glvis/ (optional) and
# AdGIA/ — see the README. Each stage can be skipped, e.g. --skip-petsc
# to reuse an existing PETSc install.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source "$SCRIPT_DIR/common.sh"

usage() {
    cat <<USAGE
Usage: $(basename "$0") [options]

Builds, in order: PETSc (configure/make/install into \$PETSC_INSTALL),
serial MFEM (+ GLVis when \$DEV/glvis exists), parallel MFEM, serial
AdGIA, parallel AdGIA. Sources must already be cloned at \$DEV/petsc,
\$DEV/mfem, \$DEV/glvis (optional) and \$DEV/AdGIA.

Options:
  -j, --jobs N       parallel build jobs (default: all cores, $(nproc));
                     PETSc's own make picks its job count itself
      --skip-petsc   skip stage 1 (reuse the install at \$PETSC_INSTALL)
      --skip-mfem    skip stages 2-3 (reuse the existing MFEM builds)
      --skip-adgia   skip stages 4-5
  -n, --dry-run      print the configuration and the stage plan, build nothing
  -h, --help         this message

MFEM and AdGIA are built with their default options (fresh build
directories; examples, miniapps and tests on). For anything finer run
build_mfem.sh / build_adgia.sh individually — each takes -n to show its
configuration. Paths and compilers come from common.sh / local.env.

mfemElasticity is not built; run build_elasticity_*.sh separately.
USAGE
}

NJOBS=$(nproc)
DO_PETSC=1
DO_MFEM=1
DO_ADGIA=1
DRY_RUN=0

while [[ $# -gt 0 ]]; do
    case $1 in
        -j|--jobs)    NJOBS=$2; shift ;;
        --skip-petsc) DO_PETSC=0 ;;
        --skip-mfem)  DO_MFEM=0 ;;
        --skip-adgia) DO_ADGIA=0 ;;
        -n|--dry-run) DRY_RUN=1 ;;
        -h|--help)    usage; exit 0 ;;
        *) echo "error: unknown option '$1'" >&2; usage; exit 1 ;;
    esac
    shift
done

# PETSc source tree and build arch. PETSc configure picks PETSC_ARCH up
# from the environment, so make can use the same value afterwards.
export PETSC_DIR=$DEV/petsc
export PETSC_ARCH=${PETSC_ARCH:-arch-build}
# petsc-configure.py reads these from the environment (it cannot source
# local.env itself).
export DEV PETSC_INSTALL

STAGES=()
[[ $DO_PETSC -eq 1 ]] && STAGES+=("petsc")
[[ $DO_MFEM  -eq 1 ]] && STAGES+=("mfem-serial (+glvis)" "mfem-parallel")
[[ $DO_ADGIA -eq 1 ]] && STAGES+=("adgia-serial" "adgia-parallel")

echo "========================================================"
echo " Full stack build"
echo " stages: ${STAGES[*]:-none}"
echo " DEV: $DEV"
echo " PETSc: source $PETSC_DIR ($PETSC_ARCH), install $PETSC_INSTALL"
echo " serial compilers: $SERIAL_CC / $SERIAL_CXX"
echo " MPI compilers: $MPICC / $MPICXX"
echo " jobs: $NJOBS"
echo "========================================================"

if [[ $DRY_RUN -eq 1 ]]; then
    [[ $DO_PETSC -eq 1 ]] && echo "would run: (cd $PETSC_DIR && petsc-configure.py && make all && make install)"
    [[ $DO_MFEM  -eq 1 ]] && echo "would run: build_mfem.sh serial -j $NJOBS; build_mfem.sh parallel -j $NJOBS"
    [[ $DO_ADGIA -eq 1 ]] && echo "would run: build_adgia.sh serial -j $NJOBS; build_adgia.sh parallel -j $NJOBS"
    echo "(dry run: nothing built)"
    exit 0
fi

# Check every stage's prerequisites up front, so a missing source is not
# discovered an hour into the PETSc build.
missing=0
if [[ $DO_PETSC -eq 1 && ! -d $PETSC_DIR/config ]]; then
    echo "error: no PETSc source tree at $PETSC_DIR" >&2; missing=1
fi
if [[ $DO_PETSC -eq 0 && $DO_MFEM -eq 1 && ! -x $MPICXX ]]; then
    echo "error: --skip-petsc, but no MPI compiler wrapper at $MPICXX" >&2; missing=1
fi
if [[ $DO_MFEM -eq 1 && ! -d $DEV/mfem ]]; then
    echo "error: no MFEM source at $DEV/mfem" >&2; missing=1
fi
if [[ $DO_ADGIA -eq 1 && ! -d $DEV/AdGIA ]]; then
    echo "error: no AdGIA source at $DEV/AdGIA" >&2; missing=1
fi
if [[ $DO_ADGIA -eq 1 && $DO_MFEM -eq 0 ]]; then
    if [[ ! -f $MFEM_SERIAL_BUILD/MFEMConfig.cmake || ! -f $MFEM_PARALLEL_BUILD/MFEMConfig.cmake ]]; then
        echo "error: --skip-mfem, but no MFEM builds at $MFEM_SERIAL_BUILD / $MFEM_PARALLEL_BUILD" >&2; missing=1
    fi
fi
[[ $missing -eq 1 ]] && exit 1

if [[ $DO_PETSC -eq 1 ]]; then
    echo "========================================================"
    echo " Stage 1: PETSc"
    echo "========================================================"
    (
        cd "$PETSC_DIR"
        "$SCRIPT_DIR/petsc-configure.py"
        make all
        make install
    )
fi

if [[ $DO_MFEM -eq 1 ]]; then
    "$SCRIPT_DIR/build_mfem.sh" serial   -j "$NJOBS"
    "$SCRIPT_DIR/build_mfem.sh" parallel -j "$NJOBS"
fi

if [[ $DO_ADGIA -eq 1 ]]; then
    "$SCRIPT_DIR/build_adgia.sh" serial   -j "$NJOBS"
    "$SCRIPT_DIR/build_adgia.sh" parallel -j "$NJOBS"
fi

echo "========================================================"
echo " Full stack build done (${STAGES[*]:-nothing})"
echo "========================================================"
