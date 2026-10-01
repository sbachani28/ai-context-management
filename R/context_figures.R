## ---- task-mix
task_counts <- q |> count(dataset, category)
ggplot(task_counts, aes(n, reorder(category, n), fill=dataset)) +
  geom_col(show.legend=FALSE) + facet_wrap(~dataset, scales='free_y') +
  scale_fill_manual(values=c('#287d70','#39769c')) +
  labs(x='Questions', y=NULL, title='The two test sets ask different kinds of questions')

## ---- history-load
ggplot(h, aes(words, colour=dataset)) + stat_ecdf(linewidth=1) +
  scale_x_log10(labels=scales::comma) + scale_y_continuous(labels=scales::percent) +
  labs(x='Words in a chat history (log scale)', y='Share at or below this length',
       colour=NULL, title='LongMemEval gives each question more text to search',
       subtitle='LoCoMo: 10 conversations; LongMemEval-S: 500 question histories')

## ---- evidence-position
ggplot(filter(q, eligible), aes(earliest_evidence, fill=dataset)) +
  geom_histogram(binwidth=.1, boundary=0, colour='white', show.legend=FALSE) +
  facet_wrap(~dataset, scales='free_y') + scale_x_continuous(labels=scales::percent) +
  labs(x='Position of the first marked source session', y='Questions we scored',
       title='Key facts can sit far back in the chat history')

## ---- evidence-burden
burden <- filter(q, eligible) |> count(dataset, gold_sessions) |>
  group_by(dataset) |> mutate(share=n/sum(n))
ggplot(burden, aes(factor(gold_sessions), share, fill=dataset)) +
  geom_col(show.legend=FALSE) + facet_wrap(~dataset, scales='free_x') +
  scale_y_continuous(labels=scales::percent) +
  labs(x='Number of marked source sessions needed', y='Share of questions we scored',
       title='Some questions need facts from several sessions')

## ---- recall-curves
ggplot(curves, aes(k, recall, colour=strategy)) +
  geom_line(linewidth=1) + geom_point(size=2.5) + facet_wrap(~dataset) +
  scale_colour_manual(values=palette) + scale_x_continuous(breaks=c(1,3,5,10)) +
  scale_y_continuous(labels=scales::percent, limits=c(0,1)) +
  labs(x='Session limit', y='Mean recall of marked source sessions', colour=NULL,
       title='The method changes which source sessions we find',
       subtitle='Our search test measures source recall, not answer quality')

## ---- complete-evidence
ggplot(curves, aes(k, all_hit, colour=strategy)) +
  geom_line(linewidth=1) + geom_point(size=2.5) + facet_wrap(~dataset) +
  scale_colour_manual(values=palette) + scale_x_continuous(breaks=c(1,3,5,10)) +
  scale_y_continuous(labels=scales::percent, limits=c(0,1)) +
  labs(x='Session limit', y='Share of questions with all marked sources found',
       colour=NULL, title='Finding some sources is easier than finding them all')

## ---- category-heatmap
ggplot(cats, aes(strategy, category, fill=recall)) +
  geom_tile(colour='white') + geom_text(aes(label=sprintf('%.0f%%',100*recall)),size=3.2) +
  facet_wrap(~dataset, scales='free_y') +
  scale_fill_gradient(low='#f0f3f7',high='#63b9a5',limits=c(0,1),labels=scales::percent) +
  labs(x=NULL,y=NULL,fill='Recall',title='Scores vary by the type of question',
       subtitle='Recall at a five-session limit; task counts are in the download')

## ---- conversation-effects
ggplot(filter(clusters,dataset=='LoCoMo'), aes(reorder(cluster,gain),100*gain)) +
  geom_hline(yintercept=0,colour='#8797a1') + geom_segment(aes(xend=cluster,y=0,yend=100*gain),colour='#287d70') +
  geom_point(size=3,colour='#287d70') + coord_flip() +
  labs(x='Conversation',y='BM25 minus Recent (percentage points)',
       title='Score gains in each of the ten chat histories',
       subtitle='Each point shows the mean gain at a five-session limit')

