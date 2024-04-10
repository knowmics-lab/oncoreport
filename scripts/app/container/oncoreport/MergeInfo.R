#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(optparse)
  library(readr)
  library(dplyr)
  library(data.table)
  library(RCurl)
  library(tidyr)
  library(fuzzyjoin)
  library(IRanges)
})

option_list <- list(
  make_option(
    c("-g", "--genome"),
    type = "character", default = NULL,
    help = "human genome version (hg19 or hg38)", metavar = "character"
  ),
  make_option(
    c("-d", "--database"),
    type = "character", default = NULL,
    help = "databases folder", metavar = "character"
  ),
  make_option(
    c("-c", "--cosmic"),
    type = "character", default = NULL,
    help = "cosmic folder", metavar = "character"
  ),
  make_option(
    c("-p", "--project"),
    type = "character", default = NULL,
    help = "project folder", metavar = "character"
  ),
  make_option(
    c("-s", "--sample"),
    type = "character", default = NULL,
    help = "sample name", metavar = "character"
  ),
  make_option(
    c("-t", "--tumor"),
    type = "character", default = NULL,
    help = "patient tumor", metavar = "character"
  )
)

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

if (is.null(opt$genome) || !(opt$genome %in% c("hg19", "hg38"))) {
  print_help(opt_parser)
  stop("Invalid genome", call. = FALSE)
}
if (is.null(opt$database) || !dir.exists(opt$database)) {
  print_help(opt_parser)
  stop("Databases path does not exist", call. = FALSE)
}
if (is.null(opt$cosmic) || !dir.exists(opt$cosmic)) {
  print_help(opt_parser)
  stop("COSMIC path does not exist", call. = FALSE)
}
if (is.null(opt$project) || !dir.exists(opt$project)) {
  print_help(opt_parser)
  stop("Project folder does not exist", call. = FALSE)
}
if (is.null(opt$sample) || is.null(opt$tumor)) {
  print_help(opt_parser)
  stop("All parameters are required", call. = FALSE)
}

genome <- opt$genome
database_path <- opt$database
cosmic_path <- opt$cosmic
project_path <- opt$project
sample_name <- opt$sample
leading_disease <- opt$tumor
genome_path <- file.path(database_path, genome)
cosmic_genome_path <- file.path(cosmic_path, genome)

this_file <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  needle <- "--file="
  match <- grep(needle, args)
  if (length(match) > 0) {
    # Rscript
    return(normalizePath(sub(needle, "", args[match])))
  } else {
    # 'source'd via R console
    return(normalizePath(sys.frames()[[1]]$ofile))
  }
}

source(file.path(dirname(this_file()), "report/constants.R"))
source(file.path(dirname(this_file()), "Functions.R"))

variants_path <- file.path(project_path, "txt/variants.txt")
variants <- suppressWarnings(fread(variants_path))
variants$Chromosome <- as.character(variants$Chromosome)
variants$Ref_base <- as.character(variants$Ref_base)
variants$Var_base <- as.character(variants$Var_base)
pat <- variants %>% select(
  Chromosome, Stop, Ref_base, Var_base, Type
)

output_path <- function(type) {
  return(
    file.path(project_path, "txt", paste0(sample_name, "_", type, ".txt"))
  )
}

## Merge with CIVIC
cat("Annotating with CIVIC...\n")
civic <- join_and_write_rds(
  variants = pat,
  db = "civic_database",
  selected_columns = c(
    "Database", "Gene", "Variant", "Disease", "Drug",
    "Drug_interaction_type", "Evidence_type", "Evidence_level",
    "Evidence_direction", "Clinical_significance",
    "Evidence_statement", "Variant_summary", "PMID", "Citation",
    "Chromosome", "Start", "Stop", "Ref_base", "Var_base", "Type"
  ),
  output_file = output_path("civic"),
  db_path = genome_path,
  separate_rows_by = c("PMID", "Citation")
)

## Merge with Clinvar
cat("Annotating with Clinvar...\n")
d <- join_and_write_rds(
  variants = variants,
  db = "clinvar_database",
  selected_columns = c(
    "Chromosome", "Stop", "Ref_base", "Var_base", "Change_type",
    "Clinical_significance", "AF", "DP", "GT", "VT", "Type"
  ),
  output_file = output_path("clinvar"),
  db_path = genome_path
)

# Merge with COSMIC
cat("Annotating with COSMIC...\n")
cosmic <- join_and_write_rds(
  variants = pat,
  db = "cosmic_database",
  selected_columns = NULL,
  output_file = output_path("cosmic"),
  db_path = cosmic_genome_path
)

f <- join_and_write_rds(
  variants = variants,
  db = "cosmic_all_variants_database",
  selected_columns = NULL,
  output_file = output_path("cosmic_all_variants"),
  db_path = cosmic_genome_path,
  check_alt_base = TRUE
)

