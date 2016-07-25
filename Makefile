# Copyright information and license terms for this software can be
# found in the file LICENSE that is included with the distribution

# Build the EPICS V4 Bundle out of Submodules

# These are our submodules
MODULES += pvCommonCPP
MODULES += pvDataCPP
MODULES += normativeTypesCPP
MODULES += pvAccessCPP
MODULES += pvaClientCPP
MODULES += pvaSrv
MODULES += pvaPy
MODULES += pvDatabaseCPP
MODULES += exampleCPP

# Dependencies between the submodules.
        pvDataCPP_DEPENDS_ON = pvCommonCPP
normativeTypesCPP_DEPENDS_ON = pvDataCPP
      pvAccessCPP_DEPENDS_ON = pvDataCPP
     pvaClientCPP_DEPENDS_ON = pvAccessCPP normativeTypesCPP
           pvaSrv_DEPENDS_ON = pvAccessCPP
            pvaPy_DEPENDS_ON = pvaClientCPP
    pvDatabaseCPP_DEPENDS_ON = pvAccessCPP
       exampleCPP_DEPENDS_ON = pvDatabaseCPP pvaSrv pvaClientCPP

# Make actions for which dependencies matter
ACTIONS = build host

# Set EPICS_HOST_ARCH if necessary
ifeq ($(origin EPICS_HOST_ARCH),undefined)
  EPICS_HOST_ARCH := $(shell perl $(EPICS_BASE)/startup/EpicsHostArch.pl)
endif

# Name of generated RELEASE files
RELEASE = RELEASE.local
# This doesn't work yet for embedded tops or pvaPy:
#RELEASE = RELEASE.$(EPICS_HOST_ARCH).Common

# Include bundle RELEASE file if it exists, sets EPICS_BASE
ifneq ($(wildcard $(RELEASE)),)
  include $(RELEASE)
else
  # Make sure EPICS_BASE is set
  ifeq ($(wildcard $(EPICS_BASE)),)
    $(error EPICS_BASE is not set/present)
  endif
endif

# These are internal build targets
BUILD_TARGETS = $(MODULES:%=build.%)
HOST_TARGETS = $(MODULES:%=host.%)
TEST_TARGETS = $(MODULES:%=test.%)
CONFIG_TARGETS = $(MODULES:%=config.%)
DECONF_TARGETS = $(MODULES:%=deconf.%)
CLEAN_TARGETS = $(MODULES:%=clean.%)
DISTCLEAN_TARGETS = $(MODULES:%=distclean.%)
CLEAN_DEP = $(filter clean distclean,$(MAKECMDGOALS))

# Public build targets
all: $(BUILD_TARGETS)
config: $(CONFIG_TARGETS)
host: $(HOST_TARGETS)
test: $(TEST_TARGETS)
clean: $(CLEAN_TARGETS)
deconf: $(DECONF_TARGETS)
	perl -MExtUtils::Command -e rm_f $(RELEASE)
distclean: $(DISTCLEAN_TARGETS) deconf
rebuild: clean
	$(MAKE) all

# Generic build rules
$(MODULES): % : build.%

$(BUILD_TARGETS): build.% : $(CLEAN_DEP) config.%
	$(MAKE) -C $* all

$(HOST_TARGETS): host.% : $(CLEAN_DEP) config.%
	$(MAKE) -C $* $(EPICS_HOST_ARCH)

$(TEST_TARGETS): test.% :
	$(MAKE) -C $* runtests CROSS_COMPILER_TARGET_ARCHS=

$(CLEAN_TARGETS): clean.% :
	$(MAKE) -C $* clean

$(DECONF_TARGETS): deconf.% :
	perl -MExtUtils::Command -e rm_f $*/configure/$(RELEASE)

$(DISTCLEAN_TARGETS): distclean.% :
	$(MAKE) -C $* distclean

# Expand %_DEPENDS_ON into %_DEPENDS_ALL
$(foreach module, $(MODULES), $(eval $(module)_DEPENDS_ALL = \
    $(foreach dep, $($(module)_DEPENDS_ON), $(dep) $($(dep)_DEPENDS_ALL))))

# Build rules for RELEASE files
$(CONFIG_TARGETS): config.% : %/configure/$(RELEASE)
pvaPy/configure/RELEASE.local:
	$(MAKE) -C pvaPy configure EPICS_BASE=$(EPICS_BASE) EPICS4_DIR=$(abspath .)
	@echo CROSS_COMPILER_TARGET_ARCHS= >> pvaPy/configure/CONFIG_SITE.local
%/configure/$(RELEASE): $(RELEASE)
	perl tools/genRelease.pl -o $@ -B $(EPICS_BASE) $($*_DEPENDS_ALL)
$(RELEASE):
	perl tools/genRelease.pl -o $@ -B $(EPICS_BASE)

# Module build dependencies
define MODULE_DEPS_template
  $(1).$(2): $$(foreach dep, $$($(2)_DEPENDS_ON), \
      $$(addprefix $(1).,$$(dep))) $(2)/configure/$(RELEASE)
endef
$(foreach action, $(ACTIONS), \
  $(foreach module, $(MODULES), \
    $(eval $(call MODULE_DEPS_template,$(action),$(module)))))

# GNUmake hints
.PHONY: all host test clean distclean rebuild help
.PHONY: $(CONFIG_TARGETS) $(BUILD_TARGETS) $(HOST_TARGETS) $(TEST_TARGETS)
.PHONY: $(CLEAN_TARGETS) $(DISTCLEAN_TARGETS)
