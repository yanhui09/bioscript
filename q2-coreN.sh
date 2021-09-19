#!/bin/bash
################################standardlized pipeline for qiime2 core analysis
#Yan Hui
#huiyan@food.ku.dk
###############################################################################
# Wrapped function, e.g. usage()
usage () {
    echo ""
    echo "Note: This script conducts qiime2 core analysis according to a subset mapping file."
    echo ""
    echo "Usage: $0 [ -m -g -b -a -t -j -h]"
    echo "  -m, --metadata    Required, load one subset mapping file, accepted by Qiime 2."
    echo "                    e.g. mapping_demo.tsv _ is needed to extract subset naming."
    echo "  -g, --group       Required, the category for comparison."
    echo "  -p, --preset      Preset arguments to direct analysis the amplicon output from KU food."
    echo "  -b, --biom        Required if -p not applied, tsv file for biom-like feature table."
    echo "  -j, --jobs        overwrite if -p applied, the number of threads."
    echo "  -h, --help        Optional, help message."   
    echo ""
    echo "Example:" 
    echo "$0 -m /path/to/mapping.file -g CategoryGroup -b /path/to/biom.tsv -j Threads"
    echo "$0 -m /path/to/mapping.file -g CategoryGroup -p"
    echo ""
    echo "";}

#############################################################################
# Check input, ensure alphabet/numbers behind -/--, and at least one option
if [ $# -eq 0 ] || ! [[ $* =~ ^(-|--)[a-z] ]]; then 
    echo "Invalid use: please check the help message below." ; usage; exit 1; fi
# Params loading
args=$(getopt --long "preset,metadata:,group:,biom:,annotation:,jobs:,help" -o "pm:g:b:a:j:h" -n "Input error" -- "$@")
# Ensure corrected input of params
if [ $? -ne 0 ]; then usage; exit 1; fi

eval set -- "$args"

while true ; do
        case "$1" in
                -m|--metadata) METADATA="$2"; shift 2;;
                -g|--group) GROUP="$2"; shift 2;;
                -b|--biom) BIOM="$2"; shift 2;;
                -a|--annotation) ANNOTATION="$2"; shift 2;;
                -j|--jobs) JOBS="$2"; shift 2;;
                -p|--preset) PRESET=true; shift 1;; # Indicator changed
                -h|--help) usage; exit 1; shift 1;;
                *) break;;    
        esac
done

#############################################################################
# Paratermer initialization
if [ "$PRESET" == true ]; then
  PREPATH=$(find ./ -type d -name "Results*")
   if [ -z "$BIOM" ]; then
    BIOM="$PREPATH/OTU-tables/zOTU_table_GG.txt"
   fi
   if [ -z "$ANNOTATION" ]; then
    ANNOTATION="$PREPATH/taxonomy/greengenes_taxa.txt"
   fi
   if [ -z "$JOBS" ]; then
    JOBS=1 
   fi
fi

source activate qiime2-2020.11
###############################################################################
# generate a random name to avoid collapse in parallel use
QIIME2ANA=qiime2Ana_${RANDOM}
mkdir -p "$QIIME2ANA"
cp "$BIOM" "$QIIME2ANA/biom.tsv"

awk '{printf $1"\t"$NF"\n"}' "$QIIME2ANA/biom.tsv" > "$QIIME2ANA/taxonomy.tsv"

cp "$METADATA" "$QIIME2ANA/metadata.tsv"

# create the aggregated metadata for grouped abundance plot
./q2meta-grouped.py -m "$METADATA" -g "$GROUP" -o "$QIIME2ANA/metadata_Group.tsv"

