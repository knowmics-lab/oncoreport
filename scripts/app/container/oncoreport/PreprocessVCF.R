#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(optparse)
  library(vcfR)
  library(readr)
  library(dplyr)
  library(tidyr)
})

option_list <- list(
  make_option(c("-i", "--input"),
    type = "character", default = NULL,
    help = "input VCF file", metavar = "character"
  ),
  make_option(c("-o", "--output"),
    type = "character", default = NULL,
    help = "output TSV file", metavar = "character"
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

vcf <- read.vcfR(input_file)
dfs <- vcfR2tidy(vcf)
merged <- cbind(dfs$fix, dfs$gt)
colnames(merged) <- make.names(colnames(merged), unique = TRUE)
if (!("AF" %in% colnames(merged))) {
  merged$AF <- NA
}
if (!("gt_FREQ" %in% colnames(merged))) {
  merged$gt_FREQ <- NA
}
if (!("gt_AF" %in% colnames(merged))) {
  merged$gt_AF <- NA
}
if (!("DP" %in% colnames(merged))) {
  merged$DP <- NA
}
if (!("FT" %in% colnames(merged))) {
  merged$FT <- NA
}
if (!("gt_FT" %in% colnames(merged))) {
  merged$gt_FT <- NA
}
if (!("GT" %in% colnames(merged))) {
  merged$GT <- NA
}
merged <- merged %>%
  mutate(
    finalAF = as.numeric(p_ifelse(
      is.na(AF),
      p_ifelse(is.na(gt_AF), as.numeric(gsub("%", "", gt_FREQ)) / 100, gt_AF),
      AF
    )),
    finalDP = as.numeric(p_ifelse(is.na(DP), gt_DP, DP)),
    VT = p_ifelse(
      nchar(REF) == nchar(ALT),
      ifelse(nchar(ALT) == 1, "SNP", "MNP"),
      "INDEL"
    ),
    finalFT = p_ifelse(is.na(FT), gt_FT, FT)
  ) %>%
  select(CHROM, POS, REF, ALT,
    AF = finalAF, DP = finalDP, GT = gt_GT, VT,
    FT = finalFT
  )

merged$GT <- gsub("|", "/", merged$GT, fixed = TRUE)

if (!is.null(dp_filter)) {
  merged <- merged %>%
    mutate(
      DPFilt = eval(rlang::parse_expr(paste0("DP", dp_filter)))
    )
} else {
  merged$DPFilt <- TRUE
}

if (!is.null(af_filter)) {
  merged <- merged %>%
    mutate(
      AFFilt = eval(rlang::parse_expr(paste0("AF", af_filter))),
      useFT = FALSE
    )
} else {
  merged$AFFilt <- FALSE
  merged$useFT <- TRUE
}

merged <- merged %>%
  filter(DPFilt) %>%
  mutate(
    Type = p_ifelse(
      !useFT | is.na(FT) | FT != "Germline",
      ifelse(!is.na(AFFilt) & AFFilt, "Germline", "Somatic"),
      FT
    )
  ) %>%
  select(
    Chromosome = CHROM, Stop = POS, Ref_base = REF, Var_base = ALT, AF, DP,
    GT, VT, Type
  )

write.table(merged, output_file,
  append = FALSE, quote = FALSE, sep = "\t",
  row.names = FALSE, col.names = TRUE
)
