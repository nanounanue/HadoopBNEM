#!/bin/bash -e
# erik reed
# runs EM algoritm on MapReduce locally

# expects: fg,em,tab files
if [ $# -ne 4 ]; then                                                                         
    echo Usage: $0 \"dir with net,fg,em\", max_iters, population size, em_flags\(-u or -alem\)
    exit 1                                                                                    
fi                                                                                            

DAT_DIR=$1

# max MapReduce job iterations, not max EM iters
MAX_ITERS=$2

# 2 choices: -u and -alem
# -u corresponds to update; standard EM with fixed population size
#   e.g. a simple random restart with $POP BNs
# -alem corresponds to Age-Layered EM with dynamic population size
EM_FLAGS=$4

# set to min_runs[0]
POP=$3

rm -rf out
mkdir -p out

LOG="tee -a out/log.txt"
echo $0 started at `date`  | $LOG
echo -- Using parameters -- | $LOG
echo Directory: $DAT_DIR | $LOG
echo Max number of MapReduce iterations: $MAX_ITERS | $LOG
echo Population size: $POP | $LOG
echo EM flags: $EM_FLAGS
echo Max iterations: $MAX_ITERS
echo ---------------------- | $LOG


./scripts/make_input.sh $DAT_DIR
echo $POP > dat/in/pop

# randomize initial population
./utils dat/in/fg $POP

cp $DAT_DIR/* in

# copy 0th iteration (i.e. initial values)
mkdir -p out/iter.0
cp in/dat out/iter.0

for i in $(seq 1 1 $MAX_ITERS); do
  echo starting local MapReduce job iteration: $i
  
  cat in/tab_content | ./dai_map | sort -t':' -g | ./dai_reduce | ./utils $EM_FLAGS
  
  mkdir -p out/iter.$i
  rm in/dat # remove previous iteration
  cp out/dat in 
  mv out/dat out/iter.$i

  if [ -n "$start_time" -a -n "$time_duration" ]; then
    dur=$((`date +%s` - $start_time))
    echo TIME: $dur
    if [ $dur -ge $time_duration ]; then
      echo $time_duration seconds reached! Quitting...
      break
    fi
  fi

  converged=`cat out/converged`
  if [ "$converged" = 1 ]; then
    echo EM complete!
    break
  fi
done

