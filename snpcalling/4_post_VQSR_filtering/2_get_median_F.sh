#!/bin/bash

file=$1

list=`grep -v NA $1 | awk '$1 < 1' | sort -g`

num=`echo "$list" | wc -l`

echo "total lines"
echo $num

mid=`echo $((($num) / 2))`


echo "median"
echo "$list" | head -n $mid | tail -n 1

echo "average the two values if original number is an even number"
echo "$list" | head -n $(($mid +1)) | tail -n 1