# extract subset metadata naming
FILE_NAME=$(basename -- "$METADATA")
FILE_NAME2=${FILE_NAME%%.*}
A=${FILE_NAME2##*_}

cd "$QIIME2ANA"
# re-transfroming txt to tsv using qiime2 default biom-format
biom convert -i biom.tsv -o table.biom --table-type="OTU table" --to-hdf5

##############################################################################################################################
# start qiime2 post-analysis
# import .biom otu table, taxonomy  and tree file
# import .biom otu table in terms of biom-format version (2.1.7)
qiime tools import \
  --input-path table.biom \
  --type 'FeatureTable[Frequency]' \
  --input-format BIOMV210Format \
  --output-path feature-table_raw.qza

# filter the samples from the feature table
qiime feature-table filter-samples \
	  --i-table feature-table_raw.qza \
	  --m-metadata-file metadata.tsv \
	  --o-filtered-table feature-table.qza
# transform to biom file to get the sample depth
unzip -jo feature-table.qza '*/data/feature-table.biom' -d ./
biom summarize-table -i feature-table.biom
read -p "Please choose the rarefraction depth: " DEPTH

# import taxonomy file to qiime2
sed -i '1d' taxonomy.tsv
qiime tools import \
  --input-path taxonomy.tsv \
  --input-format HeaderlessTSVTaxonomyFormat \
  --output-path taxonomy.qza \
  --type 'FeatureData[Taxonomy]'
###########################################################################################################################
# summarize the feature table
mkdir Overview
qiime feature-table summarize \
	--i-table feature-table.qza \
	--m-sample-metadata-file metadata.tsv \
	--o-visualization Overview/feature_table_summary.qzv

# rarifraction curves
qiime diversity alpha-rarefaction \
	--i-table feature-table.qza \
        --p-max-depth $DEPTH \
        --p-steps 20 \
        --m-metadata-file metadata.tsv \
        --o-visualization Overview/rarefaction_curves.qzv

# generate the taxonomy boxplots for each sample
mkdir Tax_Bin
qiime taxa barplot \
       --i-table feature-table.qza \
       --i-taxonomy taxonomy.qza \
       --m-metadata-file metadata.tsv \
       --o-visualization Tax_Bin/taxa_barplot_eachSample.qzv
# generate the taxonomy boxplots for each group
# each category shall have one separated feature table
qiime feature-table group \
       --i-table feature-table.qza \
       --p-axis sample \
       --p-mode sum \
       --m-metadata-file metadata.tsv \
       --m-metadata-column "$GROUP" \
       --o-grouped-table feature-table_Group.qza
# generate the respective tax barplot
qiime taxa barplot \
       --i-table feature-table_Group.qza \
       --i-taxonomy taxonomy.qza \
       --m-metadata-file metadata_Group.tsv \
       --o-visualization Tax_Bin/taxa_barplot_Group.qzv
#################################################################################################################################
# generate the diversity core-metrics-phylogenetic
# alpha and beta diversity
qiime diversity core-metrics \
       --i-table feature-table.qza \
       --p-sampling-depth $DEPTH \
       --m-metadata-file metadata.tsv \
       --p-n-jobs $JOBS \
       --output-dir diversity
# 2D diversity PCoA (already wrapped in the "Emporer" visualization file)

# significance test
# alpha diversity test
for alpha in ./diversity/*_vector.qza
do
alphaname=$(sed "-es/_vector.qza//" <<< $alpha)
qiime diversity alpha-group-significance \
	--i-alpha-diversity $alpha \
	--m-metadata-file metadata.tsv \
	--o-visualization ${alphaname}_compare_groups.qzv
done
# beta diversity permutation test
for beta in ./diversity/*_distance_matrix.qza
do
betaname=$(sed "-es/_distance_matrix.qza//" <<< $beta)
qiime diversity beta-group-significance \
        --i-distance-matrix $beta \
	--m-metadata-file metadata.tsv \
	--m-metadata-column "$GROUP" \
	--p-pairwise \
	--o-visualization ${betaname}_compare_groups.qzv
done

# Identify differentially abundant features with ANCOM ??? Personal use
# add the pseudocount
#qiime composition add-pseudocount \
#	--i-table feature-table.qza \
#	--o-composition-table feature-table_pseudocount.qza
# run ANCOM on feature table by category
#time qiime composition ancom \
#	--i-table feature-table_pseudocount.qza \
#	--m-metadata-file mapping_${A}.tsv \
#	--m-metadata-column $Group \
#	--output-dir ancom_output

# run ANCOM on upper level by category
# sumarize the feature table to different levels
mkdir ./ancom_output
for i in {2..7}
do
# collapse the feature table  to level 2-7	
qiime taxa collapse \
	--i-table feature-table.qza \
	--i-taxonomy taxonomy.qza \
	--p-level $i \
	--o-collapsed-table ./ancom_output/feature-table_l${i}.qza
# add pseudocount
qiime composition add-pseudocount \
	--i-table ./ancom_output/feature-table_l${i}.qza \
	--o-composition-table ./ancom_output/feature-table_l${i}_pseudocount.qza
# run ancom
qiime composition ancom \
	--i-table ./ancom_output/feature-table_l${i}_pseudocount.qza \
	--m-metadata-file metadata.tsv \
	--m-metadata-column "$GROUP" \
	--o-visualization ./ancom_output/ancom-Group_l${i}.qzv
done
conda deactivate
# add the file description
echo "
Qiime2 standard analysis, built with qiime2-2020.11. 
Output directory defination: qiime2Ana_[rarefaction depth]_[mapping file suffix]-[Column header for Comparison], 
eg: qiime2Ana_5000_demo-Group, qiime2 result for samples in mapping_demo.tsv comparison on Group column at the rarefaction depth of 5000. 
1. File type 
*.qza: Qiime2 input file. 
*.qzv: Qiime2 visulization file, view with browser: https://view.qiime2.org/. 
2. Directory structure 
2.1. Overview 
feature_table_summary.qzv -- overview the feature table, depth of each samples, etc. 
rarefraction_curves.qzv -- rarefraction curves based Metadata. 
2.2. Diversity 
2.2.1. Alpha diversity 
evenness|faith_pd|observed_otus|shannon_comparegroups.qzv 
2.2.2. Beta diversity 
jaccard|bray_curtis|weighted_unifrac|unweighted_unifrac_emperor.qzv 
jaccard|bray_curtis|weighted_unifrac|unweighted_unifrac_compare_groups.qzv 
*.qza -- Required Qiime2 input files 
2.3. Tax_Bin 
taxa_barplot_eachSample.qzv -- relative abundance bar plot with each samples. 
taxa_barplot_Group.qzv -- grouped relative abundance bar plot. 
2.4. ancom_output 
ancom-Group_l{2..7}.qzv -- ANCOM test across Group on the taxonomy level 2,3,4,5,6,7. 
*.qza -- Required Qiime2 input files. 

Please check the Qiim2(https://qiime2.org/) if more questions exist. 
Thanks. 

Yan Hui 
huiyan@food.ku.dk 
" > ./Readme.txt

####################################################################################################################################################
##################################################Intermediate File Cleaning AND Output Renaming####################################################
tput setaf 4
echo ""
read -p ">>>>>>Would you like to remove intermediate products?  y/n: "  CHOICE
if [ "$CHOICE" = "y" ]; then
	rm -f *qza *tree zOTU* *biom
	elif [ "$CHOICE" == "n" ]; then
echo " Yep. Temporary files will be kept"
fi
tput sgr0
# Rename output
mv ../${QIIME2ANA} ../qiime2Ana_${DEPTH}_${A}-${GROUP}

exit
