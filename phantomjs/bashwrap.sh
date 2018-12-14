#!/bin/bash
mkdir -p mappe

# start packet capture:
tshark -f 'tcp port 443' -w phantomjspcap.pcap &
sleep 10
# Name of phantomjs script:
phantom='ph2.js'
while read p; do
	urlArray=( $(QT_QPA_PLATFORM=offscreen phantomjs $phantom  https://$p |  tr " " "\n" \
	| sed -n 's/href="\(https:\/\/[^"]*\)".*/\1/ipg' | sort | uniq |  tee log.txt)) 
	echo ${#urlArray[@]}
	if [ ${#urlArray[@]} -eq 0  ]
	then
		:	
	else
		tempVar=$(( $RANDOM % ${#urlArray[@]}))
		# Log which URL was chosen
		echo ${urlArray[$tempVar]} >> ./mappe/fil.txt
		# To visit second link or not
		# Create pseudorandom number, 1 or 2
		if [ $(( 1 + $RANDOM % 2)) == '1' ]
		then
			# visit
			sleep 1
			echo ${urlArray[$tempVar]} 
			QT_QPA_PLATFORM=offscreen phantomjs $phantom ${urlArray[$tempVar]} | tee >> besøkt.txt
		else
		# dont do anything
			:
		fi
	fi
done <adresser.txt
pkill tshark
