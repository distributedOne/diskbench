#!/bin/bash

SIZE_OF_TEST="1T"
TEST_FILENAME="fio_test_file"
IO_DEPTH="32"
RUNTIME="300"

YEAR=`date +%Y`
MONTH=`date +%m`
DAY=`date +%d`
TIME=`date +%H-%M-%S`
RESULT_PATH="concurrent_results"

mkdir $RESULT_PATH

#Gets tests to run
tests=`ls -1 ../diskbench/enabled-tests`

path=/var/lib/ceph/osd
osds=`ls -1 ${path}`

for t in $tests
do
		for osd in $osds
        	do
                	echo "Running $t on $osd"
       			export TEST_DIRECTORY=${path}/${osd} && export  TEST_SIZE=${SIZE_OF_TEST} && export IO_DEPTH=${IO_DEPTH} && export TEST_FILENAME=${TEST_FILENAME} && export RUNTIME=${RUNTIME} && fio --output=${RESULT_PATH}/concurrent_${TIME}-${t}-${osd} ../diskbench/enabled-tests/${t} &
		done
        #Wait for subprocesses to finish
        wait
	echo "Test $t finished on ${osd}"

done

