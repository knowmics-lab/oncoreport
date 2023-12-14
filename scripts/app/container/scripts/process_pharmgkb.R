#!/usr/bin/env Rscript

# Load libraries
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))

# get arguments
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4) {
  cat(
    "Usage: process_pharmgkb.R <var_pheno_ann_file>",
    "<chr_file> <dbsnp_dir> <output_file>\n"
  )
  quit(status = 1)
}
var_pheno_ann_file <- args[1]
chr_file <- args[2]
dbsnp_dir <- args[3]
output_file <- args[4]

cat("Reading PharmGKB variant-phenotype annotation file...")
var_pheno_ann <- fread(var_pheno_ann_file, sep = "\t", header = TRUE)
colnames(var_pheno_ann) <- make.names(colnames(var_pheno_ann))
colnames(var_pheno_ann)[1] <- "Annotation.ID"
colnames(var_pheno_ann)[2] <- "ID"
colnames(var_pheno_ann)[4] <- "Chemical"

cat("Reading chromosome file...")
chrs <- fread(chr_file, sep = "\t", header = FALSE)
colnames(chrs) <- c("ChrID", "Chr")
chrs[[2]][chrs[[2]] == "na"] <- NA
chrs <- unique(na.omit(chrs))

cat("Reading PharmGKB dbSNP file list...")
dbsnp_files <- list.files(dbsnp_dir, full.names = TRUE)
cat("Found", length(dbsnp_files), "files\n")
dbsnp_all_data <- lapply(dbsnp_files, function(f) {
  cat(" - Processing", f, "...\n")
  dbsnp_data <- fread(f, sep = "\t", header = FALSE)
  colnames(dbsnp_data) <- c("ChrID", "Position", "ID", "REF", "Alt_base")
  suppressWarnings({
    dbsnp_data <- dbsnp_data %>%
      inner_join(chrs, by = "ChrID") %>%
      inner_join(var_pheno_ann, by = "ID") %>%
      separate_rows(Alt_base, sep = ",") %>%
      unique()
  })
  if (nrow(dbsnp_data) == 0) {
    return(NULL)
  }
  tryCatch(
    {
      dbsnp_data$Stop <- dbsnp_data$Position +
        sapply(dbsnp_data$REF, length) - 1
    },
    error = function(...) {
      dbsnp_data$Stop <- dbsnp_data$Position
    }
  )
  dbsnp_data <- dbsnp_data %>%
    select(
      Chromosome = Chr, Start = Position, Stop, REF, Alt_base, Gene,
      Sentence, Notes, Significance, Phenotype.Category, PMID, Chemical,
      Annotation.ID, ID
    )
  return(dbsnp_data)
})

cat("Merging data...")
dbsnp_all_data <- dbsnp_all_data[sapply(dbsnp_all_data, is.null) == FALSE]
pharmgkb_data <- na.omit(do.call(rbind, dbsnp_all_data))
pharmgkb_data <- unique(pharmgkb_data) %>%
  group_by(Chromosome, Start, Stop, REF, Alt_base, Gene) %>%
  summarize_all(function(x) (trimws(paste(x, collapse = ";;"))))

names(pharmgkb_data) <- c("Chromosome", "Start", "Stop", "Ref_base", "Var_base",
                          "Gene", "Variant_summary", "Evidence_statement",
                          "Evidence_level", "Clinical_significance", "PMID",
                          "Drug", "PharmGKB_ID", "Variant")
pharmgkb_data$Database <- "PharmGKB"
pharmgkb_data <- separate_rows(pharm, Variant_summary, Evidence_statement,
                               Evidence_level, Clinical_significance, PMID,
                               Drug, PharmGKB_ID, Variant, sep = ";;")
pharmgkb_data$Gene <- gsub("\\s+\\(.*\\)", "", pharmgkb_data$Gene)
pharmgkb_data$Gene <- gsub(
  pharmgkb_data$Gene, pattern = "*\\(.*?\\) *", replace = ""
)
pharmgkb_data$Drug <- gsub(
  pharmgkb_data$Drug, pattern = "\\\\x2c", replace = ","
)
pharmgkb_data$Drug <- gsub(
  pharmgkb_data$Drug, pattern = "*\\(.*?\\) *", replace = ""
)
pharmgkb_data$Drug <- gsub("\\s+", " ", trimws(pharmgkb_data$Drug))
pharmgkb_data$Drug <- gsub(",\\s+", ",", pharmgkb_data$Drug)
pharmgkb_data$Drug <- gsub("(.+)\\s*/\\s*(.+)", "\\1,\\2", pharmgkb_data$Drug)
pharmgkb_data$Drug <- unname(
  sapply(
    pharmgkb_data$Drug, 
    function(x) (paste0(str_to_title(strsplit(x, ",")[[1]]), collapse = ","))
  )
)
pharmgkb_data$Variant_summary <- gsub(
  pharmgkb_data$Variant_summary, pattern = "\\\\x2c", replace = ","
)
pharmgkb_data$Clinical_significance <- gsub(
  pattern = " ", replace = "", pharmgkb_data$Clinical_significance
)
pharmgkb_data$Evidence_statement <- gsub(
  pharmgkb_data$Evidence_statement, pattern = "\\\\x2c", replace = ","
)
pharmgkb_data <- subset.data.frame(pharmgkb_data, Evidence_level == "yes")
cat("Saving data...")
saveRDS(pharmgkb_data, file = output_file)
cat("done\n")
