# PCB workflow automation
This repo contains various tools for automating and simplifying
workflows around (KiCad) PCB designs within 3devo. This includes
automation using Github workflows, but also tools for helping the local
development workflow.

This repository is made public under a creative commons license (see the
end of this file for details) in the hope that it will be useful to
others, and to contribute something back to the excellent KiCad
ecosystem that 3devo is gratefully building upon.

However, this repository is still an internal tool, so it is published
without any warranties or guarantees about correctness and future update
might make changes that break usage of this repository. If you want to
use the scripts in this repository, it is recommended you fork the
repository and work from your own fork.

If you want to contribute improvements to this repository, you are
welcome too, but there is no guarantee contributions will be accepted.
In practice, it would  be best to open up an issue to discuss an
improvement before you invest time in creating a pull request for it.

### Setting up a new PCB project repo
To use this repo in a PCB design repo:
 - Include this repo as a submodule in the PCB project repo (typically
   directly in the root).
 - Ensure a KiCad project is already created (typically in a `PCB`
   subdirectory).
 - Run `./tools/setup-project-repo.sh /path/to/project.kicad_pro`. This sets
   up:
    - A `.gitignore` file.
    - The Github workflow.
    - The drawing sheet.
    - The text variables.
    - The kibot default config file.
    - The kibot project-specific config file.
 - When creating the board layout, use the `${BOARD_REVISION}` text
   variable on the silkscreen.

## Using this repository

### Releases and versioning
During development, the versions shown on the schematic and board title
sheet are simply "dev", since the design does not (usually) correspond
to any specific board version.

When a release is made (by tagging, see below for the format), the
proper version numbers are inserted into the title sheet, to be
displayed in the rendered PDF files.

Alternatively, the `kibot` command can be used locally as well (see
below) to generate PDF files that include the proper version numbers
(i.e. the most recent tagged version, plus an indication of whether it
was modified, and the full git version details).

### Tagging releases
To create a new PCB design release, put the changes made since the
previous release in the `Changelog.md` file in the project repository
(with a header showing the version, separate versions with an empty
line, see the [example](examples/Changelog.md) file for the required
format), and then tag the commit.

The tag must contain three parts, separated by slashes. For example:
`Devoboard/V1.6/2023-02-01`. The parts are:
 - The board name. This is just descriptive, but ideally should not
   change between commits for the same board.
 - The board version. This reflects the board design itself, so it
   should be updated whenever the board layers are changed. It should be
   kept the same when only components are changed (with pin-compatible
   parts).
 - The component date. This reflects the components that are placed on
   the board, and should be bumped whenever any signficant component is
   changed (e.g. bump for IC and transistor changes, no need to bump for
   passive component changes as long as the value remains the same).

When creating a tag in this format, the github workflow will
automatically create a release and attach schematics and other
fabrication files to the release.

### Zone fills
The workflow does not automatically do zone fills, so these are expected
to be done locally before committing changes to the board. For tags that
change the board version, or commits that make any copper changes, the
workflow *does* check if a zone fill was done.

When making only component changes (no board changes), no zone fill
should be done to prevent unintended (subtle) changes (for example when
zone fill edge clearance behavior changed slightly between KiCad 6 and
7). For tags without a board version bump, the workflow checks that the
board layers (all, not just copper) were indeed not changed.

