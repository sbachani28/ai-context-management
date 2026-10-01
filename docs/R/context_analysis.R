# Run after scripts/evaluate_retrieval.py. All analyses are deterministic.
library(jsonlite)
library(dplyr)
runs <- fromJSON('data/processed/retrieval_runs.json')
questions <- fromJSON('data/processed/question_inventory.json')
histories <- fromJSON('data/processed/history_inventory.json')
ruler <- fromJSON('data/processed/ruler_scores.json')
save_json <- function(x, name) write_json(x, paste0('data/processed/',name), pretty=TRUE, auto_unbox=TRUE, digits=8, dataframe='rows')

curves <- runs |> group_by(dataset,strategy,k) |>
  summarise(questions=n(), recall=mean(recall), any_hit=mean(any_hit), all_hit=mean(all_hit),
    retained_fraction=mean(retained_fraction), median_words=median(selected_words), .groups='drop')
category <- runs |> filter(k==5) |> group_by(dataset,category,strategy) |>
  summarise(n=n(),recall=mean(recall),all_hit=mean(all_hit),.groups='drop')
bm <- runs |> filter(k==5,strategy=='BM25') |> select(dataset,question_id,cluster,category,bm25=recall)
recent <- runs |> filter(k==5,strategy=='Recent') |> select(dataset,question_id,recent=recall)
paired <- inner_join(bm,recent,by=c('dataset','question_id')) |> mutate(gain=bm25-recent)
cluster <- paired |> group_by(dataset,cluster) |> summarise(n=n(),total=sum(gain),gain=mean(gain),.groups='drop')
set.seed(20261001)
lc <- filter(cluster,dataset=='LoCoMo')
boot <- replicate(2000,{ix<-sample(seq_len(nrow(lc)),replace=TRUE);sum(lc$total[ix])/sum(lc$n[ix])})
effects <- paired |> group_by(dataset) |> summarise(n=n(),gain=mean(gain),bm25=mean(bm25),recent=mean(recent),.groups='drop')
effects$lower <- NA_real_; effects$upper <- NA_real_
effects$lower[effects$dataset=='LoCoMo'] <- unname(quantile(boot,.025))
effects$upper[effects$dataset=='LoCoMo'] <- unname(quantile(boot,.975))

position <- runs |> filter(k==5,strategy!='Random') |>
  mutate(position_band=cut(earliest_evidence,c(0,.2,.4,.6,.8,1),include.lowest=TRUE)) |>
  group_by(dataset,strategy,position_band) |>
  summarise(n=n(),recall=mean(recall),.groups='drop')

# Published scores are aggregates; this fit is descriptive, with no p-value claims.
fit <- lm(score ~ log2(tested_tokens/4000) + factor(model),data=filter(ruler,!beyond_claim))
drop <- inner_join(filter(ruler,tested_tokens==4000) |> select(model,score4=score),
  filter(ruler,tested_tokens==128000,!beyond_claim) |> select(model,score128=score),by='model') |>
  mutate(drop=score4-score128)

inventory <- questions |> group_by(dataset) |>
  summarise(n=n(),eligible=sum(eligible),median_history_words=median(history_words),
    median_sessions=median(sessions),p90_sessions=unname(quantile(sessions,.9)),.groups='drop')
metrics <- list(question_records=nrow(questions),eligible_questions=sum(questions$eligible),
  retrieval_evaluations=nrow(runs),ruler_models=n_distinct(ruler$model),ruler_score_cells=nrow(ruler),
  locomo_cluster_count=nrow(lc),bootstrap_resamples=2000,
  ruler_within_claim_slope=unname(coef(fit)[2]),ruler_paired_models=nrow(drop),
  ruler_median_drop=median(drop$drop),lme_reused_session_warning='Question histories can reuse source sessions; no independence-based confidence interval is reported for LongMemEval.')
for (entry in list(list(curves,'retrieval_curves.json'),list(category,'retrieval_categories.json'),
 list(paired,'paired_retrieval.json'),list(cluster,'cluster_effects.json'),list(effects,'retrieval_effects.json'),
 list(position,'position_results.json'),list(drop,'ruler_drop.json'),list(inventory,'dataset_summary.json'),list(metrics,'context_metrics.json'))) save_json(entry[[1]],entry[[2]])
capture.output(sessionInfo(),file='data/processed/context_R_session.txt')
print(metrics);print(effects)
