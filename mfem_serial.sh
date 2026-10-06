#!/bin/bash
# Serial MFEM (+ GLVis) build; see build_mfem.sh for the options.
exec "$(dirname "$(readlink -f "$0")")/build_mfem.sh" serial "$@"
