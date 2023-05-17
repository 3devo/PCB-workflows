#!/bin/bash -e

# This script updates the workflow file in the parent git repository to
# match the submodule versios.
SUBMODULE_ROOT=$(cd $(dirname "$0") && git rev-parse --show-toplevel)
REPO_ROOT=$(cd "${SUBMODULE_ROOT}" && git rev-parse --show-superproject-working-tree)

# Update SHA in dispatcher
SUBMODULE_SHA=$(git --git-dir "$SUBMODULE_ROOT/.git" rev-parse HEAD)
sed -i "s/dispatcher.yml@.*/dispatcher.yml@$SUBMODULE_SHA/" "$REPO_ROOT/.github/workflows/workflow.yml"
