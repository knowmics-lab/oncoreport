#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 5) {
  cat(
    "Usage: process_dois.R <civic_file> <cgi_file> <diseases_map_file>",
    "<output_file> <parents_output_file>\n"
  )
  quit(status = 1)
}

civic_file          <- args[1]
cgi_file            <- args[2]
diseases_map_file   <- args[3]
output_file         <- args[4]
parents_output_file <- args[5]

if (!file.exists(civic_file)) {
  cat("CIVIC file not found\n")
  quit(status = 1)
}
if (!file.exists(cgi_file)) {
  cat("CGI file not found\n")
  quit(status = 1)
}
if (!file.exists(diseases_map_file)) {
  cat("Diseases map file not found\n")
  quit(status = 1)
}

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fuzzyjoin)
  library(ontologyIndex)
})

tmp_file     <- tempfile()
download_url <- paste0(
  "https://raw.githubusercontent.com/DiseaseOntology/HumanDiseaseOntology/",
  "main/src/ontology/doid.obo"
)
download.file(download_url, tmp_file)
onto         <- get_ontology(tmp_file)
unlink(tmp_file)

to_key <- function(column) (gsub("[^[:alnum:] ]|\\s+", "", gsub("'s", "", gsub("\U00F6", "oe", tolower(unname(column))))))

df_onto <- data.frame(
  doid = gsub("DOID:", "", names(onto$name)),
  name = unname(onto$name),
  key = to_key(onto$name),
  doid_orig = names(onto$name)
)

civic_diseases <- readRDS(civic_file)
cgi            <- readRDS(cgi_file)
disease_map    <- suppressWarnings(suppressMessages(read_delim(diseases_map_file, delim = "\t", escape_double = FALSE, trim_ws = TRUE)))

civic_diseases$key <- to_key(civic_diseases$disease)

cgidb_diseases <-
  data.frame(disease = unique(cgi$Disease)) %>%
  mutate(key = to_key(disease)) %>%
  stringdist_left_join(civic_diseases, by = "key", max_dist = 2, distance_col = "dist") %>%
  group_by(disease = disease.x, key = key.x) %>%
  summarise(
    doid = doid[which.min(dist)[1]]
  ) %>%
  left_join(disease_map, by = c("disease" = "Disease")) %>%
  mutate(key1 = to_key(Disease1)) %>%
  stringdist_left_join(df_onto, by = c("key1" = "key"), max_dist = 2, distance_col = "dist") %>%
  group_by(disease, doid.x) %>%
  summarise(
    doid.y = doid.y[which.min(dist)[1]]
  ) %>%
  mutate(doid = ifelse(is.na(doid.x), doid.y, doid.x)) %>%
  select(disease, doid) %>%
  unique()

civic_diseases <- civic_diseases[, c("disease", "doid")]

tumor_doid <- paste0("DOID:", trimws(na.omit(unique(c(cgidb_diseases$doid, civic_diseases$doid, "0050869", "0060108")))))

recursive_child_finder <- function(doid) {
  children <- onto$children[[doid]]
  if (length(children) == 0) {
    return(doid)
  }
  return(unique(c(doid, unname(unlist(lapply(children, recursive_child_finder))))))
}

tumor_doid_list <- setNames(lapply(tumor_doid, recursive_child_finder), tumor_doid)
all_tumors_doid <- unique(unname(unlist(tumor_doid)))
df_tumor_doid   <- data.frame(
  doid = gsub("DOID:", "", rep(tumor_doid, sapply(tumor_doid_list, length))),
  rdoid = unname(unlist(tumor_doid_list))
)
all_db_diseases <- rbind(civic_diseases, cgidb_diseases)
all_db_diseases <- all_db_diseases[order(all_db_diseases$disease), ]
all_db_diseases <- all_db_diseases %>%
  left_join(df_tumor_doid, by = "doid", relationship = "many-to-many") %>%
  left_join(df_onto, by = c("rdoid" = "doid_orig")) %>%
  select(disease, name, rdoid)
all_db_diseases$tumor <- 1
all_db_diseases$general <- 0
all_db_diseases$general[is.na(all_db_diseases$name)] <- 1
all_db_diseases$name[is.na(all_db_diseases$name)] <- all_db_diseases$disease[is.na(all_db_diseases$name)]
all_db_diseases   <- all_db_diseases[!is.na(all_db_diseases$name), ]
onto_remaining    <- df_onto[!(df_onto$doid_orig %in% na.omit(all_db_diseases$rdoid)), ]
all_onto_diseases <- data.frame(
  disease = onto_remaining$name,
  name = onto_remaining$name,
  rdoid = onto_remaining$doid_orig,
  tumor = 0,
  general = 0
)
final_db_diseases <- rbind(all_db_diseases, all_onto_diseases)
colnames(final_db_diseases) <- c(
  "Database_name", "DO_name", "DOID", "tumor", "general"
)
final_db_diseases <- final_db_diseases[grepl("^DOID", final_db_diseases$DOID), ]
final_db_diseases <- final_db_diseases[!onto$obsolete[final_db_diseases$DOID], ]
final_db_diseases$DO_name <- gsub("–", "-", final_db_diseases$DO_name)
final_db_diseases <- unique(final_db_diseases)

write_tsv(final_db_diseases, output_file, quote = "all")

remove_parents <- function(x) {
  return(x[!(x %in% c("DOID:0050687"))])
}

onto$parents <- setNames(
  lapply(
    onto$parents,
    function(x) (remove_parents(x[order(as.numeric(gsub("DOID:", "", x)), decreasing = TRUE)]))
  ),
  names(onto$parents)
)

df_parents <- data.frame(
  doid = names(onto$parents),
  parents = unname(sapply(onto$parents, function(x) (paste0(x, collapse = ";"))))
)
df_parents <- df_parents[df_parents$parents != "", ]
write_tsv(df_parents, parents_output_file, quote = "all")
