#!/usr/bin/env Rscript

install.packages("BiocManager")
BiocManager::install(c(
    "shiny", "rmarkdown", "kableExtra", "dplyr",
    "filesstrings", "data.table", "RCurl", "stringr",
    "xml2", "knitr", "tidyr", "DT"
),ask = FALSE)
