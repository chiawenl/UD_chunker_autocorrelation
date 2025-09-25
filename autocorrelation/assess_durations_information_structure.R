library(ggplot2)
library(ggpubr)
library(lme4)
library(ggeffects)
library(grid)
library(gridExtra)
library(emmeans)
library(R.matlab)
library(dplyr)
library(tidyr)
library(effects)
library(mgcv)
library(tidyr)
library(MASS)
library(lmerTest)

# load data
#setwd("~/data/")
data = readMat("chunkDurationsIndices.mat")
cell = data.frame(data$data)
names(cell) = c("Sentence","Words","Duration","ChunkID","Language")

# add off / even predictor
cell$oddeven = as.factor(as.integer(cell$ChunkID %% 2 == 0))

# add iso
langs = read.csv("autocorrelation/chunk_data/langs.csv")
idx = array()
for (k in 1 : nrow(langs)){
  idx[cell$Language==as.character(k)] = langs$ll[k]
}
cell$iso = as.factor(idx)
cell$Sentence = as.factor(cell$Sentence)
cell$Duration = scale(cell$Duration)

# truncate to maximum count (arbitrary 10)
cell = cell %>%
  group_by(iso,Sentence) %>%
  filter(all(ChunkID <= 10)) %>%
  ungroup()

# remove sentences with single chunk
cell_filtered = cell %>%
  group_by(Language,Sentence) %>%
  filter(n() > 1) %>%
  ungroup()
cell = cell_filtered

# assess whether duration depends on position within sequence
DurPosMod = lmer(Duration ~ ChunkID + (1|iso) + (1|Sentence) + (1|Sentence:iso),data=cell)
summary(DurPosMod)
anova(DurPosMod)