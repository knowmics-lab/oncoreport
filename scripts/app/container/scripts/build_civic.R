#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("Please provide the path to the databases folder as the first argument.")
}
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))
database_path <- args[1]
if (!file.exists(database_path)) {
  stop("The path to the databases folder does not exist.")
}

clean_string <- function(x) {
  x <- gsub(x, pattern = "\\u00E2", replace = "-")
  x <- gsub(x, pattern = "\\\\x2c", replace = ",")
  return(x)
}

clean_columns <- function(df, columns) {
  for (c in columns) {
    df[[c]] <- clean_string(df[[c]])
  }
  return(df)
}

process_civic <- function(civic) {
  civic_selection <- civic[, c("chromosome", "start", "stop", "reference_bases",
                               "variant_bases", "gene", "variant", "disease",
                               "drugs", "drug_interaction_type",
                               "evidence_type", "evidence_level",
                               "evidence_direction", "clinical_significance",
                               "evidence_statement", "variant_summary",
                               "citation_id", "citation", "nccn_guideline",
                               "nccn_guideline_version", "assertion_summary",
                               "regulatory_approval")]
  civic_selection <- unique(civic_selection)
  names(civic_selection) <- c(
    "Chromosome", "Start", "Stop", "Ref_base", "Var_base", "Gene", "Variant",
    "Disease", "Drug", "Drug_interaction_type", "Evidence_type",
    "Evidence_level", "Evidence_direction", "Clinical_significance",
    "Evidence_statement", "Variant_summary", "PMID", "Citation",
    "NCCN_guideline", "NCCN_guideline_version", "Assertion_summary",
    "Regulatory_approval"
  )
  chr_selection <- !grepl("^chr", civic_selection$Chromosome)
  civic_selection$Chromosome[chr_selection] <- paste0(
    "chr", civic_selection$Chromosome[chr_selection]
  )
  civic_selection$Start <- as.character(civic_selection$Start)
  civic_selection$Stop <- as.character(civic_selection$Stop)
  civic_selection$Database <- "Civic"
  civic_selection <- clean_columns(
    civic_selection,
    c(
      "Evidence_statement", "Drug", "Citation", "Variant_summary",
      "NCCN_guideline", "Assertion_summary"
    )
  )
  civic_selection$Evidence_level <- as.character(civic_selection$Evidence_level)
  civic_selection$Evidence_level[civic_selection$Evidence_level == "A"] <- "Validated association"
  civic_selection$Evidence_level[civic_selection$Evidence_level == "B"] <- "Clinical evidence"
  civic_selection$Evidence_level[civic_selection$Evidence_level == "C"] <- "Case study"
  civic_selection$Evidence_level[civic_selection$Evidence_level == "D"] <- "Preclinical evidence"
  civic_selection$Evidence_level[civic_selection$Evidence_level == "E"] <- "Inferential association"
  civic_selection <- civic_selection %>% 
    group_by(
      Chromosome, Start, Stop, Ref_base, Var_base, Gene, Variant,
      Disease, Drug, Drug_interaction_type, Evidence_type,
      Evidence_level, Evidence_direction, Clinical_significance
    ) %>% 
    summarize_all(~ paste0(unique(na.omit(.x)), collapse = ";;"))
  return(civic_selection)
}

civic_coords_hg19_converted <- read_tsv(
  file.path(database_path, "civic_hg19_partial_2.bed"), 
  col_names = c("chromosome", "start", "stop", "variant_id"), 
  col_types = cols(chromosome = "c")
)
civic_coords_hg38_converted <- read_tsv(
  file.path(database_path, "civic_hg38_partial_2.bed"), 
  col_names = c("chromosome", "start", "stop", "variant_id"), 
  col_types = cols(chromosome = "c")
)

civic_hg19_partial <- read_tsv(
  file.path(database_path, "civic_hg19_partial_1.tsv"), 
  col_types = cols(
    variant_bases = "c", citation_id = "c", chromosome2 = "c", chromosome = "c"
  )
)
civic_hg38_partial <- read_tsv(
  file.path(database_path, "civic_hg38_partial_1.tsv"), 
  col_types = cols(
    variant_bases = "c", citation_id = "c", chromosome2 = "c", chromosome = "c"
  )
)

hg19_converted <- civic_hg38_partial %>%
  inner_join(
    civic_coords_hg19_converted, 
    by = "variant_id", 
    suffix = c("", "_hg19"),
    relationship = "many-to-many"
  ) %>%
  select(-chromosome, -start, -stop) %>%
  mutate(chromosome = chromosome_hg19, start = start_hg19, stop = stop_hg19) %>%
  select(-chromosome_hg19, -start_hg19, -stop_hg19)

hg38_converted <- civic_hg19_partial %>%
  inner_join(
    civic_coords_hg38_converted,
    by = "variant_id", 
    suffix = c("", "_hg38"),
    relationship = "many-to-many"
  ) %>%
  select(-chromosome, -start, -stop) %>%
  mutate(chromosome = chromosome_hg38, start = start_hg38, stop = stop_hg38) %>%
  select(-chromosome_hg38, -start_hg38, -stop_hg38)

hg19_complete <- rbind(civic_hg19_partial, hg19_converted)
hg38_complete <- rbind(civic_hg38_partial, hg38_converted)

hg19_processed <- process_civic(hg19_complete)
hg38_processed <- process_civic(hg38_complete)

diseases <- unique(na.omit(rbind(
  hg19_complete[,c("disease", "doid")],
  setNames(hg19_complete[, c("disease_2", "doid_2")], c("disease", "doid")),
  hg38_complete[,c("disease", "doid")],
  setNames(hg38_complete[, c("disease_2", "doid_2")], c("disease", "doid"))
)))

saveRDS(hg19_processed, file.path(database_path, "hg19/civic_database.rds"))
saveRDS(hg38_processed, file.path(database_path, "hg38/civic_database.rds"))
saveRDS(diseases, file.path(database_path, "civic_diseases.rds"))
