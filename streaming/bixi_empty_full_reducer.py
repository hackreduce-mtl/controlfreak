#!/usr/bin/python

import sys;


def main(argv):
    numFull = 0
    numEmpty = 0
    current_station = False
    line = sys.stdin.readline();
    try:
        while line:
            fields = line.rstrip().split('\t')
            id = fields[0]
            nbBikes = int(fields[1])
            nbEmptyDocks = int(fields[2])
            if current_station != id:
                if current_station != False:
                    print current_station, '\t', numFull, '\t', numEmpty
                current_station = id
                numFull = 0
                numEmpty = 0

            if (nbBikes == 0):
                numEmpty += 1
            if (nbEmptyDocks == 0):
                numFull += 1
            line = sys.stdin.readline();
    except Exception, msg:
        print msg
        return None

if __name__ == "__main__":
     main(sys.argv)
