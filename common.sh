#!/bin/bash
#
# Shared configuration for the build scripts. Sourced, not executed.
#
# Every value is a default that can be overridden from the environment,
# so nothing here needs editing on another machine:
#
#   export DEV=/scratch/david MPICC=mpicc MPICXX=mpicxx
#   build_mfem.sh parallel
#
# Alternatively put the exports in local.env next to this file; it is
# sourced automatically and gitignored.

_common_dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
if [[ -f $_common_dir/local.env ]]; then
    # shellcheck source=/dev/null
    source "$_common_dir/local.env"
fi
unset _common_dir

# Root under which the sources and builds live.
: "${DEV:=$HOME/dev}"

# PETSc prefix install; also provides MPI, hypre and metis for the
# parallel MFEM build.
: "${PETSC_INSTALL:=$DEV/petsc-install}"

# Compilers. On a machine with its own MPI (e.g. a cluster) override
# MPICC/MPICXX with the system wrappers.
: "${SERIAL_CC:=gcc}"
: "${SERIAL_CXX:=g++}"
: "${MPICC:=$PETSC_INSTALL/bin/mpicc}"
: "${MPICXX:=$PETSC_INSTALL/bin/mpic++}"

# MFEM build trees that the downstream projects compile against.
: "${MFEM_SERIAL_BUILD:=$DEV/mfem_serial_build}"
: "${MFEM_PARALLEL_BUILD:=$DEV/mfem_parallel_build}"
