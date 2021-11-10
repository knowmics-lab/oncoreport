create.dummy.type <- function(x) {
  x$Type = rep("NA", nrow(x))
  return (x)
}

pharm.urls <- function(x) {
  x[is.na(x)] <- " "
  x$Drug <- as.character(x$Drug)
  x$Gene <- as.character(x$Gene)
  x$Clinical_significance <- gsub(pattern = " ", replace = "", x$Clinical_significance)
  x <- x[order(x$Gene, x$Variant, x$Drug, x$Clinical_significance, x$PMID),]
  list.pubmed <- list.pubmed.urls(x, "pharm")
  write.table(list.pubmed, paste0(project.path, "/txt/reference/", sample.name, "_pharm.txt"), quote = FALSE,
              row.names = FALSE, na = "NA", sep = "\t")
}

cosmic.urls <- function(x)
{
  x[is.na(x)] <- " "
  names(x)[names(x) == "Primary.Tissue"] <- "Primary_tissue"
  x <- x[order(x$Gene, x$Variant, x$Drug, x$Primary_tissue, x$PMID),]
  list.pubmed <- list.pubmed.urls(x, "cosmic")
  write.table(list.pubmed, paste0(project.path, "/txt/reference/", sample.name, "_cosmic.txt"), quote = FALSE,
              row.names = FALSE, na = "NA", sep = "\t")
}

