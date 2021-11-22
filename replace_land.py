#!/usr/bin/python3

# reqs
import sys

# main
if __name__ == "__main__":

    # read params
    infile = sys.argv[1]
    date = sys.argv[2]
    outfile = sys.argv[3]

    # open input and output files
    infile_fd = open(infile)
    outfile_fd = open(outfile, "w")

    # iterate over lines
    counter = 0
    for line in infile_fd:

        ### if line contains 
        if "***** Site is out of model grid OR land *****" in line:
            part1 = line.split("*")[0]
            part2 = "%s %02.d:00:00 9999 9999" % (date, counter)
            outfile_fd.write("%s %s\n" % (part1, part2))
            
            counter += 1
            if counter == 24:
                counter = 0
                
        else:
            outfile_fd.write(line)

