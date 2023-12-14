#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2) {
  stop("Usage: process_clinvar.R <input_vcf> <output_file>")
}

suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(stringr))

input_vcf <- args[1]
output_file <- args[2]

cli <- fread(input_vcf, skip = "#CHROM")
cli <- cli[, c("#CHROM", "POS", "REF", "ALT", "INFO")]

names(cli) <- c("Chromosome", "Stop", "Ref_base", "Var_base", "info")

cli$Chromosome <- paste0("chr", cli$Chromosome)
cli$Stop <- as.character(cli$Stop)

cli$Clinical_significance <- sub(".*CLNSIG= *(.*?) *;CLNVC.*", "\\1", cli$info)
cli$Clinical_significance <- sub(
  ";CLNSIGCONF.*", "\\1", cli$Clinical_significance
)
cli$Clinical_significance <- gsub(
  "_", " ", cli$Clinical_significance,
  fixed = TRUE
)
cli$Clinical_significance <- str_to_title(cli$Clinical_significance)

cli$Change_type <- sub(".*\\| *(.*?) *;ORIGIN.*", "\\1", cli$info)
cli$Change_type <- gsub("_variant", "", cli$Change_type, fixed = TRUE)
cli$Change_type <- str_to_title(cli$Change_type)
cli <- cli[, c(
  "Chromosome", "Stop", "Ref_base", "Var_base", "Change_type",
  "Clinical_significance"
)]
saveRDS(cli, output_file)
# unlink(input_vcf)
