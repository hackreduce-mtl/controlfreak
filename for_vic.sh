#!/bin/bash
## munge output so it is just the way I like it.

cat results.out | sed 's/,/\t/g' | awk '{print $3$4,$1,$2,$5}' | sort -n > results2.outi
