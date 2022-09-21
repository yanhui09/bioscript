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
        python texlca.py -i hits.tsv -o lca.tsv [non-header tsv]
        python texlca.py -i hits.csv -o lca.csv -a -r 1 -s , -t 4 [header csv]
        python texlca.py -i hits.tsv -o lca.tsv -p 0.8 [DCAs in non-header tsv] '''))
    parser.add_argument("-i", "--input", help='hits table as input', required=True)
    parser.add_argument("-s", "--sep", help='file separator (default: \\t)', default="\t")
    parser.add_argument("-a", "--header", help='header as column name ', action="store_true", default=False)
    parser.add_argument("-r", "--read", help='zero-indexing column position for read (default: %(default)s)', default=0)
    parser.add_argument("-t", "--tax", help='zero-indexing column position for taxonomy (default: %(default)s)', default=-1)
    parser.add_argument("-d", "--delimiter", help='delimiter for taxonomic levels (default: %(default)s)', default=";")
    parser.add_argument("-p", "--percent", help='percentage of agreement on local common ancestors, making dorminant common ancestors if below 1 (default: %(default)s)', default="1")
    parser.add_argument("-b", "--substring", help='find common substring rather than prefix block (default: %(default)s)', action="store_true", default=False)
    parser.add_argument("-e", "--escore", help='zero-indexing column position for similarity score , keep top hits if applied (default: %(default)s)', default=None)
    parser.add_argument("-o", "--output", help='output file path', required=True)

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
 
    return str(prefix)

def LCPB(strList, delimiter):
    """export the most common prefix blocks from the most common prefix"""
    lcprefix = LCP(strList)
    n_delimters = lcprefix.count(str(delimiter)) + 1
    """get the minimum length of the desired prefix block"""
    blocList = [str(delimiter).join(s.split(delimiter)[0:n_delimters]) for s in strList]
    # join without delimiter in the end
    minlen_bloc = minlen(blocList) + 1
    if len(lcprefix) < minlen_bloc:
        lcprefix = lcprefix.rsplit(delimiter, 1)[0]
    return lcprefix    

# extend longest common prefix block if a percentage of hits agree
# DCPB: dominant common prefix blcok

# get value by index from list, split from string
# return None if index is out of range
def split_str(str, delimiter, index):
    try:
        return str.split(delimiter)[index]
    except IndexError:
        return None

def DCPB(strList, delimiter, pct):
    lcpb = LCPB(strList, delimiter)
    n_delimeters = lcpb.count(delimiter)
    # max number of delimiters in strList
    nmax_delimters = max([s.count(delimiter) for s in strList])
    # appending new block if the percentage of agreed hits is above the threshold
    if n_delimeters < nmax_delimters:
        for i in range(n_delimeters + 1, nmax_delimters + 1):
            blocList = [split_str(s, delimiter, i) for s in strList]
            # remove None
            blocList = [s for s in blocList if s]
            # get the most common block and its frequency
            bloc = max(sorted(set(blocList)), key = blocList.count)
            freq = blocList.count(bloc)
            if freq / len(strList) >= float(pct):
                lcpb = str(delimiter).join([lcpb, bloc])
            else:
                break
    return lcpb
    
def LCA(arr, pattern, delimiter, pct):
    """length(arr) == 1, just return the string"""
    arr = list(arr)
    n = len(arr)
    if n == 1:
        out = arr[0]
    else:
        if pattern:
            out = LCSubstr(arr)
        else:
            out = DCPB(arr, delimiter, pct)
    return out

def LCAtex(input, sep, header, read, tax, delimiter, pct, pattern, escore):
    """load hits table"""
    if header:
        df = pandas.read_csv(input, sep=sep, header=0, engine = 'python')
    else:
        df = pandas.read_csv(input, sep=sep, header=None, engine = 'python')
    
    # escore filter or not
    if escore is None:
        df1 = df.iloc[:, [int(read), int(tax)]]
    else:
        df1 = df.iloc[:, [int(read), int(tax), int(escore)]]
        # idx by groupby max escore 
        idx = df1.groupby(df1.iloc[:,0])[df1.columns[2]].apply(lambda x: x == x.max())
        # filter by escore and discard escore column
        df1 = df1[idx].iloc[:,0:2]
    
    """get LCA taxonomy grouped by read, rstrip last comma"""
    df2 = df1.groupby(df1.iloc[:,0]).agg(lambda x: LCA(x, pattern=pattern, delimiter=delimiter, pct=pct))        
    df2.iloc[:,1] = df2.iloc[:,1].str.rstrip(delimiter)
    return df2

if __name__ == "__main__":
    args = parse_arguments()
    df = LCAtex(args.input, args.sep, args.header, args.read, args.tax, args.delimiter, args.percent, args.substring, args.escore)
    df.to_csv(args.output, sep=args.sep, index=False, header=args.header)