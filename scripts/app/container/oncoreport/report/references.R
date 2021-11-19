cat("Building References File\n")

template.env$references <- list(
  ref=NULL,
  pharm=NULL,
  off=NULL,
  cosmic=NULL
)

.variables.to.keep <- ls()

create.table <- function (data, group.by="Gene") {
  if (nrow(data) <= 0) return (NULL)
  if (is.null(group.by)) {
    return (
      kable(data, "html", escape = FALSE) %>% 
        kable_styling(bootstrap_options = c("striped", "hover", "condensed"))
    )
  }
  all.groups <- data[[group.by]]
  data[[group.by]] <- NULL
  table <- kable(data, "html", escape = FALSE) %>% 
    kable_styling(bootstrap_options = c("striped", "hover", "condensed"))
  groups <- unique(all.groups)
  for (g in groups) {
    rows <- which(all.groups == g)
    if (length(rows) > 0) {
      rng  <- range(rows)
      table <- table %>% pack_rows(group_label = g, start_row = rng[1], end_row = rng[2], indent = FALSE)
    }
  }
  return (table)
}



#####################################################################################################################
template.env$references$ref <- create.table(
  read.csv(paste0(path_project, "/txt/reference/", pt_fastq, ".txt"), sep = "\t", 
           colClasses = "character", stringsAsFactors = FALSE) %>%
    select(Gene, Reference, PMID, Citation, URL) %>% distinct() %>% mutate(Reference = as.numeric(Reference)) %>%
    arrange(Gene, Reference) %>%
    mutate(PMID = paste0('<a href=\"', URL, '\" target=\"_blank\">', PMID, '</a>')) %>% 
    group_by(Gene, PMID) %>%
    summarise(
      ReferenceNumber = min(Reference),
      Reference = paste0(unique(paste0('<a id="ref-', Reference, '"></a>', Reference)), collapse = ", "),
      Citation = paste0(unique(Citation), collapse = "; ")
    ) %>% arrange(Gene, ReferenceNumber) %>% select(Gene, Reference, PMID, Citation)
)

#####################################################################################################################
template.env$references$pharm <- create.table(
  read.csv(paste0(path_project, "/txt/reference/", pt_fastq, "_pharm.txt"), sep = "\t", 
           colClasses = "character", stringsAsFactors = FALSE) %>%
    select(Gene, PMID, Reference, URL) %>% distinct() %>%
    mutate(
      ReferenceNumber = as.numeric(Reference),
      Reference = paste0('<a id="pharm-', Reference, '"></a>', Reference),
      PMID = paste0('<a href=\"', URL, '\" target=\"_blank\">', PMID, '</a>')
    ) %>% arrange(Gene, Reference, PMID) %>% select(Gene, Reference, PMID)
)

#####################################################################################################################
template.env$references$off <- create.table(
  read.csv(paste0(path_project, "/txt/reference/", pt_fastq, "_off.txt"), sep = "\t", 
           colClasses = "character", stringsAsFactors = FALSE) %>%
    select(Reference, PMID, Citation, URL) %>% distinct() %>% mutate(Reference = as.numeric(Reference)) %>%
    arrange(Reference) %>%
    mutate(PMID = paste0('<a href=\"', URL, '\" target=\"_blank\">', PMID, '</a>')) %>% 
    group_by(PMID) %>%
    summarise(
      ReferenceNumber = min(Reference),
      Reference = paste0(unique(paste0('<a id="off-', Reference, '"></a>', Reference)), collapse = ", "),
      Citation = paste0(unique(Citation), collapse = "; ")
    ) %>% arrange(ReferenceNumber) %>% select(Reference, PMID, Citation),
  group.by = NULL
)

#####################################################################################################################
template.env$references$cosmic <- create.table(
  read.csv(paste0(path_project, "/txt/reference/", pt_fastq, "_cosmic.txt"), sep = "\t", 
           colClasses = "character", stringsAsFactors = FALSE) %>%
    select(Gene, PMID, Reference, URL) %>% distinct() %>%
    mutate(
      ReferenceNumber = as.numeric(Reference),
      Reference = paste0('<a id="cosmic-', Reference, '"></a>', Reference),
      PMID = paste0('<a href=\"', URL, '\" target=\"_blank\">', PMID, '</a>')
    ) %>% arrange(Gene, Reference, PMID) %>% select(Gene, Reference, PMID)
)

brew(
  file = paste0(path_html_source, "/reference.html"),
  output = paste0(report_output_dir, "reference.html"),
  envir = template.env
)

rm(list = setdiff(ls(), .variables.to.keep))

