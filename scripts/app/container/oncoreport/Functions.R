create.dummy.type <- function(x) {
  x$Type <- rep("NA", nrow(x))
  return(x)
}

pharm_urls <- function(x, project_path, sample_name) {
  x[is.na(x)] <- " "
  x$Clinical_significance <-
    gsub(pattern = " ", replace = "", x$Clinical_significance)
  x <- x[order(x$Gene, x$Variant, x$Drug, x$Clinical_significance, x$PMID), ]
  list_pubmed <- list_pubmed_urls(x, "pharm")
  write.table(
    list_pubmed,
    paste0(project_path, "/txt/reference/", sample_name, "_pharm.txt"),
    quote = FALSE, row.names = FALSE, na = "NA", sep = "\t"
  )
}

cosmic_urls <- function(x, project_path, sample_name) {
  x[is.na(x)] <- " "
  names(x)[names(x) == "Primary.Tissue"] <- "Primary_tissue"
  x <- x[order(x$Gene, x$Variant, x$Drug, x$Primary_tissue, x$PMID), ]
  list_pubmed <- list_pubmed_urls(x, "cosmic")
  write.table(
    list_pubmed,
    paste0(project_path, "/txt/reference/", sample_name, "_cosmic.txt"),
    quote = FALSE, row.names = FALSE, na = "NA", sep = "\t"
  )
}

leading_urls <- function(x, leading_disease, dis, project_path, sample_name) {
  db_diseases <- dis$Database_name[dis$DOID == leading_disease]
  selection <- x$Evidence_direction == "Supports" & x$Disease %in% db_diseases
  x <- x[selection, , drop = FALSE]
  x[is.na(x)] <- " "
  x$Drug_interaction_type <- gsub(" ", "", x$Drug_interaction_type)
  x$Evidence_type <- factor(
    x$Evidence_type,
    levels = c(
      "Diagnostic", "Prognostic", "Predisposing",
      "Predictive", "Oncogenic", "Functional"
    )
  )
  x$Evidence_level <- factor(
    x$Evidence_level,
    levels = c(
      "Validated association", "FDA guidelines", "NCCN guidelines",
      "Clinical evidence", "Late trials", "Early trials", "Case study",
      "Case report", "Preclinical evidence", "Pre-clinical",
      "Inferential association"
    )
  )
  x <- x[order(
    x$Gene, x$Evidence_level, x$Evidence_type, x$Variant, x$Drug,
    x$Drug_interaction_type, x$Clinical_significance, x$PMID
  ), ]
  list_pubmed <- list_pubmed_urls(x, "leading")
  list_trials <- list_trials_urls(x, "leading")
  write.table(list_pubmed,
    paste0(project_path, "/txt/reference/", sample_name, ".txt"),
    quote = FALSE, row.names = FALSE, na = "NA", sep = "\t"
  )
  write.table(list_trials,
    paste0(project_path, "/txt/trial/", sample_name, ".txt"),
    quote = FALSE, row.names = FALSE, na = "NA", sep = "\t"
  )
}

off_urls <- function(x, leading_disease, dis, project_path, sample_name) {
  db_diseases <- dis$Database_name[dis$DOID == leading_disease]
  selection <- x$Evidence_direction == "Supports" &
    !(x$Disease %in% db_diseases)
  x <- x[selection, , drop = FALSE]
  x[is.na(x)] <- " "
  x$Drug <- as.character(x$Drug, levels = (x$Drug))
  x$Evidence_type <- factor(
    x$Evidence_type,
    levels = c(
      "Diagnostic", "Prognostic", "Predisposing", "Predictive",
      "Oncogenic", "Functional"
    )
  )
  x$Evidence_level <- factor(
    x$Evidence_level,
    levels = c(
      "Validated association", "FDA guidelines", "NCCN guidelines",
      "Clinical evidence", "Late trials", "Early trials", "Case study",
      "Case report", "Preclinical evidence", "Pre-clinical",
      "Inferential association"
    )
  )
  x <- x[order(
    x$Disease, x$Evidence_level, x$Evidence_type, x$Gene, x$Variant,
    x$Drug, x$Clinical_significance, x$PMID
  ), ]
  list_pubmed <- list_pubmed_urls(x, "off")
  list_trials <- list_trials_urls(x, "off")
  write.table(list_pubmed,
    paste0(project_path, "/txt/reference/", sample_name, "_off.txt"),
    quote = FALSE,
    row.names = FALSE, na = "NA", sep = "\t"
  )
  write.table(list_trials,
    paste0(project_path, "/txt/trial/", sample_name, "_off.txt"),
    quote = FALSE, row.names = FALSE, na = "NA", sep = "\t"
  )
}

