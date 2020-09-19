#!/bin/bash

#Yan Hui
#This is a shell script to transfrom L7 table to one OTU-table like table
#L7 table uses taxonomic label as OTU id, with no taxonomy column
#otu table with first column as OTU ID and last column as taxonomy

#Add help message
args=$(getopt -l "input-path:output-path" -o "i:o:h" -- "$@")

eval set -- "$args"

while [ $# -ge 1 ]; do
        case "$1" in
                --)
                    # No more options left.
                    shift
                    break
                   ;;
                -i|--input-path)
                        INPUT_PATH="$2"
                        shift
                        ;;
                -o|--output-path)
                        OUTPUT_PATH="$2"
                        shift
                        ;;
                -h)
                   echo "This transform a L7 summarized table to a OTU-table like table for biom format. And it automatically removes the unclassified features."
                   echo "Usage: $0 [-n number-of-people] [-s section-id] [-c cache-file]"
                   echo "  -i, --input-path    The path for the imported L7_summarized table"
                   echo "  -o, --output-path    The path for the exported OTU-table like table"
                   echo ""
                   echo "Example: $0 -i ./L7.table -o ./OTU.table"
                   exit 0
                        ;;
        esac

        shift
done

#############################################################################################
# processing code
# clean the input data, remove unclassified reads
grep -v 'Unassigned;Other' $INPUT_PATH > ./file.tmp 
# add column names for the last column -- "Taxonomy" column
awk '{if(NR==2) {FS="\t";OFS="\t";print $0, "Taxonomy";} else print $0}' ./file.tmp | 
# use awk to adjust the column
awk -v my_var=Feature '{if(NR>2) {FS="\t";OFS="\t";first=$1; $1=""; print my_var NR-2, "\t", $0, first;} else print $0}' >  $OUTPUT_PATH

rm -f ./file.tmp
exit 
