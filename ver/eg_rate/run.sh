#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
iverilog -g2012 -s test -o "$tmp/test" test.v ../../hdl/jtopl_eg_ctrl.v ../../hdl/jtopl_eg_step.v ../../hdl/jtopl_eg_pure.v
(cd "$tmp" && vvp ./test)
