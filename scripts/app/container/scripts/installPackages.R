#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
stage1 <- length(args) >= 1 && args[1] == "stage1"

install.packages("BiocManager")
if (stage1) {
  BiocManager::install(c(
    "data.table", "tidyr", "dplyr", "readr", "rvest",
    "data.table", "readxl", "fuzzyjoin", "webchem",
    "googleLanguageR", "dbparser"
  ), ask = FALSE)
} else {
  BiocManager::install(c(
    "shiny", "rmarkdown", "kableExtra", "dplyr", "R.utils",
    "filesstrings", "data.table", "RCurl", "stringr",
    "xml2", "knitr", "tidyr", "DT", "devtools", "optparse",
    "fuzzyjoin", "IRanges", "ontologyIndex", "brew", "vcfR",
    "dbparser"
  ), ask = FALSE)
}
