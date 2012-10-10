#!/bin/bash

## SETTINGS ##
NUMBER_OF_TIMES_TO_RUN_EACH_JOB=3
export TEST_SIZE="4096m"
export TEST_FILENAME="fio_test_file"
export IO_DEPTH="256"
export RUNTIME="3600"

# get time and create results folder
YEAR=`date +%Y`
MONTH=`date +%m`
DAY=`date +%d`
TIME=`date +%H%M`

# Used to formatting
bold=`tput bold`
normal=`tput sgr0`

usage()
{
    echo "Usage: $0: [OPTIONS]"
    echo "  -u              : Directory/mountpoint to test"
    echo "  -s              : Test file size (default: 4G)"
    echo "  -i              : I/O depth (used by fio) (default: 256 - heavy)" 
    echo "  -n              : Test name (used for the comparaison)"
    echo "  -p profile_name : Enable tests based on a profile (optional)"
    echo "  -g 500          : Number of pgs for the rados bench pool (default: 500) (optional)"
    echo "  -x              : Run extra tests: IOZone and Bonnie++ (optional)"
    echo "  -t              : Set the runtime for indiviual FIO test (default: 3600 seconds)"
    echo "  -l              : List available tests"
    echo ""
    echo "Example:"
    echo "  $0 -u /mnt/nfs/ -s 4G -i 256 -n mytestname -x -t 600"
    exit 1
}

log()
{
    echo $1 | tee -a ${RESULT_PATH}/output.log
}

sysinfo()
{
  mkdir -p ${RESULT_PATH}/sysinfo

  for proc in cpuinfo meminfo mounts modules version
  do
    cat /proc/$proc > ${RESULT_PATH}/sysinfo/$proc
  done

  for cmd in dmesg env lscpu lsmod lspci dmidecode free
  do
    $cmd > ${RESULT_PATH}/sysinfo/$cmd
  done
}

launch_rados()
{
  log "===> CREATE POOL: ${TIME}_performance (`date +%H:%M:%S`)"
  sudo ceph osd pool create ${TIME}_performance ${PGS} ${PGS}

  log "===> RADOS BENCH WRITE TEST: START (`date +%H:%M:%S`)"
  sudo rados bench 600 write -p ${TIME}_performance -o ${RESULT_PATH}/result_rados_write.csv
  log "===> RADOS BENCH WRITE TEST: END (`date +%H:%M:%S`)"

  log "===> RADOS BENCH READ TEST: START (`date +%H:%M:%S`)"
  sudo rados bench 600 seq -p ${TIME}_performance -o ${RESULT_PATH}/result_rados_seq.csv
  log "===> RADOS BENCH READ TEST: END (`date +%H:%M:%S`)"

  sudo ceph osd pool delete ${TIME}_performance
  log "===> DELETE POOL: ${TIME}_performance (`date +%H:%M:%S`)"
}

launch_fio()
{
  log "===> FIO TESTS: START (`date +%H:%M:%S`)"
  COUNTER=1
  until [ $COUNTER -gt $NUMBER_OF_TIMES_TO_RUN_EACH_JOB ]; do
    for t in `ls -1 enabled-tests/`
    do
      log "===================="
        log "Running: ${t}"
        log "Pass Number: ${COUNTER}"
        log "Test Size: ${TEST_SIZE}"
        export RESULT_PATH="./results/${YEAR}${MONTH}${DAY}_${TIME}_${TEST_NAME}"
        mkdir -p ${RESULT_PATH}
        touch ${RESULT_PATH}/fio-${t}-pass-${COUNTER}
        echo -n ${TEST_NAME} > ${RESULT_PATH}/NAME
        #Drop caches
        echo 3 > /proc/sys/vm/drop_caches
        fio --output=${RESULT_PATH}/fio-${t}-pass-${COUNTER} ./enabled-tests/${t}
      log ""
    done
    let COUNTER+=1
  done
  log "===> FIO TESTS: END (`date +%H:%M:%S`)"

  fiotocsv
}

launch_iozone()
{
  log "===> IOZONE TESTS: START (`date +%H:%M:%S`)"
  if [ `grep ${TEST_DIRECTORY} /etc/fstab` ]; then
    iozone -a -R -c -U ${TEST_DIRECTORY} -f ${TEST_DIRECTORY}/${TEST_FILENAME} -b ${RESULT_PATH}/result_iozone.xls
  else
    iozone -a -R -c -f ${TEST_DIRECTORY}/${TEST_FILENAME} -b ${RESULT_PATH}/result_iozone.xls
  fi
  log "===> IOZONE TESTS: END (`date +%H:%M:%S`)"

}

launch_bonnie()
{
  bonnie++ -q -u `whoami` -d ${TEST_DIRECTORY}/ -m ${TEST_NAME} -n 258 > ${RESULT_PATH}/result_bonnie.csv
}

