#!/bin/bash
LINES=$(cat $1)
for line in $LINES
do
    cp -r ud-treebanks-v2.9/$line ud-subset-v2.9/
done
