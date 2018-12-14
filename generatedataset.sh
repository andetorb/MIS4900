#!/bin/bash

# Depends on csvtool, joy, sed, python

# For temp files
mkdir -p ./tmp/mal ./tmp/curl ./tmp/phantoma ./tmp/spleis

#1: Merge malicious pcaps into one large:
mergecap -F pcap -w ./tmp/merged.pcap ./malcap/*.pcap
mv ./tmp/merged.pcap ./tmp/delete.pcap
# Extract only traffic that uses port 443
tshark -r ./tmp/delete.pcap -Y 'tcp.port eq 443' -w ./tmp/merged.pcap
# clean
rm ./tmp/delete.pcap
# Merge benign traffic into one large file
mergecap -F pcap -w ./tmp/spleis/spleis.pcap ./spleis/*.pcap

#2: Pcap to json.gz:
joy tls=1 bidir=1 type=1 ./tmp/spleis/*.pcap > ./tmp/spleis/spleis.gz
joy tls=1 bidir=1 type=1 ./tmp/merged.pcap > ./tmp/mal/malware.gz

function fixcsv() {
	fil=datafil
	tmp=./tmp

	# retrieves labels
	head -n 1 $fil > $tmp/labels
	# retrieves features 
	tail -n +2 "$fil" > $tmp/tmpfil
	mv $tmp/tmpfil $tmp/$fil

	# removing brackets etc.
	sed -i 's/\[//g' $tmp/$fil 
	sed -i 's/\]/\n/g' $tmp/$fil
	sed -i 's/^,//' $tmp/$fil
	sed -i 's/^ //' $tmp/$fil

	# fixing labels and adding them to the whole dataset
	cat $tmp/labels | tr -d '[]'  | sed 's/,/\n/g' | sed 's/^ //' > ./tmp/labels2
	mv $tmp/labels2 $tmp/labels
	paste -d "," $tmp/$fil $tmp/labels > finished.csv
	# fix
	sed -i 's/^,//' finished.csv

	# adding a header row with 1,2..n :
	# width of the dataset
	col=$(csvtool width finished.csv)
	# empty the header-file
	echo ""> ./tmp/header
	# for i in range 1..width of file=
	for i in $(seq "$col")
	do
		echo -n "$i," >> ./tmp/header
	done

	# replace the last comma with a z
	sed -i 's/.$/z/' ./tmp/header
	# replace the 'z' with a newline
	tr 'z' '\n' < ./tmp/header > ./tmp/header2
	# Stitch together the header with the rest
	cat ./tmp/header2 finished.csv > fin.csv
	# fix
	mv fin.csv finished.csv
	# Remove the first line which is empty
	sed -i '/^\s*$/d' finished.csv

	# replace binary classification with "true/false"
	# count number of benign and malicious flows
	benign=$(cut -d "," -f $col finished.csv | grep -c 0.0)
	mal=$(cut -d "," -f $col finished.csv | grep -c 1.0)

	# Start by recreating the header
	echo $col > ./tmp/lab

	# For benign traffic
	for i in $(seq "$benign")
	do
		echo " benign_traffic" >> ./tmp/lab
	done

	# For malicious traffic
	for i in $(seq "$mal")
	do
		echo " mal_traffic" >> ./tmp/lab
	done

	# Remove the binary classification:
	cut -d "," -f $col --complement finished.csv > ./tmp/withoutlabel.csv
	# Add the newly created labels
	paste -d "," ./tmp/withoutlabel.csv ./tmp/lab > finished.csv

	# Cleanup:
	rm ./tmp/labels params_bd.txt datafil ./tmp/header ./tmp/header2 ./tmp/withoutlabel.csv ./tmp/lab 
}

python ./analysis/model.py --ssl --meta --lengths --times -n ./tmp/spleis/ -p ./tmp/mal/ -o params_bd.txt > datafil
fixcsv
mv finished.csv ./ml/spleis.csv

