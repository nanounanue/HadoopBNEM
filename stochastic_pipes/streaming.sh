hadoop fs -rmr out

MAPPERS=4
REDUCERS=1 # bug when REDUCERS > 1
POP=5

echo $POP > in/pop

# randomize initial population
names=
for id in $(seq 0 1 $(($POP - 1)))
do
	names+="in/fg.$id "
done
./utils in/fg $names

$HADOOP_HOME/bin/hadoop jar $HADOOP_HOME/contrib/streaming/hadoop-streaming-1.0.0.jar \
	-files "./dai_map,./dai_reduce,./in" \
	-D 'stream.map.output.field.separator=*' \
	-D 'stream.reduce.output.field.separator=*' \
	-D mapred.tasktracker.tasks.maximum=$MAPPERS \
	-D mapred.map.tasks=$MAPPERS \
	-D dfs.block.size=256KB \
	-input ./in/tab_content \
	-output out \
	-mapper ./dai_map \
	-reducer ./dai_reduce \
	-numReduceTasks $REDUCERS

