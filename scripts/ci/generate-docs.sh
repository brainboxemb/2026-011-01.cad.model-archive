#!/usr/bin/env bash
# Generate model documentation in the central Linux CAD drawing image.
# This script is run by GitHub Actions, not on Windows workstations.
set -euo pipefail

cd "$(dirname "$0")/../.."
IMAGE="${SCAD_DRAWING_IMAGE:-ghcr.io/brainboxemb/scad-toolchain-drawing:v0.6.3}"
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

bracket="models/corner_bracket/v0.1"
mkdir -p "$bracket/design" "$bracket/docs"

# Verify the new 2D square-minus-circle profile is geometrically identical
# to the former 19-point polygon for supported radius/relief combinations.
in_container /work/models/corner_bracket/v0.1 \
  bash /work/scripts/ci/verify-corner-rounding.sh

in_container /work/models/corner_bracket/v0.1 \
  bash /work/scripts/ci/verify-combined-chamfer-experiment.sh

# Compare the printable model with the historical per-edge relief cutters.
in_container /work/models/corner_bracket/v0.1 \
  bash /work/scripts/ci/verify-elephant-foot-hull.sh

# Test the proposed "two corrected hull surfaces only" EF simplification
# independently from the production geometry.
in_container /work/models/corner_bracket/v0.1 \
  bash /work/scripts/ci/verify-ef-two-surface-experiment.sh

in_container /work/models/corner_bracket/v0.1 \
  bash /work/scripts/ci/render-bracket-steps.sh

# NopSCADlib discovers the document builder from scad/*.scad.
# Keep the authoritative source under docs/ and make a temporary copy
# only for generation; remove it before publishing any source files.
test ! -e "$bracket/scad/documentation.scad"
cp "$bracket/docs/documentation.scad" "$bracket/scad/documentation.scad"
trap 'rm -f "$bracket/scad/documentation.scad"' EXIT
in_container /work/models/corner_bracket/v0.1 \
  xvfb-run -a python /work/ext/NopSCADlib/scripts/make_all.py
rm "$bracket/scad/documentation.scad"
trap - EXIT

# Generate guide HTML next to its Markdown in docs/.
in_container /work/models/corner_bracket/v0.1/docs \
  bash -c 'for page in mounting-options hull-guide polygon-guide chamfer-guide ef-hull-experiment; do python -m markdown -x tables -x sane_lists "$page.md" > "$page.html"; done'

bash scripts/ci/validate-docs.sh
