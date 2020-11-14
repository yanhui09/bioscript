#!/usr/bin/env Rscript

#################################################################
# Function:  Merge two collapsed biom tables based on the taxa/OTUID
# Call: Rscript merge_bioms.R -i *.biom -o merged.biom
# R packages used: optparse, biomformat
# Authors: Yan Hui
# Last update: 2020-11-6, Yan Hui
# University of Copenhagen
#################################################################
# install necessary packages
p <- c("argparse", "biomformat")
load_package <- function(p) {
  if (!requireNamespace(p, quietly = TRUE)) {
    if (!requireNamespace("BiocManager", quietly = TRUE))
      install.packages("BiocManager", repos = "http://cran.us.r-project.org/")
    BiocManager::install(p)
  }
  require(p, character.only = TRUE, quietly = TRUE)
}
invisible(lapply(p, load_package))

## clean R environment
rm(list = ls())
setwd("./")

## parsing arguments

# create parser object
dsc <- "Merge biom tables based on OTU ID.\\n\\
It is written to merge multiple collapsed biom tables.\\n\\
It also makes sense to merge biom tables by consistent OTU IDs.\\n\\
Taxonomy column will be merged accordingly if provided."
epil <- "Usage:\\n\\
merge_bioms.R -i *txt -o merge.txt\\n\\
merge_bioms.R -i *.biom -o merge.biom --biom --na2zero --all"

parser <- ArgumentParser(prog = "merge_bioms.R",
 formatter_class = "argparse.RawTextHelpFormatter",
 description = dsc, epilog = epil)
parser$add_argument("-i", metavar = "input", type = "character", nargs = "+",
help = "import biom tables.")
parser$add_argument("-o", metavar = "ouput", type = "character", nargs = 1,
help = "Export a merged biom table.")
parser$add_argument("--na2zero", action = "store_true",
help = "Transform NAs to zeros.")
parser$add_argument("--biom", action = "store_true", help = "Use biom files.")
parser$add_argument("--all", action = "store_true",
help = "Keep all taxa, NAs will filled for unmatched taxa.")

args <- parser$parse_args()
# load data
file_list <- args$i
file_out <- args$o
na2zero <- args$na2zero
biom_format <- args$biom
all <- args$all
#------------------------------------------------------------
### load the collapsed tables
# load the biom_format
if (biom_format == TRUE) {
  # supress warnings for some biom files
  biom_list <- suppressWarnings(lapply(file_list, read_biom))
  df_list <- lapply(biom_list, function(x) as(biom_data(x), "matrix"))
  reform <- function(x) {
    x <- rbind(colnames(x), x)
    x <- cbind(rownames(x), x)
    colnames(x) <- NULL
    rownames(x) <- NULL
    x <- as.data.frame(x, stringsAsFactors = FALSE)
    x[1, 1] <- "#OTU ID"
    return(x)
  }
  df_list <- lapply(df_list, reform)
} else{
# load tsv file lists
df_list <- lapply(file_list,
FUN = function(files) {
  read.table(files, header = FALSE, sep = "\t", skip = 1,
  comment.char = "", check.names = F, stringsAsFactors = FALSE)
  })
}

#####################################################
# manipulating the dts
# check names to be unique
sample_name_l <- lapply(df_list, `[`, 1, ) # extract all names
sample_name_l <- lapply(sample_name_l, as.character)
sample_name_a <- do.call(c, sample_name_l)
# remove taxonomy column
sample_name_clean <- sample_name_a[! sample_name_a %in% c("#OTU ID", "Taxonomy")]
# extract duplicate names
dup_names <- sample_name_clean[duplicated(sample_name_clean)]
# merge tables
if (length(dup_names) != 0) {
  duplicated_names <- paste(dup_names, collapse = ", ")
  cat(paste("Duplicate sample names:", duplicated_names))
  q(status = 1)
} else{
  df_merge <- Reduce(function(...) merge(..., all = all, by = "V1"), df_list)
}

# check if OTUID and taxonomy are consistent.
merged_names <- as.character(df_merge[1, ])
ntax <- length(merged_names[merged_names == "Taxonomy"])
if (ntax > 1) {
  cat("OTU ID and Taxonomy are not matched consistently.\n
  Consistent OTU IDs are required to merge OTU tables")
  q(status = 1)
}
  
# check if has overlapped taxa
if (dim(df_merge)[1] == 1) {
  taxa_warning <- "No overlapped taxa found.\n
  Please check if the taxa format is uniform.\n
  e.g. taxonomy separed by \";\" or \"; \" "
  cat(taxa_warning)
  q(status = 1)
  }
# use zero to replace NAs
if (na2zero == TRUE)
  df_merge[is.na(df_merge)] <- 0


#### write the mergerd table
# write out biom file
if (biom_format == TRUE) {
 rownames(df_merge) <- df_merge[, 1]
 colnames(df_merge) <- df_merge[1, ]
 df_merge <- df_merge[-1, -1]
 biom_merge <- make_biom(df_merge)
 write_biom(biom_merge, file_out)
} else{
# write.out a biomformat tsv file
header <- "# Constructed from biom file"
write(header, file_out)
write.table(df_merge, file_out, sep = "\t", row.names = FALSE,
col.names = FALSE, quote = FALSE, append = TRUE)
}