#!/bin/bash
  
for i in *R1*fastq.gz
do
    dir1=$(echo "$i" | cut -d '_' -f1)
    dir2=$(echo "$i" | cut -d '_' -f3)
    dir="${dir1}_${dir2}"
    mkdir -p $dir
    mv $i $dir
    mv ${i//R1/R2} $dir
done

exit
