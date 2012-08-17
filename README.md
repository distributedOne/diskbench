FIO Testing Tools
===========

A collection of Flexible IO Tester (fio) tests and simple tools for disk performance testing with fio.

Tests
===========

You can find a list of all current tests within the available-tests/ folder.

In order to enable a test I have been creating a symlink from the enabled-tests/ folder pointing to a test in the available-tests folder. For example:

    cd enabled-tests;
    ln -s ../available-tests/libaio-buffered-4m-randrw ./

That will enable the "libaio-buffered-4m-randrw" test and it will run the next time you start the fio-runner.sh script.

By default the following tests are enabled:

    libaio-buffered-4m-randrw
    libaio-buffered-4m-rw
    libaio-not-buffered-4m-randrw
    libaio-not-buffered-4m-rw
    sync-buffered-4k-r
    sync-buffered-4k-w
    sync-buffered-4m-r
    sync-buffered-4m-w
    sync-not-buffered-4k-r
    sync-not-buffered-4k-w
    sync-not-buffered-4m-r
    sync-not-buffered-4m-w

Executing The Tests
===========

Once you have enabled the tests you want to run all you need to do is execute is the fio-runner.sh script:

    ./fio-runner.sh

This will execute each of the fio tests and their results will be stored into the results folder.

Analyzing The Results
===========

You can find the result files in the results/ folder. For my own purposes I've been requiring read/write iops and bandwidth information. If you're interested in the same there is a parse-csv.sh file which will generate a csv you can import into your favorite spreadsheet application:

    ./parse-csv.sh > results.csv

If you don't pipe the output somewhere it will go to your console's default output.

Do with it as you will.