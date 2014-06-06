# -*- makefile-gmake -*-
#
# Author: Nicolas Berthier
#
# ------------------------------------------------------------------------------
# Makefile utilities to build opam packages. To use it, define an environment
# variable (e.g., OPAM_DEVEL_DIR) and make it refer the absolute directory
# containting this `opam-dist.mk' file. Also add a `devel-config.mk' file in the
# same directory, containing the following definitions:
# 
# DIST_POOL_DIR = <path of directory where archives will be put>
# OPAM_POOL_URL = <public URL of the directory pointed to by the above variable>
# OPAM_REPO_DIR = <path of OPAM repository directory>
#
# Then, add the following definitions in the Makefile of your project:
# 
# PKGNAME = <OPAM package name>
# VERSION_STR <OPAM-compatible version of your package>
# ifneq ($(OPAM_DEVEL_DIR),)
#   OPAM_DIR = <directory containting all OPAM-related files listed bellow>
#   OPAM_FILES = descr opam files
#   DIST_FILES = <list of files to put in the distribution archive (configure
#                 LICENSE README Makefile myocamlbuild.ml src _tags ...)>
#   -include $(OPAM_DEVEL_DIR)/opam-dist.mk
# endif
#
# Eventually, type `make opam-package' to create the distribution archive in
# directory $(DIST_POOL_DIR) and deploy the necessary files in the OPAM
# repository directory ($(OPAM_REPO_DIR)). Then run `opam-admin make -g -i' in
# the latter directory to set it up. If and when the changes made in
# $(OPAM_REPO_DIR) by the latter command are made accessible through a public
# URL of the repository (say, `http://repo-url/', and the pool is also made
# accessible through $(OPAM_POOL_URL), then the OPAM package should be available
# for installation after executing `opam repo add <repo-name> http://repo-url/;
# opam update repo <repo-name>'.
# 
# ------------------------------------------------------------------------------

-include $(dir $(lastword $(MAKEFILE_LIST)))/devel-config.mk
-include devel-config.mk

DIST_DIR := $(PKGNAME)-$(VERSION_STR)
DIST_NAME := $(PKGNAME)/$(DIST_DIR).tar.gz
DIST_POOL_DIR ?= .
DIST_ARCH := $(DIST_POOL_DIR)/$(DIST_NAME)

.PHONY: opam-dist
opam-dist: $(DIST_ARCH) force
$(DIST_ARCH): $(DIST_FILES) $(DIST_DEPS)
	mkdir -p "$(DIST_DIR)";
	cp -r $(DIST_FILES) "$(DIST_DIR)";
	mkdir -p "$(dir $@)";
	tar cvaf "$@" "$(DIST_DIR)";
	rm -rf "$(DIST_DIR)";

# ---

HAS_OPAM_INFO = $(shell test -d "$(OPAM_DIR)" && echo yes || echo no)
ifeq ($(HAS_OPAM_INFO),yes)

  OPAM_REPO_DIR ?= .
  OPAM_DEST_DIR = $(OPAM_REPO_DIR)/packages/$(PKGNAME).$(VERSION_STR)
  OPAM_DEPS = $(addprefix $(OPAM_DIR)/, $(OPAM_FILES))

  .PHONY: opam-package
  opam-package: $(DIST_ARCH) $(OPAM_DEPS)
	test -d "$(OPAM_DEST_DIR)" && rm -rf "$(OPAM_DEST_DIR)" || true;
	mkdir -p "$(OPAM_DEST_DIR)";
	cp -r $(OPAM_DEPS) "$(OPAM_DEST_DIR)";
	exec 1>"$(OPAM_DEST_DIR)/url";					\
	echo "archive: \"$(OPAM_POOL_URL)/$(DIST_NAME)\"";		\
	echo "checksum: \"$$(md5sum "$(DIST_ARCH)" | cut -d ' ' -f 1)\"";

  .PHONY: opam-package-clean
  opam-package-clean: force
	rm -rf $(OPAM_DEST_DIR);

endif

# ---

.PHONY: force
force:

# ------------------------------------------------------------------------------
