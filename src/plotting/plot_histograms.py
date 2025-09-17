import matplotlib.pyplot as plt
import os, sys
import numpy as np
import seaborn as sns
from collections import Counter
from matplotlib.ticker import EngFormatter

sns.set_style("white", {'font.family': [u'serif'],
'font.serif': [u'Helvetica']})
blue = "#8ca5c3"
eblue = "#09547a"
text = sys.argv[1]
if text.endswith("/"):
    text = text[:-1]
    
if "--" in text:
    parts = text.split("--")
    name = ", ".join([p.capitalize() for p in parts[1:]])
else:
    name = text.split("-")[-1].capitalize()
name = name.replace("_", " ")
    #
#img_outpath="img/"+text+"-histogram.png"
img_outpath="img/"+text+"-histogram.svg"
print(img_outpath)


lengths = []
count = 0
for filename in os.listdir(sys.argv[1]):
    filepath=sys.argv[1]+os.sep+filename
    print(filename)
    with open(filepath, "r") as f:
        for l in f:
            lengths.append(int(l))
    count += 1
    

fig, ax = plt.subplots(figsize=(5,3))
ax.set_xlabel("Chunk length (#tokens)", size=14)
ax.set_ylabel("Counts", size=14)
count_dict = Counter(lengths)
labels = [k for k, v in count_dict.items() if v>5]
labels = sorted(labels)
counts = [count_dict[l] for l in labels]
print(counts[:15])
ax.bar(labels,counts,width=0.9, color=blue, edgecolor=eblue)
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
fig.subplots_adjust(left=0.135)
fig.subplots_adjust(right=0.98)
fig.subplots_adjust(bottom=0.17)
fig.subplots_adjust(top=0.98)
formatter1 = EngFormatter(places=0, sep="")  # U+2009
ax.yaxis.set_major_formatter(formatter1)
ax.set_xticks(labels)#, labels)
ax.set_xlim(0,15)
ax.set_ylim(0, 4.55e6)


#ax.annotate(' Distribution\n across all\n treebanks', xy=(0.7, 0.7),
 #           xycoords='axes fraction', size=14,
 #           horizontalalignment='center',)
ax.annotate(name, xy=(0.7, 0.7),
            xycoords='axes fraction', size=14,
            horizontalalignment='center',)
fig.savefig(img_outpath)
    
