#!bin/bash

#===============================================
#decription: 	config file for compMotifs.py
#author:		Katarzyna Kedzierska
#date:			September 26th, 2017
#usage:			bash config.sh
#===============================================


error()
{
    echo -e "$@" 1>&2
    usage_and_exit 1
}

usage() 
{     
    echo -e "Usage: 
    bash config.sh

    Configures compMotifs.py script. Only needs to run once. Needs to be run from the directory it is in!"
}  

usage_and_exit()
{
    usage
    exit $1
}

### I'm checking where you put me so I can modify the path for the script!
script_path=$(pwd -P)

### Checking for python3 path
if command -v python3 > /dev/null 2>&1; then
    python3_path=$(which python3)
    sed "s/python3_path required/$python3_path/g" compMotifs.py > tmp.py && mv tmp.py compMotifs.py
    sed "s/script_path required/$script_path/g" compMotifs.py > tmp.py && mv tmp.py compMotifs.py
else
    error 'Python3 required to run!'
fi

### Checking for the necessary packages
for f in numpy re Bio itertools os; do
	if python -c "import package_name" &> /dev/null; 
        then
	else
		error 'Package' $f 'is not installed.'
	fi

