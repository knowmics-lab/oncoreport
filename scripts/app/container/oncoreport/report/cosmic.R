cat("Building COSMIC Report File\n")

template.env$cosmic <- list(
  summary = NULL,
  details = NULL
)
.variables.to.keep <- ls()

cosmic_references <- read.csv(paste0(path_project, "/txt/reference/", pt_fastq, "_cosmic.txt"),
  sep = "\t",
  colClasses = "character", stringsAsFactors = FALSE
)
cosmic_references <- cosmic_references[, c("PMID", "Reference")]

cosmic_data_orig <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_cosmic.txt"),
  sep = "\t",
  colClasses = "character", stringsAsFactors = FALSE
)
cosmic_data <- cosmic_data_orig %>%
  select(Gene, Variant, Drug, Primary.Tissue, PMID) %>%
  distinct() %>%
  inner_join(cosmic_references) %>%
  arrange(Gene, Variant, Drug, Primary.Tissue, Reference) %>%
  mutate(
    Primary.Tissue = gsub("_", " ", Primary.Tissue, perl = FALSE, fixed = TRUE),
    Reference = paste0('<a href="Javascript:;" class="ref-link" data-id="#cosmic-', Reference, '">', Reference, "</a>")
  ) %>%
  select(Gene, Variant, Drug, Primary.Tissue, Reference) %>%
  group_by(Gene, Variant, Drug, Primary.Tissue) %>%
  summarise(Reference = paste(Reference, collapse = ","))
if (nrow(cosmic_data) > 0) {
  cosmic_data$Number <- seq_len(nrow(cosmic_data))
  cosmic_data <- cosmic_data[, c("Number", "Gene", "Variant", "Drug", "Primary.Tissue", "Reference")]
  names(cosmic_data) <- c("#", "Gene", "Variant", "Drug", "Primary Tissue", "References")
  table <- kable(cosmic_data, "html", escape = FALSE) %>%
    kable_styling(bootstrap_options = c("striped", "hover", "condensed"))
  genes <- unique(cosmic_data$Gene)
  if (length(genes) > 1) {
    for (g in genes) {
      rows <- which(cosmic_data$Gene == g)
      if (length(rows) > 0) {
        rng <- range(rows)
        table <- table %>% pack_rows(group_label = g, start_row = rng[1], end_row = rng[2], indent = FALSE)
      }
    }
  }
  template.env$cosmic$summary <- table
}

if (nrow(cosmic_data_orig) > 0) {
  cosmic_data_orig[is.na(cosmic_data_orig$Var_base), "Var_base"] <- "T"
  cosmic_data_orig[is.na(cosmic_data_orig$Ref_base), "Ref_base"] <- "T"
}
cosmic_data_details <- cosmic_data_orig %>%
  select(Gene, Variant, Chromosome, Ref_base, Var_base, Start, Stop) %>%
  mutate(
    Start = format(as.numeric(Start), big.mark = ",", scientific = FALSE),
    Stop = format(as.numeric(Stop), big.mark = ",", scientific = FALSE)
  ) %>%
  arrange(Gene, Variant) %>%
  distinct()
if (nrow(cosmic_data_details) > 0) {
  rownames(cosmic_data_details) <- NULL
  names(cosmic_data_details) <- c("Gene", "Variant", "Chromosome", "Ref. Base", "Var. Base", "Start", "Stop")
  table <- kable(cosmic_data_details, "html", escape = FALSE) %>%
    kable_styling(bootstrap_options = c("striped", "hover", "condensed"))
  genes <- unique(cosmic_data_details$Gene)
  if (length(genes) > 1) {
    for (g in genes) {
      rows <- which(cosmic_data_details$Gene == g)
      if (length(rows) > 0) {
        rng <- range(rows)
        table <- table %>% pack_rows(group_label = g, start_row = rng[1], end_row = rng[2], indent = FALSE)
      }
    }
  }
  template.env$cosmic$details <- table
}

brew(
  file = paste0(path_html_source, "/cosmic.html"),
  output = paste0(report_output_dir, "cosmic.html"),
  envir = template.env
)

rm(list = setdiff(ls(), .variables.to.keep))
