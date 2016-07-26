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

# Dependencies between modules, also used for RELEASE files
        pvDataCPP_DEPENDS_ON = pvCommonCPP
normativeTypesCPP_DEPENDS_ON = pvDataCPP
      pvAccessCPP_DEPENDS_ON = pvDataCPP
     pvaClientCPP_DEPENDS_ON = pvAccessCPP normativeTypesCPP
           pvaSrv_DEPENDS_ON = pvAccessCPP
            pvaPy_DEPENDS_ON = pvaClientCPP
    pvDatabaseCPP_DEPENDS_ON = pvAccessCPP
       exampleCPP_DEPENDS_ON = pvDatabaseCPP pvaSrv pvaClientCPP

# Embedded tops, which also need RELEASE files
    pvaSrv_CONTAINS_TOPS := testTop exampleTop
exampleCPP_CONTAINS_TOPS := database exampleClient exampleLink powerSupply
exampleCPP_CONTAINS_TOPS += helloPutGet helloRPC pvDatabaseRPC arrayPerformance

# Make actions for which dependencies matter
ACTIONS = build host

# Build tools
PERL = perl
RM = $(PERL) -MExtUtils::Command -e rm_f

# Set EPICS_HOST_ARCH if necessary
ifeq ($(origin EPICS_HOST_ARCH),undefined)
  EPICS_HOST_ARCH := $(shell $(PERL) $(EPICS_BASE)/startup/EpicsHostArch.pl)
endif

# Name of generated RELEASE files
RELEASE = RELEASE.$(EPICS_HOST_ARCH).Common

# Include the bundle's RELEASE file if it exists; sets EPICS_BASE
ifneq ($(wildcard $(RELEASE)),)
  include $(RELEASE)
else
  # Make sure EPICS_BASE is set
  ifeq ($(wildcard $(EPICS_BASE)),)
    $(error EPICS_BASE is not set or doesn't exist)
  endif
endif

# Internal build targets
BUILD_TARGETS = $(MODULES:%=build.%)
HOST_TARGETS = $(MODULES:%=host.%)
TEST_TARGETS = $(MODULES:%=test.%)
CLEAN_TARGETS = $(MODULES:%=clean.%)
DISTCLEAN_TARGETS = $(MODULES:%=distclean.%)
CLEAN_DEP = $(filter clean distclean,$(MAKECMDGOALS))
CONFIG_TARGETS = $(MODULES:%=config.%) $(foreach module, $(MODULES), \
    $(foreach top, $($(module)_CONTAINS_TOPS), config.$(module)/$(top)))
DECONF_TARGETS = $(MODULES:%=deconf.%) $(foreach module, $(MODULES), \
    $(foreach top, $($(module)_CONTAINS_TOPS), deconf.$(module)/$(top)))

# Public build targets
all: $(BUILD_TARGETS)
host: $(HOST_TARGETS)
test: $(TEST_TARGETS)
clean: $(CLEAN_TARGETS)
distclean: $(DISTCLEAN_TARGETS) deconf
rebuild: clean
	$(MAKE) all
config: $(CONFIG_TARGETS)
deconf: $(DECONF_TARGETS)
	$(RM) $(RELEASE)

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

$(DISTCLEAN_TARGETS): distclean.% :
	$(MAKE) -C $* distclean

# Expand %_DEPENDS_ON into %_DEPENDS_ALL
$(foreach module, $(MODULES), $(eval $(module)_DEPENDS_ALL = \
    $(foreach dep, $($(module)_DEPENDS_ON), $(dep) $($(dep)_DEPENDS_ALL))))

# Set %_DEPENDS_ALL for embedded tops too
$(foreach module, $(MODULES), $(foreach top, $($(module)_CONTAINS_TOPS), \
    $(eval $(module)/$(top)_DEPENDS_ALL = $(module) $($(module)_DEPENDS_ALL))))

# Special rules for pvaPy
config.pvaPy: pvaPy/configure/RELEASE.local
pvaPy/configure/RELEASE.local:
	$(MAKE) -C pvaPy configure EPICS_BASE=$(EPICS_BASE) EPICS4_DIR=$(abspath .)
	@echo CROSS_COMPILER_TARGET_ARCHS= >> pvaPy/configure/CONFIG_SITE.local
deconf.pvaPy:
	$(RM) pvaPy/configure/RELEASE.local pvaPy/configure/CONFIG_SITE.local

# Generic config rules
$(filter-out config.pvaPy, $(CONFIG_TARGETS)): config.% : %/configure/$(RELEASE)
%/configure/$(RELEASE): | $(RELEASE)
	$(PERL) tools/genRelease.pl -o $@ -B $(EPICS_BASE) $($*_DEPENDS_ALL)
$(RELEASE):
	$(PERL) tools/genRelease.pl -o $@ -B $(EPICS_BASE)
$(filter-out deconf.pvaPy, $(DECONF_TARGETS)): deconf.% :
	$(RM) $*/configure/$(RELEASE)

# Module build dependencies
define MODULE_DEPS_template
  $(1).$(2): $$(foreach dep, $$($(2)_DEPENDS_ON), \
      $$(addprefix $(1).,$$(dep))) $(2)/configure/$(RELEASE)
endef
$(foreach action, $(ACTIONS), \
  $(foreach module, $(MODULES), \
    $(eval $(call MODULE_DEPS_template,$(action),$(module)))))

# GNUmake hints
.PHONY: all host test clean distclean rebuild config deconf
.PHONY: $(BUILD_TARGETS) $(HOST_TARGETS) $(TEST_TARGETS) $(CLEAN_TARGETS)
.PHONY: $(DISTCLEAN_TARGETS) $(CONFIG_TARGETS) $(DECONF_TARGETS)
