library(jsonlite)
library(dplyr)
library(ggplot2)
read_data <- function(name) fromJSON(paste0('data/processed/',name,'.json'))
q <- read_data('question_inventory'); h <- read_data('history_inventory')
rr <- read_data('ruler_scores'); curves <- read_data('retrieval_curves')
cats <- read_data('retrieval_categories'); pairs <- read_data('paired_retrieval')
clusters <- read_data('cluster_effects'); effects <- read_data('retrieval_effects')
pos <- read_data('position_results'); drops <- read_data('ruler_drop')
cm <- read_data('context_metrics'); counts <- read_data('benchmark_counts')
em <- read_data('experiment_manifest')
palette <- c('BM25'='#287d70','Recent'='#d68242','Random'='#8095ab')
theme_set(theme_minimal(base_size=12)+theme(
  panel.grid.minor=element_blank(),plot.title=element_text(face='bold',color='#142c36'),
  plot.subtitle=element_text(color='#536875'),legend.position='bottom',
  plot.background=element_rect(fill='#fbfcfd',color=NA)))
knitr::opts_chunk$set(echo=TRUE,warning=FALSE,message=FALSE,fig.width=9,fig.height=5.4,dpi=150)
knitr::read_chunk('R/context_figures.R')
