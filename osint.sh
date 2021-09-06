#!/bin/bash


### Colors

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'


### Installing required dependencies

#NEED TO ADD
#go, python3, pip3, gospider, damnsmallurlcrawler, gobuster, webtech

### URL input

echo "Enter the URL to scan"
read turl

if curl -s --head  --request GET $turl | grep "200\|301\|302" > /dev/null; then 
   echo -e "${GREEN}$turl is accessible ${NC}\n"
else
   echo -e "${RED}$turl is not accessible ${NC}\n"
   exit 1
fi

echo "Deep crawl (Y/N)?"
read deep

echo Enter the Wordlist path
read word

dir=${turl#*//} ## create a directory with the domain name of $turl
mkdir $(pwd)/$dir

name=$(echo $dir | cut -f1 -d ".")


### External Links (DUSC Crawler - Need more refining in external links as valid links are not being listed)

mkdir $(pwd)/$dir/crawler
echo -e "\n${GREEN}Crawling External Links${NC}"

if [ "$deep" == "Y" ]; then
	python3 $(pwd)/tools/Damn-Small-URL-Crawler/dsuc.py -u $turl -d -e| sed "1,5d" | grep -v -i ".$name" | grep "http" | tee $(pwd)/$dir/crawler/external_link.txt > /dev/null
elif [ "$deep" == "N" ]; then
	python3 $(pwd)/tools/Damn-Small-URL-Crawler/dsuc.py -u $turl -e| sed "1,5d" | grep -v -i ".$name" | grep "http" | tee $(pwd)/$dir/crawler/external_link.txt > /dev/null
else
	echo -e "${RED}Invalid Character. Please use only Y or N in Deep crawl.${NC}"
	exit 1
fi
sed -i '/^$/d' $(pwd)/$dir/crawler/external_link.txt #remove blank line
sed -i "s/^.//g" $(pwd)/$dir/crawler/external_link.txt #remove special chars
tr -d '[[:blank:]]' < $(pwd)/$dir/crawler/external_link.txt > $(pwd)/$dir/crawler/$(date +"%d-%m-%Y")_extern.txt # remove indent space
sleep 10
rm $(pwd)/$dir/crawler/external_link.txt


### Fuuzable Links (DUSC Crawler - Completed)

echo -e "\n${GREEN}Crawling Fuzzable Links${NC}"

if [ "$deep" == "Y" ]; then
	python3 $(pwd)/tools/Damn-Small-URL-Crawler/dsuc.py -u $turl -d -f | sed "1,5d" | grep -i "=" | sort | uniq | tee $(pwd)/$dir/crawler/Fuzzable_link.txt > /dev/null
elif [ "$deep" == "N" ]; then
	python3 $(pwd)/tools/Damn-Small-URL-Crawler/dsuc.py -u $turl -f| sed "1,5d" | grep -i "=" | sort |uniq | tee $(pwd)/$dir/crawler/Fuzzable_link.txt > /dev/null
else
	echo -e "${RED}Invalid Character. Please use only Y or N in Deep crawl.${NC}"
	exit 1
fi
sed -i '/^$/d' $(pwd)/$dir/crawler/Fuzzable_link.txt
sed -i "s/^.//g" $(pwd)/$dir/crawler/Fuzzable_link.txt
tr -d '[[:blank:]]' < $(pwd)/$dir/crawler/Fuzzable_link.txt > $(pwd)/$dir/crawler/$(date +"%d-%m-%Y")_Fuzz.txt
sleep 10
rm $(pwd)/$dir/crawler/Fuzzable_link.txt

: '
### Directory Bruteforcing (Gobuster - Completed)

echo -e "\n${GREEN}Running Directory Scan${NC}"
if test -f "$word"; then
	mkdir $(pwd)/$dir/directories
	gobuster dir -q -u $turl -w $word -k -o "$(pwd)/$dir/directories/$(date +"%d-%m-%Y")_directories.txt"
else
	echo -e "\n${RED}The Wordlist file is not found. Please check the path of the list.${NC}"
	exit 1
fi
'

### Internal JS File Crawler (Completed)

echo -e "\n${GREEN}Crawling JS files${NC}"

~/go/bin/gospider -s "$turl" -d 2 | grep ".js$" | tee $(pwd)/$dir/crawler/jsedit.txt > /dev/null
cat $(pwd)/$dir/crawler/jsedit.txt | grep ".js$" | grep -Eo '(http|https)://[^"]+' > $(pwd)/$dir/crawler/js_files.txt
sleep 10
rm $(pwd)/$dir/crawler/jsedit.txt
sort $(pwd)/$dir/crawler/js_files.txt | uniq > $(pwd)/$dir/crawler/$(date +"%d-%m-%Y")_js_filesss.txt
rm $(pwd)/$dir/crawler/js_files.txt


### Extracting Possible sensitive JS (SecretFinder Completed)

echo -e "\n${GREEN}Looking inside JS files${NC}"

while read line; do
	python3 $(pwd)/tools/SecretFinder/SecretFinder.py -i ${line} -o cli >> $(pwd)/$dir/crawler/$(date +"%d-%m-%Y")_sensitive.txt
done <$(pwd)/$dir/crawler/$(date +"%d-%m-%Y")_js_filesss.txt


### Extracting possible Technologies used in the Web App

echo -e "\n${GREEN}Identifying Technologies${NC}"
$(pwd)/tools/webtech/webtech -u $name --rua --udb | sed "1,6d" | tee $(pwd)/$dir/crawler/Tech.txt > /dev/null


### Check URL reputation
### Better to implemet broken link checker as separate tool
### Need to address redirects
### Need to increase depth for dsuc