leading.urls <- function(x)
{
  dis <- read.csv(paste0(database.path, "/Disease.txt"), sep = "\t")
  x <- merge(dis, x, by.x = "Disease_database_name", by.y = "Disease")
  x$Disease <- NULL
  colnames(x)[1] <- "Disease"
  x <- data.frame(lapply(x, as.character), stringsAsFactors = FALSE)
  x[is.na(x)] <- " "
  x <- x[x$Evidence_direction == "Supports" & x$ICD.11_Code == leading.disease, , drop = FALSE]
  x$Drug <- as.character(x$Drug, levels = (x$Drug))
  x$Drug_interaction_type <- gsub(" ", "", x$Drug_interaction_type)
  x$Evidence_type <- factor(
    x$Evidence_type, 
    levels = c("Diagnostic", "Prognostic", "Predisposing", "Predictive")
  )
  x$Evidence_level <- factor(
    x$Evidence_level, 
    levels = c("Validated association", "FDA guidelines", "NCCN guidelines", 
               "Clinical evidence", "Late trials", "Early trials", "Case study", 
               "Case report", "Preclinical evidence", "Pre-clinical", "Inferential association")
  )
  x <- x[order(x$Gene, x$Evidence_level, x$Evidence_type, x$Variant, x$Drug, x$Drug_interaction_type,
               x$Clinical_significance, x$PMID),]
  list.pubmed <- list.pubmed.urls(x, "leading")
  list.trials <- list.trials.urls(x, "leading")
  write.table(list.pubmed, paste0(project.path, "/txt/reference/", sample.name, ".txt"),
              quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")
  write.table(list.trials, paste0(project.path, "/txt/trial/", sample.name, ".txt"),
              quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")
}

off.urls <- function(x)
{
  dis <- read.csv(paste0(database.path, "/Disease.txt"), sep = "\t")
  x <- merge(dis, x, by.x = "Disease_database_name", by.y = "Disease")
  x$Disease <- NULL
  colnames(x)[1] <- "Disease"
  x <- x[x$Evidence_direction == "Supports" & x$Disease != leading.disease, , drop = F]
  x[is.na(x)] <- " "
  x$Drug <- as.character(x$Drug, levels = (x$Drug))
  x$Evidence_type <- factor(
    x$Evidence_type, 
    levels = c("Diagnostic", "Prognostic", "Predisposing", "Predictive")
  )
  x$Evidence_level <- factor(
    x$Evidence_level, 
    levels = c("Validated association", "FDA guidelines", "NCCN guidelines", 
               "Clinical evidence", "Late trials", "Early trials", "Case study", 
               "Case report", "Preclinical evidence", "Pre-clinical","Inferential association")
  )
  x$Disease <- as.character(x$Disease, levels = (x$Disease))
  x <- x[order(x$Disease, x$Evidence_level, x$Evidence_type, x$Gene, x$Variant, x$Drug,
               x$Clinical_significance, x$PMID),]
  list.pubmed <- list.pubmed.urls(x, "off")
  list.trials <- list.trials.urls(x, "off")
  write.table(list.pubmed, paste0(project.path, "/txt/reference/", sample.name, "_off.txt"), quote = FALSE,
              row.names = FALSE, na = "NA", sep = "\t")
  write.table(list.trials, paste0(project.path, "/txt/trial/", sample.name, "_off.txt"),
              quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")
}

list.pubmed.urls <- function(x, type)
{
  if (nrow(x) > 0)
  {
    if (type == "leading") {
      link_pmid <- x[, c("Citation", "Gene", "PMID")]
    } else if (type == "off") {
      link_pmid <- x[, c("Citation", "Disease", "PMID")]
    } else {
      link_pmid <- x[, c("Gene", "PMID")]
    }
    link_pmid <- unique(link_pmid)
    link_pmid$URL <- paste0("https://www.ncbi.nlm.nih.gov/pubmed/", link_pmid$PMID)
    check.exists <- logical(nrow(link_pmid))
    list.urls <- unique(link_pmid$URL)
    y <- sapply(list.urls, url.exists)
    for (i in 1:length(list.urls))
    {
      if (y[i])
        check.exists[which(link_pmid$URL == list.urls[i])] <- T
    }
    link_pmid <- link_pmid[check.exists,]
    link_pmid$Reference <- 1:nrow(link_pmid)
  } else
  {
    if (type == "leading") {
      link_pmid <- data.frame(Citation = character(), Gene = character(), PMID = character(),
                              URL = character(), Reference = character())
    } else if (type == "off") {
      link_pmid <- data.frame(Citation = character(), Disease = character(), PMID = character(),
                              URL = character(), Reference = character())
    } else {
      link_pmid <- data.frame(Gene = character(), PMID = character(),
                              URL = character(), Reference = character())
    }
  }
  link_pmid
}

list.trials.urls <- function(x, type)
{
  if (nrow(x) > 0)
  {
    if (type == "leading") {
      link_cli <- x[, c("Gene", "Variant", "Drug", "PMID")]
    } else {
      link_cli <- x[, c("Disease", "Gene", "Variant", "Drug", "PMID")]
    }
    link_cli <- unique(link_cli)
    link_cli <- link_cli[link_cli$Drug != "",]
    link_cli <- link_cli[link_cli$Gene != link_cli$Drug,]
    link_cli$Clinical_trial <- paste0("https://clinicaltrials.gov/ct2/results?cond=",
                                      link_cli$Variant, "&term=",
                                      gsub(" ", "", link_cli$Drug, fixed = TRUE),
                                      "&cntry=&state=&city=&dist=")
    check.exists <- logical(nrow(link_cli))
    list.clinical.trials <- unique(link_cli$Clinical_trial)
    y <- sapply(list.clinical.trials, url.exists)
    for (i in 1:length(list.clinical.trials))
    {
      if (y[i])
        check.exists[which(link_cli$Clinical_trial == list.clinical.trials[i])] <- T
    }
    link_cli <- link_cli[check.exists,]
  } else
  {
    if (type == "leading") {
      link_cli <- data.frame(Gene = character(), Variant = character(), Drug = character(),
                             PMID = character(), Clinical_trial = character())
    } else {
      link_cli <- data.frame(Disease = character(), Gene = character(), Variant = character(),
                             Drug = character(), PMID = character(), Clinical_trial = character())
    }
  }
  link_cli
}
