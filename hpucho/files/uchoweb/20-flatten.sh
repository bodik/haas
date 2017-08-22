#!/bin/sh

OUTDIR="OUTPUT"
cd $OUTDIR || exit 1

rm -r _data
mkdir -p _data

for all in `find . -type f`; do
	T=$(echo $all | sed 's/\.\///' | sed 's/\//AAAA/g' | sed 's/\?/BBBB/g')
	cp $all _data/$T
done

for all in `find _data -name '*.1'`; do 
	T=$(echo $all | sed 's/\.1$//')
	mv $all $T
done
