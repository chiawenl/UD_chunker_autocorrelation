library(ggplot2)
library(ggpubr)
library(philentropy)
library(ppcor)
library(lme4)
library(fitdistrplus)
library(data.table)
library(ggeffects)
library(grid)
library(gridExtra)
library(emmeans)
library(cowplot)


## load data and format

# load data
# setwd("~/data/")

# reformat
# some data sample demo; the whole lags can be found on OSF.
data = read.csv("autocorrelation/chunk_data/sample_allLanguagesAllLagsR.csv")
data$color = data$language
data$language = as.factor(data$language)
data$sentence = as.factor(data$sentence)

# add iso label column
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

# remove sentences with just a single chunk
data = data %>%
  group_by(language,sentence) %>%
  filter(n() > 1) %>%
  ungroup()


## test

# test which distribution the lags form
allAic = data.frame()
for (lang in 1 : max(as.numeric(data$language))){
  for (cnt in 2 : max(as.numeric(data$count))){
    idx = data$language==as.character(lang)&data$count==cnt
    lag = as.numeric(data$lags[idx])
    norm = fitdist(lag,"norm")
    lnorm = fitdist(lag,"lnorm")
    gamma = fitdist(lag, "gamma")
    unif = fitdist(lag, "unif")
    thisAic = cbind(as.numeric(cnt),length(lag),as.numeric(lang),norm$aic,lnorm$aic,gamma$aic,unif$aic)
    allAic = rbind(allAic,thisAic)
  }
  print(lang)
}

# save
save(allAic,file="aic.RData")

# load and reformat
load("aic.RData")
names(allAic) = c("Count","NLags","Language","Normal","Log-normal","Gamma","Uniform")
long = as.data.frame(melt(setDT(allAic), id.vars = c("Count","Language","NLags"), variable.name = "Distribution"))
long$Count = as.factor(long$Count)
long$Language = as.factor(long$Language)
long$fill = as.numeric(long$Language)

# test -> any distribution fits better than uniform; max = gamma
mbDist = lmer(value ~ + (1|NLags) + (1|Language) + (1|Count),data=long)
meDist = lmer(value ~ + Distribution + (1|NLags) + (1|Language) +  (1|Count),data=long)
anova(mbDist,meDist)
summary(meDist)
emmeans(meDist, list(pairwise ~ Distribution), adjust = "tukey")


## check whether KLD increases with count

# compare to uniform and quantify by KLD
nruns = 1000
allKLD = data.frame(language="",count="",run="",kld="")
for (lang in 1 : max(as.numeric(data$language))){
  for (cnt in 2 : max(as.numeric(data$count))){

    # get lags
    KLD = data.frame()
    idx = data$language==as.character(lang)&data$count==cnt
    lag = as.numeric(data$lags[idx])

    # test changes across languages / counts
    observedData = lag
    nbins = round(sqrt(length(lag)))
    nBrk = seq(min(lag),max(lag),l=nbins+1)
    observedCounts = hist(lag,breaks=nBrk,plot=FALSE)
    observedDns = observedCounts$counts/sum(observedCounts$counts)
    minO = min(observedData)
    maxO = max(observedData)
    nL = length(lag)

    # bootstrapped KLD (use gamma, see above)
    for (k in 1:nruns){
      unifData = runif(nL,minO,maxO)
      unifCounts = hist(unifData,breaks=seq(min(unifData),max(unifData),l=nbins+1),plot=FALSE)
      unifDns = unifCounts$counts/sum(unifCounts$counts)
      comparisonMatrix = rbind(observedDns,unifDns)
      kldUnif = suppressMessages(KL(comparisonMatrix,unit = 'log'))
      KLD = rbind(KLD,c(lang,cnt,k,as.numeric(kldUnif[1])))
      print(k)
    }
    names(KLD) = c("language","count","run","kld")

    # store
    allKLD = rbind(allKLD,KLD)
  }
  print(lang)
}

# save
save(allKLD,file="allkld.RData")

# load and check
load("allkld.RData")
allKLD$language = as.factor(allKLD$language)
allKLD$count = as.numeric(allKLD$count)
allKLD$run = as.factor(allKLD$run)
allKLD$kld = as.numeric(allKLD$kld)
aakld = aggregate(allKLD$kld,list(allKLD$language,allKLD$count),mean)
names(aakld) = c("language","count","kld")

# stats -> KLD decreases with increasing count
aakld$count = as.numeric(aakld$count)
mbKld = lmer(kld ~ (1|language),
             data=aakld,
             REML = FALSE,
             control = lmerControl(optimizer ="Nelder_Mead"))
meKld = lmer(kld ~ count + (1|language),
             data=aakld,
             REML = FALSE,
             control = lmerControl(optimizer ="Nelder_Mead"))
anova(mbKld,meKld)
summary(meKld)


## plotting

# aggregate for plotting distribution fit
agLong = aggregate(long$value,list(lng=long$Language,dstr=long$Distribution),mean)
agLong$lng = as.factor(agLong$lng)
agLong$dstr = as.factor(agLong$dstr)
for (k in 1 : 21){
  agLong$lab[agLong$lng==k] = langs$ll[k]
}
agLong$lab = as.factor(as.character(agLong$lab))

# add label column
for (k in 1 : 21){
  aakld$lab[aakld$language==k] = langs$ll[k]
}
aakld$language = as.factor(as.character(aakld$language))

# plot
g2 = ggplot(agLong,aes(x=lab,y=log(x),fill=lab,alpha=dstr)) +
  geom_bar(width = 0.65,
           position = position_dodge(width = .85),
           stat='summary',
           fun='mean') +  scale_fill_viridis_d() +
  theme_minimal() +
  xlab("Language") +
  ylab("log(AIC)") +
  scale_alpha_manual(values = scales::rescale(2:11, to = c(0.2, 1))) +
  coord_cartesian(ylim=c(10,17)) +
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
  guides(fill = "none",alpha=guide_legend(nrow=1,title = "Distribution")) +
  labs(tag = "B")

# plot decay with count
aakld$count = as.factor(aakld$count)
g3 = ggplot(aakld,aes(x=lab,y=kld,alpha=count,fill=lab)) +
  geom_bar(width = 0.65,
           position = position_dodge(width = .85),
           stat='summary',
           fun='mean') +
  scale_fill_viridis_d() +
  xlab("Language") +
  ylab("KLD") +
  ylim(c(0,2.3)) +
  scale_y_continuous(breaks=c(0,1,2)) +
  theme_minimal() +
  scale_alpha_manual(values = scales::rescale(2:10, to = c(0.2, 1))) +
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
  guides(fill = "none",alpha=guide_legend(nrow=1,title="Count")) +
  labs(tag = "C")

# put together
load("variances_plot.RData")
pdf(height=3.25,file="ABC.pdf")
plot_grid(g1,g2,g3,align="v",nrow = 3)
dev.off()
