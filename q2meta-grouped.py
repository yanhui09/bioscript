#!/usr/bin/python
# The python script builds qiime 2 grouped metadata for one category.
#-------------------
# Author: Yan Hui
# E-mail: huiyan@food.ku.dk
# Date: 16/02/2021
#-------------------
__doc__ = "build qiime 2 grouped metadata for one category"
import os
import pandas as pd
import argparse

def parse_arguments():
    """Read arguments from the console"""
    parser = argparse.ArgumentParser(description="Note: generate qiime 2 aggregated metadata.")
    parser.add_argument("-m", "--metadata", help='metadata')
    parser.add_argument("-g", "--group", help='output directory')
    parser.add_argument("-o", "--out", help='aggregated metadata by -g')

    args = parser.parse_args()
    return args

def aggregate_df(df_in, by, df_out):
    """Aggregate the df by -g"""
    df = pd.read_csv(df_in, sep='\t')
    pd_select = df[by].rename('SampleID').drop_duplicates()
    pd_select.to_csv(df_out, sep='\t', index=False, header=True)

def main():
    args = parse_arguments()
    aggregate_df(df_in=args.metadata, by=args.group, df_out=args.out)

if __name__ == "__main__":
    main()