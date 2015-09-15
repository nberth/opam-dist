# -*- makefile-gmake -*-
# ----------------------------------------------------------------------
#
# Makefile utilities to build and distribute opam packages either
# directly (`pool' method) or web-hosted git.
#
# Copyright (C) 2015 Nicolas Berthier
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# ----------------------------------------------------------------------
#
# o Usage Instructions
#
# To use these utilities, define an environment variable (e.g.,
# OPAM_DIST_DIR) and make it refer the absolute directory containting
# this `opam-dist.mk' file. This variable will be used to check the
# project is built on a setup capable of buildingt and distributing
# the projects' release archives.
#
# Configuration can be done on a per-project or per-site basis:
#
# - Per-site definitions are read first, and should be placed in a
#   file named `$(OPAM_DIST_DIR)/opam-dist-config.mk' (i.e., in the
#   same directory as `opam-dist.mk');
#
# - Per-project definitions must be placed at the root of the
#   projects' source code directory, in a file named either
#   `opam-dist-config.mk' or `.opam-dist-config.ml'.
#
# When loaded by make, `opam-dist.mk' first reads, if they exist, the
# per-site configuration file and then the per-project ones. In the
# end, several variables must have been defined; among them are the
# two following variables, common to all distribution methods:
#
# OPAM_REPO_DIR = <path of OPAM repository directory>
# OPAM_DIST_METHOD = { pool | git }
#
# Two methods are currently available for distributing the archives:
# `pool' or `git'.
#
# - Selecting the `pool' distribution method means that the
#   distributed archives will be generated into a given directory that
#   should then be accessible on the Internet. To use it, you must
#   additionally define the following variables:
#
#   DIST_POOL_DIR = <absolute path of directory where archives will be	\
#                    put>
#   DIST_POOL_URL = <URL of the directory pointed to by the above	\
#                    variable>
#
# - Selecting the `git' distribution method means that the released
#   archives shall be retrieved directly form a git repository
#   available on the Internet (such as github). In this case, you must
#   define the following variable:
#
#   OPAM_DIST_GIT_ARCH_FROM_REF = <URL of the reference $(1)>
#
#   e.g., on github, for project `p' of user `u', one cas define this
#   variable as:
# 
#   OPAM_DIST_GIT_ARCH_FROM_REF =					\
#                             https://github.com/u/p/archive/$(1).tar.gz
#
# o Specifying the Contents of Project Distribution Archives
#
# Once opam-dist is configured, add the following definitions in the
# Makefile of your project:
# 
# PKGNAME = <OPAM package name>
# VERSION_STR = <OPAM-compatible version of your package>
# ifneq ($(OPAM_DIST_DIR),)
#   OPAM_DIR = <directory containting the OPAM-related files listed	\
#               bellow>
#   OPAM_FILES = descr opam files
#   DIST_FILES = <list of files to put in the distribution archive	\
#                 (configure LICENSE README Makefile myocamlbuild.ml src
#                 _tags ...)>
#   -include $(OPAM_DIST_DIR)/opam-dist.mk
# endif
#
# When using the `git' distribution method, it is recommended to use
# tags to define version numbers, and then generate VERSION_STR using
# something like:
#
# VERSION_STR = $(shell git describe --tags --always)
# 
# Also, do not forget to push tags (using `git push --tags') on the
# remote repository.
#
# o Building and Distributing the Package
# 
# Eventually, type `make opam-package' to create the distribution
# archive (if using the `pool' method) and deploy the necessary files
# in the OPAM repository directory ($(OPAM_REPO_DIR)).
#
# If the repository directory is version-controlled using git, then
# just commit (anf push) the changes. Otherwise run `opam-admin make
# -g -i' in it to set it up. If and when the changes made in
# $(OPAM_REPO_DIR) by the latter command are made accessible through a
# public URL of the repository (say, `http://repo-url/', and the pool
# is also made accessible through $(DIST_POOL_URL), then the OPAM
# package should be available for installation after executing `opam
# repo add <repo-name> http://repo-url/; opam update repo
# <repo-name>'.
#
# ------------------------------------------------------------------------------

-include $(dir $(lastword $(MAKEFILE_LIST)))/opam-dist-config.mk
-include opam-dist-config.mk
-include .opam-dist-config.mk

# ---

DIST_DIR := $(PKGNAME)-$(VERSION_STR)
ifeq ($(DIST_POOL_DEEP),yes)
  DIST_NAME := $(PKGNAME)/$(DIST_DIR).tar.gz
else
  DIST_NAME := $(DIST_DIR).tar.gz
endif
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
  OPAM_PKG_DIR := $(OPAM_REPO_DIR)/packages
  ifeq ($(OPAM_REPO_DEEP),yes)
    OPAM_PKG_DIR := $(OPAM_PKG_DIR)/$(PKGNAME)
  endif
  OPAM_DEST_DIR := $(OPAM_PKG_DIR)/$(PKGNAME).$(VERSION_STR)
  OPAM_DEPS = $(addprefix $(OPAM_DIR)/, $(OPAM_FILES))

  .PHONY: opam-package opam-package-pool
  opam-package: opam-package-$(OPAM_DIST_METHOD)

  opam-package-dir-repo: $(OPAM_DEPS)
	@test -d "$(OPAM_DEST_DIR)" && rm -rf "$(OPAM_DEST_DIR)" || true;
	@echo -n "Creating \`$(OPAM_DEST_DIR)'..." >/dev/stderr;	\
	mkdir -p "$(OPAM_DEST_DIR)";					\
	cp -r $(OPAM_DEPS) "$(OPAM_DEST_DIR)";				\
	echo " done" >/dev/stderr;

  opam-package-pool: $(DIST_ARCH) opam-package-dir-repo
	echo -n "Computing checksum..." >/dev/stderr;			\
	md5sum="$$(md5sum "$(DIST_ARCH)" | cut -d ' ' -f 1)";		\
	echo -ne " done\nGenerating url file..." >/dev/stderr;		\
	exec 1>"$(OPAM_DEST_DIR)/url";					\
	echo "archive: \"$(DIST_POOL_URL)/$(DIST_NAME)\"";		\
	echo "checksum: \"$${md5sum}\"";				\
	echo " done" >/dev/stderr;

  opam-package-git: opam-package-dir-repo
	@ref="$(VERSION_STR)";						\
	arch="$(call OPAM_DIST_GIT_ARCH_FROM_REF,$${ref})";		\
	echo -n "Testing archive \`$${arch}'..." >/dev/stderr;		\
	if wget --spider -q "$${arch}"; then				\
	  echo " found" >/dev/stderr;					\
	else								\
	  echo " no found" >/dev/stderr;				\
	  echo "Reference \`$${ref}' does not seem to exist on remote"	\
	       "repository. Did you push your changes?" > /dev/stderr;	\
	  exit 1;							\
	fi;								\
	echo -n "Computing checksum..." >/dev/stderr;			\
	md5sum="$$(wget -O - -q "$${arch}" | md5sum | cut -d ' ' -f 1)";\
	echo -ne " done\nGenerating url file..." >/dev/stderr;		\
	exec 1>"$(OPAM_DEST_DIR)/url";					\
	echo "archive: \"$${arch}\"";					\
	echo "checksum: \"$${md5sum}\"";				\
	echo " done" >/dev/stderr;

  .PHONY: opam-package-clean
  opam-package-clean: force
	rm -rf $(OPAM_DEST_DIR);

endif

# ---

.PHONY: force
force:

# ------------------------------------------------------------------------------
