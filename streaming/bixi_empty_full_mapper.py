#!/usr/bin/python

import sys;
import csv;

def main(argv):
    reader = csv.reader(sys.stdin)
    for row in reader:
        print row[0], '\t', row[10], '\t', row[11]
if __name__ == "__main__":
     main(sys.argv)