list_pubmed_urls <- function(x, type) {
  if (nrow(x) == 0) {
    return(
      switch(type,
        "leading" = data.frame(
          Citation = character(), Gene = character(), PMID = character(),
          URL = character(), Reference = character()
        ),
        "off" = data.frame(
          Citation = character(), Disease = character(), PMID = character(),
          URL = character(), Reference = character()
        ),
        data.frame(
          Citation = character(), Disease = character(), PMID = character(),
          URL = character(), Reference = character()
        )
      )
    )
  }

  if (type == "leading") {
    link_pmid <- x[, c("Citation", "Gene", "PMID")]
  } else if (type == "off") {
    link_pmid <- x[, c("Citation", "Disease", "PMID")]
  } else {
    link_pmid <- x[, c("Gene", "PMID")]
  }
  link_pmid <- unique(link_pmid)
  link_pmid$URL <- paste0(
    "https://www.ncbi.nlm.nih.gov/pubmed/", link_pmid$PMID
  )
  list_urls <- unique(link_pmid$URL)
  y <- setNames(sapply(list_urls, url.exists), list_urls)
  r <- setNames(seq_along(list_urls), list_urls)
  link_pmid <- link_pmid[unname(y[link_pmid$URL]), ]
  link_pmid$Reference <- unname(r[link_pmid$URL])
  return(link_pmid)
}

list_trials_urls <- function(x, type) {
  if (nrow(x) == 0) {
    if (type == "leading") {
      return(data.frame(
        Gene = character(), Variant = character(),
        Drug = character(), PMID = character(),
        Clinical_trial = character()
      ))
    }
    return(data.frame(
      Disease = character(), Gene = character(),
      Variant = character(), Drug = character(),
      PMID = character(), Clinical_trial = character()
    ))
  }

  if (type == "leading") {
    link_cli <- x[, c("Gene", "Variant", "Drug", "PMID")]
  } else {
    link_cli <- x[, c("Disease", "Gene", "Variant", "Drug", "PMID")]
  }
  link_cli <- unique(link_cli)
  link_cli <- link_cli[link_cli$Drug != "" & link_cli$Gene != link_cli$Drug, ]
  link_cli$Clinical_trial <- paste0(
    "https://clinicaltrials.gov/ct2/results?cond=",
    link_cli$Variant, "&term=",
    gsub(" ", "%20", link_cli$Drug, fixed = TRUE),
    "&cntry=&state=&city=&dist="
  )
  list_urls <- unique(link_cli$Clinical_trial)
  y <- setNames(sapply(list_urls, url.exists), list_urls)
  return(link_cli[unname(y[link_cli$Clinical_trial]), ])
}

join.and.write <- function(
    variants, db, selected_columns = NULL, output_file,
    genome, db_path, check_for_type = FALSE, check_alt_base = FALSE) {
  data <- fread(paste0(db_path, "/", db, "_", genome, ".txt", quote = ""))
  if (check_alt_base && any(colnames(data) == "Alt_base")) {
    colnames(data)[colnames(data) == "Alt_base"] <- "Var_base"
  }
  data <- suppressMessages(data %>% inner_join(variants))
  if (check_for_type) {
    data$Type <- rep("NA", nrow(data))
  }
  if (!is.null(selected_columns)) {
    data <- data.frame(data)[, selected_columns, drop = FALSE]
  }
  write.table(data, output_file,
    quote = FALSE, row.names = FALSE,
    na = "NA", sep = "\t"
  )
  return(data.frame(data))
}

join_and_write_rds <- function(
    variants, db, selected_columns = NULL, output_file,
    db_path, check_for_type = FALSE, check_alt_base = FALSE) {
  data <- readRDS(file.path(db_path, paste0(db, ".rds")))
  if (check_alt_base && any(colnames(data) == "Alt_base")) {
    colnames(data)[colnames(data) == "Alt_base"] <- "Var_base"
  }
  data$Stop <- as.integer(data$Stop)
  data <- suppressMessages(data %>% inner_join(variants))
  if (check_for_type) {
    data$Type <- rep("NA", nrow(data))
  }
  if (!is.null(selected_columns)) {
    data <- data.frame(data)[, selected_columns, drop = FALSE]
  }
  write.table(data, output_file,
    quote = FALSE, row.names = FALSE,
    na = "NA", sep = "\t"
  )
  return(data.frame(data))
}
