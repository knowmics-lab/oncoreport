#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2) {
  stop("Usage: process_refgene.R <input_vcf> <output_file>")
}

suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(stringr))

input_file <- args[1]
output_file <- args[2]

ref <- read.csv(input_file, sep = "\t", header = FALSE)
names(ref) <- c(
  "bin", "name", "Chromosome", "strand", "txStart", "txEnd", "cdsStart",
  "cdsEnd", "exonCount", "exonStarts", "exonEnds", "score", "Gene"
)
ref <- unique(ref[, c(
  "bin", "name", "Chromosome", "strand", "txStart", "txEnd", "cdsStart",
  "cdsEnd", "score", "Gene"
)])
saveRDS(ref, output_file)
unlink(input_file)
