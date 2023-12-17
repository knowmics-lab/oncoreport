#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1) {
  stop("Usage: process_versions.R <versions.txt_file_path>")
}

versions_file <- args[1]

versions <- readr::read_tsv(versions_file, col_names = FALSE)
versions <- unique(versions)
colnames(versions) <- c("database", "version", "download_date")
versions <- versions[order(versions$database), ]
readr::write_tsv(versions, versions_file, quote = "needed")
