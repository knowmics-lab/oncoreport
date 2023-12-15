#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2) {
  stop("Usage: process_cgi.R <input_file> <output_file>")
}

suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(stringr))

input_file  <- args[1]
output_file <- args[2]

cgi <- fread(input_file, sep = "\t")
cgi <- cgi[, c(
  "Chromosome", "start", "stop", "ref_base", "alt_base", "Gene",
  "individual_mutation", "Association", "Drug.full.name", "Evidence.level",
  "Primary.Tumor.type.full.name", "Source", "Abstract", "authors_journal_data"
)]
names(cgi) <- c(
  "Chromosome", "Start", "Stop", "Ref_base", "Var_base", "Gene", "Variant",
  "Clinical_significance", "Drug", "Evidence_level", "Disease", "PMID",
  "Evidence_statement", "Citation"
)
cgi$Database <- "Cancer Genome Interpreter"
cgi <- cgi %>%
  separate_rows(
    Chromosome, Ref_base, Var_base, Gene, Variant, Clinical_significance, Drug,
    Evidence_level, Disease, PMID, Evidence_statement, Citation,
    sep = ";;"
  ) %>%
  mutate(
    PMID = gsub(";", ",,", PMID)
  ) %>%
  separate_rows(
    Chromosome, Ref_base, Var_base, Gene, Variant, Clinical_significance, Drug,
    Evidence_level, Disease, PMID, Evidence_statement, Citation,
    sep = ",,"
  ) %>%
  separate_rows(Disease, sep = ";") %>%
  separate_rows(PMID, sep = ",")

cgi         <- cgi[grep("PMID:", cgi$PMID), ]
cgi$PMID    <- gsub(cgi$PMID, pattern = "PMID:", replace = "")
cgi$Variant <- gsub(".*:(.*)", "\\1", cgi$Variant)

cgi$Drug <- gsub(cgi$Drug, pattern = " *\\[.*?\\] *", replace = "")
cgi$Drug <- gsub(cgi$Drug, pattern = " *\\(.*?\\) *", replace = "")
cgi$Drug <- gsub(cgi$Drug, pattern = ";", replace = ",", fixed = TRUE)

cgi$Evidence_type      <- "Predictive"
cgi$Evidence_direction <- "Supports"
cgi$Evidence_statement <- gsub(
  cgi$Evidence_statement, pattern = "\\\\x2c", replace = ","
)
cgi$Citation <- gsub(cgi$Citation, pattern = "\\\\x2c", replace = ",")
cgi$Drug_interaction_type <- ""
cgi$Drug_interaction_type[grep(" + ", cgi$Drug, fixed = TRUE)] <- "Combination"
cgi$Drug <- gsub(cgi$Drug, pattern = " + ", replace = ",", fixed = TRUE)
cgi$Variant_summary <- ""
cgi <- cgi[, c(1:7, 14, 9, 18, 16, 10, 17, 8, 11, 19, 15, 12, 13)]
saveRDS(cgi, output_file)
# unlink(input_file)
