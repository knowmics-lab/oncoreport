#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("Please provide the path to the databases folder as the first argument.")
}
library(readr)
library(dplyr)
library(tidyr)
database_path <- args[1]
if (!file.exists(database_path)) {
  stop("The path to the databases folder does not exist.")
}

variants <- read_tsv(
  file.path(database_path, "civic/variants.tsv"),
  col_names = TRUE
)
molecular_profiles <- read_tsv(
  file.path(database_path, "civic/molecular_profiles.tsv"),
  col_names = TRUE
)
clinical_evidences <- read_tsv(
  file.path(database_path, "civic/clinical_evidences.tsv"),
  col_names = TRUE,
  col_types = cols(citation_id = col_character())
)
assertions <- read_tsv(
  file.path(database_path, "civic/assertions.tsv"),
  col_names = TRUE
)

molecular_profiles <- molecular_profiles %>%
  separate_rows(variant_ids, sep = ",") %>%
  mutate(variant_id = as.numeric(trimws(variant_ids))) %>%
  select(-variant_ids)

civic <- clinical_evidences %>%
  left_join(
    molecular_profiles,
    by = "molecular_profile_id",
    relationship = "many-to-many",
    suffix = c("", "_1")
  ) %>%
  left_join(variants, by = "variant_id", suffix = c("", "_2")) %>%
  left_join(
    assertions,
    by = "molecular_profile_id",
    relationship = "many-to-many",
    suffix = c("", "_2")
  ) %>%
  unique()

tmp <- colnames(civic)
tmp[tmp == "significance"]             <- "clinical_significance"
tmp[tmp == "summary"]                  <- "variant_summary"
tmp[tmp == "therapies"]                <- "drugs"
tmp[tmp == "therapy_interaction_type"] <- "drug_interaction_type"
colnames(civic) <- tmp

to_change <- is.na(civic$reference_build) & !is.na(civic$ensembl_version) & 
  civic$ensembl_version == 75
civic$reference_build[to_change] <- "GRCh37"
civic <- civic[!is.na(civic$reference_build), ]

civic_hg19 <- civic %>%
  filter(reference_build == "GRCh37")
civic_hg38 <- civic %>%
  filter(reference_build == "GRCh38")

write_tsv(
  x = civic_hg19,
  file = file.path(database_path, "civic_hg19_partial_1.tsv"),
  col_names = TRUE,
  quote = "needed"
)
write_tsv(
  x = civic_hg38,
  file = file.path(database_path, "civic_hg38_partial_1.tsv"),
  col_names = TRUE,
  quote = "needed"
)

civic <- civic %>%
  select(
    chromosome, start, stop, variant_id, reference_build
  )
civic <- civic[complete.cases(civic), ]
civic <- unique(civic)
# Swap start and stop if start > stop
to_swap <- which(civic[, "start"] > civic[, "stop"])
if (length(to_swap) > 0) {
  for (i in seq_along(to_swap)) {
    tmp                        <- civic[to_swap[i], "start"]
    civic[to_swap[i], "start"] <- civic[to_swap[i], "stop"]
    civic[to_swap[i], "stop"]  <- tmp
  }
  rm(tmp)
}
# Sort by chromosome (numerically), start, stop, variant_id
numeric_chr <- civic$chromosome
numeric_chr[numeric_chr == "X"] <- 23
numeric_chr[numeric_chr == "Y"] <- 24
numeric_chr[numeric_chr == "M"] <- 25
numeric_chr <- as.numeric(numeric_chr)
civic <- civic[order(numeric_chr, civic$start, civic$stop, civic$variant_id), ]
civic$chromosome <- paste0("chr", civic$chromosome)
civic_hg19 <- civic[civic$reference_build == "GRCh37", ] %>%
  select(chromosome, start, stop, variant_id)
civic_hg38 <- civic[civic$reference_build == "GRCh38", ] %>%
  select(chromosome, start, stop, variant_id)
write_tsv(
  x = civic_hg19,
  file = file.path(database_path, "civic_hg19_partial_1.bed"),
  col_names = FALSE,
  quote = "none"
)
write_tsv(
  x = civic_hg38,
  file = file.path(database_path, "civic_hg38_partial_1.bed"),
  col_names = FALSE,
  quote = "none"
)

