Benchmark Automation Script
===========

A script that automates benchmark testing via a collection fio and iozone tests and simple tools for disk performance testing.

Tests
===========

You can find a list of all current tests within the available-tests/ folder.

In order to enable a test I have been creating a symlink from the enabled-tests/ folder pointing to a test in the available-tests folder. For example:

    cd enabled-tests;
    ln -s ../available-tests/libaio-buffered-4m-randrw ./

That will enable the "libaio-buffered-4m-randrw" test and it will run the next time you start the fio-runner.sh script.

By default all the tests are enabled.

Executing The Tests
===========

Once you have enabled the tests you want to run all you need to do is execute is the diskbench.sh script:

    ./diskbench.sh 
    Usage: ./diskbench.sh: [OPTIONS]
      -u              : Directory/mountpoint to test
      -s              : Test file size (default: 4G)
      -i              : I/O depth (used by fio) (default: 256 - heavy)
      -n              : Test name (used for the comparaison)
      -p profile_name : Enable tests based on a profile (optional)
      -g 500          : Number of pgs for the rados bench pool (default: 500) (optional)
      -x              : Run extra tests: IOZone and Bonnie++ (optional)
      -l              : List available tests

This will execute each of the fio tests and their results will be stored into the results folder.
