# EPICS V4 Release 4.6.0 C++ Bundle Release Notes

This document summarizes the Release Notes entries from each individual C++
submodule for this bundled version of EPICS V4. For patch releases the patch changes will appear in addition to the original release notes.


## pvCommonCPP 4.2.0

The Boost header files are now only installed for VxWorks target architectures, since they are only essential for that OS. This prevents clashes with sofware that has been built with a different version of Boost.


## pvDataCPP 6.0.0


## pvAccessCPP 5.0.0

* Remote channel destroy support
* Multiple network inteface support
* Local multicast (repetitor) reimplemented
* Monitor reconnect when channel type changes fix
* C++11 compilation fixes
* Added version to pvaTools
* Memory management improved
* pipeline: ackAny argument percentage support
* Monitor overrun memory issues fixed
* CA provider destruction fixed
* Replaced LGPL wildcard matcher with simplistic EPICS version


## normativeTypesCPP 5.1.0


## pvaClientCPP 0.12.0

* The examples are moved to exampleCPP.
* Support for channelRPC is now available.
* In PvaClientMultiChannel checkConnected() now throws an exception if connect fails.


## pvaSrv 0.12.0
* Major clean-up wrt returned structures on gets
  and monitors
* Treat enum as uint16 (not int32)
* Security plugin improvements
* Fix issues #3, #5
* Changes in Jenkins jobs (@CloudBees)


## pvDatabaseCPP 4.2.0

* The examples are moved to exampleCPP
* Support for channelRPC is now available.
* removeRecord and traceRecord are now available.

The test is now a regression test the can be ran via

     make runtests


## exampleCPP 4.2.0

* HelloWorld has been renamed helloRPC.

* The following examples have been moved from pvDatabaseCPP:
  * arrayPerformance
  * database
  * exampleLink
  * helloPutGet
  * powerSupply
  * pvDatabaseRPC

* The following have been moved from pvaClientCPP:
  * exampleClient
  * test


## pvaPy 0.6

- added support for channel putGet() and getPut() operations
- introduced PvObject support for field path notation (e.g, 'x.y.z')
- introduced PvObject support for __getitem__, __setitem__, __contains__
- new constructor for PvObject allows optional value dictionary
- added PvObject support for retrieving numeric scalar arrays as
  read-only numpy arrays (requires compiling with Boost.NumPy)

