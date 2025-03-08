#!/usr/bin/env python3
import os

petsc_install=os.path.join(os.getenv('HOME'),'dev/petsc-install-test')


configure_options = [
  '--prefix='+petsc_install,
  '--with-cc=gcc-13',
  '--with-cxx=g++-13',
  'COPTFLAGS=-g -O',
  'FOPTFLAGS=-g -O',
  'CXXOPTFLAGS=-g -O',
  '--with-single-library=0',
  '--download-mpich=1',
  '--with-strict-petscerrorcode',
  '--with-coverage',
  ]

if __name__ == '__main__':
  import sys,os
  sys.path.insert(0,os.path.abspath('config'))
  import configure
  configure.petsc_configure(configure_options)


