#!/usr/bin/env python3
#
# PETSc configure. Run it from the root of a PETSc source tree:
#
#   cd $DEV/petsc && ~/dev/install_scripts/petsc-configure.py
#
# Pass -n / --show to print the configure options and exit without
# configuring (works from any directory). Any other arguments are
# forwarded to PETSc configure unchanged.
#
# PETSc is used here mainly as a dependency provider: it downloads and
# builds a coherent MPI (MPICH) + hypre + metis/parmetis stack that the
# parallel MFEM build points at (see build_mfem.sh). The install prefix
# follows the DEV / PETSC_INSTALL environment variables, defaulting to
# ~/dev/petsc-install, to match common.sh.
import os
import shlex
import sys

dev = os.environ.get('DEV', os.path.join(os.environ['HOME'], 'dev'))
petsc_install = os.environ.get('PETSC_INSTALL', os.path.join(dev, 'petsc-install'))

# Additional configure options without editing this script: a space-
# separated list in PETSC_EXTRA_OPTIONS (shell quoting for options that
# contain spaces), e.g. in local.env:
#
#   export PETSC_EXTRA_OPTIONS="--download-hdf5=1 --download-netcdf=1"
#
# build_all.sh passes the environment through, so this works there too.
extra_options = shlex.split(os.environ.get('PETSC_EXTRA_OPTIONS', ''))

configure_options = [
  '--prefix=' + petsc_install,

  # No explicit --with-cc/--with-cxx: use the system defaults.

  # Enable Fortran
  '--with-fc=gfortran',

  # Download native Fortran BLAS/LAPACK instead of the f2c translation
  '--download-fblaslapack=1',

  # Appended (+=) rather than overwriting, so PETSc's own default C flags
  # are kept. These suppressions let newer GCC (14+) build the older
  # downloaded packages, which it would otherwise reject as hard errors.
  'CFLAGS+=-Wno-implicit-function-declaration -Wno-incompatible-pointer-types -Wno-implicit-int',

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
# keep the PETSc build shorter. Enable via PETSC_EXTRA_OPTIONS (or the
# command line) if an MFEM build needs them, e.g.
#
#   export PETSC_EXTRA_OPTIONS="--download-netcdf=1 --download-hdf5=1
#     --download-gslib=1 --download-zlib=1 --download-szlib=1"

configure_options += extra_options

if __name__ == '__main__':
  show_only = False
  for flag in ('-n', '--show', '--dry-run'):
    if flag in sys.argv:
      sys.argv.remove(flag)
      show_only = True

  print('PETSc configure options (install prefix: %s):' % petsc_install)
  for opt in configure_options:
    marker = '  [PETSC_EXTRA_OPTIONS]' if opt in extra_options else ''
    print('  ' + opt + marker)
  if len(sys.argv) > 1:
    print('extra options from the command line:')
    for opt in sys.argv[1:]:
      print('  ' + opt)

  if show_only:
    sys.exit(0)

  if not os.path.isdir('config'):
    sys.exit('error: run this script from the root of a PETSc source tree '
             '(no config/ directory in ' + os.getcwd() + ')')
  sys.path.insert(0, os.path.abspath('config'))
  import configure
  configure.petsc_configure(configure_options)
