#!/bin/bash
# tansform the keg data from kegg to wide-format kegg table
# inherted from a post on biostar forum

# Yan Hui
# ?2019
# huiyan@food.ku.dk

# download htxt file from kegg website
wget 'http://www.genome.jp/kegg-bin/download_htext?htext=ko00001.keg&format=htext&filedir=' -O ko00001.keg
# parse .keg file to table
kegfile="ko00001.keg"

while read -r prefix content
do
    case "$prefix" in A) col1="$content";; \
                      B) col2="$content" ;; \
                      C) col3="$content";; \
                      D) echo -e "$col1\t$col2\t$col3\t$content";;
    esac 
done < <(sed '/^[#!+]/d;s/<[^>]*>//g;s/^./& /' < "$kegfile") > KO_Orthology_ko00001.txt
# sort the table 
cut -f 4 KO_Orthology_ko00001.txt|cut -d " " -f 1 > KoID.txt
cut -f 4 KO_Orthology_ko00001.txt|cut -c9- > KoDes.txt
cut -f 1,2,3 KO_Orthology_ko00001.txt > KO_Orthology.txt
# write the headline 
echo -e "KEGG_l1\tKEGG_l2\tKEGG_l3\tKoID\tDescription" >KO_table.txt
paste KO_Orthology.txt KoID.txt KoDes.txt >> KO_table.txt 
rm KoID.txt KoDes.txt KO_Orthology.txt
rm ko00001.keg  KO_Orthology_ko00001.txt 
exit
