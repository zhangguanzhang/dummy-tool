
HOST_ARCH ?= $(shell uname -m | tr A-Z a-z)
ifeq ($(HOST_ARCH),x86_64)
	HOST_ARCH=amd64
endif
ifeq ($(HOST_ARCH),aarch64)
	HOST_ARCH=arm64
endif
ifeq ($(HOST_ARCH),loongarch64)
    HOST_ARCH=loong64
endif

GOARCH ?= $(HOST_ARCH)

DOCKER_BUILDKIT ?= 1
DOCKER_BUILD_ARGS ?= 

COMMIT ?= $(shell git describe --dirty --long --always)
BUILDDATE   ?= $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
GIT_TREE_STATE ?= $(shell [ -z "$$(git status --porcelain 2>/dev/null)" ] || echo -dirty)
TAG_VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null || echo master)
BIN_VERSION = $(TAG_VERSION)$(GIT_TREE_STATE)

DOCKER_IMAGE_NAME       ?= zhangguanzhang/dummy-tool:$(TAG_VERSION)
GO ?= go

LDFLAGS_COMMON := \
  -X main.Version=$(TAG_VERSION) \
  -X main.gitCommit=$(COMMIT) \
  -X main.gitTreeState=$(GIT_TREE_STATE) \
  -X main.buildDate=$(BUILDDATE) \

bin:
	CGO_ENABLED=0 GOARCH=$(GOARCH) $(GO) build -trimpath \
		$(EXTRA_FLAGS) -ldflags "$(LDFLAGS_COMMON) $(EXTRA_LDFLAGS)" \
		-o dummy-tool main.go

docker-local: bin
	docker build . -f Dockerfile.local -t $(DOCKER_IMAGE_NAME)

image:
	docker buildx build . --platform linux/amd64,linux/arm64 --push --tag $(DOCKER_IMAGE_NAME)
