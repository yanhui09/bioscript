#!/usr/bin/python
#-------------------
# Author: Yan Hui
# E-mail: huiyan@food.ku.dk
# Date: 09/09/2022

# group lines and the next if a string is found
import argparse

def parse_arguments():
    """Read arguments from the console"""
    parser = argparse.ArgumentParser(description="Note: group lines if containing a substring.")
    parser.add_argument("-i", "--input", help='txt file as input')
    parser.add_argument("-s", "--string", help='substring to be found')
    parser.add_argument("-w", "--wide", help='append lines by column as a wide table', action="store_true", default=False)
    parser.add_argument("-o", "--output", help='txt file as output')

    args = parser.parse_args()
    return args

def main():
    args = parse_arguments()
    with open(args.input, "r") as fi:
        with open(args.output, "w") as fo:
            # if args.wide is true, append lines by column
            if args.wide is True:
                # rm /n in the end, add /n in the front if found
                for line in fi:
                    line = line.rstrip() + "\t"
                    if args.string in line:
                        line = "\n" + line
                    fo.write(line)
            else:
                counter = 0
                # add 1 if find a line containing a string
                for line in fi:
                    if args.string in line:
                        counter += 1
                        # write the line to the output file with counter in the start, separated by a \t
                    fo.write(str(counter) + "\t" + line)
                
            
 
if __name__ == "__main__":
    main()