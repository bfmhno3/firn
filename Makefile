ifndef FIRN_DEVSHELL
$(error run inside nix develop)
endif

CHAPTERS := $(notdir $(wildcard lab/ch*))
NIX_FILES = $(shell git ls-files '*.nix')
NIX_STRICT = $(filter-out lab/% templates/%,$(NIX_FILES))
SHELL_FILES = $(shell git ls-files '*.sh')

.PHONY: chapters lint check repro ci clean $(CHAPTERS)

$(CHAPTERS):
	bash scripts/chapter.sh $@

chapters:
	@set -e; for c in $(CHAPTERS); do bash scripts/chapter.sh $$c; done

lint:
	nixfmt --check $(NIX_FILES)
	@set -e; for f in $(NIX_STRICT); do statix check $$f; done
	deadnix --fail $(NIX_STRICT)
	shellcheck $(SHELL_FILES)
	shfmt -i 2 -bn -ci -d $(SHELL_FILES)

check:
	nix flake check -L

repro:
	nix build .#firn-hello --rebuild

ci: lint chapters check

clean:
	rm -rf out
