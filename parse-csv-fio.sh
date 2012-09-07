#!/bin/bash

ROOT_PATH="results"

echo "Test Name,Read IOPS,WRITE IOPS,READ BW, WRITE BW"
for runset in `ls -1 $ROOT_PATH/`;
do
  ROOT_PATH="${ROOT_PATH}/${runset}"
  for pass in `ls -1 $ROOT_PATH/fio-* | awk -F'pass-' {'print \$2'} | uniq | sort | uniq`;
  do
    for file in `ls -1 $ROOT_PATH/fio-*-$pass`;
    do
      cat $ROOT_PATH/NAME
      echo -n ","
      JOB=`head -n 1 ${file} | awk -F: {'print \$1'}`
      echo -n "${JOB},";
      READ_IOPS=`grep iops ${file}| grep read | awk -F'iops=' {'print \$2'} | awk {'print \$1'}`
      echo -n "${READ_IOPS},"
      WRITE_IOPS=`grep iops ${file}| grep write | awk -F'iops=' {'print \$2'} | awk {'print \$1'}`
      echo -n "${WRITE_IOPS},"
      READ_BANDWIDTH=`grep READ ${file} | awk -F'maxb=' {'print \$2'} | awk -F, {'print \$1'}`
      echo -n "${READ_BANDWIDTH},"
      WRITE_BANDWIDTH=`grep WRITE ${file} | awk -F'maxb=' {'print \$2'} | awk -F, {'print \$1'}`
      echo "${WRITE_BANDWIDTH}"
    done
  done
done
