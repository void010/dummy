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

dir=${turl#*//}__$(date +"%d-%m-%Y") ## create a directory with the domain name of $turl
mkdir $(pwd)/$dir

name=$(echo $dir | cut -f1 -d ".")

### Crawler with gospider 
#echo -e "\n${GREEN}Running Crawler${NC}"
#/home/kali/go/bin/gospider -s $turl -t 10 -d $deep -c 10 | grep -o -E "(([a-zA-Z][a-zA-Z0-9+-.]*\:\/\/)|mailto|data\:)([a-zA-Z0-9\.\&\/\?\:@\+-\_=#%;,])*" | sort -u | tee "$turl_$(date +"%d-%m-%Y")crawl.txt" > /dev/null


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
tr -d '[[:blank:]]' < $(pwd)/$dir/crawler/external_link.txt > $(pwd)/$dir/crawler/external_url.txt # remove indent space
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
tr -d '[[:blank:]]' < $(pwd)/$dir/crawler/Fuzzable_link.txt > $(pwd)/$dir/crawler/Fuzz.txt
sleep 10
rm $(pwd)/$dir/crawler/Fuzzable_link.txt

<<comment
### Directory Bruteforcing (Gobuster - Completed)

echo -e "\n${GREEN}Running Directory Scan${NC}"
if test -f "$word"; then
	mkdir $(pwd)/$dir/directories
	gobuster dir -q -u $turl -w $word -k -o "$(pwd)/$dir/directories/Directories.txt"
else
	echo -e "\n${RED}The Wordlist file is not found. Please check the path of the list.${NC}"
	exit 1
fi
comment

### Internal JS File Crawler (Completed)

echo -e "\n${GREEN}Crawling Internal JS files${NC}"

~/go/bin/gospider -s "$turl" -d 2 | grep ".js$" | tee $(pwd)/$dir/crawler/jsedit.txt > /dev/null
cat $(pwd)/$dir/crawler/jsedit.txt | grep ".js$" | grep -Eo '(http|https)://[^"]+' > $(pwd)/$dir/crawler/js_files.txt
sleep 10
rm $(pwd)/$dir/crawler/jsedit.txt
sort $(pwd)/$dir/crawler/js_files.txt | uniq > $(pwd)/$dir/crawler/js_filesss.txt
rm $(pwd)/$dir/crawler/js_files.txt


### Extracting possible sensitive external JS (************)

file="$(pwd)/$dir/crawler/external_url.txt"
echo -e "\n${GREEN}Crawling External JS files${NC}"
lines=$(cat $file)
for l in $lines
do
	echo "${l}" | cut -d "/" -f1,2,3 >> $(pwd)/$dir/crawler/test.txt
done
sort $(pwd)/$dir/crawler/test.txt >> $(pwd)/$dir/crawler/sorted.txt
uniq $(pwd)/$dir/crawler/sorted.txt >> $(pwd)/$dir/crawler/external_domain.txt
rm $(pwd)/$dir/crawler/test.txt
rm $(pwd)/$dir/crawler/sorted.txt
echo -e "\n${GREEN}Looking inside external JS files${NC}"
while read ext_line; do
	python3 $(pwd)/tools/SecretFinder/SecretFinder.py -i ${ext_line} -o cli >> $(pwd)/$dir/crawler/external_js_sensitive.txt
done <$(pwd)/$dir/crawler/external_url.txt


### Extracting Possible sensitive internal JS (SecretFinder Completed)

echo -e "\n${GREEN}Looking inside inetrnal JS files${NC}"

while read line; do
	python3 $(pwd)/tools/SecretFinder/SecretFinder.py -i ${line} -o cli >> $(pwd)/$dir/crawler/internal_js_sensitive.txt
done <$(pwd)/$dir/crawler/js_filesss.txt


### Extracting possible Technologies used in the Web App(Need to work on installation)

echo -e "\n${GREEN}Identifying Technologies${NC}"
$(pwd)/webtech -u $turl --rua --udb | sed "1,6d" | tee $(pwd)/$dir/crawler/Tech.txt > /dev/null


### Check for Domain Expiry

echo -e "\n${GREEN}Checking Invalid external domains${NC}"

awk -F \/ '{l=split($3,a,"."); print (a[l-1]=="com"?a[l-2] OFS:X) a[l-1] OFS a[l]}' OFS="." $(pwd)/$dir/crawler/external_domain.txt | sort -u > test_file.txt
while read mine; do
	echo $mine | tr -d '\n' >> $(pwd)/$dir/crawler/external_domain_expire.txt
	echo -e '\t:' | tr -d '\n' >> $(pwd)/$dir/crawler/external_domain_expire.txt
	whois $mine | grep -i "expiration date:" | sed 's/^[^:]*://g' >> $(pwd)/$dir/crawler/external_domain_expire.txt

done<test_file.txt
rm test_file.txt


### Check URL reputation (Need IBM X API)
### Check for broken links. Better to implemet broken link checker as separate tool (blc)
### Need to increase depth for dsuc (Current crawl level 2)
### Research on common js files to exclude them
### 
