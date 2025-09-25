# library
library(ggplot2)
library(ggpubr)
library(viridis)
library(tidyverse)
library(cowplot)
library(dplyr)

# load data
# setwd("~/data/")

# reformat
# some data sample demo; the whole lags can be found on OSF.
data = read.csv("autocorrelation/chunk_data/sample_allLanguagesAllLagsR.csv")
data$color = data$language
data$language = as.factor(data$language)
data$sentence = as.factor(data$sentence)

# add iso
langs = read.csv("autocorrelation/chunk_data/langs.csv")
idx = array()
for (k in 1 : nrow(langs)){
  idx[data$language==as.character(k)] = langs$ll[k]
}
idx = as.factor(idx)
data$iso = idx

# truncate to maximum count (arbitrary 10)
data = data %>%
  group_by(iso,sentence) %>%
  filter(all(count <= 10)) %>%
  ungroup()  

# labels
ns = c("2"="n = 2","3"="n = 3","4"="n = 4","5"="n = 5","6"="n = 6","7"="n = 7","8"="n = 8","9"="n = 9","10"="n = 10")

# for medians
dv = data %>% group_by(count,iso) %>% mutate(median = median(lags))
medians <- dv %>%
  group_by(count,iso) %>%
  summarise(median_value = median(lags),.groups = "drop")
medians$median_value_s = medians$median_value/100
medians$median_value_s = sprintf("%.2f",medians$median_value_s)

# plot
ggplot(dv,
       aes(x=lags,
           fill=color,
           color=color)) +
  geom_density(color=NA) +
  # geom_histogram(aes(y=..density..),
  #                colour = "white",
  #                size = .1,
  #                binwidth = 25) + 
  scale_fill_viridis() +
  scale_x_continuous(breaks = c(0,200,400),
                     labels=c(0,2,4),
                     limits = c(0,450)) +
  scale_y_continuous(breaks = c(0,0.015),
                     limits = c(0,0.0175)) +
  theme_bw() + 
  theme(panel.border = element_blank(),
        aspect.ratio = .85,
        legend.position = "none",
        strip.background = element_blank(),
        strip.text.x = element_text(size = 5),
        strip.text.y = element_text(size = 5),
        axis.title.x = element_text(size = 6),
        axis.title.y = element_text(size = 6),
        axis.line = element_line(colour = "black",linewidth=.25),
        axis.ticks = element_line(colour = "black", linewidth = .25),
        axis.text.x = element_text(size = 4.75),
        axis.text.y = element_text(size = 4.75),
        panel.spacing = unit(0.025, "cm")) +
  xlab("Autocorrelation lag (s)") +
  ylab("Probability density") +
  geom_vline(aes(xintercept = median),
             color="red",
             linewidth=.25) +
  geom_text(data = medians,
            aes(x = 440,y = 0.015,
                label = median_value_s,
                group = interaction(count,iso)), 
            color = "red",
            inherit.aes = FALSE,
            size = 2,
            hjust = 1) +
  facet_grid(count ~ iso,
             labeller = labeller(count=ns))