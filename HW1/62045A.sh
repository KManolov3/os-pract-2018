#!/bin/bash

morseCipherFilename="secret_message"
morseTableFilename="morse"
latinCipherFilename="encrypted"

updatedCipher=$(mktemp)
translatedCipher=$(mktemp)
sed -r 's/(\.|\-)/\\\1/g' "${morseCipherFilename}"> "${updatedCipher}"
for i in $(cat ${updatedCipher})
do
	egrep "\ ${i}$" "${morseTableFilename}" | cut -d ' ' -f 1 >> "${translatedCipher}"
done
cat "${translatedCipher}" | tr -d "\n" | tr 'A-Z' 'a-z' > "${latinCipherFilename}"
echo "" >> "${latinCipherFilename}"
