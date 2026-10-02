#!/bin/bash
# Serial mfemElasticity build; see build_elasticity.sh for the options.
exec "$(dirname "$(readlink -f "$0")")/build_elasticity.sh" serial "$@"
