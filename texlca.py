#!/usr/bin/python
#-------------------
# Author: Yan Hui
# E-mail: huiyan@food.ku.dk
# Date: 28/03/2022
#-------------------

import argparse
import pandas

def parse_arguments():
    """Read arguments from the console"""
    parser = argparse.ArgumentParser(
        prog='texlca.py',
        description="TexLCA: simple local common ancestors based on taxonomy in text.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=('''Example:
        texlca.py -i hits.tsv -o lca.tsv [non-header tsv]
        texlca.py -i hits.csv -o lca.csv -a -s , -r 1 -t 4 -d ; [header csv]'''))
    parser.add_argument("-i", "--input", help='hits table as input')
    parser.add_argument("-s", "--sep", help='file separator [\\t]', default="\t")
    parser.add_argument("-a", "--header", help='header as column name [TRUE]', action="store_true", default=False)
    parser.add_argument("-r", "--read", help='zero-indexing column position for read [0]', default=0)
    parser.add_argument("-t", "--tax", help='zero-indexing column position for taxonomy [-1]', default=-1)
    parser.add_argument("-d", "--delimiter", help='delimiter for taxonomic levels [;]', default=";")
    parser.add_argument("-b", "--substring", help='find common substring rather than prefix [FALSE]', action="store_true", default=False)
    parser.add_argument("-o", "--output", help='output file path')

    args = parser.parse_args()
    return args

#https://www.geeksforgeeks.org/longest-common-substring-array-strings/
def LCSubstr(arr):
    """solve the longest common substring problem with dynamic programming"""
    arr = list(arr)
    # Determine size of the array
    n = len(arr)
    # Take first word from array
    # as reference
    s = arr[0]
    l = len(s)
    lcs = ""
 
    for i in range(l):
        for j in range(i + 1, l + 1):
            # generating all possible substrings
            # of our reference string arr[0] i.e s
            stem = s[i:j]
            k = 1
            for k in range(1, n):
                # Check if the generated stem is
                # common to all words
                if stem not in arr[k]:
                    break
 
            # If current substring is present in
            # all strings and its length is greater
            # than current result
            if (k + 1 == n and len(lcs) < len(stem)):
                lcs = stem
 
    return lcs

# longest common suffix with binary search
#https://www.geeksforgeeks.org/longest-common-prefix-using-binary-search/
# A Function to find the string having the
# minimum length and returns that length
def minlen(strList):
    return len(min(strList, key = len))

# check common prefix 
def common_prefix(strList, str, start, end):
    for i in range(0, len(strList)):
        word = strList[i]
        for j in range(start, end + 1):
            if word[j] != str[j]:
                return False
    return True
 
# A Function that returns the longest
# common prefix from the array of strings
def LCP(strList):
    index = minlen(strList)
    prefix = ""
 
    # in-place binary search
    # on the first string of the array
    # in the range 0 to index
    low, high = 0, index - 1
    while low <= high:
 
        # Same as (low + high)/2, but avoids
        # overflow for large low and high
        mid = int(low + (high - low) / 2)
        if common_prefix(strList,  
                             strList[0], low, mid):
             
            # If all the strings in the input array
            # contains this prefix then append this
            # substring to our answer
            prefix = prefix + strList[0][low:mid + 1]
 
            # And then go for the right part
            low = mid + 1
        else:
             
            # Go for the left part
            high = mid - 1
 
    return prefix

def LCA(arr, pattern):
    """length(arr) == 1, just return the string"""
    arr = list(arr)
    n = len(arr)
    if n == 1:
        out = arr[0]
    else:
        if pattern:
            out = LCSubstr(arr)
        else:
            out = LCP(arr)
    return out

def LCAtex(input, sep, header, read, tax, delimiter, pattern):
    """load hits table"""
    if header:
        df = pandas.read_csv(input, sep=sep, header=0, engine = 'python')
    else:
        df = pandas.read_csv(input, sep=sep, header=None, engine = 'python')
    df1 = df.iloc[:, [int(read), int(tax)]]
    
    """get LCA taxonomy grouped by read, rstrip last comma"""
    df2 = df1.groupby(df1.iloc[:,0]).agg(lambda x: LCA(x,pattern=pattern))
    df2.iloc[:,1] = df2.iloc[:,1].str.rstrip(delimiter)
    return df2

if __name__ == "__main__":
    args = parse_arguments()
    df = LCAtex(args.input, args.sep, args.header, args.read, args.tax, args.delimiter, args.substring)
    df.to_csv(args.output, sep=args.sep, index=False, header=args.header)