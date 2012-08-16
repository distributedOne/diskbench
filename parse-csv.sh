#!/bin/bash

ROOT_PATH="results"

for year in `ls -1 $ROOT_PATH/`;
do
  YEAR_PATH=$ROOT_PATH/$year
  for month in `ls -1 $YEAR_PATH/`;
  do
    MONTH_PATH=$YEAR_PATH/$month
    for day in `ls -1 $MONTH_PATH/`;
    do
      DAY_PATH=$MONTH_PATH/$day
      for runset in `ls -1 $DAY_PATH | awk -F- {'print \$1"-"\$2"-"\$3'} | uniq | sort | uniq`;
      do
        for pass in `ls -1 $DAY_PATH/$runset-* | awk -F'pass-' {'print \$2'} | uniq | sort | uniq`;
        do
          for file in `ls -1 $DAY_PATH/$runset-*-$pass`;
          do
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
    done
  done
done
