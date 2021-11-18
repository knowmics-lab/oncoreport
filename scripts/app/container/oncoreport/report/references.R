cat("Building References File\n")

template.env$references <- list(
  ref=NULL,
  pharm=NULL,
  off=NULL,
  cosmic=NULL
)

.variables.to.keep <- ls()


brew(
  file = paste0(path_html_source, "/reference.html"),
  output = paste0(report_output_dir, "reference.html"),
  envir = template.env
)


