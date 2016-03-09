#!/bin/bash
# ---------------------------------------------------------
# Check if the files in the current folder are empty or not
# ---------------------------------------------------------

for filename in ./*.txt
do
    [ -s $filename ] || echo "${filename} is empty"
done

exit 0

