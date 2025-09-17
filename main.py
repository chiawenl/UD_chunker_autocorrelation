import os
from src.NPMI_calculator import get_np_mutual_information_values
from src.chunk_labeler import annotate_trees_with_chunk_labels, get_stats, save_lengths
from src.utils import read_treebank, save_as_conllxi
from argparse import ArgumentParser
import numpy as np

    
    
if __name__ == "__main__":
    argparser = ArgumentParser()
    
    argparser.add_argument("--ftreebank", required=True)
    argparser.add_argument("--npmi_threshold", default=-99.9, type=float)
    argparser.add_argument("--outpath", required=True)
    argparser.add_argument("--csv", action="store_true", default=False)
    argparser.add_argument("--no_punct", action="store_true", default=False)
    argparser.add_argument("--sweep_unitaries", action="store_true", default=False)
    argparser.add_argument("--save_lengths", action="store_true", default=False)
    args = argparser.parse_args()

    punct=True
    if args.no_punct:
        punct = False
    trees = read_treebank(args.ftreebank, punct=punct)
    MI_values = get_np_mutual_information_values(trees)
    annotated_trees = annotate_trees_with_chunk_labels(trees,
                                                       MI_values,
                                                       args.npmi_threshold,
                                                       args.sweep_unitaries)
    lengths, lengths_wo_punct = get_stats(annotated_trees, csv=args.csv)
    if args.save_lengths:
        treebank = args.ftreebank.split("/")[-2]
        outfile = "lengths/"+treebank
        save_lengths(lengths, outfile)
                
    save_as_conllxi(annotated_trees, args.outpath)
