#!/bin/bash
# Parallel MFEM build; see build_mfem.sh for the options.
exec "$(dirname "$(readlink -f "$0")")/build_mfem.sh" parallel "$@"
