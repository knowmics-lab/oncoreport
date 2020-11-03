#!/usr/bin/env Rscript

install.packages("BiocManager")
BiocManager::install(c(
    "shiny", "rmarkdown", "kableExtra", "dplyr",
    "filesstrings", "data.table", "RCurl", "stringr"
),ask = FALSE)
