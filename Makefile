# ====================================================================================
# Setup Project

PROJECT_NAME := provider-nutanix
PROJECT_REPO := github.com/mgeorge67701/crossplane-nutanix

PLATFORMS ?= linux_amd64 linux_arm64

# -include will silently skip missing files, which allows us
# to load those files with a target in the Makefile. If only
# "include" was used, the make command would fail and refuse
# to run a target until the include commands succeeded.
-include build/makelib/common.mk

# ====================================================================================
# Setup Output

-include build/makelib/output.mk

# ====================================================================================
# Setup Go

# Set a sane default so that the nprocs calculation below is less noisy on the initial
# loading of this file
NPROCS ?= 1

# each of our test suites starts a kube-apiserver and running many test suites in
# parallel can lead to high CPU utilization. by default we reduce the parallelism
# to half the number of CPU cores.
GO_TEST_PARALLEL := $(shell echo $$(( $(NPROCS) / 2 )))

GO_REQUIRED_VERSION ?= 1.21
# Only build the provider binary we actually have  
GO_STATIC_PACKAGES = $(GO_PROJECT)/cmd/provider
# Fix GO_SUBDIRS to match our actual project structure
GO_SUBDIRS += cmd internal apis
-include build/makelib/golang.mk

# ====================================================================================
# Setup Kubernetes tools

KIND_VERSION = v0.20.0
UP_VERSION = v0.28.0
UP_CHANNEL = stable
UPTEST_VERSION = v0.11.1
CROSSPLANE_CLI_VERSION = v2.0.2
CROSSPLANE_CLI_CHANNEL = stable
-include build/makelib/k8s_tools.mk

# ====================================================================================
# Setup Images

REGISTRY_ORGS ?= ghcr.io/mgeorge67701
IMAGES = $(PROJECT_NAME)
-include build/makelib/imagelight.mk

# ====================================================================================
# Setup XPKG

XPKG_REG_ORGS ?= ghcr.io/mgeorge67701
# NOTE(hasheddan): skip promoting on xpkg.upbound.io as channel tags are
# inferred.
XPKG_REG_ORGS_NO_PROMOTE ?= xpkg.upbound.io/mgeorge67701
XPKGS = $(PROJECT_NAME)
-include build/makelib/xpkg.mk

# NOTE(mgeorge67701): we ensure crossplane CLI is available before building packages
xpkg.build.provider-nutanix: $(CROSSPLANE_CLI)