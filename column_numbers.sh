#!/usr/bin/env bash
#==============================================================================
#description:   Reads header of deliminated file and prints column names with
#               their numbers.
#author:        Kasia Kedzierska
#date:          February 12th, 2020
#usage:         bash column_number.sh INPUT or to be used in a pipeline (== can
#               read from stdin)
#==============================================================================

# Defining helper functions
error()
{
    echo -e "$@" 1>&2
    usage_and_exit 1
}

usage()
{
  echo -e "
$PROGRAM [-s\--sep SEPARATOR] FILEPATH

Reads header of deliminated file and prints column names with their numbers.

Arguments:

FILEPATH   path to the file; if not provided expects STDIN

Options:

--sep\-s    separator [Default: tab]
--help\-h   prints usage info"
}

usage_and_exit()
{
    usage
    exit $1
}

# Initializing variables
SEP="\t"
PROGRAM=$(basename $0)

# Get options
while (( "$#" )); do
  case "$1" in
    --sep | -s )
      SEP=$2
      shift 2
      ;;
    --help | -h | '-?' | '--?' )
      usage_and_exit 0
      ;;
    --) # end argument parsing
       shift
       break
       ;;
    -*|--*=) # unsupported flags
       error "Error: Unsupported flag $1"
       ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

# Read input from file or STDIN
if [[ "$PARAMS" == "" ]]; then
  INPUT=/dev/stdin
else
  if [[ $(echo $PARAMS | wc -w) > 1 ]]; then
    error "More than one positional argument!"
  else
    INPUT=$PARAMS
  fi
fi

# # Test if file has at least one line and is readible
# # doesn't work bc accessing stdin cleans it apparently
# lines=$(head $INPUT | wc -l)
#
# if [[ $lines < 1 ]]; then
#   error "File with no lines!"
# fi

# Actual execution
head -n 1 $INPUT  |
  sed "s/${SEP}/\n/g" |
    awk -v OFS="\t" '{print NR, $0}'