# Merge with PharmGKB
cat("Annotating with PharmGKB...\n")
pharm <- join_and_write_rds(
  variants = pat,
  db = "pharm_database",
  selected_columns = c(
    "Database", "Gene", "Variant_summary", "Evidence_statement",
    "Evidence_level", "Clinical_significance", "PMID", "Drug",
    "PharmGKB_ID", "Variant", "Chromosome", "Start", "Stop",
    "Ref_base", "Var_base", "Type"
  ),
  output_file = output_path("pharm"),
  db_path = genome_path
)

# Merge with RefGene
cat("Annotating with RefGene...\n")
if (nrow(pat) > 0) {
  data <- readRDS(file.path(genome_path, "refgene_database.rds"))
  tmp_pat <- pat
  tmp_pat$txStart <- tmp_pat$Stop
  tmp_pat$txEnd <- tmp_pat$Stop
  data <- genome_left_join(
    tmp_pat, data,
    by = c("Chromosome", "txStart", "txEnd")
  )
  columns <- c("Chromosome.x", "Stop", "Ref_base", "Var_base", "Gene", "Type")
  data <- data[, columns]
  colnames(data)[1] <- "Chromosome"
  data <- unique(data)
} else {
  data <- data.frame(
    Chromosome = character(0), Stop = character(0), Ref_base = character(0),
    Var_base = character(0), Gene = character(0), Type = character(0)
  )
}
write.table(
  data, output_path("refgene"),
  quote = FALSE, row.names = FALSE, na = "NA",
  sep = "\t"
)

# Merge with CGI
cat("Annotating with CGI...\n")
cgi <- join_and_write_rds(
  variants = pat,
  db = "cgi_database",
  selected_columns = c(
    "Database", "Gene", "Variant", "Disease", "Drug",
    "Drug_interaction_type", "Evidence_type", "Evidence_level",
    "Evidence_direction", "Clinical_significance",
    "Evidence_statement", "Variant_summary", "PMID", "Citation",
    "Chromosome", "Start", "Stop", "Ref_base", "Var_base", "Type"
  ),
  output_file = output_path("cgi"),
  db_path = genome_path,
  separate_rows_by = c("PMID", "Citation")
)

cat("Reading OncoKB annotations...\n")
if (file.exists(output_path("oncokb"))) {
  oncokb <- read.delim(output_path("oncokb")) %>%
    tidyr::separate_rows(PMID, Citation, sep = ";;") %>%
    unique()
  # Fix PMID and Citation columns for the score computation
  # We will use the most recent publication
  # for (i in seq_len(nrow(oncokb))) {
  #   parts <- strsplit(oncokb$Citation[i], ";;")[[1]]
  #   if (length(parts) > 1) {
  #     selected <- which.max(as.numeric(
  #       gsub(".*,([0-9]{4})", "\\1", parts, perl = TRUE)
  #     ))
  #     pmid <- strsplit(oncokb$PMID[i], ";;")[[1]][selected]
  #     oncokb$PMID[i] <- pmid
  #     oncokb$Citation[i] <- parts[selected]
  #   }
  # }
} else {
  oncokb <- NULL
}

# Merge CIVIC and CGI info
cat("Combining CIVIC, CGI, and OncoKB...\n")
def <- merge(civic, cgi, all = TRUE)
if (!is.null(oncokb)) {
  def <- merge(def, oncokb, all = TRUE)
}
def$Disease[
  def$Disease %in% c("All Solid Tumors", "All Liquid Tumors", "All Tumors")
] <- "Any cancer type"
def$Clinical_significance[
  def$Clinical_significance == "Responsive"
] <- "Sensitivity/Response"
def$Clinical_significance[
  def$Clinical_significance == "Resistant"
] <- "Resistance"

cat("Annotating Agency Approval...\n")
drug <- readRDS(file.path(database_path, "approved_drugs.rds"))
drug_map <- setNames(drug[[2]], drug[[1]])
def$Approved <- unname(sapply(
  def$Drug,
  function(x) {
    (
      ifelse(is.na(x), "", paste0(
        sapply(
          drug_map[unlist(strsplit(x, ",", fixed = TRUE))],
          function(x) (ifelse(is.na(x), "", x))
        ),
        collapse = ","
      ))
    )
  }
))
def$Approved <- gsub("^,*|(?<=,),|,*$", "", def$Approved, perl = TRUE)
def <- def[, c(
  "Database", "Gene", "Variant", "Disease", "Drug", "Drug_interaction_type",
  "Evidence_type", "Evidence_level", "Evidence_direction",
  "Clinical_significance", "Evidence_statement", "Variant_summary", "PMID",
  "Citation", "Chromosome", "Start", "Stop", "Ref_base", "Var_base", "Type",
  "Approved"
)]

