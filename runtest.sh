#!/bin/bash

#Run tests on each OSD one at a time.
#OSD location based on defaults.
#Default File SIze: 1TB

#TODO: Replace with Python script
#Author: Tyler Brekke tyler.brekke@inktank.com

path=/var/lib/ceph/osd
osds=`ls -1 ${path}`
test_size=1T
runtime=120
iodepth=32
hostname=`hostname -s`

for osd in $osds
do
	./diskbench.sh -p direct -u ${path}/${osd} -s ${test_size} -i ${iodepth} -t ${runtime} -n single_${hostname}_${osd}
done



