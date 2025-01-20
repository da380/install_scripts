#!/bin/bash

cmake -S $HOME/dev/mfem -B mfem_cuda_build \
      -DCMAKE_CXX_COMPILER=g++-13          \
      -DCMAKE_BUILD_TYPE=RELEASE           \
      -DMFEM_USE_CUDA=ON                   \
      -DCMAKE_CUDA_ARCHITECTURES=86

cmake --build mfem_cuda_build -j 20
cmake --build mfem_cuda_build -t tests -j 20
cmake --build mfem_cuda_build -t examples -j 20
cmake --build mfem_cuda_build -t miniapps -j 20




