#!/usr/bin/env python3
#-------------------
# Author: Yan Hui
# E-mail: huiyan@food.ku.dk
# Date: 12/06/2021
#-------------------

import sys
import argparse
import pandas as pd
from pathlib import Path
from Bio import SeqIO

def parse_arguments():
    """Read arguments from the console"""
    parser=argparse.ArgumentParser(description="Note: Extract ARG fasta using CARD RGI output.")
    parser.add_argument('-b', '--inputb', help='CARD RGI results')
    parser.add_argument('-i', '--inputf', help='Fasta file for CARD RGI')
    parser.add_argument('-o', '--output', help='Output directory')

    args = parser.parse_args()
    return args

def table_screen(rgi):
    t=pd.read_table(rgi)
    t.dropna(subset = ["CARD_Protein_Sequence"], inplace=True)
    # reindex
    t.reset_index(drop=True, inplace=True)
    t["Contig_header"]=t["Contig"].apply(lambda r: '_'.join(r.split('_')[:-1]))
    return t

# use biopython to extract seqeunce
def extract_orf(fasta_in,rgi_in,out):
    # index fasta
    record_dict=SeqIO.index(fasta_in, "fasta")
    # creat output directory
    Path(out).mkdir(parents=True, exist_ok=True)
    with open(out+"/AMG.fasta", "w") as f_orf:
        for i in range(len(rgi_in)):
            f_orf.write('>' + str(rgi_in.loc[i, 'Contig']) + "\n")
            header=str(rgi_in.loc[i, 'Contig_header'])
            start=int(rgi_in.loc[i, 'Start'])-1
            stop=int(rgi_in.loc[i, 'Stop'])
            seqs=record_dict[header].seq
            f_orf.write(str(seqs[start:stop]) + '\n')

def main():
    args = parse_arguments()
    t_keep = table_screen(args.inputb)
    extract_orf(args.inputf, t_keep, args.output)
    t_keep.to_csv(args.output + "/kept.tsv", sep="\t")

if __name__ == "__main__":
    main()