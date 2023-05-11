#!/bin/bash -e

KICAD_PRO=$1
SUBMODULE_ROOT=$(cd $(dirname "$0") && git rev-parse --show-toplevel)

#$(false)

#exit 2
if [ -z "$SUBMODULE_ROOT" ]; then
	echo "Not running this script from a submodule?"
	exit 1
fi

if [ -z "$KICAD_PRO" ]; then
	echo "usage: $0 /path/to/board.kicad_pro"
	exit 1
fi
if [ ! -f "$KICAD_PRO" ]; then
	echo "Not a (regular) file: $KICAD_PRO"
	exit 1
fi

if [ "${KICAD_PRO##*.}" != "kicad_pro" ]; then
	echo "Extension is not .kicad_pro: $KICAD_PRO"
	exit 1
fi

KICAD_DIR=$(realpath "$(dirname "$KICAD_PRO")")
REPO_ROOT=$(cd "$KICAD_DIR" && git rev-parse --show-toplevel)

if [ -z "$REPO_ROOT" ]; then
	echo "KiCad project not in a git repo?"
	exit 1
fi

echo "About to make changes to:"
echo " - the git repo at $REPO_ROOT"
echo " - the KiCad files in $KICAD_DIR"
echo "to point to files in $SUBMODULE_ROOT"
echo "Press enter to continue, or control-C to abort"
read FOO

SUBMODULE_RELATIVE=$(realpath --relative-to="$KICAD_DIR" "$SUBMODULE_ROOT")

# This does very simple matching, to make minimal changes to the file
# (e.g. using jq for more advanced edits also changes the number of
# decimal digits in numbers...). This does mean that if the strings
# searched for are not present with exactly this indentation etc., this
# will not work.
sed -i "s#^\(    \"page_layout_descr_file\": \)\"[^\"]*\"#\1\"$SUBMODULE_RELATIVE/sheets/versioned_sheet.kicad_wks\"#" "$KICAD_PRO"
sed -i 's#^\(  "text_variables": \){}#\1{\n    "BOARD_REVISION": "dev",\n    "COMPONENTS_DATE": "dev",\n    "GIT_REVISION_INFO": "",\n    "VARIANT": ""\n  }#' "$KICAD_PRO"

# Sanity check to see if it worked
if [ "$(grep "versioned_sheet.kicad_wks\|GIT_REVISION_INFO" "$KICAD_PRO" --count)" -ne 3 ]; then
	echo "It looks like modifying your project file failed."
	echo "Maybe you already had some text variables? This script is simple, so you might need to doublecheck the regexes in it."
	exit 1
fi

# Drop any existing dates and revisions, since these are no longer
# displayed by the custom title sheet / page layout, so better to remove
# them.
sed -i '/^ *(date /d;/^ *(rev /d;' "$KICAD_DIR"/*.kicad_pcb "$KICAD_DIR"/*.kicad_sch

# Use --interactive to prompt before overwriting
cp --interactive "$SUBMODULE_ROOT/examples/gitignore" "$REPO_ROOT/.gitignore"

mkdir -p "$REPO_ROOT/.github/workflows/"
cp --interactive "$SUBMODULE_ROOT/examples/workflow.yml" "$REPO_ROOT/.github/workflows/"

cp --interactive "$SUBMODULE_ROOT/examples/config.kibot.yaml" "$KICAD_DIR/"

mkdir -p "$REPO_ROOT/kibot"
cp --interactive "$SUBMODULE_ROOT/examples/kibot-project-config.yaml" "$REPO_ROOT/kibot/"

cp --interactive "$SUBMODULE_ROOT/examples/Changelog.md" "$REPO_ROOT/"

EXPECTED_SUBMODULE_SUBDIR="PCB-workflows"
EXPECTED_KICAD_SUBDIR="PCB"

if [ "$(realpath --relative-to="$REPO_ROOT" "$SUBMODULE_ROOT")" != "$EXPECTED_SUBMODULE_SUBDIR" ]; then
	echo "Your submodule is not at $EXPECTED_SUBMODULE_SUBDIR, you might need to modify the workflow file to match"
fi

if [ "$(realpath --relative-to="$REPO_ROOT" "$KICAD_DIR")" != "$EXPECTED_KICAD_SUBDIR" ]; then
	echo "Your submodule is not at $EXPECTED_KICAD_SUBDIR, you might need to modify the workflow file to match"
fi
