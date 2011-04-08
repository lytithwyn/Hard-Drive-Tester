# Hard Drive Tester

I designed this to run from our linux PXE environment to give us a way to easily run tests on hard drives without having to remember command line parameters.  For simplicity reasons the initial version runs as a normal user, so the actual binaries being called must be setuid root.  Security is not an issue in this case since it's in a controlled environment that only we use but in the future I'll probably get root'ed'ness migrated into the Ruby script itself.

Right now there isn't anything fluffy, no special checks for attempting to run multiple tests or anything; it just does what you tell it to do.

Hard drives are detected by looking in /proc/partitions, so pretty much anything that shows up in there should appear in the list of drives.
