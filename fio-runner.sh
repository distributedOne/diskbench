#!/bin/bash

## SETTINGS ##
NUMBER_OF_TIMES_TO_RUN_EACH_JOB=3

#Get time and create results folder
YEAR=`date +%Y`
MONTH=`date +%m`
DAY=`date +%d`
TIME=`date +%H-%M-%S`
RESULT_PATH="./results/${YEAR}/${MONTH}/${DAY}"
mkdir -p ${RESULT_PATH}

for t in `ls -1 enabled-tests/`
do
  COUNTER=1
  echo "===================="
  until [ $COUNTER -gt $NUMBER_OF_TIMES_TO_RUN_EACH_JOB ]; do
    echo "Running: ${t}"
    echo "Pass Number: ${COUNTER}"
    touch ${RESULT_PATH}/${TIME}-${t}-pass-${COUNTER}
    fio --output=${RESULT_PATH}/${t}-pass-${COUNTER} ./available-tests/${t} 
    let COUNTER+=1
  done
  echo "===================="
done

echo "===================="
echo "DONE"