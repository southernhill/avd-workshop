.PHONY: setup build preview twin lab lab-down lab-reset lab-status clean reset help

# Settings
VENV := .venv
ANSIBLE := $(VENV)/bin/ansible-playbook
INVENTORY ?= inventory.yml
CEOS_IMAGE := ceos:4.35.0F
CEOS_URL := https://ha-web.vdwal.xyz/cEOS64-lab-4.35.0F.tar.xz
CEOS_TAR := cEOS64-lab-4.35.0F.tar.xz
# ─────────────────────────────────────────────────────────────────────────────
# Setup
# ─────────────────────────────────────────────────────────────────────────────

setup:
	@if ! docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '$(CEOS_IMAGE)'; then \
		echo "Downloading cEOS image..."; \
		wget -q --show-progress -O $(CEOS_TAR) $(CEOS_URL); \
		docker import $(CEOS_TAR) $(CEOS_IMAGE); \
		rm -f $(CEOS_TAR); \
	else \
		echo "cEOS image already present, skipping download."; \
	fi
	uv venv $(VENV) --python 3.13
	uv pip install --python $(VENV)/bin/python "pyavd[ansible]"
	$(VENV)/bin/ansible-galaxy collection install arista.avd
	@echo ""
	@echo "Done. Run 'make build' to generate configs."

# ─────────────────────────────────────────────────────────────────────────────
# Build & Deploy
# ─────────────────────────────────────────────────────────────────────────────

build:
ifdef HOST
	$(ANSIBLE) build.yml -i $(INVENTORY) --limit $(HOST)
else
	$(ANSIBLE) build.yml -i $(INVENTORY)
endif

preview:
	$(ANSIBLE) deploy.yml -i $(INVENTORY) --check --diff

twin:
ifdef HOST
	$(ANSIBLE) deploy.yml -i $(INVENTORY) --limit $(HOST)
else
	$(ANSIBLE) deploy.yml -i $(INVENTORY)
endif

# ─────────────────────────────────────────────────────────────────────────────
# Lab
# ─────────────────────────────────────────────────────────────────────────────

lab:
	cd clab && sudo clab deploy

lab-down:
	cd clab && sudo clab destroy

lab-reset:
	cd clab && sudo clab destroy --cleanup

lab-status:
	sudo clab inspect -a

# ─────────────────────────────────────────────────────────────────────────────
# Cleanup
# ─────────────────────────────────────────────────────────────────────────────

clean:
	rm -rf intended/ documentation/ config_backup/

reset: clean
	rm -rf $(VENV)

# ─────────────────────────────────────────────────────────────────────────────
# Help
# ─────────────────────────────────────────────────────────────────────────────

help:
	@echo "Usage: make <command> [HOST=<device>]"
	@echo ""
	@echo "Setup"
	@echo "  setup       Install dependencies"
	@echo ""
	@echo "Workflow"
	@echo "  build       Generate configs"
	@echo "  preview     Show what would change"
	@echo "  twin        Deploy to digital twin"
	@echo ""
	@echo "Lab"
	@echo "  lab         Start containerlab"
	@echo "  lab-down    Stop containerlab"
	@echo "  lab-reset   Stop and remove all lab files"
	@echo "  lab-status  Show lab status"
	@echo ""
	@echo "Cleanup"
	@echo "  clean       Remove generated files"
	@echo "  reset       Remove everything (clean + venv)"
	@echo ""
	@echo "Examples"
	@echo "  make build              Build all devices"
	@echo "  make build HOST=leaf-01"
	@echo "  make preview            See changes before deploy"
	@echo "  make twin               Deploy to digital twin"
