#!/bin/bash

# CONSTANT
# Send mail to these users
#$ -M kasia@well.ox.ac.uk

# Mail at beginning/end/on suspension
#$ -m esa

# Project name and target queue
#$ -P wedge.prjc
# -q short.qc

# VARIABLE

# Remember to save output and errors!
#$ -e %ERRMSG_PATH%/%JOBNAME%.e
#$ -o %ERRMSG_PATH%/%JOBNAME%.o

# Working directory
#$ -wd %WD%

# Specify a job name
#$ -N %JOBNAME%

# Parallel environemnt settings
#  For more information on these please see the wiki
#  Allowed settings:
#   shmem
#   mpi
#   node_mpi
#   ramdisk
#$ -pe shmem %CORES%

# Some useful data about the job to help with debugging
echo "------------------------------------------------"
echo "SGE Job ID: $JOB_ID"
echo "SGE Task ID: $SGE_TASK_ID"
echo "Run on host: "`hostname`
echo "Operating system: "`uname -s`
echo "Username: "`whoami`
echo "Started at: "`date`
echo "------------------------------------------------"

### THE CODE TO BE RUN ###
