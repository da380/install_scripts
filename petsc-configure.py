#!/usr/bin/env python3
import os
import sys

petsc_install = os.path.join(os.getenv('HOME'), 'dev/petsc-install')

configure_options = [
  '--prefix=' + petsc_install,
  
  # Removed explicit --with-cc and --with-cxx to use system defaults (GCC 13)
  
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
  
  # --- OPTIONAL I/O ---
  '--download-netcdf=1',
  '--download-hdf5=1',
  '--download-gslib-1',
  '--download-zlib=1',
  '--download-szlib=1',
  
  '--with-strict-petscerrorcode',
]

if __name__ == '__main__':
  sys.path.insert(0, os.path.abspath('config'))
  import configure
  configure.petsc_configure(configure_options)
