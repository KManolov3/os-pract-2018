#!/bin/bash

keyword="fuehrer"
latinCipherFilename="encrypted"
latinAlphabetSize=26
startOfSmallLatinLetters=97

asciiToDec(){
	LC_CTYPE=C printf "%d" "'$1"
}

decToAscii(){
	[ "$1" -lt 256 ] || return 1
	printf "\\$(printf '%03o' "$1")"
}

getDiff(){
	firstChar=$(echo "${1}"|cut -c 1)
	secondChar=$(echo "${1}"|cut -c 2)
	diff=$(( $(asciiToDec "${secondChar}") - $(asciiToDec "${firstChar}") ))
	if [ "${diff}" -lt 0 ]
	then
		((diff+=latinAlphabetSize))
	fi
	echo "${diff}"
}

keywordLength=$(echo -n "${keyword}" | wc -c)
cipherLength=$(cat "${latinCipherFilename}"|wc -c)
positionInCipher=1
while [ "${positionInCipher}" -le $((cipherLength - keywordLength + 1)) ] 
do
	positionInKeyword=1
	while [ "${positionInKeyword}" -lt "${keywordLength}" ]
	do
		cipherCurr=$(cat "${latinCipherFilename}"|cut -c "$((positionInCipher + positionInKeyword - 1))"-$((positionInCipher + positionInKeyword)))
		keywordCurr=$(echo "${keyword}"|cut -c "${positionInKeyword}"-$((positionInKeyword+1)))
		
		if [ $(getDiff "${cipherCurr}") -eq $(getDiff "${keywordCurr}") ]
		then
			((positionInKeyword+=1))
		else
			break
		fi
	done
	if [ "${positionInKeyword}" -eq "${keywordLength}" ]
	then
		keyInDec=$(getDiff $(echo "${keywordCurr}" | cut -c1)$(echo "${cipherCurr}" | cut -c1) )
		break
	else
		((positionInCipher+=1))
	fi
done

cat "${latinCipherFilename}" | tr "$(decToAscii $((keyInDec + startOfSmallLatinLetters)) )-za-$(decToAscii $((keyInDec + startOfSmallLatinLetters -1)) )" "a-z"
