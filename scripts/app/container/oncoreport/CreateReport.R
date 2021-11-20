#!/usr/bin/env Rscript
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
source(file.path(dirname(thisFile()), "report", "args.R"), local = knitr::knit_global())
options(knitr.table.format = "html")

pt_name               <- get.option("name")
pt_surname            <- get.option("surname")
pt_sample_name        <- get.option("code")
pt_sex                <- get.option("gender")
pt_age                <- get.option("age")
pt_tumor              <- get.option("tumor")
pt_fastq              <- get.option("fastq")
path_project          <- get.option("project")
path_db               <- get.option("database")
tumor_type            <- get.option("analysis")
pt_city               <- get.nullable("city")
pt_phone              <- get.nullable("phone")
pt_tumor_stage        <- get.nullable("stage")
pt_path_file_comorbid <- get.option("drugs")
path_html_source      <- get.option("sources")

if (tumor_type == "biopsy") {
  depth <- get.option("depth")
  af    <- get.option("af")
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
suppressMessages(source(file.path(dirname(thisFile()), "report", "drugInteractions.R")))
suppressMessages(source(file.path(dirname(thisFile()), "report", "drugFoodInteractions.R")))
suppressMessages(source(file.path(dirname(thisFile()), "report", "mutations.R")))
suppressMessages(source(file.path(dirname(thisFile()), "report", "esmo.R")))
suppressMessages(source(file.path(dirname(thisFile()), "report", "pharmgkb.R")))
suppressMessages(source(file.path(dirname(thisFile()), "report", "cosmic.R")))
suppressMessages(source(file.path(dirname(thisFile()), "report", "offlabel.R")))
suppressMessages(source(file.path(dirname(thisFile()), "report", "references.R")))


brew(
  file = paste0(path_html_source, "/index.html"),
  output = paste0(report_output_dir, "index.html"),
  envir = template.env
)

cat("Copying assets\n")
if (file.copy(file.path(path_html_source, "assets"), report_output_dir, recursive = TRUE)) {
  cat("OK!\n")
} else {
  cat("Unable to copy assets!\n")
  quit(save = "no", status = 100)
}
