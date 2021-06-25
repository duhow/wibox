.DEFAULT_GOAL := help

BUILD_DIR = cramfs
FILE = mtd4
DATE := $(shell date +%y%m%d-%H%M)
MODEL ?= none

all: extract patch build

extract:
	cramfsck -x $(BUILD_DIR) $(FILE)

build:
	rm -f $(BUILD_DIR)/patched 2>/dev/null
	mkdir -p release
	mkcramfs -e 0 -v -L $(BUILD_DIR) release/image-$(DATE)
	ln -sf image-$(DATE) release/latest

patch:
	@for PATCH in scripts/??_*.sh; do \
		echo ">> $$PATCH"; \
		ROOTFS=$(BUILD_DIR) sh $$PATCH; \
		echo "----"; \
	done | tee -a patch.log
	@touch $(BUILD_DIR)/patched

clean:
	rm -rf $(BUILD_DIR) 2>/dev/null

$(BUILD_DIR): extract
$(BUILD_DIR)/patched: patch

help:
	@echo "Usage (as root): "
	@echo ""
	@echo "  make extract FILE=mtd4 - Extract the content of the image."
	@echo "                           Beware $(BUILD_DIR) will be deleted!"
	@echo ""
	@echo "  make patch             - Apply patches."
	@echo ""
	@echo "  make build             - Create a new image in release folder."
	@echo ""
