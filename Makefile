# Pathsettting
WORK_DIR  ?= $(CURDIR)

# Args
IMAGE     ?= riscv-gnu-toolchain
NAMESPACE ?=
REGISTRY  ?= nderjung.net
TAG       ?= $(shell git symbolic-ref HEAD | sed -e "s/^refs\/heads\///")
CONTAINER ?= $(subst //,/,$(REGISTRY)/$(NAMESPACE)/$(IMAGE):$(TAG))

# Tools
DOCKER    ?= docker

# Targets
.PHONY: all
all: container

.PHONY: container
container:
	$(DOCKER) build \
		--network host \
		-f $(WORK_DIR)/Dockerfile \
		-t $(CONTAINER) \
		.
