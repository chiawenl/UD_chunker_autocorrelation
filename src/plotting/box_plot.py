import matplotlib.pyplot as plt
import os, sys
import numpy as np
import seaborn as sns

sns.set_style("white", {'font.family': [u'serif'],
'font.serif': [u'Helvetica']})

img_outpath="img/"+sys.argv[1]+"-boxplot.png"
print(img_outpath)
data = []
labels = []

count = 0
for filename in os.listdir(sys.argv[1]):
    labels.append(filename[3:])
    filepath=sys.argv[1]+os.sep+filename
    lengths = []
    print(filename)
    with open(filepath, "r") as f:
        for l in f:
            lengths.append(int(l))
    data.append(lengths)
    count += 1


fig, ax = plt.subplots(2,2,figsize=(18,8),sharey=True)
ax[0][0].boxplot(data[:9], 0, "")
ax[0][0].set_xticklabels(labels[:9],rotation=60,ha="right",rotation_mode="anchor")
ax[0][1].boxplot(data[9:18], 0, "")
ax[1][0].boxplot(data[18:27], 0, "")
ax[1][1].boxplot(data[27:], 0, "")
ax[0][0].set_ylim(0,7)

ax[0][1].set_xticklabels(labels[9:18],rotation=60,ha="right",rotation_mode="anchor")
ax[1][0].set_xticklabels(labels[18:27],rotation=60,ha="right",rotation_mode="anchor")
ax[1][1].set_xticklabels(labels[27:],rotation=60,ha="right",rotation_mode="anchor")
for i in range(0,2):
    for j in range(0,2):
        ax[i][j].spines['top'].set_visible(False)
        ax[i][j].spines['right'].set_visible(False)
fig.subplots_adjust(left=0.04)
fig.subplots_adjust(hspace=0.64)
fig.subplots_adjust(wspace=0.0)
fig.subplots_adjust(right=0.99)
fig.subplots_adjust(bottom=0.21)
fig.subplots_adjust(top=0.99)
ax[0][0].set_ylabel("Chunk length (#tokens)",size=14)
ax[1][0].set_ylabel("Chunk length (#tokens)",size=14)
fig.savefig(img_outpath)
