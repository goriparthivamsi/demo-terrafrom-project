#!/bin/bash

#VAR=$*

#echo "this is your input: $VAR"

# for i in $@
# do 
#   echo "this is your input: $i"
# done
# x=1
# while true 
# do
#  echo $x
#  x=$x+1
# done
# ls ../Downloads/ | while read -r filename
#     do
#         echo "$(date +%F): $filename"
#     done

read -p "Enter your name: " NAME
read -p "Enter your age: " age

echo "Your name is $NAME and your are $age years old"