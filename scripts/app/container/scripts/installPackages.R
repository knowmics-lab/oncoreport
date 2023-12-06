#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
stage1 <- length(args) >= 1 && args[1] == "stage1"
stage2 <- length(args) >= 1 && args[1] == "stage2"

install.packages("BiocManager")
if (stage1) {
  BiocManager::install(c(
    "data.table", "tidyr", "dplyr", "readr", "rvest",
    "readxl", "fuzzyjoin", "webchem", "googleLanguageR",
    "dbparser", "R.utils"
  ), ask = FALSE)
} else if (stage2) {
  # Remove packages that are not needed in stage 2
  remove.packages(c("rvest", "webchem", "googleLanguageR"))
  # Install additional packages needed in stage 2
  BiocManager::install(c(
    "shiny", "rmarkdown", "kableExtra", "filesstrings",
    "RCurl", "stringr", "xml2", "knitr", "DT", "devtools",
    "optparse", "IRanges", "ontologyIndex", "brew", "vcfR"
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