check_apps()
{
  for app in fio dmidecode
  do
    if [ ! "`which $app`" ]; then
        echo "ERROR: '$app' application is required."
        EXIT=1
    fi
  done
  
  if [ ! -z "${EXTRA_TESTS}" ]; then

    for app in iozone bonnie++
    do
      if [ ! "`which $app`" ]; then
          echo "ERROR: '$app' application is required."
          EXIT=1
      fi
    done
  fi
  
  if [ "$EXIT" == "1" ]; then
    echo "Please install the above application(s) then re-run the script."
    exit $EXIT
  fi
}

fiotocsv()
{
  echo "Test name,Test type,Read IOPS,WRITE IOPS,READ BW, WRITE BW" > ${RESULT_PATH}/result_fio.csv
  for pass in `ls -1 $RESULT_PATH/fio-* | awk -F'pass-' {'print \$2'} | uniq | sort | uniq`;
  do
    for file in `ls -1 $RESULT_PATH/fio-*-$pass`;
    do
      cat $RESULT_PATH/NAME >> ${RESULT_PATH}/result_fio.csv
      echo -n "," >> ${RESULT_PATH}/result_fio.csv
      JOB=`head -n 1 ${file} | awk -F: {'print \$1'}`
      echo -n "${JOB}," >> ${RESULT_PATH}/result_fio.csv
      READ_IOPS=`grep iops ${file}| grep read | awk -F'iops=' {'print \$2'} | awk {'print \$1'}`
      echo -n "${READ_IOPS}," >> ${RESULT_PATH}/result_fio.csv
      WRITE_IOPS=`grep iops ${file}| grep write | awk -F'iops=' {'print \$2'} | awk {'print \$1'}`
      echo -n "${WRITE_IOPS}," >> ${RESULT_PATH}/result_fio.csv
      READ_BANDWIDTH=`grep READ ${file} | awk -F'maxb=' {'print \$2'} | awk -F, {'print \$1'}`
      echo -n "${READ_BANDWIDTH}," >> ${RESULT_PATH}/result_fio.csv
      WRITE_BANDWIDTH=`grep WRITE ${file} | awk -F'maxb=' {'print \$2'} | awk -F, {'print \$1'}`
      echo "${WRITE_BANDWIDTH}" >> ${RESULT_PATH}/result_fio.csv
    done
  done
}

available_tests()
{
  echo -e "\n${bold}Available tests${normal}"
  for test in `ls -1 available-tests`;
  do
    echo -e "\t$test"
  done

  echo -e "\n${bold}Enabled tests${normal}"
  for test in `ls -1 enabled-tests`;
  do
    echo -e "\t$test"
  done

  echo -e "\n${bold}Available profiles${normal}"
  for profile in `ls -1 profiles`
  do
    echo -e "\t$profile"
  done

  exit 1
}

check_profile()
{
  if [ ! -e profiles/${PROFILE_NAME} ]
    then
      echo "Profile does not exist!"
      echo -e "${bold}Available Profiles${normal}"
      for profile in `ls -1 profiles`
      do
        echo -e "\t$profile"
      done
      exit 1
  fi
}

results()
{
  tar cfz results.${TEST_NAME}.${YEAR}${MONTH}${DAY}_${TIME}.tar.gz ${RESULT_PATH}/
  log "Results: results.${TEST_NAME}.${YEAR}${MONTH}${DAY}_${TIME}.tar.gz"
}

while getopts 'u:s:i:n:p:g:x:t:l' OPTION
do
    case ${OPTION} in
    u)
        export TEST_DIRECTORY="${OPTARG}"
        ;;
    s)
        export TEST_SIZE="${OPTARG}"
        ;;
    i)
        export IO_DEPTH="${OPTARG}"
        ;;
    n)
        export TEST_NAME="${OPTARG}"
        ;;
    p)
        export PROFILE_NAME="${OPTARG}"
        ;;
    g)
        export PGS="${OPTARG}"
        ;;
    x)
        export EXTRA_TESTS="1"
        ;;
    t)
        export RUNTIME="${OPTARG}"
        ;;
    l)
        available_tests
        ;;
    ?)
        usage
        ;;
    esac
done

# mandatory parameters
if [ ! "${TEST_DIRECTORY}" ] || [ ! "${TEST_SIZE}" ] || [ ! "${IO_DEPTH}" ] || [ ! "${TEST_NAME}" ]; then
    usage
fi

# first, check that all applications are installed on the system
check_apps

# collect system information
sysinfo

# set profile to none if empty
if [ -z "${PROFILE_NAME}" ]; then
    PROFILE_NAME="none"
else
  check_profile

  if [ -z "${PGS}" ]; then
      PGS="500"
  fi
  
  for oldtest in `ls -1 ./enabled-tests/`; do rm ./enabled-tests/$oldtest; done;
  for test in `cat ./profiles/${PROFILE_NAME}`;
    do
      if [ "$test" == "rados-bench" ]; then
        launch_rados
      else
        cd ./enabled-tests/; ln -s ../available-tests/$test; cd ..;
      fi
    done;
fi

# start the tests
log "Start: `date +%H:%M:%S`"

launch_fio
if [ ! -z "${EXTRA_TESTS}" ]; then
    launch_iozone
    launch_bonnie
fi
log "Done: `date +%H:%M:%S`"

# prepare the result tar.gz
results

exit 0
