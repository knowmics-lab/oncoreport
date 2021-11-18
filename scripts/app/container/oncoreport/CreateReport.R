thisFile <- function() {
  cmdArgs <- commandArgs(trailingOnly = FALSE)
  needle <- "--file="
  match <- grep(needle, cmdArgs)
  if (length(match) > 0) {
    # Rscript
    return(normalizePath(sub(needle, "", cmdArgs[match])))
  } else {
    # 'source'd via R console
    return(normalizePath(sys.frames()[[1]]$ofile))
  }
}
source(file.path(dirname(thisFile()), "report", "imports.R"), local = knitr::knit_global())
source(file.path(dirname(thisFile()), "report", "commons.R"), local = knitr::knit_global())
options(knitr.table.format = "html")

cargs <- commandArgs(trailingOnly = TRUE)

pt_name <- cargs[1]
pt_surname <- cargs[2]
pt_sample_name <- cargs[3]
pt_sex <- cargs[4]
pt_age <- cargs[5]
pt_tumor <- cargs[6]
pt_fastq <- cargs[7]
path_project <- cargs[8]
path_db <- cargs[9]
tumor_type <- cargs[10]
pt_tumor_site <- cargs[11]
pt_city <- cargs[12]
pt_phone <- cargs[13]
pt_tumor_stage <- cargs[14]
pt_path_file_comorbid <- cargs[15]
path_html_source <- cargs[16]

if (tumor_type == "lb") {
  depth <- cargs[17]
  af <- cargs[18]
}

report_output_dir <- paste0(path_project, "/report/")
dir.create(report_output_dir, showWarnings = FALSE)


imported_diseases        <- read.diseases(path_db)
diseases_db              <- imported_diseases[[1]]
diseases_db_simple       <- imported_diseases[[2]]
pt_disease_details       <- diseases_db[diseases_db$DOID == pt_tumor,,drop = FALSE]
pt_disease_name          <- unique(pt_disease_details$DO_name)[1]

evidence_list <- c("Validated association", "FDA guidelines", "NCCN guidelines", "Clinical evidence", "Late trials", 
                   "Early trials", "Case study", "Case report", "Preclinical evidence", "Pre-clinical", 
                   "Inferential association")


template.env <- new.env()
template.env$pt_surname      <- pt_surname
template.env$pt_name         <- pt_name
template.env$pt_sex          <- ifelse(pt_sex == "m", "Male", "Female")
template.env$pt_age          <- pt_age
template.env$pt_city         <- pt_city
template.env$pt_phone        <- pt_phone
template.env$pt_sample_name  <- pt_sample_name
template.env$pt_disease_name <- pt_disease_name
template.env$pt_tumor_stage  <- pt_tumor_stage


suppressMessages(source(file.path(dirname(thisFile()), "report", "therapeutic.R")))
# suppressMessages(source(file.path(dirname(thisFile()), "report", "drugInteractions.R")))
suppressMessages(source(file.path(dirname(thisFile()), "report", "drugFoodInteractions.R")))
suppressMessages(source(file.path(dirname(thisFile()), "report", "mutations.R")))
suppressMessages(source(file.path(dirname(thisFile()), "report", "esmo.R")))
suppressMessages(source(file.path(dirname(thisFile()), "report", "pharmgkb.R")))
suppressMessages(source(file.path(dirname(thisFile()), "report", "cosmic.R")))
suppressMessages(source(file.path(dirname(thisFile()), "report", "offlabel.R")))
suppressMessages(source(file.path(dirname(thisFile()), "report", "references.R")))


stop()


cat("Copying assets\n")
file.copy(file.path(path_html_source, "assets"), report_output_dir, recursive = TRUE)
cat("OK!\n")
stop()


if (tumor_type == "tumnorm") {
  sample.type <- "Tumor and Blood Biopsy"
} else {
  sample.type <- "Liquid Biopsy"
}
pat <- data.frame(Name = pt_name, Surname = pt_surname, ID = pt_sample_name, Gender = pt_sex, Age = pt_age,
                  Sample = sample.type, Tumor = pt_tumor)
patient_info <- kable(pat) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "responsive"))
xml_patient_info <- kable_as_xml(patient_info)


