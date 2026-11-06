#!/usr/bin/env bash
# Generate model documentation in the central Linux CAD drawing image.
# This script is run by GitHub Actions, not on Windows workstations.
set -euo pipefail

cd "$(dirname "$0")/../.."
IMAGE="${SCAD_DRAWING_IMAGE:-ghcr.io/brainboxemb/scad-toolchain-drawing:edge}"
LIBRARY_PATH="/work/ext:/opt/openscad-libraries"

in_container() {
  local workdir="$1"
  shift
  docker run --rm --init -v "$PWD:/work" -w "$workdir" \
    -e OPENSCADPATH="$LIBRARY_PATH" "$IMAGE" "$@"
}

mkdir -p ext
in_container /work vcs import --input dependencies.repos ext
test -f ext/NopSCADlib/core.scad
test -f ext/NopSCADlib/scripts/make_all.py

in_container /work/examples/spacer/v0.1 \
  xvfb-run -a python /work/ext/NopSCADlib/scripts/make_all.py

mkdir -p models/corner_bracket/v0.1/design
in_container /work/models/corner_bracket/v0.1 \
  bash /work/scripts/ci/render-bracket-steps.sh

in_container /work/models/corner_bracket/v0.1 \
  xvfb-run -a python /work/ext/NopSCADlib/scripts/make_all.py

# Separate focused guides: mounting options and the extended hull tutorial.
# Use the central drawing image, just like the NopSCADlib generator.
in_container /work/models/corner_bracket/v0.1 \
  bash -c 'for page in mounting-options hull-guide polygon-guide; do python -m markdown -x tables -x sane_lists "$page.md" > "$page.html"; done'

bash scripts/ci/validate-docs.sh
