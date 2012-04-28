#!/bin/bash

CSVFILE=`cat - | ~/users/controlfreak/streaming/heatmap-video/bixi_munge.pl`
~/users/controlfreak/src/R/heatmap.R $CSVFILE
PNGFILE=${CSVFILE/csv/png}
echo $mapred_output_dir
$HADOOP_HOME/bin/hadoop -dfs -copyFromLocal $PNGFILE $mapred_output_dir
