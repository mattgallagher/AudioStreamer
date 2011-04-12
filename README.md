AudioStreamer
=============

This is a fork of the [mattgallagher/AudioStreamer](https://github.com/mattgallagher/AudioStreamer) repo.

History
-------

April 12, 2001
  * Updated AudioStream with the latest from [mattgallagher/AudioStreamer](https://github.com/mattgallagher/AudioStreamer).
  * Added level meter code from [idevsoftware/AudioStreamer](https://github.com/idevsoftware/AudioStreamer)
  * Added level meter display to the sample projects.

January 30, 2011

  * Forked [mattgallagher/AudioStreamer](https://github.com/mattgallagher/AudioStreamer).
  * Replaced #ifdef TARGET_OS_IPHONE with #if TARGET_OS_IPHONE. This is Apple's recommended approach for [conditionalizing compilation and linking](http://developer.apple.com/library/ios/#documentation/Xcode/Conceptual/iphone_development/115-Configuring_Applications/configuring_applications.html#//apple_ref/doc/uid/TP40007959-CH19-SW3). Also, TargetConditionals.h header in Mac 10.6 SDK defines TARGET_OS_IPHONE as 0 so this change is needed if one wishes to compile against 10.6 or greater.
  * Merged shoutcast branch from [jfricker/AudioStreamer](https://github.com/jfricker/AudioStreamer) adding support for retrieving shoutcast metadata and replacing the alert display with a notification message.
  * Replaced SHOUTCAST_METADATA marco with retrieveShoutcastMetadata BOOL on the AudioStreamer class.
  * Added this README.