## ---- context-efficiency
ggplot(curves, aes(retained_fraction,recall,colour=strategy)) +
  geom_path(linewidth=1) + geom_point(size=3) + geom_text(aes(label=k),vjust=-.8,size=3,show.legend=FALSE) +
  facet_wrap(~dataset) + scale_colour_manual(values=palette) +
  scale_x_continuous(labels=scales::percent) + scale_y_continuous(labels=scales::percent,limits=c(0,1)) +
  labs(x='Mean share of source words kept',y='Mean recall of marked source sessions',colour=NULL,
       title='Keeping less text can mean losing key facts',subtitle='Point labels show session limits; words are not billed tokens')

## ---- position-performance
ggplot(pos,aes(position_band,recall,colour=strategy,group=strategy)) +
  geom_line(linewidth=1) + geom_point(size=2.5) + facet_wrap(~dataset) +
  scale_colour_manual(values=palette) + scale_y_continuous(labels=scales::percent,limits=c(0,1)) +
  theme(axis.text.x=element_text(angle=30,hjust=1)) +
  labs(x='First marked source position (share of history)',y='Mean recall at k = 5',colour=NULL,
       title='The latest-chat method tends to miss older facts')

## ---- ruler-heatmap
order_models <- rr |> group_by(model) |> summarise(avg=mean(score)) |> arrange(avg) |> pull(model)
ggplot(rr,aes(factor(tested_tokens/1000),factor(model,levels=order_models),fill=score)) +
  geom_tile(colour='white') + geom_text(aes(label=sprintf('%.0f',score)),size=2.8) +
  scale_fill_gradient(low='#f9eadc',high='#469d9b',limits=c(0,100)) +
  labs(x='Test length (thousands of tokens)',y=NULL,fill='Score',
       title='Published RULER scores across context lengths',
       subtitle='Scores from older models; this is not a ranking of current tools')

## ---- ruler-degradation
ggplot(drops,aes(reorder(model,drop),drop)) +
  geom_col(fill='#39769c',width=.7) + coord_flip() +
  labs(x=NULL,y='Score at 4K minus score at 128K (points)',
       title='Scores can fall as the input grows',
       subtitle='Published scores; each model claims to support at least 128K')

## ---- ruler-curves
selected <- c('Gemini-1.5-pro','GPT-4-1106-preview','Qwen3-14B (14B)','Llama3.1 (70B)')
ggplot(filter(rr,model %in% selected),aes(tested_tokens/1000,score,colour=model)) +
  geom_line(linewidth=1) + geom_point(size=2) +
  scale_x_log10(breaks=c(4,8,16,32,64,128)) +
  labs(x='Test length (thousands of tokens, log scale)',y='Published RULER score',colour=NULL,
       title='Four older models show different score drops')

## ---- economic-sensitivity
# Example inputs. We have not measured time saved or returns.
scenario <- expand.grid(tasks=c(20,100,500),minutes_saved=seq(0,5,.1)) |>
  mutate(net_value=tasks*minutes_saved/60*30 - 20 - tasks*.02)
ggplot(scenario,aes(minutes_saved,net_value,colour=factor(tasks))) +
  geom_hline(yintercept=0,linetype='dashed') + geom_line(linewidth=1) +
  labs(x='Assumed work minutes saved per task',y='Monthly value after costs (USD, example)',
       colour='Tasks / month',title='The value depends on how much work time it saves',
       subtitle='Assumptions: $30/hour, $20/month fixed cost, $0.02 extra cost/task')

## ---- input-cost-grid
costs <- expand.grid(input_tokens=c(8000,32000,128000,512000),price_per_million=c(.1,.5,1,3,10)) |>
  mutate(cost=input_tokens*price_per_million/1e6)
ggplot(costs,aes(factor(input_tokens/1000),factor(price_per_million),fill=cost)) +
  geom_tile(colour='white') + geom_text(aes(label=sprintf('$%.3f',cost)),size=3.4) +
  scale_fill_gradient(low='#edf5f7',high='#67aaa8') +
  labs(x='Input tokens (thousands)',y='Assumed USD per million input tokens',fill='USD',
       title='Input cost increases with context length and unit price',
       subtitle='Example costs; excludes cached rates, output, and memory tools')
