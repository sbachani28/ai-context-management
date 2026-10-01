CONTEXT MANAGEMENT ACROSS AI TOOLS: MEMORY, RELIABILITY, AND COST — R / QUARTO RESEARCH WEBSITE

Open AI-Economy.Rproj in RStudio. Install R packages jsonlite, dplyr,
ggplot2, scales, knitr, and rmarkdown if needed. Python 3 uses its standard library.

From the project directory:
  python3 scripts/fetch_benchmarks.py
  python3 scripts/evaluate_retrieval.py
  Rscript R/context_analysis.R
  python3 scripts/audit_results.py
  python3 scripts/prepare_data.py
  Rscript R/analyze.R
  quarto render
  quarto preview

The rendered website is _site/index.html. Serve _site with a local HTTP
server for the full search/navigation experience, or publish _site to a
static host such as GitHub Pages, Netlify, or Quarto Pub. No API key is needed to reproduce the archived analysis.

What is completed:
- LoCoMo and LongMemEval-S retrieval analysis: 2,486 public questions,
  2,006 eligible questions, and 24,072 method-by-budget evaluations.
- Paired recall comparisons, conversation-cluster bootstrap analysis,
  and context-retention comparisons.
- Analysis of 264 published RULER scores across 45 models.
- Eight primary-study evidence summaries, source links, and research limits.
- Archived OpenRouter catalog analysis for a selected 12-developer cohort.
- Python extraction, SQLite table, R charts and descriptive regressions.
- Interactive price explorer; R code and provenance downloads.
- Executed, expanded R code directly above every graph on the website.
- A six-question optional survey, local anonymous JSON export, and a saved
  Google Apps Script generator for a centrally collected Google Form.

What is NOT completed:
- Historical monthly company usage/prices and a labor-market panel.
- A causal AI employment effect, quality-adjusted price trend, or market shares.
- Survey recruitment or findings. The Google generator has not been executed.

The catalog snapshot was captured September 30, 2026 PDT / October 1 UTC.
Its hash, timestamp, selection query, and source are in the manifest.
Listings are not users, revenue, market shares, or independent companies.
Price estimates use advertised base token prices and exclude other fees.

The short survey supersedes the long survey concept in the earlier kit.
Before distributing: run scripts/create_pulse_form.gs in Google Apps Script,
inspect form publishing/responder settings, test consent routing, and identify
your researcher/contact details if your institution requires them. Filter out
nonconsent, inconsistent, and duplicate submissions before analysis.

Main pages: index.qmd, datasets.qmd, retrieval.qmd, market.qmd,
evidence.qmd, economics.qmd, methods.qmd, pulse.qmd. Edit these source files and re-render.

The website uses Quarto Minty, matching the Data Viz website at
https://sbachani28.github.io/data-notebook/.

The project ZIP excludes the large LongMemEval-S raw file. The benchmark
fetch script restores its pinned source version and checks the SHA-256 hash.
Retrieval scores measure finding marked source sessions, not answer accuracy.
Economic savings scenarios use assumed inputs, not measured user savings.

Public website: https://sbachani28.github.io/ai-context-management/
