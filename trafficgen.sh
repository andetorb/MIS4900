#!/bin/bash
## Dependencies:
# wget curl tshark
# sed tee phantomjs
# 

mkdir -p logs pcaps
### HTTPS ###
function createTrafficCurl() {
	urlFile=./url

	sleep 20
	tshark -i eth0 -f 'tcp port 443' -w ./pcaps/httpscurl.pcap &
	while read p; do
		urlArray=( $(curl -sSL https://$p -A 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:59.0) Gecko/20100101 Firefox/59.0' \
		 --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 1 \
		| tr " " "\n" | sed -n 's/href="\(https:\/\/[^"]*\)".*/\1/ipg' | tee ./logs/log.txt) )	
		echo ${#urlArray[@]}
		# which link in the array to curl:
		if [ ${#urlArray[@]} -eq 0  ]
		then
			:	
		else
			tempVar=$(( $RANDOM % ${#urlArray[@]}))
			echo ${urlArray[$tempVar]} >> ./logs/selectedsitecurl.txt
			# To curl or not to curl a second link
			# Create pseudorandom number, 1 or 2
			if [ $(( 1 + $RANDOM % 2)) == '1' ]
			then
				# Curl the selected array
				sleep 1
				curl -sSL ${urlArray[$tempVar]} -A 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:59.0) Gecko/20100101 Firefox/59.0' | tee >> ./logs/visitedrandomcurl.txt
			else
				# dont do anything
				:
			fi
		fi
	done <$urlFile
	sleep 5
	pkill tshark
	echo "Saved to https.pcap"
}


function downloadFile() {

	tshark -w download.pcap "tcp port 443" &
	sleep 5
	# Download newest firefox
	url='https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US'
	ua='Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:59.0) Gecko/20100101 Firefox/59.0'
	# Save to /dev/null
	wget -qO- $url --user-agent $ua &> /dev/null
	sleep 1
	pkill tshark
	echo "Saved to download.pcap"
}

function createTrafficPhantom() {
	urlFile=./url
	# start packet capture:
	tshark -f 'tcp port 443' -w ./pcaps/phantomjspcap.pcap &
	sleep 10
	# Name of phantomjs script:
	phantom='./phantomjs/ph2.js'
	while read p; do
		urlArray=( $(QT_QPA_PLATFORM=offscreen phantomjs $phantom  https://$p |  tr " " "\n" \
		| sed -n 's/href="\(https:\/\/[^"]*\)".*/\1/ipg' | sort | uniq |  tee ./logs/log.txt)) 
		echo ${#urlArray[@]}
		if [ ${#urlArray[@]} -eq 0  ]
		then
			:	
		else
			tempVar=$(( $RANDOM % ${#urlArray[@]}))
			# Log which URL was chosen
			echo ${urlArray[$tempVar]} >> ./logs/selectedsitephantom.txt
			# To visit second link or not
			# Create pseudorandom number, 1 or 2
			if [ $(( 1 + $RANDOM % 2)) == '1' ]
			then
				# visit
				sleep 1
				echo ${urlArray[$tempVar]} 
				QT_QPA_PLATFORM=offscreen phantomjs $phantom ${urlArray[$tempVar]} | tee >> ./logs/visitedrandom.txt
			else
				# dont do anything
				:
			fi
		fi
	done <$urlFile
	sleep 5
	pkill tshark
}


# Run things:
#createTrafficCurl
#downloadFile
#createTrafficPhantom

