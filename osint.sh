#!/bin/bash


### Colors

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'


### Installing required dependencies

#NEED TO ADD
#go, python3, pip3, gospider, damnsmallurlcrawler, gobuster, webtech, jq, gobuster, whois

###### HELP

Help()
{	
	echo ""
	echo -e "${YELLOW}Syntax: ./script url crawl_depth wordlist_path"
	echo ""
	echo -e "-h            - print this help message"
	echo -e "crawl depth   - Y(level2) N(level1)"
	echo -e "wordlist_path - Complete path for directory wordlist"
	return
}

while getopts ":h" option; do
	case $option in
		h) Help
			exit;;
	esac
done


######


echo -e "${GREEN}Entered URL : $1 ${NC}"

if curl -s --head  --request GET $1 | grep "200\|301\|302" > /dev/null; then 
   echo -e "${GREEN}$1 is accessible ${NC}\n"
else
   echo -e "${RED}$1 is not accessible ${NC}\n"
   exit 1
fi

echo -e "${GREEN}Depth Crawl enabled : $2 ${NC}"
echo
echo -e "${GREEN}Wordlist path : $3 ${NC}"


dir=${1#*//}__$(date +"%d-%m-%Y") ## create a directory with the domain name of $1
mkdir $(pwd)/$dir
name=$(echo $dir | cut -f1 -d ".")


turl=$1


### Crawler with gospider 
#echo -e "\n${GREEN}Running Crawler${NC}"
#/home/kali/go/bin/gospider -s $turl -t 10 -d $2 -c 10 | grep -o -E "(([a-zA-Z][a-zA-Z0-9+-.]*\:\/\/)|mailto|data\:)([a-zA-Z0-9\.\&\/\?\:@\+-\_=#%;,])*" | sort -u | tee "$turl_$(date +"%d-%m-%Y")crawl.txt" > /dev/null


### External Links (DUSC Crawler - Need more refining in external links as valid links are not being listed)

mkdir $(pwd)/$dir/crawler
echo -e "\n${GREEN}Crawling External Links${NC}"

if [[ "$2" == "Y" || "$2" == "y" ]]; then
	python3 $(pwd)/tools/Damn-Small-URL-Crawler/dsuc.py -u $turl -d -e| sed "1,5d" | grep -v -i ".$name" | grep "http" | tee $(pwd)/$dir/crawler/external_link.txt > /dev/null
elif [[ "$2" == "N" || "$2" == "n" ]]; then
	python3 $(pwd)/tools/Damn-Small-URL-Crawler/dsuc.py -u $turl -e| sed "1,5d" | grep -v -i ".$name" | grep "http" | tee $(pwd)/$dir/crawler/external_link.txt > /dev/null
else
	echo -e "${RED}Invalid Character. Please use only Y or N in crawl value.${NC}"
	exit 1
fi
sed -i '/^$/d' $(pwd)/$dir/crawler/external_link.txt #remove blank line
sed -i "s/^.//g" $(pwd)/$dir/crawler/external_link.txt #remove special chars
tr -d '[[:blank:]]' < $(pwd)/$dir/crawler/external_link.txt > $(pwd)/$dir/crawler/external_url.txt # remove indent space
cat $(pwd)/$dir/crawler/external_url.txt | grep -v -i "googleusercontent.com\|sstatic.net\|google.com\|google.co.in\|facebook.com\|youtube.com\|twitter.com\|microsoft.com" | tee $(pwd)/$dir/crawler/external_url.txt > /dev/null
sleep 5
rm $(pwd)/$dir/crawler/external_link.txt
sleep 1


### Fuuzable Links (DUSC Crawler - Completed)

echo -e "\n${GREEN}Crawling Fuzzable Links${NC}"

if [[ "$2" == "Y" || "$2" == "y" ]]; then
	python3 $(pwd)/tools/Damn-Small-URL-Crawler/dsuc.py -u $turl -d -f | sed "1,5d" | grep -i "=" | sort | uniq | tee $(pwd)/$dir/crawler/Fuzzable_link.txt > /dev/null
elif [[ "$2" == "N" || "$2" == "n" ]]; then
	python3 $(pwd)/tools/Damn-Small-URL-Crawler/dsuc.py -u $turl -f| sed "1,5d" | grep -i "=" | sort |uniq | tee $(pwd)/$dir/crawler/Fuzzable_link.txt > /dev/null
else
	echo -e "${RED}Invalid Character. Please use only Y or N in crawl value.${NC}"
	exit 1
fi
sed -i '/^$/d' $(pwd)/$dir/crawler/Fuzzable_link.txt
sed -i "s/^.//g" $(pwd)/$dir/crawler/Fuzzable_link.txt
tr -d '[[:blank:]]' < $(pwd)/$dir/crawler/Fuzzable_link.txt > $(pwd)/$dir/crawler/Fuzz.txt
sleep 5
rm $(pwd)/$dir/crawler/Fuzzable_link.txt
sleep 1


### Directory Bruteforcing (Gobuster - Completed)

#echo -e "\n${GREEN}Running Directory Scan${NC}"
#if test -f "$3"; then
#	mkdir $(pwd)/$dir/directories
#	gobuster dir -q -u $turl -w $3 -k -o "$(pwd)/$dir/directories/Directories.txt"
#else
#	echo -e "\n${RED}The Wordlist file is not found. Please check the path of the list.${NC}"
#	exit 1
#fi


### Internal JS File Crawler (Completed)

echo -e "\n${GREEN}Crawling Internal JS files${NC}"

~/go/bin/gospider -s "$turl" -d 2 | grep ".js$" | tee $(pwd)/$dir/crawler/jsedit.txt > /dev/null
cat $(pwd)/$dir/crawler/jsedit.txt | grep ".js$" | grep -Eo '(http|https)://[^"]+' > $(pwd)/$dir/crawler/js_files.txt
sleep 5
rm $(pwd)/$dir/crawler/jsedit.txt
sort $(pwd)/$dir/crawler/js_files.txt | uniq > $(pwd)/$dir/crawler/js_filesss.txt
rm $(pwd)/$dir/crawler/js_files.txt
sleep 1


### Extracting possible sensitive external JS (Completed)

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
echo -e "\n${GREEN}Looking Inside External JS files${NC}"
while read ext_line; do
	python3 $(pwd)/tools/SecretFinder/SecretFinder.py -i ${ext_line} -o cli >> $(pwd)/$dir/crawler/external_js_sensitive.txt
done <$(pwd)/$dir/crawler/external_url.txt
sleep 1


### Extracting Possible sensitive internal JS (SecretFinder Completed)

echo -e "\n${GREEN}Looking Inside Internal JS files${NC}"

while read line; do
	python3 $(pwd)/tools/SecretFinder/SecretFinder.py -i ${line} -o cli >> $(pwd)/$dir/crawler/internal_js_sensitive.txt
done <$(pwd)/$dir/crawler/js_filesss.txt
sleep 1


### Extracting possible Technologies used in the Web App(Need to work on installation)

echo -e "\n${GREEN}Identifying Technologies${NC}"
$(pwd)/webtech -u $turl --rua --udb | sed "1,6d" | tee $(pwd)/$dir/crawler/Tech.txt > /dev/null
sleep 1


### Check for Domain Expiry (whois Completed)

echo -e "\n${GREEN}Checking Invalid External Domains${NC}"

awk -F \/ '{l=split($3,a,"."); print (a[l-1]=="com"?a[l-2] OFS:X) a[l-1] OFS a[l]}' OFS="." $(pwd)/$dir/crawler/external_domain.txt | sort -u >> $(pwd)/$dir/crawler/test_file.txt
while read mine; do
	echo $mine | tr -d '\n' >> $(pwd)/$dir/crawler/external_domain_expire.txt
	echo -e '\t:' | tr -d '\n' >> $(pwd)/$dir/crawler/external_domain_expire.txt
	expdate=$(whois $mine | grep -iE 'expir.*date|expir.*on' | head -1 | grep -oE '[^ ]+$') >> /dev/null
	expdate2=$(date -d"$expdate" +%s)
	curdate=$(date +%s)
	if (($curdate > $expdate2)); then
		echo "  Expired" >> $(pwd)/$dir/crawler/external_domain_expire.txt
	else
		echo "  Not Expired" >> $(pwd)/$dir/crawler/external_domain_expire.txt
	fi
done<$(pwd)/$dir/crawler/test_file.txt
sleep 5


### Check for Domain-IP reputation

echo -e "\n${GREEN}Checking External Domain Abusive score${NC}"

while read domain; do
   echo $domain >> $(pwd)/$dir/crawler/ips.txt
   dig $domain +short >> $(pwd)/$dir/crawler/ips.txt
done<$(pwd)/$dir/crawler/test_file.txt

while read ip; do
   echo $ip | tr -d '\n'>> $(pwd)/$dir/crawler/Domain_Abusive_score.txt
   echo -e '\t:' | tr -d '\n' >>$(pwd)/$dir/crawler/Domain_Abusive_score.txt
   curl -G https://api.abuseipdb.com/api/v2/check --silent --data-urlencode "ipAddress=$ip" -d maxAgeInDays=30 -H "Key: 19a74f48e2b914e9db81d99475f876dbd4c590377d9c9b6602327c321a8e81fff0aa2237b6d6b588" -H "Accept: application/json" | jq -r '.data.abuseConfidenceScore' >>$(pwd)/$dir/crawler/Domain_Abusive_score.txt
done<$(pwd)/$dir/crawler/ips.txt
rm $(pwd)/$dir/crawler/test_file.txt
rm $(pwd)/$dir/crawler/ips.txt
sleep 1


echo -e "\n${GREEN}COMPLETED !!!${NC}"
exit 0


### Check for broken links. Better to implemet broken link checker as separate tool (blc)
### Need to increase depth for dsuc (Current crawl level 2)
### Research on common js files to exclude them
