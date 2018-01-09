# EPICS V4 Release 4.7.0 C++ Bundle Release Notes

This EPICS V4 C++ Package version 4.7.0 contains the same set of the EPICS V4 C++ modules as the full EPICS 7.0.1 release (with the pvaPy Python bindings added and no copy of EPICS Base), along with a top-level build system to allow configuring all the modules at once rather than doing each one individually.

This document contains the Release Notes entries from each individual C++ submodule, describing the changes between the previous bundleCPP version and this release version. For any future 4.7.x patch releases the information about the patch changes included will supplement the note entries from this release.

### Compatibilty

This release can be built against EPICS Base versions 3.15.x or 3.16.x. Later versions of EPICS Base are referred to as EPICS 7 and already include all the necessary V4 modules. EPICS Base versions 3.14.12.x and earlier are not compatible with the pva2pva module that was added to this package in this release. The other V4 modules may build and run against EPICS Base 3.14.12.x, but they have not been built or tested against that Base version recently.


------

## pvCommonCPP 4.2.3

The `mb.h` header has been updated to build properly against EPICS Base
versions prior to 3.15.0.1.


------

## pvDataCPP 7.0.0

### Removals

- Remove requester.h, monitor.h, and destroyable.h which were migrated to the pvAccessCPP module.
- Previously deprecated monitorPlugin.h is removed.
- Remove pv/messageQueue.h and epics::pvData::MessageQueue

### Deprecations

The following utility classes will be removed in 8.0:

- epics::pvData::Queue
- epics::pvData::Executor
- epics::pvData::TimeFunction

### Additions

- Add pv/pvdVersion.h which is included by pv/pvIntrospect.h
- Add epics::pvData::createRequest() function.  Alternative to epics::pvData::CreateRequest class which throws on error.
- epics::pvData::FieldBuilder allow Structure defintion to be changed/appended
- Add epics::pvData::ValueBuilder like FieldBuilder also sets initial values.
 - Can also be constructed using an existing PVStructure to allow "editing".
- Add debugPtr.h wrapper with reference tracking to assist in troubleshooting shared_ptr related ref. loops.
- Add pvjson utilities


------

## pvAccessCPP 6.0.0

### Incompatible changes

- Requires pvDataCPP >=7.0.0 due to headers moved from pvDataCPP into this module: requester.h, destoryable.h, and monitor.h
- Major changes to shared_ptr ownership rules for epics::pvAccess::ChannelProvider and
  associated classes.
- Add new library pvAccessIOC for use with PVAClientRegister.dbd and PVAServerRegister.dbd.
  Necessary to avoid having pvAccess library depend on all IOC core libraries.
- Added new library pvAccessCA with "ca" provider.  Main pvAccess library no longer depends on libca.
  Applications needing the "ca" provider must link against pvAccessCA and pvAccess.
  See examples/Makefile in the source tree.
  The headers associated with this library are: caChannel.h, caProvider.h, and caStatus.h
- A number of headers which were previously installed, but considered "private", are no longer installed.
- epics::pvAccess::ChannelProviderRegistry may no longer be sub-classed.
- Removed access to singleton registry via getChannelProviderRegistry() and registerChannelProviderFactory()
  in favor of epics::pvAccess::ChannelProviderRegistry::clients() and epics::pvAccess::ChannelProviderRegistry::servers().
  The "pva" and "ca" providers are registered with the clients() singleton.
  epics::pvAccess::ServerContext() looks up names with the servers() singleton.
- Removed deprecated epics::pvAccess::Properties
- The data members of epics::pvAccess::MonitorElement become const, preventing these pointers from being re-targeted.

### Simplifications

- use of the epics::pvAccess::ChannelRequester interface is optional
  and may be omitted when calling createChannel().
  Channel state change notifications are deliviered
  to individual operations via epics::pvAccess::ChannelBaseRequester::channelDisconnect()
- Default implementions added for the following methods
 - epics::pvAccess::Lockable::lock() and epics::pvAccess::Lockable::unlock() which do nothing.
 - epics::pvAccess::Channel::getConnectionState() returns CONNECTED
 - epics::pvAccess::Channel::isConnected() uses getConnectionState()
 - epics::pvAccess::Channel::getField() which errors
 - epics::pvAccess::Channel::getAccessRights() which returns rw
- Added epics::pvAccess::SimpleChannelProviderFactory template and
  epics::pvAccess::ChannelProviderRegistry::add() avoids need for custom
  factory.
- Added epics::pvAccess::MonitorElement::Ref iterator/smart-pointer
  to ensure proper handling of calls Monitor::poll() and Monitor::release().
