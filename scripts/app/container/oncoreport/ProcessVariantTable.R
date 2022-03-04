#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(optparse)
  library(readr)
  library(data.table)
  library(dplyr)
  library(tidyr)
})

option_list <- list(
  make_option(c("-i", "--input"), type = "character", default = NULL, help = "input file", metavar = "character"),
  make_option(c("-o", "--output"), type = "character", default = NULL, help = "output file", metavar = "character"),
  make_option(c("-d", "--dp"), type = "character", default = NULL, help = "DP filtering expression", metavar = "character"),
  make_option(c("-a", "--af"), type = "character", default = NULL, help = "AF filtering expression", metavar = "character")
);

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)
args <- commandArgs(trailingOnly = TRUE)

if (is.null(opt$input) || !file.exists(opt$input)) {
  print_help(opt_parser)
  stop("Input file does not exist", call. = FALSE)
}
if (is.null(opt$output)) {
  print_help(opt_parser)
  stop("Output is empty", call. = FALSE)
}

input.file  <- opt$input
output.file <- opt$output
output.dir  <- dirname(output.file)
dp.filter   <- opt$dp
af.filter   <- opt$af

if (!dir.exists(output.dir)) {
  dir.create(output.dir, showWarnings = FALSE, recursive = TRUE)
}

variant.table <- fread(input.file)
colnames(variant.table) <- make.names(colnames(variant.table))
variant.table <- variant.table %>% 
  mutate(
    GT="",
    VT=ifelse(nchar(Reference.Allele) == nchar(Variant.Allele), ifelse(nchar(Reference.Allele) == 1, "SNP", "MNP"), "INDEL"),
  ) %>%
  select(Chromosome=Chromosome, Stop=Position, Ref_base=Reference.Allele, Var_base=Variant.Allele, AF=Variant.Frequency, 
         DP=Total.Depth, GT, VT) %>%
  mutate(
    DPFilt=eval(rlang::parse_expr(paste0("DP", dp.filter))),
    AFFilt=eval(rlang::parse_expr(paste0("AF", af.filter)))
  ) %>%
  filter(DPFilt) %>%
  mutate(
    Type=ifelse(AFFilt, "Germline", "Somatic")
  ) %>%
  select(Chromosome, Stop, Ref_base, Var_base, AF, DP, GT, VT, Type)

write.table(variant.table, output.file, append = FALSE, quote = FALSE, sep = "\t", row.names = FALSE, col.names = TRUE)
