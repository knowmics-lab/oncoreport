#!/usr/bin/env Rscript

# Load libraries
suppressPackageStartupMessages(library(data.table))

# get arguments
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3) {
  cat(
    "Usage: clean_dbnsfp.R <hg19_dbnsfp_file>",
    "<hg38_dbnsfp_file> <output_dir>\n"
  )
  quit(status = 1)
}
hg19       <- args[1]
hg38       <- args[2]
output_dir <- args[3]

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

priority_by_column <- list(
  "SIFT_pred" = c("D", "T"),
  "LRT_pred" = c("D", "N", "U"),
  "MutationTaster_pred" = c("A", "D", "N", "P"),
  "MutationAssessor_pred" = c("H", "M", "L", "N"),
  "FATHMM_pred" = c("D", "T"),
  "PROVEAN_pred" = c("D", "N"),
  "MetaSVM_pred" = c("D", "T"),
  "MetaLR_pred" = c("D", "T"),
  "fathmm-MKL_coding_pred" = c("D", "N")
)

prepare_pred_column <- function(column, priority) {
  return(sapply(strsplit(column, ";", fixed = TRUE), function(x) {
    x <- unique(x[x != "."])
    if (length(x) == 0) {
      return(".")
    } else if (length(x) == 1) {
      return(x[1])
    } else {
      for (p in priority) {
        if (p %in% x) {
          return(p)
        }
      }
      return(x[1])
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
    tbl[[c]] <- prepare_pred_column(tbl[[c]], priority_by_column[[c]])
  }

  tbl <- na.omit(tbl)

  return(tbl[, columns_after, with = FALSE])
}

# read hg19 and hg38 dbnsfp files with readr
cat("Reading hg19 dbNSFP file...")
dbnsfp_hg19 <- fread(hg19, sep = "\t", header = FALSE)
cat("preparing...")
dbnsfp_hg19 <- prepare_table(dbnsfp_hg19)
cat("writing...")
colnames(dbnsfp_hg19) <- columns_after
saveRDS(dbnsfp_hg19, file = file.path(output_dir, "hg19", "dbNSFP.rds"))
rm(dbnsfp_hg19)
cat("done\n")

cat("Reading hg38 dbNSFP file...")
dbnsfp_hg38 <- fread(hg38, sep = "\t", header = FALSE)
cat("preparing...")
dbnsfp_hg38 <- prepare_table(dbnsfp_hg38)
cat("writing...")
colnames(dbnsfp_hg38) <- columns_after
saveRDS(dbnsfp_hg38, file = file.path(output_dir, "hg38", "dbNSFP.rds"))
rm(dbnsfp_hg38)
cat("done\n")
