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

tube="examples/rounded-rectangular-tube/v0.1"
mkdir -p "$tube/figures" "$tube/design"
in_container "/work/$tube" bash -c '
  xvfb-run -a openscad --imgsize=900,650 --viewall --autocenter --projection=ortho \
    -o figures/rounded_rectangular_tube.png scad/rounded_rectangular_tube.scad

  stages=(
    01_profiles
    02_outer_chamfer_inputs
    03_outer_hull
    04_hollow_tube
    05_inner_chamfer_inputs
    06_inner_chamfer_cut
    07_bottom_chamfer_result
    08_final
    09_chamfer_closeup
  )
  for stage in "${stages[@]}"; do
    xvfb-run -a openscad --imgsize=900,650 --viewall --autocenter --projection=ortho \
      -D "design_step=\"$stage\"" \
      -o "design/tube_$stage.png" \
      design/rounded_rectangular_tube_explained.scad
    test -s "design/tube_$stage.png"
  done

  python -m markdown -x tables -x sane_lists -x fenced_code README.md > readme.html
'

lbracket="examples/rounded-l-bracket/v0.1"
mkdir -p "$lbracket/figures" "$lbracket/design"
in_container "/work/$lbracket" bash -c '
  xvfb-run -a openscad --imgsize=900,650 --viewall --autocenter --projection=ortho \
    -o figures/rounded_l_bracket.png scad/rounded_l_bracket.scad

  stages=(
    01_outer_profile
    02_inner_profile
    03_shell_profile
    04_outer_chamfer_inputs
    05_outer_body
    06_inner_chamfer_inputs
    07_inner_chamfer_cut
    08_before_trim
    09_final_trim
    10_chamfer_closeup
  )
  for stage in "${stages[@]}"; do
    xvfb-run -a openscad --imgsize=900,650 --viewall --autocenter --projection=ortho \
      -D "design_step=\"$stage\"" \
      -o "design/lbracket_$stage.png" \
      design/rounded_l_bracket_explained.scad
    test -s "design/lbracket_$stage.png"
  done

  python -m markdown -x tables -x sane_lists -x fenced_code README.md > readme.html
'

bracket="models/corner_bracket/v0.1"
mkdir -p "$bracket/design" "$bracket/docs"

# Verify the new 2D square-minus-circle profile is geometrically identical
# to the former 19-point polygon for supported radius/relief combinations.
in_container /work/models/corner_bracket/v0.1 \
  bash /work/scripts/ci/verify-corner-rounding.sh

in_container /work/models/corner_bracket/v0.1 \
  bash /work/scripts/ci/verify-combined-chamfer-experiment.sh

# Verify the readable fixed-rotation arm-tip correction against the legacy multmatrix placement.
in_container /work/models/corner_bracket/v0.1 \
  bash /work/scripts/ci/verify-elephant-foot-relief.sh

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
  bash -c 'for page in mounting-options hull-guide polygon-guide chamfer-guide; do python -m markdown -x tables -x sane_lists "$page.md" > "$page.html"; done'

mkdir -p docs/figures
in_container /work/docs bash -c '
  stages=(01_keep 02_cut 03_clip 04_hull_keep 05_hull_cut 06_convexity 07_decompose)
  for stage in "${stages[@]}"; do
    xvfb-run -a openscad --imgsize=900,560 --viewall --autocenter --projection=ortho \
      -D "concept_step=\"$stage\"" \
      -o "figures/concept_$stage.png" \
      design-concepts.scad
    test -s "figures/concept_$stage.png"
  done

  python -m markdown -x tables -x sane_lists -x fenced_code design-concepts.md > design-concepts.html
'

bash scripts/ci/validate-docs.sh
