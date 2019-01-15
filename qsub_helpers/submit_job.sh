#!/bin/bash
DATE="$(date +%y%m%d)"
PROGRAM="$(basename $0)"
error() 
{
  echo -e "$@" 1>&2
  usage_and_exit 1
}

usage()
{
  echo -e " 
bash $PROGRAM [-ds] [-l ERRMSG_PATH] [-w WD] [-o OUT_PATH] [-n JOBNAME] [-t CORES] SCRIPT_PATH

Sumbit job to the cluster with defined options and command in SCRIPT_PATH to execute. 

Arguments:
SCRIPT_PATH   path to the bash script with commands to be executed

Options:
--delete\-d   Don't save the job script. Job script is saved on default.
--stop\-s     Don't submit the job. Job is submitted on default.
--logs\-l     Path to the directory in which the logs should be saved, default: ~/logs/
--working\-w  Working directory, default: ./
--out\-o      Output path to which the final script should be saved, default: ~/jobs/
--name\-n     Job name, default: basename of the SCRIPT_PATH without extension
--threads\-t  Number of cores to be requested, default: 1
"
}

usage_and_exit()
{
  usage
  exit $1
}

# Initialize variables
# user-specific
TEMPLATE=./qsub_helpers/qsub_job_template.sh
ERRMSG_PATH=~/logs/
OUT_PATH=~/jobs/
# generic
CORES=1
PARAMS=
DELETE=false
JOBNAME=
WD=./
DONT_RUN=false

while (( "$#" )); do
  case "$1" in
    --logs | -l )
      ERRMSG_PATH="$2"
      shift 2
      ;;
    --working | -w )
      WD="$2"
      shift 2
      ;;
    --name | -n )
      JOBNAME="$2"
      shift 2
      ;;
    --delete | -d )
      DELETE=true
      OUT_PATH=./temp/
      shift 1
      ;;
    --out | -o )
      OUT_PATH=$2
      shift 2
      ;;
    --threads | -t )
      CORES="$2"
      shift 2
      ;;
    --stop | -s )
      DONT_RUN=true
      shift 1
      ;;
    --help | -h | '-?' | '--?' ) 
      usage_and_exit 0
      ;;
    -- ) # end argument parsing
      shift
      break
      ;;
    -* | --*= ) # unsupported flags
      error "Error: Unsupported flag $1"
      ;;
    * ) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

# Set positional arguments in their proper place
eval set -- "$PARAMS"

SCRIPT_PATH=$1

# TESTS
if [ "X${SCRIPT_PATH}" == "X" ]; then
  error "No script path provided!"
fi

if [ "${DONT_RUN}" == "true" -a "${DELETE}" == "true" ]; then
  error "The output won't be saved and the job won't be run, what's teh point? ;)"
fi

# Finish setting up 
# if no name provided, set it to the basename of the script
if [ "X${JOBNAME}" == "X" ]; then
  JOBNAME=$(basename ${SCRIPT_PATH} | rev | cut -f2- -d'.' | rev)
fi

created=
if [ ! -d ./temp/ ]; then
  mkdir ./temp/
  created=true
fi

# Execute
# Fill the all variables
sed "s/%JOBNAME%/${JOBNAME}/g; s/%ERRMSG_PATH%/${ERRMSG_PATH//\//\\/}/g; s/%WD%/${WD//\//\\/}/g; s/%CORES%/${CORES}/g" ${TEMPLATE} > ./temp/${JOBNAME}_${DATE}.tmp

# Create a proper job script with options and the commands to be executed
cat ./temp/${JOBNAME}_${DATE}.tmp ${SCRIPT_PATH} > ${OUT_PATH}/${JOBNAME}_${DATE}.sh

# Run the job 
if [ "${DONT_RUN}" == "false" ]; then
  qsub ${OUT_PATH}/${JOBNAME}_${DATE}.sh
fi

# Cleanup 
if [ "${DELETE}" == "true" ]; then
  rm -f ${OUT_PATH}/${JOBNAME}_${DATE}.sh
fi

if [ "X${created}" == "Xtrue" ]; then
  rm -fr ./temp
else
  rm -f ./temp/${JOBNAME}_${DATE}.tmp
fi


