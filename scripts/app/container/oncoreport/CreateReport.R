#!/usr/bin/env Rscript
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
this_dir <- dirname(this_file())
source(file.path(this_dir, "report", "imports.R"), local = knitr::knit_global())
source(file.path(this_dir, "report", "commons.R"), local = knitr::knit_global())
source(file.path(this_dir, "report", "args.R"), local = knitr::knit_global())
options(knitr.table.format = "html")

pt_name <- get_option("name")
pt_surname <- get_option("surname")
pt_sample_name <- get_option("code")
pt_sex <- get_option("gender")
pt_age <- get_option("age")
pt_tumor <- get_option("tumor")
pt_fastq <- get_option("fastq")
path_project <- get_option("project")
path_db <- get_option("database")
tumor_type <- get_option("analysis")
pt_tumor_stage <- get_nullable("stage")
pt_path_file_comorbid <- get_option("drugs")
path_html_source <- get_option("sources")

if (tumor_type == "biopsy") {
  depth <- get_option("depth")
  af <- get_option("af")
}

report_output_dir <- paste0(path_project, "/report/")
dir.create(report_output_dir, showWarnings = FALSE)

imported_diseases <- read.diseases(path_db)
diseases_db <- imported_diseases[[1]]
diseases_db_simple <- imported_diseases[[2]]
pt_disease_details <- diseases_db[diseases_db$DOID == pt_tumor, , drop = FALSE]
pt_disease_name <- unique(pt_disease_details$DO_name)[1]

evidence_list <- c(
  "Validated association", "FDA guidelines", "NCCN guidelines",
  "Clinical evidence", "Late trials", "Early trials", "Case study",
  "Case report", "Preclinical evidence", "Pre-clinical",
  "Inferential association"
)


template.env <- new.env()
template.env$pt_surname <- pt_surname
template.env$pt_name <- pt_name
template.env$pt_sex <- ifelse(pt_sex == "m", "Male", "Female")
template.env$pt_age <- pt_age
template.env$pt_sample_name <- pt_sample_name
template.env$pt_disease_name <- pt_disease_name
template.env$pt_tumor_stage <- pt_tumor_stage

suppressMessages({
  source(file.path(this_dir, "report", "therapeutic.R"))
  source(file.path(this_dir, "report", "drugInteractions.R"))
  source(file.path(this_dir, "report", "drugFoodInteractions.R"))
  source(file.path(this_dir, "report", "mutations.R"))
  source(file.path(this_dir, "report", "esmo.R"))
  source(file.path(this_dir, "report", "pharmgkb.R"))
  source(file.path(this_dir, "report", "cosmic.R"))
  source(file.path(this_dir, "report", "offlabel.R"))
  source(file.path(this_dir, "report", "references.R"))
})

brew(
  file = paste0(path_html_source, "/index.html"),
  output = paste0(report_output_dir, "index.html"),
  envir = template.env
)

cat("Copying assets\n")
copy_result <- file.copy(
  file.path(path_html_source, "assets"), report_output_dir,
  recursive = TRUE
)
if (copy_result) {
  cat("OK!\n")
} else {
  cat("Unable to copy assets!\n")
  quit(save = "no", status = 100)
}
