#!/bin/bash
outdir="ud-labelled-v2.9/"
treebanks="ud-subset-v2.9"
csv="chunk-stats.csv"
echo "treebank,mu,std,unitary_ratio,mu_wo_punct,std_wo_punct,unitary_ratio_wo_punct" > $csv
for treebank_dir in $treebanks/UD*
do
    treebank=$(basename $treebank_dir)
    echo $treebank
    full_treebank=$treebanks/$treebank/full.conllu
    if ! [ -f $full_treebank ]; then
	cat $treebank_dir/*conllu >> $full_treebank
    fi
    filebase=$(basename $full_treebank)
    outpath=$outdir$treebank/$filebase
    if ! [ -d $outdir$treebank ]; then
	mkdir $outdir$treebank
    fi
    values=$(python main.py --ftreebank $full_treebank \
		    --outpath $outpath \
		    --csv \
		    --save_lengths)
    echo $treebank,$values >> $csv
done
