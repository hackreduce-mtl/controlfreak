~/hadoop/bin/hadoop jar contrib/streaming/hadoop-0.20.2-streaming.jar \                                                                                                           -mapper bixi_empty_full_mapper.py -reducer bixi_empty_full_reducer.py -file bixi_empty_full_mapper.py -file bixi_empty_full_reducer.py -input /datasets/montreal/2012.csv -output /mnt/bixidata/blah.txt
    -mapper bixi_empty_full_mapper.py \
    -reducer bixi_empty_full_reducer.py \
    -file ~/users/controlfreak/streaming/bixi_empty_full_mapper.py \
    -file ~/users/controlfreak/streaming/bixi_empty_full_reducer.py \
    -input /datasets/montreal/2012.csv \
    -output /mnt/bixidata/blah.txt

