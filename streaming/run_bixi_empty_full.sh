java -classpath ".:lib/*" org.apache.hadoop.streaming.HadoopStreaming \
    -mapper bixi_empty_full_mapper.py \
    -reducer bixi_empty_full_reducer.py \
    -file ~/users/controlfreak/streaming/bixi_empty_full_mapper.py \
    -file ~/users/controlfreak/streaming/bixi_empty_full_reducer.py \
    -input /datasets/bixidata/montreal/2012.csv \
    -output /tmp/bixidata_result.txt

