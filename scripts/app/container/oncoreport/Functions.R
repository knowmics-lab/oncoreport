create.dummy.type <- function(x) {
  x$Type <- rep("NA", nrow(x))
  return(x)
}

pharm.urls <- function(x, project.path, sample.name) {
  x[is.na(x)] <- " "
  x$Clinical_significance <- gsub(pattern = " ", replace = "", x$Clinical_significance)
  x <- x[order(x$Gene, x$Variant, x$Drug, x$Clinical_significance, x$PMID),]
  list.pubmed <- list.pubmed.urls(x, "pharm")
  write.table(
    list.pubmed,
    paste0(project.path, "/txt/reference/", sample.name, "_pharm.txt"),
    quote = FALSE, row.names = FALSE, na = "NA", sep = "\t"
  )
}

cosmic.urls <- function(x, project.path, sample.name) {
  x[is.na(x)] <- " "
  names(x)[names(x) == "Primary.Tissue"] <- "Primary_tissue"
  x <- x[order(x$Gene, x$Variant, x$Drug, x$Primary_tissue, x$PMID),]
  list.pubmed <- list.pubmed.urls(x, "cosmic")
  write.table(
    list.pubmed,
    paste0(project.path, "/txt/reference/", sample.name, "_cosmic.txt"),
    quote = FALSE, row.names = FALSE, na = "NA", sep = "\t"
  )
}

leading.urls <- function(x, leading.disease, dis, project.path, sample.name) {
  db_diseases <- dis$Database_name[dis$DOID == leading.disease]
  x <- x[x$Evidence_direction == "Supports" & x$Disease %in% db_diseases, , drop = FALSE]
  x[is.na(x)] <- " "
  x$Drug_interaction_type <- gsub(" ", "", x$Drug_interaction_type)
  x$Evidence_type <- factor(
    x$Evidence_type,
    levels = c("Diagnostic", "Prognostic", "Predisposing", "Predictive", "Oncogenic", "Functional")
  )
  x$Evidence_level <- factor(
    x$Evidence_level,
    levels = c("Validated association", "FDA guidelines", "NCCN guidelines",
               "Clinical evidence", "Late trials", "Early trials", "Case study",
               "Case report", "Preclinical evidence", "Pre-clinical",
               "Inferential association")
  )
  x <- x[order(x$Gene, x$Evidence_level, x$Evidence_type, x$Variant, x$Drug,
               x$Drug_interaction_type, x$Clinical_significance, x$PMID),]
  list.pubmed <- list.pubmed.urls(x, "leading")
  list.trials <- list.trials.urls(x, "leading")
  write.table(list.pubmed, paste0(project.path, "/txt/reference/", sample.name, ".txt"),
              quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")
  write.table(list.trials, paste0(project.path, "/txt/trial/", sample.name, ".txt"),
              quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")
}

off.urls <- function(x, leading.disease, dis, project.path, sample.name) {
  db_diseases <- dis$Database_name[dis$DOID == leading.disease]
  x <- x[x$Evidence_direction == "Supports" & !(x$Disease %in% db_diseases), , drop = FALSE]
  x[is.na(x)] <- " "
  x$Drug <- as.character(x$Drug, levels = (x$Drug))
  x$Evidence_type <- factor(
    x$Evidence_type,
    levels = c("Diagnostic", "Prognostic", "Predisposing", "Predictive", "Oncogenic", "Functional")
  )
  x$Evidence_level <- factor(
    x$Evidence_level,
    levels = c("Validated association", "FDA guidelines", "NCCN guidelines",
               "Clinical evidence", "Late trials", "Early trials", "Case study",
               "Case report", "Preclinical evidence", "Pre-clinical", "Inferential association")
  )
  x <- x[order(x$Disease, x$Evidence_level, x$Evidence_type, x$Gene, x$Variant,
               x$Drug, x$Clinical_significance, x$PMID),]
  list.pubmed <- list.pubmed.urls(x, "off")
  list.trials <- list.trials.urls(x, "off")
  write.table(list.pubmed, paste0(project.path, "/txt/reference/", sample.name, "_off.txt"), quote = FALSE,
              row.names = FALSE, na = "NA", sep = "\t")
  write.table(list.trials, paste0(project.path, "/txt/trial/", sample.name, "_off.txt"),
              quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")
}

list.pubmed.urls <- function(x, type) {
  if (nrow(x) == 0) {
    return(
      switch(
        type,
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
  link_pmid$URL <- paste0("https://www.ncbi.nlm.nih.gov/pubmed/", link_pmid$PMID)
  list.urls <- unique(link_pmid$URL)
  y <- setNames(sapply(list.urls, url.exists), list.urls)
  r <- setNames(seq_along(list.urls), list.urls)
  link_pmid <- link_pmid[unname(y[link_pmid$URL]),]
  link_pmid$Reference <- unname(r[link_pmid$URL])
  return(link_pmid)
}

list.trials.urls <- function(x, type) {
  if (nrow(x) == 0) {
    if (type == "leading") {
      return(data.frame(Gene = character(), Variant = character(),
                        Drug = character(), PMID = character(),
                        Clinical_trial = character()))
    }
    return(data.frame(Disease = character(), Gene = character(),
                      Variant = character(), Drug = character(),
                      PMID = character(), Clinical_trial = character()))
  }

  if (type == "leading") {
    link_cli <- x[, c("Gene", "Variant", "Drug", "PMID")]
  } else {
    link_cli <- x[, c("Disease", "Gene", "Variant", "Drug", "PMID")]
  }
  link_cli <- unique(link_cli)
  link_cli <- link_cli[link_cli$Drug != "" & link_cli$Gene != link_cli$Drug,]
  link_cli$Clinical_trial <- paste0("https://clinicaltrials.gov/ct2/results?cond=",
                                    link_cli$Variant, "&term=",
                                    gsub(" ", "%20", link_cli$Drug, fixed = TRUE),
                                    "&cntry=&state=&city=&dist=")
  list.urls <- unique(link_cli$Clinical_trial)
  y <- setNames(sapply(list.urls, url.exists), list.urls)
  return(link_cli[unname(y[link_cli$Clinical_trial]),])
}

join.and.write <- function(variants, db, selected.columns = NULL, output.file, genome, db.path, check.for.type = FALSE, check.alt.base = FALSE) {
  data <- fread(paste0(db.path, "/", db, "_", genome, ".txt", quote = ""))
  if (check.alt.base && any(colnames(cosmic) == "Alt_base")) {
    colnames(data)[colnames(data) == "Alt_base"] <- "Var_base"
  }
  data <- suppressMessages(data %>% inner_join(variants))
  if (check.for.type) {
    data$Type <- rep("NA", nrow(data))
  }
  if (!is.null(selected.columns)) {
    data <- data.frame(data)[, selected.columns, drop = FALSE]
  }
  write.table(data, output.file, quote = FALSE, row.names = FALSE,
              na = "NA", sep = "\t")
  return(data.frame(data))
}
