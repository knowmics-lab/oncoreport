option_list <- list(
  make_option(c("-n", "--name"),
    type = "character", default = NULL,
    help = "patient name", metavar = "character"
  ),
  make_option(c("-s", "--surname"),
    type = "character", default = NULL,
    help = "patient surname", metavar = "character"
  ),
  make_option(c("-c", "--code"),
    type = "character", default = NULL,
    help = "patient sample code", metavar = "character"
  ),
  make_option(c("-g", "--gender"),
    type = "character", default = NULL,
    help = "patient gender", metavar = "character"
  ),
  make_option(c("-a", "--age"),
    type = "numeric", default = NULL,
    help = "patient age", metavar = "number"
  ),
  make_option(c("-t", "--tumor"),
    type = "character", default = NULL,
    help = "patient tumor (DiseaseOntology ID)", metavar = "character"
  ),
  make_option(c("-f", "--fastq"),
    type = "character", default = NULL,
    help = "fastq name", metavar = "character"
  ),
  make_option(c("-p", "--project"),
    type = "character", default = NULL,
    help = "project path", metavar = "character"
  ),
  make_option(c("-d", "--database"),
    type = "character", default = NULL,
    help = "database path", metavar = "character"
  ),
  make_option(c("-A", "--analysis"),
    type = "character", default = NULL,
    help = "analysis type", metavar = "character"
  ),
  make_option(c("-D", "--drugs"),
    type = "character", default = NULL,
    help = paste0(
      "path of file containing list of patient drugs ",
      "for comorbidities (Drugbank IDs)"
    ),
    metavar = "character"
  ),
  make_option(c("-H", "--sources"),
    type = "character", default = NULL,
    help = "html sources path", metavar = "character"
  ),
  make_option(c("-S", "--site"),
    type = "character", default = NULL,
    help = "tumor site", metavar = "character"
  ),
  make_option(c("-T", "--stage"),
    type = "character", default = NULL,
    help = "tumor stage (TNM)", metavar = "character"
  ),
  make_option(c("-E", "--depth"),
    type = "character", default = NULL,
    help = "analysis depth filter", metavar = "character"
  ),
  make_option(c("-F", "--af"),
    type = "character", default = NULL,
    help = "analysis AF filter", metavar = "character"
  )
)

opt_parser <- OptionParser(option_list = option_list)
opt <- tryCatch(parse_args(opt_parser), error = function(e) {
  print_help(opt_parser)
  print(e)
  stop("An unknown error occurred", call. = FALSE)
})

patient_data_filled <- is.null(opt$name) || is.null(opt$surname) ||
  is.null(opt$code) || is.null(opt$gender) || is.null(opt$age)

if (patient_data_filled) {
  print_help(opt_parser)
  stop("No patient personal data specified", call. = FALSE)
}
if (is.null(opt$tumor)) {
  print_help(opt_parser)
  stop("No patient tumor specified", call. = FALSE)
}
if (is.null(opt$fastq)) {
  print_help(opt_parser)
  stop("No fastq name specified", call. = FALSE)
}
if (is.null(opt$drugs) || !file.exists(opt$drugs)) {
  print_help(opt_parser)
  stop("Patient comorbidites drug file does not exist", call. = FALSE)
}
if (is.null(opt$database) || !dir.exists(opt$database)) {
  print_help(opt_parser)
  stop("Databases path does not exist", call. = FALSE)
}
if (is.null(opt$project) || !dir.exists(opt$project)) {
  print_help(opt_parser)
  stop("Project folder does not exist", call. = FALSE)
}
if (is.null(opt$sources) || !dir.exists(opt$sources)) {
  print_help(opt_parser)
  stop("HTML sources path does not exist", call. = FALSE)
}
if (is.null(opt$analysis) || !(opt$analysis %in% c("biopsy", "tumnorm"))) {
  print_help(opt_parser)
  stop("Invalid analysis type", call. = FALSE)
}

get_nullable <- function(x) (ifelse(is.null(opt[[x]]), "", opt[[x]]))
get_option <- function(x) (opt[[x]])
