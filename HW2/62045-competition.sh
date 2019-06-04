#!/bin/bash

participants(){
	find "${1}" -mindepth 1 -maxdepth 1 -printf "%f\n"
}

findConnectedTo(){
	connected=$(mktemp)
	participants=$(participants "${1}")
	while read participant
	do
		cat "${1}/${participant}" | egrep '^QSO: ' | awk '{print $9}' | cut -d '/' -f 1 | sed 's/\r$//g'>> "${connected}"
		echo "" >> "${connected}"
	done < <(echo "${participants}")

	cat "${connected}"
}


outliers(){
	participants=$(participants "${1}")
	connected=$(findConnectedTo "${1}")
	connectedUniq=$(echo "${connected}" | sort | uniq)
	while read each
	do
		if [ -z $(echo "${participants}"| egrep "^${each}$") ]
		then 
			echo "${each}"
		fi
	done < <(echo "${connectedUniq}")
}

unique(){
	connections=$(findConnectedTo "${1}" | sort | uniq -c)
	for each in $(participants "${1}")
	do
		line=$(echo "${connections}" | egrep "\<${each}\>")
		if [ -z "$(echo ${line})" ] || [ "$(echo "${line}" | awk '{print $1}')" -le 3 ]
		then
			echo "${each}"
		fi
	done
}

findOneSidedConnections(){
	connectedWholeLines=$(mktemp)
	participants=$(participants "${1}")
	maxTimeDiff="${2}"
	while read participant
	do
		cat "${1}/${participant}" | egrep '^QSO: ' >> "${connectedWholeLines}"
	done < <(echo "${participants}")

	while read line
	do
		day=$(echo "${line}" | awk '{print $4}' | cut -d '-' -f 3)
		monthYear=$(echo "${line}" | awk '{print $4}' | cut -d '-' -f 1,2)
		hour=$(echo "${line}" | awk '{print $5}')
		from=$(echo "${line}" | awk '{print $6}')
		to=$(echo "${line}" | awk '{print $9}' | cut -d '/' -f 1 | sed 's/\r$//g' )
		
		if [ -z "$(echo "${participants}" | egrep "^${to}$" )" ]
		then
			echo "The following line's correspondent isn't a participant with a log file:"
		fi
		toFromMatches=$(cat ${connectedWholeLines} | egrep "${monthYear}.*${to}.*${from}")
		timeMatchFlag=0
		timeDiff=9999
		while read toFromMatch
		do
			if [ -z "${toFromMatch}" ]
			then
				continue
			fi
			
			toFromMatchDay=$(echo "${toFromMatch}"| awk '{print $4}' | cut -d '-' -f 3)
			dayDiff=$((10#$toFromMatchDay - 10#$day))
			toFromMatchHour=$(echo "${toFromMatch}" | awk '{print $5}')
			timeDiff=$((10#$toFromMatchHour - 10#$hour))
			((timeDiff +=  dayDiff*2400))

			if [ "${timeDiff}" -le "${maxTimeDiff}" ] && [ "${timeDiff}" -ge -"${maxTimeDiff}" ]
			then
				timeMatchFlag=1
				break
			fi
		done < <(echo "${toFromMatches}")

		if [ "${timeMatchFlag}" -eq 0 ]
		then
			echo "${line}"
		fi
	done < ${connectedWholeLines}

}	

cross_check(){
	findOneSidedConnections "${1}" 0
}

bonus(){
	findOneSidedConnections "${1}" 3
}

if [ $# -ne 2 ] 
then
	echo "Usage: ${0} [directory] [function name]"
	exit 1
fi

if [ ! -d "${1}" ]
then
	echo "${1} doesn't exist, or is not a directory!"
	exit 2
fi

case "${2}"
in
"participants")
	participants "${1}"
	;;
"outliers")
	outliers "${1}"
	;;
"unique")
	unique "${1}"
	;;
"cross_check")
	cross_check "${1}"
	;;
"bonus")
	bonus "${1}"
	;;
*)
	echo "No such function exists"
	exit 3
	;;
esac

exit 0
