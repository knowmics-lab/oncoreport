#!/usr/bin/env Rscript

install.packages("BiocManager")
BiocManager::install(c(
  "shiny", "rmarkdown", "kableExtra", "dplyr", "R.utils",
  "filesstrings", "data.table", "RCurl", "stringr",
  "xml2", "knitr", "tidyr", "DT", "devtools", "optparse",
  "fuzzyjoin", "IRanges", "ontologyIndex"
), ask = FALSE)

library(devtools)
devtools::install_github("ropensci/dbparser")
