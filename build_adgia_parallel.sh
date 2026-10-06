#!/bin/bash
# Parallel AdGIA build; see build_adgia.sh for the options.
exec "$(dirname "$(readlink -f "$0")")/build_adgia.sh" parallel "$@"
