#!/bin/bash
# mfemElasticity build (serial|parallel); see build_project.sh for the options.
exec "$(dirname "$(readlink -f "$0")")/build_project.sh" mfemElasticity "$@"
