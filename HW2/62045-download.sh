#!/bin/bash

if [ $# -ne 2 ]
then
	echo "Usage: ${0} [directory] [download link]"
       	exit 1
fi	

if [ ! -d "${1}" ]
then
	echo "${1} does not exist, or is not a directory. Trying to create it."
	mkdir -p "${1}"
	if [ $? -eq 0 ]
	then
		dir=${1}
	else
		echo "Could not create directory. Exiting."
		exit 2
	fi
else
	dir="${1}"
fi

temporary=$(mktemp)
wget -q -O "${temporary}" "${2}"

for participant in $(echo $(cat "${temporary}" | tail -n +10 | head -n -2 | cut -d "\"" -f6))
do
	wget -q --directory-prefix "${dir}" "${2}"/"${participant}"
done
