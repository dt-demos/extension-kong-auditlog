-include .env
export DT_TENANT_URL
export DT_API_TOKEN

VENV    := .venv/bin
DT_SDK  := $(VENV)/dt-sdk
VERSION := $(shell grep '^version:' extension/extension.yaml | awk '{print $$2}')
EXT     := custom_com.dynatrace.extension.kong-auditlog
ZIP     := dist/$(EXT)-$(VERSION).zip

# Path to your CA cert for attaching to releases — override if needed:
#   make release CA_PEM=/path/to/ca.pem
CA_PEM  ?= $(HOME)/.dynatrace/certificates/ca.pem

.DEFAULT_GOAL := help

.PHONY: help build validate upload release schemas clean

help:
	@echo ""
	@echo "Kong Audit Log Extension — v$(VERSION)"
	@echo ""
	@echo "  make build      Assemble and sign the extension → dist/"
	@echo "  make validate   Validate the signed ZIP against your DT tenant"
	@echo "  make upload     Validate and upload to your DT tenant"
	@echo "  make release    Create a GitHub Release and attach the signed ZIP"
	@echo "  make schemas    Download extension schemas into .schemas/ (dev only)"
	@echo "  make clean      Remove dist/"
	@echo ""
	@echo "  Tenant: $(DT_TENANT_URL)"
	@echo "  ZIP:    $(ZIP)"
	@echo ""

build:
	@if [ -f "$(ZIP)" ]; then \
		echo ""; \
		echo "ERROR: $(ZIP) already exists."; \
		echo "Bump version: in extension/extension.yaml before running make build."; \
		echo ""; \
		exit 1; \
	fi
	mkdir -p dist
	cd extension && zip -qr ../dist/extension.zip . --exclude "*.DS_Store"
	$(DT_SDK) sign dist/extension.zip -o $(ZIP)
	@rm -f dist/extension.zip

validate: $(ZIP)
	$(DT_SDK) upload --validate -u "$(DT_TENANT_URL)" -t "$(DT_API_TOKEN)" $(ZIP)

upload: $(ZIP)
	$(DT_SDK) upload -u "$(DT_TENANT_URL)" -t "$(DT_API_TOKEN)" $(ZIP)
	@echo ""
	@echo "Upload successful — activate the extension in your tenant:"
	@echo "  $$(echo '$(DT_TENANT_URL)' | sed 's/\.live\./.apps./g')ui/apps/dynatrace.extensions.manager"
	@echo ""

release: $(ZIP)
	@test -f "$(CA_PEM)" || { echo "ERROR: CA cert not found at $(CA_PEM)"; echo "Run: dt-sdk gencerts  (or set CA_PEM=/path/to/ca.pem)"; exit 1; }
	gh release create v$(VERSION) $(ZIP) $(CA_PEM) \
	  --title "Kong Konnect Audit Log Extension v$(VERSION)" \
	  --generate-notes

schemas:
	mkdir -p .schemas
	gh release download --repo dynatrace-extensions/extensions-schemas --dir .schemas

clean:
	rm -rf dist/

$(ZIP):
	@echo "Run 'make build' first"
	@exit 1
