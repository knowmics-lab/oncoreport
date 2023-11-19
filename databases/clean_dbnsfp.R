#!/usr/bin/env Rscript

# Load libraries
library(data.table)

# get arguments
args <- commandArgs(trailingOnly = TRUE)
hg19 <- args[1]
hg38 <- args[2]

columns_before <- c(
  "Chr", "Start", "Ref", "Alt", "SIFT_pred", "LRT_pred",
  "MutationTaster_pred", "MutationAssessor_pred", "FATHMM_pred",
  "PROVEAN_pred", "MetaSVM_pred", "MetaLR_pred", "fathmm-MKL_coding_pred"
)
columns_after <- c(
  "Chr", "Start", "End", "Ref", "Alt", "SIFT_pred", "LRT_pred",
  "MutationTaster_pred", "MutationAssessor_pred", "FATHMM_pred",
  "PROVEAN_pred", "MetaSVM_pred", "MetaLR_pred", "fathmm-MKL_coding_pred"
)

prepare_pred_column <- function(column) {
  return(sapply(strsplit(column, ";", fixed = TRUE), function(x) {
    x <- unique(x[x != "."])
    if (length(x) == 0) {
      return(".")
    } else if (length(x) == 1) {
      return(x[1])
    } else {
      return(paste(x, collapse = ";"))
    }
  }))
}

prepare_table <- function(tbl) {
  colnames(tbl) <- columns_before

  tbl <- tbl[Start != ".", ]
  tbl <- tbl[Ref != ".", ]

  tbl$Start <- as.numeric(tbl$Start)
  tbl$End <- tbl$Start + sapply(tbl$Ref, length) - 1

  for (c in grep("_pred", colnames(tbl), value = TRUE)) {
    tbl[[c]] <- prepare_pred_column(tbl[[c]])
  }

  tbl <- na.omit(tbl)

  return(tbl[, columns_after, with = FALSE])
}

# read hg19 and hg38 dbnsfp files with readr
dbnsfp_hg19 <- fread(hg19, sep = "\t", header = FALSE)
dbnsfp_hg19 <- prepare_table(dbnsfp_hg19)
fwrite(dbnsfp_hg19,
  file = hg19, sep = "\t", quote = FALSE,
  row.names = FALSE, col.names = FALSE
)
rm(dbnsfp_hg19)

dbnsfp_hg38 <- fread(hg38, sep = "\t", header = FALSE)
dbnsfp_hg38 <- prepare_table(dbnsfp_hg38)
fwrite(dbnsfp_hg38,
  file = hg38, sep = "\t", quote = FALSE,
  row.names = FALSE, col.names = FALSE
)
rm(dbnsfp_hg38)
