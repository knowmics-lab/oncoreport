#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(optparse)
  library(readr)
  library(data.table)
  library(dplyr)
  library(tidyr)
})

option_list <- list(
  make_option(c("-i", "--input"),
    type = "character", default = NULL,
    help = "input file", metavar = "character"
  ),
  make_option(c("-o", "--output"),
    type = "character", default = NULL,
    help = "output file", metavar = "character"
  ),
  make_option(c("-d", "--dp"),
    type = "character", default = NULL,
    help = "DP filtering expression", metavar = "character"
  ),
  make_option(c("-a", "--af"),
    type = "character", default = NULL,
    help = "AF filtering expression", metavar = "character"
  )
)

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

input_file <- opt$input
output_file <- opt$output
output_dir <- dirname(output_file)
dp_filter <- opt$dp
af_filter <- opt$af

if (!dir.exists(output_dir)) {
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
}

p_ifelse <- function(test, yes, no) {
  if (length(yes) < length(test)) yes <- rep(yes, length.out = length(test))
  if (length(no) < length(test)) no <- rep(no, length.out = length(test))
  return(sapply(seq_along(test), function(i) (ifelse(test[i], yes[i], no[i]))))
}

variant_table <- fread(input_file)
colnames(variant_table) <- make.names(colnames(variant_table))
variant_table <- variant_table %>%
  mutate(
    GT = "",
    VT = p_ifelse(
      nchar(Reference.Allele) == nchar(Variant.Allele),
      ifelse(nchar(Reference.Allele) == 1, "SNP", "MNP"),
      "INDEL"
    ),
  ) %>%
  select(
    Chromosome = Chromosome, Stop = Position, Ref_base = Reference.Allele,
    Var_base = Variant.Allele, AF = Variant.Frequency, DP = Total.Depth, GT, VT
  ) %>%
  mutate(
    DPFilt = eval(rlang::parse_expr(paste0("DP", dp_filter))),
    AFFilt = eval(rlang::parse_expr(paste0("AF", af_filter)))
  ) %>%
  filter(DPFilt) %>%
  mutate(
    Type = ifelse(AFFilt, "Germline", "Somatic")
  ) %>%
  select(Chromosome, Stop, Ref_base, Var_base, AF, DP, GT, VT, Type)

write.table(variant_table, output_file,
  append = FALSE, quote = FALSE, sep = "\t", row.names = FALSE, col.names = TRUE
)