def$Approved <- gsub("^,*|(?<=,),|,*$", "", def$Approved, perl = TRUE)

# Score
cat("Computing scores with dbNSFP...\n")
dbnsfp <- readRDS(file.path(genome_path, "dbNSFP.rds"))
colnames(dbnsfp)[1:5] <- c(
  "Chromosome", "Start", "Stop", "Ref_base", "Var_base"
)
dbnsfp$Chromosome <- paste0("chr", dbnsfp$Chromosome)
def$Start <- as.numeric(def$Start)
def$Stop <- as.numeric(def$Stop)
if (!is.character(def$Chromosome)) { # This should never happen but just in case
  def$Chromosome <- paste0("chr", def$Chromosome)
}
tot <- def %>% inner_join(dbnsfp)
if (nrow(tot) != 0) {
  matr <- apply(tot, 1, function(row) {
    return(sum(
      switch(row["SIFT_pred"],
        "D" = 1,
        "." = -1,
        0
      ),
      switch(row["MutationTaster_pred"],
        "A" = 1,
        "D" = 0.7,
        "N" = 0.3,
        "." = -1,
        0
      ),
      switch(row["MutationAssessor_pred"],
        "H" = 1,
        "M" = 0.7,
        "L" = 0.3,
        "." = -1,
        0
      ),
      switch(row["LRT_pred"],
        "D" = 1,
        "U" = -1,
        "." = -1,
        0
      ),
      switch(row["FATHMM_pred"],
        "D" = 1,
        "." = -1,
        0
      ),
      switch(row["PROVEAN_pred"],
        "D" = 1,
        "." = -1,
        0
      ),
      switch(row["fathmm-MKL_coding_pred"],
        "D" = 1,
        "." = -1,
        0
      ),
      switch(row["MetaSVM_pred"],
        "D" = 1,
        "." = -1,
        0
      ),
      switch(row["MetaLR_pred"],
        "D" = 1,
        "." = -1,
        0
      )
    ))
  })
  tot$Score <- matr
  def <- merge(tot, def, all = TRUE)
  def$Score[is.na(def$Score)] <- 0
  def <- def[, c(
    "Database", "Gene", "Variant", "Disease", "Drug", "Drug_interaction_type",
    "Evidence_type", "Evidence_level", "Evidence_direction",
    "Clinical_significance", "Evidence_statement", "Variant_summary", "PMID",
    "Citation", "Chromosome", "Start", "Stop", "Ref_base", "Var_base", "Type",
    "Approved", "Score"
  )]
} else {
  def$Score <- rep(0, nrow(def))
}
write.table(
  def, output_path("definitive"),
  quote = FALSE, row.names = FALSE, na = "NA",
  sep = "\t"
)
# Food interactions
cat("Processing drug-food interactions...\n")
drugs <- gsub("\\\"+", "\"", c(def$Drug, pharm$Drug), perl = TRUE)
to_clean <- grep("\\\"", drugs, value = TRUE)
to_split <- grep("\\\"", drugs, value = TRUE, invert = TRUE)
list_drugs <- unique(unlist(strsplit(to_split, ",")))
if (length(to_clean) > 0) {
  cleaned <- sapply(lapply(strsplit(to_clean, "\\\""), function(x) {
    x[x != ","] <- gsub(",", "\\,", x[x != ","], fixed = TRUE)
    return(x)
  }), function(x) (paste0(x, collapse = "")))
  cleaned <- unique(gsub(
    pattern = "(\\\\,.*)",
    replacement = "",
    x = unlist(
      strsplit(x = cleaned, split = "(?<!\\\\),", perl = TRUE)
    ),
    perl = TRUE
  ))
  list_drugs <- unique(c(list_drugs,cleaned))
}
list_drugs <- na.omit(list_drugs)
drugfood <- readRDS(file.path(database_path, "drugfood_database.rds"))
drugfood <- drugfood[drugfood$Drug %in% list_drugs, ]
write.table(
  drugfood, output_path("drugfood"),
  quote = FALSE, row.names = FALSE, na = "NA",
  sep = "\t"
)


# Create Pubmed URLs and links to clinical trials
dis <- read.csv(
  file.path(database_path, "diseases.tsv"),
  sep = "\t",
  stringsAsFactors = FALSE
)
# Leading disease
cat("Searching URLs related to the primary disease...\n")
leading_urls(def, leading_disease, dis, project_path, sample_name)
# OFF - Other diseases
cat("Searching URLs related to the other diseases...\n")
off_urls(def, leading_disease, dis, project_path, sample_name)
# Cosmic
cat("Searching COSMIC URLs...\n")
cosmic_urls(cosmic, project_path, sample_name)
# PharmGKB
cat("Searching PharmGKB URLs...\n")
pharm_urls(pharm, project_path, sample_name)