##
##
##
## Reference {.tabset}
##
##
##
cat("REFERENCE - Mutations\n")
reference <- (read_html(paste0(path_html_source, "/reference.html")))
children_reference_mut <- xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(reference, 2), 1), 2), 4), 1), 1)
array_table <- c()
an <- xml_child(xml_child(xml_child(xml_child(xml_child(reference, 2), 1), 1), 2), 2)
xml_replace(an, an_xml)
### Mutation

options(knitr.table.format = "html")
#cargs=commandArgs(trailingOnly = TRUE)
try({
  x_url <- read.csv(paste0(path_project, "/txt/reference/", pt_fastq, ".txt"), sep = "\t")
  link1 <- x_url[, c("Reference", "PMID", "Citation")]
  link1 <- link1[!duplicated(x_url[, c("PMID")]),]
  if (nrow(link1) > 0)
  {
    link1$Reference <- as.character(link1$Reference)
    link1$Reference <- paste0('<a id="ref-', link1$Reference, '" name="ref-', link1$Reference, '"></a>', link1$Reference)
    link1$PMID <- paste0('<a href=\"https://www.ncbi.nlm.nih.gov/pubmed/', link1$PMID, '\" style=\"     \" >', link1$PMID, '</a>')
    
    t <- link1 %>%
      #mutate(PMID = cell_spec(link1$PMID, "html", link = x_url$URL)) %>%
      kable("html", escape = FALSE) %>%
      kable_styling(bootstrap_options = c("hover", "condensed"))
    x_url$Gene <- as.factor(x_url$Gene)
    lvl <- levels(x_url$Gene)
    for (l in lvl)
    {
      a <- which(x_url$Gene == l)
      if (length(a) != 0)
        t <- t %>% pack_rows(l, min(a), max(a), indent = FALSE)
    }
    array_table <- (t)
  } else {
    array_table <- paste('<div id="no-data-available." class="section level5">
                        <h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
    cat("  \n##### No data available.  \n")
    
  }
  
}, silent = TRUE)
xml_table_evidence <- kable_as_xml(paste(array_table, collapse = " "))
node_to_be_replaced <- children_reference_mut
xml_replace(node_to_be_replaced, xml_table_evidence)
write_html(reference, paste0(path_project, "/", pt_fastq, "/reference.html"))


### Pharm
cat("REFERENCE - Pharm\n")
children_reference_pharm <- xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(reference, 2), 1), 2), 4), 2), 1)
array_table <- c()

