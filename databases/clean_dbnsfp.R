#!/usr/bin/env Rscript

# Load libraries
library(dplyr)
library(readr)

# get arguments
args <- commandArgs(trailingOnly = TRUE)
hg19 <- args[1]
hg38 <- args[2]

# read hg19 and hg38 dbnsfp files with readr
dbnsfp_hg19 <- read_tsv(hg19, col_names = FALSE, col_types = cols())
dbnsfp_hg38 <- read_tsv(hg38, col_names = FALSE, col_types = cols())

# TODO