- epics::pvAccess::PipelineMonitor "internal" is collapsed into epics::pvAccess::Monitor.
  PipelineMonitor becomes a typedef for Monitor.
- epics::pvAccess::RPCService is now a sub-class of epics::pvAccess::RPCServiceAsync

### Additions

- pv/pvAccess.h now provides macros OVERRIDE and FINAL which conditionally expand to the c++11 keywords override and final.
- Deliver disconnect notifications to individual Operations (get/put/rpc/monitor/...) via
  new epics::pvAccess::ChannelBaseRequester::channelDisconnect()
- New API for server creation via epics::pvAccess::ServerContext::create() allows direct specification
  of configuration and ChannelProvider(s).
- Add epics::pvAccess::ServerContext::getCurrentConfig() to get actual configuration, eg. for use with a client.
- Classes from moved headers requester.h, destoryable.h, and monitor.h added to epics::pvAccess namespace.
  Typedefs provided in epics::pvData namespace.
- Added Client API based on pvac::ClientProvider
- pv/pvaVersion.h defines VERSION_INT and PVACCESS_VERSION_INT
- epics::pvAccess::RPCClient may be directly constructed.
- epics::pvAccess::RPCServer allows epics::pvAccess::Configuration to be specified and access to ServerContext.
- Added epics::pvAccess::Configuration::keys() to iterate configuration parameters (excluding environment variables).
- Added epics::pvAccess::Destoryable::cleaner

### Deprecations

- epics::pvAccess::GUID in favor of epics::pvAccess::ServerGUID due to win32 name conflict.


------

## normativeTypesCPP 5.2.0

This release contains bug fixes and minor source updates needed to build against the latest version of pvData.


------

## pvaClientCPP 4.3.0

### Works with pvDataCPP-7.0 and pvAccessCPP-6.0 versions

Will not work with older versions.

### destroy methods removed

All the destroy methods are removed since implementation is RAII compliant.

### API changes to PvaClientMonitor

The second argument of method

    static PvaClientMonitorPtr create(
        PvaClientPtr const &pvaClient,
        epics::pvAccess::Channel::shared_pointer const & channel,
        epics::pvData::PVStructurePtr const &pvRequest
    );

Is now changed to

    static PvaClientMonitorPtr create(
        PvaClientPtr const &pvaClient,
        PvaClientChannelPtr const & pvaClientChannel,
        epics::pvData::PVStructurePtr const &pvRequest
    );

A new method is also implemented

    static PvaClientMonitorPtr create(
        PvaClientPtr const &pvaClient,
        std::string const & channelName,
        std::string const & providerName,
        std::string const & request,
        PvaClientChannelStateChangeRequesterPtr const & stateChangeRequester,
        PvaClientMonitorRequesterPtr const & monitorRequester
    );


------

## pva2pva 1.0.0

This module replaces the original pvaSrv.


------

## pvDatabaseCPP 4.3.0

This release contains bug fixes and minor source updates needed to build against the latest versions of pvData and pvAccess.


------

## pvaPy

### Release 1.0.0 (2018/01/04)

- added build support for python3
- added build support for EPICS7 releases

### Release 0.9 (2017/09/17)

- improved support for channel monitors: no monitor startup thread results in
  faster initial connections; monitors connect automatically when channels
  come online
- fixed support for older EPICS v4 releases (4.4, 4.5 and 4.6)
- added build support for numpy included with boost releases 1.63.0 and later

### Release 0.8 (2017/07/17)

- added new Channel monitor() method that can be used instead of
  subscribe()/startMonitor() sequence in case when there is only one
  subscriber
- enhanced PvaServer functionality: single server instance can serve multiple
  channels; channels can be added and removed dynamically; added (optional)
  callback for channel writes

### Release 0.7 (2017/05/10)

- added initial version of PvaServer class: PvObject exposed via instance of
  this class can be retrieved and manipulated using standard PVA command line
  tools and APIs
- fixed boolean array conversion to python list
- improved support for builds relying on custom boost installation


------

## bundleCPP 4.7.0

### Submodule Changes

In this release the pvaSrv module has been replaced with the newer and more functional pva2pva module. The exampleCPP module was dropped for this release as it hasn't yet been updated to demonstrate the latest pvData and pvAccess API changes.

The top-level Makefile has been modified to try and improve the behaviour of some of the buld targets (e.g. `make distclean` shouldn't try to configure any submodules that aren't already configured). In general this Makefile was designed for building the submodules from scratch, not for developers to use while working on the code.
