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

COUNTER=1
until [ $COUNTER -gt $NUMBER_OF_TIMES_TO_RUN_EACH_JOB ]; do
  for t in `ls -1 enabled-tests/`
  do
    echo "===================="
      echo "Running: ${t}"
      echo "Pass Number: ${COUNTER}"
      touch ${RESULT_PATH}/${TIME}-${t}-pass-${COUNTER}
      fio --output=${RESULT_PATH}/${TIME}-${t}-pass-${COUNTER} ./enabled-tests/${t} 
    echo "===================="
  done
  let COUNTER+=1
done

echo "===================="
echo "DONE"