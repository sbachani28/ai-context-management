# Reproducible catalog analysis. Run from the project root.
library(jsonlite)
library(ggplot2)
library(dplyr)
dir.create('figures', showWarnings=FALSE)
d <- fromJSON('data/processed/models.json')
stopifnot(!anyDuplicated(d$model_id), nrow(d)>0,
          all(d$input_price>=0 | is.na(d$input_price)),
          all(d$output_price>=0 | is.na(d$output_price)))
theme_set(theme_minimal(base_size=12) + theme(panel.grid.minor=element_blank(),
  plot.title=element_text(face='bold', color='#102824'), plot.subtitle=element_text(color='#53635f'),
  axis.title=element_text(color='#53635f'),plot.background=element_rect(fill='#fcfbf7',color=NA)))
counts <- d |> count(company, name='listings') |> arrange(desc(listings))
p1 <- ggplot(counts,aes(reorder(company,listings),listings)) + geom_col(fill='#286854',width=.67) + coord_flip() +
  labs(x=NULL,y='Listed catalog entries',title='Coverage is uneven across developers',subtitle='Counts describe this catalog sample, not market share')
ggsave('figures/coverage.png',p1,width=9,height=5.4,dpi=160)
# Restrict output type; retain image-input indicator. Remove only exact configuration aliases.
eligible <- d |> filter(text_output==1, input_price>0, output_price>0, context_tokens>0)
p <- eligible |> distinct(canonical_slug,company,context_tokens,input_price,output_price,image_input,has_price_overrides,.keep_all=TRUE)
stopifnot(nrow(p)>30)
p2 <- ggplot(p,aes(reorder(company,output_price,FUN=median),output_price)) +
  geom_boxplot(fill='#cfe3d7',color='#286854',outlier.alpha=.45,width=.55) +
  scale_y_log10() + coord_flip() + labs(x=NULL,y='Output USD per million tokens · logarithmic scale',
    title='The price of an API listing varies widely',subtitle='Positive-price, text-output configurations; base prices only')
ggsave('figures/prices.png',p2,width=9,height=5.4,dpi=160)
p3 <- ggplot(p,aes(context_tokens,output_price,color=company)) + geom_point(alpha=.65,size=2) +
  scale_x_log10() + scale_y_log10() + guides(color='none') +
  labs(x='Context window (tokens) · log scale',y='Output USD / million tokens · log scale',
    title='Context length is only one product attribute',subtitle='Every point is a catalog configuration; color denotes developer')
ggsave('figures/context.png',p3,width=9,height=5.4,dpi=160)
# This regression is descriptive. There is no benchmark/quality adjustment in this snapshot.
fit <- lm(log(output_price) ~ log(context_tokens) + factor(company) + image_input, data=p)
simple <- lm(log(output_price) ~ log(context_tokens),data=p)
sensitivity <- lm(log(output_price) ~ log(context_tokens) + factor(company) + image_input,
                  data=filter(p,company!='OpenAI'))
metrics <- list(catalog_n=nrow(d),companies=n_distinct(d$company),
  priced_text_before_dedup=nrow(eligible),priced_text_n=nrow(p),aliases_removed=nrow(eligible)-nrow(p),
  zero_output_price_n=sum(d$output_price==0,na.rm=TRUE),
  median_input=median(p$input_price),median_output=median(p$output_price),
  output_p10=unname(quantile(p$output_price,.1)),output_p90=unname(quantile(p$output_price,.9)),
  output_p90_p10=unname(quantile(p$output_price,.9)/quantile(p$output_price,.1)),
  spearman_context_output=unname(cor(p$context_tokens,p$output_price,method='spearman')),
  context_coefficient=unname(coef(fit)['log(context_tokens)']),
  doubling_context_association_pct=100*(2^unname(coef(fit)['log(context_tokens)'])-1),
  fit_r2=summary(fit)$r.squared,unadjusted_context_coef=unname(coef(simple)[2]),
  no_openai_context_coef=unname(coef(sensitivity)['log(context_tokens)']),
  price_override_n=sum(p$has_price_overrides),
  interpretation='Descriptive catalog association, not a causal elasticity, quality-adjusted price index or representative provider comparison.')
write_json(metrics,'data/processed/metrics.json',pretty=TRUE,auto_unbox=TRUE,digits=8)
write_json(counts,'data/processed/company_counts.json',pretty=TRUE,dataframe='rows')
write_json(p,'data/processed/analysis_sample.json',pretty=TRUE,dataframe='rows',digits=8)
capture.output(sessionInfo(),file='data/processed/R-session-info.txt')
saveRDS(fit,'data/processed/descriptive_fit.rds')
print(metrics)
