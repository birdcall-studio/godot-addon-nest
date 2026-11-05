# Shared targets for Birdcall Studio Godot add-ons, included by the Makefile.
# Every repo made from the godot-addon-nest template has its own copy of
# toolchain/. `make upgrade FROM=<release tag>` refreshes it.

GODOT ?= godot
EC ?= editorconfig-checker
MARKDOWNLINT ?= markdownlint-cli2
TIMEOUT ?= 180
# The highest Flesch-Kincaid grade a paragraph or comment may read at.
READING_GRADE ?= 12
NEST := toolchain
SCRIPTS := $(wildcard $(NEST)/bin/*) $(wildcard scripts/*.sh)

.PHONY: help check doctor hooks lint import test package verify-package clean init upgrade

help:
	@echo "make check                doctor + lint + import + test + verify-package (what CI runs)"
	@echo "make doctor               check the add-on layout and the Godot branch"
	@echo "make hooks                install the git hooks (the dev container does this)"
	@echo "make lint                 check style rules, Markdown, reading level, workflows and shell scripts"
	@echo "make import               open the project headless (loads the editor plugin)"
	@echo "make test                 check warning settings, compile add-on scripts, run tests/**/test_*.gd"
	@echo "make package              zip the add-on into dist/, as a release does"
	@echo "make verify-package       zip it, then enable it in a clean project and compile it"
	@echo "make clean                delete the import cache (.godot/) and dist/"
	@echo "make upgrade FROM=<tag>   copy that template release's toolchain files into this repo"
	@echo "                          Put this repo's own targets in local.mk."

check: doctor lint import test verify-package

doctor:
	@$(NEST)/bin/nest-doctor

hooks:
	lefthook install

lint:
	$(EC)
	$(MARKDOWNLINT) "**/*.md"
	node $(NEST)/readability.mjs $(READING_GRADE)
	actionlint
	shellcheck $(SCRIPTS)

import:
	timeout $(TIMEOUT) $(GODOT) --headless --path . --import

test:
	timeout $(TIMEOUT) $(GODOT) --headless --path . -s res://tests/run_tests.gd

package:
	$(NEST)/bin/nest-package

verify-package: package
	GODOT="$(GODOT)" TIMEOUT="$(TIMEOUT)" $(NEST)/bin/nest-verify-package

clean:
	rm -rf .godot dist

## Turn a fresh copy of the template into a new add-on: make init NAME=lyrebird
init:
	@test -x scripts/init.sh || { echo "This repo is already initialised."; exit 1; }
	scripts/init.sh "$(NAME)"

upgrade:
	@test -n "$(FROM)" || { echo "usage: make upgrade FROM=<release tag | template checkout>"; exit 1; }
	$(NEST)/bin/nest-upgrade "$(FROM)"
