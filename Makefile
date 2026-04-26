include scripts/init.mk

# ==============================================================================
# Project targets

format: # Auto-format code @Quality
	# No formatting required for this repository

lint-file-format: # Check file formats @Quality
	check=all ./scripts/quality/check-file-format.sh && echo "file format: ok"

lint-markdown-format: # Check markdown formatting @Quality
	check=all ./scripts/quality/check-markdown-format.sh && echo "markdown format: ok"

lint-markdown-links: # Check markdown links @Quality
	output=$$(check=all ./scripts/quality/check-markdown-links.sh 2>&1) && echo "markdown links: ok" || { echo "$$output"; exit 1; }

lint-shell: # Check shell scripts @Quality
	$(MAKE) check-shell-lint

lint: # Run linter to check code style and errors @Quality
	$(MAKE) lint-file-format
	$(MAKE) lint-markdown-format
	$(MAKE) lint-markdown-links
	$(MAKE) lint-shell

test: # Run all tests @Testing
	bash ./scripts/tests/apply.test.sh && echo "apply: ok"
	bash ./scripts/tests/import.test.sh && echo "import: ok"

clone-rt: # Clone the repository template into .github/skills/repository-template @Operations
	.github/skills/repository-template/scripts/git-clone-repository-template.sh

specify: # Fetch upstream spec-kit and apply local extensions @Operations
	./scripts/specify.sh

apply: # Copy prompt files assets to a destination repository; mandatory: dest=[path] ai=[copilot|claude]; optional: clean|revert=[true|false], all|python|typescript|go|reactjs|rust|terraform|tauri|playwright|django|fastapi=[true] @Operations
	$(if $(dest),,$(error dest is required. Usage: make apply dest=/path/to/destination ai=copilot|claude))
	$(if $(ai),,$(error ai is required. Usage: make apply dest=/path/to/destination ai=copilot|claude))
	./scripts/apply.sh "$(dest)" "$(ai)"

import: # Import changed prompt files from a destination repository; mandatory: dest=[path] ai=[copilot|claude]; optional: force|new=[true] @Operations
	$(if $(dest),,$(error dest is required. Usage: make import dest=/path/to/destination ai=copilot|claude))
	$(if $(ai),,$(error ai is required. Usage: make import dest=/path/to/destination ai=copilot|claude))
	./scripts/import.sh "$(dest)" "$(ai)"

count-tokens: # Count LLM tokens for key instruction packs; optional: args=[files/options] @Operations
	uv run --with tiktoken python scripts/count-tokens.py \
		$(if $(args),$(args), \
			--sort-by tokens \
			.github/copilot-instructions.md \
			.specify/memory/constitution.md \
			.github/instructions/makefile.instructions.md \
			.github/instructions/shell.instructions.md \
			.github/instructions/docker.instructions.md \
			.github/instructions/python.instructions.md \
			.github/instructions/includes \
			.github/skills/repository-template/SKILL.md \
		)

clean:: # Remove project-specific generated files (main) @Operations
	rm -rf .github/skills/repository-template/assets
	find . \( \
		-name ".coverage" -o \
		-name ".env" -o \
		-name "*.log" -o \
		-name "coverage.xml" \
	\) -prune -exec rm -rf {} +

config:: # Configure development environment (main) @Configuration
	$(MAKE) _install-dependencies
	$(MAKE) clone-rt

# ==============================================================================

${VERBOSE}.SILENT: \
	apply \
	clean \
	clone-rt \
	config \
	count-tokens \
	format \
	import \
	lint \
	lint-file-format \
	lint-markdown-format \
	lint-markdown-links \
	lint-shell \
	specify \
	test \
