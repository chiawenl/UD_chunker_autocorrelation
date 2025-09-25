# Chunks of Local Syntactic Dependencies Form Periodic Sequences, within and across 21 Languages 
### Chia-Wen Lo<sup>*1</sup>, Mark Anderson<sup>2</sup>, Lorenzo Titone<sup>1</sup>, John T. Hale<sup>3</sup>, Lars Meyer<sup>1,4</sup>
<sup>1</sup>Language Cycles, Max Planck Institute for Human Cognitive and Brain Sciences, Leipzig & 04013, Germany.
<sup>2</sup>SAMBA, Norwegian Computing Center, Oslo & 0373, Norway.
<sup>3</sup>Department of Cognitive Science, Johns Hopkins University, Baltimore & 21218, USA.
<sup>4</sup>Clinic for Phoniatrics and Paediatric Audiology, University Hospital Münster, Münster & 48149, Germany. 
<sup>*</sup>lo@cbs.mpg.de

### Abstract
Our ability to combine words and bound morphemes defines the communicative potential of human language. But when exerting this ability on continuous speech, we are constrained by the instruments of our brain. Specifically, our brain processes both speech and text in a windowed manner rather than continuously. Here, autocorrelation analysis in 21 languages shows that chunks of multiple words follow each other at similar durations, when defining chunks as clusters of local syntactic dependencies, consistent with psycholinguistic research. This periodic pace of chunks may have evolved for human language to be processed well by the periodic electrophysiological activity of our brain—ensuring that one chunk of words that are densely connected by syntactic dependencies can always be processed within one cycle of electrophysiological activity.

# Dependenents
### main script libraries
numpy

### for plotting scripts
matplotlib
seaborn

# Main script

You can run the code itself on a treebank:

```
python main.py  --ftreebank path-to-treebank
		--outpath path-to-save-output-file 
		--csv (optional, if present will save stats to csv) 
		--save_lengths (optional, if present will save chunk lengths)
		--no_punc (optional, if present will remove punctuation token which have no dependents)
		--sweep_unitaries (optional, if present will attempt to attach unitary chunks which neighbour non-unitary chunks if syntactically linked)
```

There's also some plotting scripts in `src/plotting/` that were used to generate the plots we shared here, in case that's of any interest.

# Scripts to get treebanks of interest and label all

```
python get_treebank_subset.py
```

creates a file `treebank-list.txt` of treebanks with more than 10000 tokens using `ud-tts-ud-corpus.csv`

We usually create a soft link to our ud data:

```
ln -s path/ud-treebanks-v2.9
```

Otherwise edit `collect_subset.sh` to change the path to the data directory

```
./collect_subset.sh treebank-list.txt
```

Copies the directories from `ud-treebanks-v2.9`. The treebanks are saved in `ud-subset-v2.9`


```
./label-all.sh \
```

Runs the chunk labeller on all the treebanks in `ud-subset-v2.9` and saves the labelled data in `ud-labelled-v2.9`. It's set to run so that the stats are saved in `chunk-stats.csv` and the lengths of each chunk in each treebank is saved in `lengths`. 

# Scripts for autocorrelation and visualization  
Matlab and R scripts for chunk lags can be found in the folder `autocorrelation`.  
The whole lag dataset can be found here: https://osf.io/rdz7j/. 

The folder `chunk_data` includes only 1000 rows of the data.


Matlab scripts for computing AC lags: 
- `ICI_autocorr_by_chnk_size_matrix.m`  
- `ICI_autocorr_by_chnk_size_save_lengths.m`  


R scripts for the statistical analysis and the visualization:  
- `assess_durations_information_structure.R`: assess whether duration depends on position within sequence  
- `plot_acf_histogram.R`: generate plots for probability density of autocorrelation lags across different sequence lengths and languages  
- `test_fits_acf_lag_distribution.R`: quantify and plot within language and subsequence count the Kullback-Leibler Divergence (KLD) of the observed AC lag distribution from a uniform distribution, applying a bootstrapping method  
- `variance_by_distance_stats_and_plots`:  compute duration variance in pairs of chunks of increasing inter-chunk distance from 1 to 9 chunks  


# Citation 
Chia-Wen Lo, Mark Anderson, Lorenzo Titone, John T. Hale, Lars Meyer. (Under review). Chunks of Local Syntactic Dependencies Form Periodic Sequences, within and across 21 Languages. MPI-CBS.