options(knitr.table.format = "html")
#cargs=commandArgs(trailingOnly = TRUE)
#pharm
try({
  x_url_p <- read.csv(paste0(path_project, "/txt/reference/", pt_fastq, "_pharm.txt"), sep = "\t")
  link1 <- x_url_p[, c("Reference", "PMID")]
  if (nrow(link1) > 0)
  {
    link1$Reference <- paste0(link1$Reference, "p")
    link1$Reference <- paste0('<a id="ref-', link1$Reference, '" name="ref-', link1$Reference, '"></a>', link1$Reference)
    link1$PMID <- paste0('<a href=\"https://www.ncbi.nlm.nih.gov/pubmed/', link1$PMID, '\" style=\"     \" >', link1$PMID, '</a>')
    t <- link1 %>%
      #mutate(PMID = cell_spec(PMID, "html", link = x_url_p$URL)) %>%
      kable("html", escape = FALSE) %>%
      kable_styling(bootstrap_options = c("hover", "condensed"))
    x_url_p$Gene <- as.factor(x_url_p$Gene)
    lvl <- levels(x_url_p$Gene)
    for (l in lvl)
    {
      a <- which(x_url_p$Gene == l)
      if (length(a) != 0)
        t <- t %>% pack_rows(l, min(a), max(a), indent = FALSE)
    }
    array_table <- (t)
  } else
  {
    array_table <- paste('<div id="no-data-available." class="section level5">
                        <h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
    cat("  \n##### No data available.  \n")
    
  }
  
}, silent = TRUE)
xml_table_evidence <- kable_as_xml(paste(array_table, collapse = " "))
node_to_be_replaced <- children_reference_pharm
xml_replace(node_to_be_replaced, xml_table_evidence)
write_html(reference, paste0(path_project, "/", pt_fastq, "/reference.html"))


### Off label Drug
cat("REFERENCE - Offlabel\n")
children_reference_drug <- xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(reference, 2), 1), 2), 4), 3), 1)
array_table <- c()
options(knitr.table.format = "html")
#cargs=commandArgs(trailingOnly = TRUE)
#Off label
try({
  x_url <- read.csv(paste0(path_project, "/txt/reference/", pt_fastq, "_off.txt"), sep = "\t")
  dis <- read.csv(paste0(path_db, "/Disease.txt"), sep = "\t")
  colnames(dis)[1] <- "Disease"
  x_url <- merge(dis, x_url, by = "Disease")
  x$Category <- NULL
  x$DOID <- NULL
  x_url$Disease <- NULL
  colnames(x_url)[1] <- "Disease"
  x_url <- x_url[!duplicated(x_url[, c("PMID")]),]
  link1 <- x_url[, c("Reference", "PMID", "Citation")]
  if (nrow(link1) > 0)
  {
    link1$Reference <- paste0(link1$Reference, "a")
    link1$Reference <- paste0('<a id="ref-', link1$Reference, '" name="ref-', link1$Reference, '"></a>', link1$Reference)
    link1$PMID <- paste0('<a href=\"https://www.ncbi.nlm.nih.gov/pubmed/', link1$PMID, '\" style=\"     \" >', link1$PMID, '</a>')
    
    t <- link1 %>%
      #mutate(PMID = cell_spec(PMID, "html", link = x_url$URL)) %>%
      kable("html", escape = FALSE) %>%
      kable_styling(bootstrap_options = c("hover", "condensed"))
    x_url$Disease <- as.factor(x_url$Disease)
    lvl <- levels(x_url$Disease)
    for (l in lvl)
    {
      a <- which(x_url$Disease == l)
      if (length(a) != 0)
        t <- t %>% pack_rows(l, min(a), max(a), indent = FALSE)
    }
    array_table <- (t)
  } else
  {
    array_table <- paste('<div id="no-data-available." class="section level5">
                        <h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
    cat("  \n##### No data available.  \n")
    
  }
  
}, silent = TRUE)
xml_table_evidence <- kable_as_xml(paste(array_table, collapse = " "))
node_to_be_replaced <- children_reference_drug
xml_replace(node_to_be_replaced, xml_table_evidence)
write_html(reference, paste0(path_project, "/", pt_fastq, "/reference.html"))


### Cosmic
cat("REFERENCE - Cosmic\n")
children_reference_cosmic <- xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(reference, 2), 1), 2), 4), 4), 1)
array_table <- c()
options(knitr.table.format = "html")
#cargs=commandArgs(trailingOnly = TRUE)
#Cosmic
try({
  cosm <- read.csv(paste0(path_project, "/txt/reference/", pt_fastq, "_cosmic.txt"), sep = "\t")
  link1 <- cosm[, c("Reference", "PMID")]
  if (nrow(link1) > 0)
  {
    link1$Reference <- paste0(link1$Reference, "c")
    link1$Reference <- paste0('<a id="ref-', link1$Reference, '" name="ref-', link1$Reference, '"></a>', link1$Reference)
    link1$PMID <- paste0('<a href=\"https://www.ncbi.nlm.nih.gov/pubmed/', link1$PMID, '\" style=\"     \" >', link1$PMID, '</a>')
    
    t <- link1 %>%
      #mutate(PMID = cell_spec(PMID, "html", link = cosm$URL)) %>%
      kable("html", escape = FALSE) %>%
      kable_styling(bootstrap_options = c("hover", "condensed"))
    cosm$Gene <- as.factor(cosm$Gene)
    lvl <- levels(cosm$Gene)
    for (l in lvl)
    {
      a <- which(cosm$Gene == l)
      if (length(a) != 0)
        t <- t %>% pack_rows(l, min(a), max(a), indent = FALSE)
    }
    array_table <- (t)
  } else {
    array_table <- paste('<div id="no-data-available." class="section level5">
                        <h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
    cat("  \n##### No data available.  \n")
    
  }
  
}, silent = TRUE)
xml_table_evidence <- kable_as_xml(paste(array_table, collapse = " "))
node_to_be_replaced <- children_reference_cosmic
xml_replace(node_to_be_replaced, xml_table_evidence)
write_html(reference, paste0(path_project, "/", pt_fastq, "/reference.html"))

cat("Copying assets\n")
file.copy(file.path(path_html_source, "assets"), file.path(path_project, pt_fastq), recursive = TRUE)
cat("OK!\n")
