#!/usr/bin/env python3
#
# PETSc configure. Run it from the root of a PETSc source tree:
#
#   cd $DEV/petsc && ~/dev/install_scripts/petsc-configure.py
#
# PETSc is used here mainly as a dependency provider: it downloads and
# builds a coherent MPI (MPICH) + hypre + metis/parmetis stack that the
# parallel MFEM build points at (see build_mfem.sh). The install prefix
# follows the DEV / PETSC_INSTALL environment variables, defaulting to
# ~/dev/petsc-install, to match common.sh.
import os
import sys

dev = os.environ.get('DEV', os.path.join(os.environ['HOME'], 'dev'))
petsc_install = os.environ.get('PETSC_INSTALL', os.path.join(dev, 'petsc-install'))

configure_options = [
  '--prefix=' + petsc_install,

  # No explicit --with-cc/--with-cxx: use the system defaults.

  # Enable Fortran
  '--with-fc=gfortran',

  # Download native Fortran BLAS/LAPACK instead of the f2c translation
  '--download-fblaslapack=1',

  'CFLAGS=-Wno-implicit-function-declaration -Wno-incompatible-pointer-types -Wno-implicit-int',

  'COPTFLAGS=-g -O',
  'CXXOPTFLAGS=-g -O',
  '--with-single-library=0',

  # --- THE CORE PARALLEL MFEM DEPENDENCIES ---
  '--download-mpich=1',
  '--download-hypre=1',
  '--download-metis=1',
  '--download-parmetis=1',

  '--with-strict-petscerrorcode',
]

# Optional I/O packages: nothing in the current MFEM builds uses these
# (MFEM_USE_NETCDF / MFEM_USE_GSLIB are off), so they are left out to
# keep the PETSc build shorter. Re-enable if an MFEM build needs them.
# configure_options += [
#   '--download-netcdf=1',
#   '--download-hdf5=1',
#   '--download-gslib=1',
#   '--download-zlib=1',
#   '--download-szlib=1',
# ]

if __name__ == '__main__':
  if not os.path.isdir('config'):
    sys.exit('error: run this script from the root of a PETSc source tree '
             '(no config/ directory in ' + os.getcwd() + ')')
  sys.path.insert(0, os.path.abspath('config'))
  import configure
  configure.petsc_configure(configure_options)
