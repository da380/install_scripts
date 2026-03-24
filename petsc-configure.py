#!/usr/bin/env python3
import os
import sys

petsc_install = os.path.join(os.getenv('HOME'), 'dev/petsc-install')

configure_options = [
  '--prefix=' + petsc_install,
  '--with-cc=gcc-14.1.0',
  '--with-cxx=g++-14.1.0',
  '--with-fc=0',                     
  
  # PETSc still needs BLAS/LAPACK for basic math, so we keep the C-translation
  '--download-f2cblaslapack=1',      
  'CFLAGS=-Wno-implicit-function-declaration -Wno-incompatible-pointer-types -Wno-implicit-int',
  
  'COPTFLAGS=-g -O',
  'CXXOPTFLAGS=-g -O',
  '--with-single-library=0',
  
  # --- THE CORE PARALLEL MFEM DEPENDENCIES ---
  '--download-mpich=1',
  '--download-hypre=1',
  '--download-metis=1',
  '--download-parmetis=1',
  
  # --- OPTIONAL I/O (You can safely delete these if you don't use them) ---
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
