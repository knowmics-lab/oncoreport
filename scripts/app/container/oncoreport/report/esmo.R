cat("Building ESMO browser file\n")

.variables.to.keep <- ls()

esmo_parsed_content <- readLines(paste0(path_project, "/esmo_parsed.html"))
template.env$esmo_guidelines_sections <- paste0(esmo_parsed_content, collapse = "\n")

brew(
  file = paste0(path_html_source, "/esmoguide.html"),
  output = paste0(report_output_dir, "esmoguide.html"),
  envir = template.env
)

rm(list = setdiff(ls(), .variables.to.keep))
