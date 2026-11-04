# Makefile for wiktoria-skills
# Run `make` to set up skills locally

.PHONY: setup install-skills

# Default target - runs when `make` is called without arguments
setup: install-skills
	@echo "Skills setup complete!"

# Install skills globally (symlinks to agent directories)
install-skills:
	@echo "Installing skills globally..."
	./setup-global.sh --both
