#!/bin/bash

cmake -S $HOME/dev/raja -B raja_cuda_build \
      -DCMAKE_CXX_COMPILER=g++-13          \
      -DCMAKE_BUILD_TYPE=RELEASE           \
      -DENABLE_CUDA=ON                     \
      -DENABLE_OPENMP=ON                   \
      -DCMAKE_CUDA_ARCHITECTURES=native
