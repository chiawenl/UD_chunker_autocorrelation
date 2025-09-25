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

# function to compute pairwise variance for one sequence
compute_pairwise_variance <- function(data) {
  pairs <- t(combn(seq_along(data$Duration),2))
  idx = pairs[,1]==1 & pairs[,2]>pairs[,1]
  pairs <- pairs[idx,,drop = FALSE]
  distances <- pairs[,2] - pairs[,1]
  distances = distances[distances>0]
  variances <- apply(pairs, 1, function(idx) var(data$Duration[idx]))
  return(data.frame(distance = distances,variance = variances))
}

# load data
# setwd("~/data/")
# data = readMat("chunkDurationsIndices.mat")
# cell = data.frame(data$data)
# names(cell) = c("Sentence","Words","Duration","ChunkID","Language")

# add iso
langs = read.csv("autocorrelation/chunk_data/langs.csv")
# idx = array()
# for (k in 1 : nrow(langs)){
#   idx[cell$Language==as.character(k)] = langs$ll[k]
# }
# cell$iso = as.factor(idx)

# # truncate to maximum count (arbitrary 10)
# cell = cell %>%
#   group_by(iso,Sentence) %>%
#   filter(all(ChunkID <= 10)) %>%
#   ungroup()  

# # remove sentences with single chunk
# cell_filtered = cell %>%
#   group_by(Language,Sentence) %>%
#   filter(n() > 1) %>%
#   ungroup()
# cell = cell_filtered

# # check for pairs
# maxL = max(cell$Language)
# allVar = data.frame(distance="",variance="",language="")
# for (k in 1 : maxL){
#   thisLang = cell[cell$Language==k,]
#   df = thisLang %>%
#     group_by(Sentence) %>%
#     group_map(~ compute_pairwise_variance(.x), .keep = TRUE) %>%
#     bind_rows()
#   df$language = rep(k,nrow(df))
#   allVar = rbind(allVar,df)
#   print(k)
# }

# # save
# save(allVar,file="pairwise_variances.RData")

# plot
load("pairwise_variances.RData")
allVar$language = as.factor(allVar$language)
allVar$distance = as.factor(allVar$distance)
allVar$variance = as.numeric(allVar$variance)
langs = read.csv("autocorrelation/chunk_data/langs.csv")
idx = array()
for (k in 1 : nrow(langs)){
  idx[allVar$language==as.character(k)] = langs$ll[k]
}
idx = as.factor(idx)
allVar$iso = idx
allVar = subset(allVar,is.na(allVar$iso)==F)
allVar$numDist = as.numeric(allVar$distance)

# plot
g1 = ggplot(allVar,aes(x=iso,y=variance,alpha=distance,fill=iso)) +
  geom_bar(width = 0.65,
           position = position_dodge(width = .85),
           stat='summary',
           fun='mean') +
  theme_minimal() +
  scale_fill_viridis_d() +
  xlab("Language") +
  ylab("Variance") +
  scale_alpha_manual(values = scales::rescale(2:11, to = c(0.2, 1))) +
  theme(aspect.ratio = .08,
        panel.grid.minor.x = element_blank(),
        panel.grid.minor.y = element_blank(),
        axis.title.x = element_text(size = 6),
        axis.title.y = element_text(size = 6),
        legend.position = c(1,1),
        legend.direction = "horizontal",
        legend.justification = c(1,1),
        legend.text = element_text(size = 6,margin=margin(l=1.5)),
        legend.title = element_text(size = 7),
        legend.key.size = unit(0.25, "cm"),
        axis.text.x = element_text(size = 4.75),
        axis.text.y = element_text(size = 4.75),
        plot.margin = unit(c(0, 0, 0, 0), "cm")) +
  guides(fill = "none",alpha=guide_legend(nrow=1,title="Distance")) +
  labs(tag = "A")

# save plot
save(g1,file='variances_plot.RData')

# stats (variance increases with distance)
allVar$distance = as.numeric(allVar$distance)
mbD = lmer(variance ~ (1|language),
          data=allVar,
          REML = FALSE,
          control = lmerControl(optimizer ="Nelder_Mead"))
meD = lmer(variance ~ distance + (1|language),
          data=allVar,
          REML = FALSE,
          control = lmerControl(optimizer ="Nelder_Mead"))
anova(mbD,meD)
summary(meD)