### Local development
The automated workflows rely on [kibot](https://github.com/INTI-CMNB/KiBot)
for generating output files. When working on the PCB design locally,
kibot can also be used to generate files. Once kibot is installed (see
its documentation), it can be run locally. The current directory should
always be the directory with the KiCad project (e.g. the `PCB`
subdirectory). From there, simply call `kibot` to have it generate the
default set of outputs:

    kibot

To do the same, but skip preflights (like ERC/DRC), use:

    kibot -s all

Outputs will be generated in the `kibot-output` directory by default.

It is also possible to generate just single outputs. Run `kibot -l` to
get a list of supported outputs, and pass one or more output names to
run just those:

    kibot -s all pdf_pcb_print pdf_sch_print

Kibot can also generate a diff of changes in your local working copy,
versus the current commit, previous commit or most recent release. These
are not generated by default, but can be called explicitly:

    kibot -s all diff_pcb_uncommitted diff_sch_uncommitted
    kibot -s all diff_pcb_last_commit diff_sch_last_commit
    kibot -s all diff_pcb_since_last_release diff_sch_since_last_release

Remember that the output is generated into the `kibot-output`
directory.

### Customizing the kibot config
If the board needs kibot customizations, these can be made in the
`kibot/kibot-project-config.yaml` file, which is included by the actual
kibot configuration files used.

Typical configuration to add here would be:
 - Defining multiple board variants (see below).
 - Disabling some preflights (e.g. DRC when it does not pass yet).

### Board variants
Kibot supports board variants, in which different version of the board
are used that omit or exchange some components (but the same pcb
layout).

For this, the available variants should be listed in the
`kibot-project-config.yaml` file in the project repository (using the
`kibom` type). Which components are present in which variants is then
defined using custom attributes in the schematic (By setting e.g.
`Config=+SR` to include a component only in the `SR` variant).

See [this example
repo](https://inti-cmnb.github.io/kibot_variants_arduprog/) for more
info on how kibot implements variants.

### Updating
To update the version of PCB-workflows used by a project, two changes
must be made:
 - The PCB-footprints submodule must be updated to a newer version.
 - The `.github/workflows/workflow.yml` file must be updated to
   reference the same version. The `tools/update-workflow-version.sh`
   script can automatically make this change for you.

These two versions must always be kept synchronized, otherwise workflow
and kibot configs from different versions might be used, which can cause
problems.

For updating the submodule, the
[commit-submodule](https://github.com/matthijskooijman/scripts/blob/master/commit-submodule)
script is recommended, which generates a list of submodule commits
automatically.

Be sure to check the commit log of the submodule as well, to see if any
additional changes are needed.

## Implementation details

### Title sheet & versioning
This repo contains a custom title sheet, which is used for both
schematics and board design rendering and shows the proper version
numbers.

This is implementd using KiCad's "text variables", which are referenced
directly by the custom title sheet and updated by kibot when generating
outputs.

Note that this approach bypasses the regular sheet date and revision
values (that are normally shown in the title block and can be set in
KiCad using File -> Page Setup...), so those are ignored and should be
kept empty to prevent confusion.

### Workflows
The project repo contains a small `workflow.yml file`, which calls the
`dispatcher.yml` workflow that lives in this repository and does the
actual work. The small workflow is generic (it handles a number of
different events) and the actual workflow adapts its behavior depending
on the exact event (e.g.  pushing a tag or a branch).

Originally, the idea was to always call the latest `dispatcher.yml`
workflow and have it figure out the version of the submodule and then
dispatch to the right version of the actual workflow, but this proved
non-trivial (maybe impossible) to implement in Github Actions.

### Running kibot locally
To allow running kibot locally with minimum parameters, a small
`config.kibot.yaml` file is stored next to the KiCad project files (so
it can be autodetected by `kibot`). This file imports the
`development.yaml` file from this repository, which again imports the
relevant bits of config for local development. It also imports the
`kibot-project-config.yaml` file directly (see below for why).

### Silkscreen board revision
When putting the board revision on the silkscreen, if the
`${BOARD_REVISION}` placeholder is used, it will work the the same as
the title sheet versioning, being automatically populated from the tag
version

Note that this does not currently work for local kibot runs due to [this
issue](https://github.com/INTI-CMNB/KiBot/issues/441, the workflow has
a workaround). You can make it work locally as well by running:

    sed -i '/^ *(property "\(BOARD_REVISION\|COMPONENTS_DATE\|GIT_REVISION_INFO\|VARIANT\)" /d' *.kicad_pcb

This strips the text variable cache from the pcb file, to force using
the modified text variables. This cache will be added again when opening
the board setup window in the PCB editor.

Also note that text variables cannot be used on copper/keepout layers,
since that would typically require a zone fill, which should be done
locally before committing.

### Project-specific config
The `kibot-project-config.yaml` file is included in all runs of kibot,
by explicitly including it. For workflows, this path can be customized
from the project repo using a workflow parameter (`with: kibot-config`),
though the default value should usually be sufficient. This value is
then passed through the workflow to kibot using the `kibot -E` option,
which essentially does a simple search-replace in the workflow-specific
kibot config files.

To not need the same `-E` option for local development, but also not
hardcode the path in this repo, this file is included by the
project-specific `PCB/config.kibot.yaml` file (so it is only hardcoded
in the project repository, which is ok).

## Future Improvements
 - Generate more outputs (BOM, gerbers, PnP file).
 - Remove some workarounds from .github/workflows/dispatcher.yml once
   their bugs are fixed.
 - Enable workflow-submodule sync check in
   .github/workflows/dispatcher.yml once [this github
   bug](https://github.com/actions/runner/issues/2417) is fixed.
 - Maybe add example project to copy design rules from?

# Licensing
The content of this repository is subject to copyright by 3devo B.V. and
is licensed under the the Creative Commons CC-BY-SA-4.0 license. Full
text of the license (including a disclaimer on warranty and liability)
can be found at: https://creativecommons.org/licenses/by-sa/4.0/legalcode

One exception to this is the `sheets/` subdirectory. Files in there are
based on work by the KiCad project and licensed under the KiCad
Libraries license. This is essentially the same CC-BY-SA-4.0 license,
but with an additional exception waving the attribution and share-alike
requirements when used as part of an electronic circuit design. For the
full licensing terms, see: https://gitlab.com/kicad/libraries/kicad-templates/-/blob/master/LICENSE.md
