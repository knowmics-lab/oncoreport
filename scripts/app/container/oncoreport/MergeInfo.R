suppressPackageStartupMessages({
  library(optparse)
  library(readr)
  library(dplyr)
  library(data.table)
  library(RCurl)
  library(tidyr)
  library(fuzzyjoin)
  library(IRanges)
})

option_list <- list(
  make_option(c("-g", "--genome"), type="character", default=NULL, help="human genome version (hg19 or hg38)", metavar="character"),
  make_option(c("-d", "--database"), type="character", default=NULL, help="databases folder", metavar="character"),
  make_option(c("-c", "--cosmic"), type="character", default=NULL, help="cosmic folder", metavar="character"),
  make_option(c("-p", "--project"), type="character", default=NULL, help="project folder", metavar="character"),
  make_option(c("-s", "--sample"), type="character", default=NULL, help="sample name", metavar="character"),
  make_option(c("-t", "--tumor"), type="character", default=NULL, help="patient tumor", metavar="character"),
  make_option(c("-a", "--pipeline"), type="character", default=NULL, help="pipeline type (biopsy or tumnorm)", metavar="character")
);

opt_parser <- OptionParser(option_list=option_list)
opt        <- parse_args(opt_parser)

if (is.null(opt$genome) || !(opt$genome %in% c("hg19", "hg38"))) {
  print_help(opt_parser)
  stop("Invalid genome", call.=FALSE)
}
if (is.null(opt$database) || !dir.exists(opt$database)) {
  print_help(opt_parser)
  stop("Databases path does not exist", call.=FALSE)
}
if (is.null(opt$cosmic) || !dir.exists(opt$cosmic)) {
  print_help(opt_parser)
  stop("COSMIC path does not exist", call.=FALSE)
}
if (is.null(opt$project) || !dir.exists(opt$project)) {
  print_help(opt_parser)
  stop("Project folder does not exist", call.=FALSE)
}
if (is.null(opt$pipeline) || !(opt$pipeline %in% c("biopsy", "tumnorm"))) {
  print_help(opt_parser)
  stop("Invalid pipeline type", call.=FALSE)
}
if (is.null(opt$sample) || is.null(opt$tumor)) {
  print_help(opt_parser)
  stop("All parameters are required", call.=FALSE)
}

genome <- opt$genome
database.path <- opt$database
cosmic.path <- opt$cosmic
project.path <- opt$project
sample.name <- opt$sample
leading.disease <- opt$tumor
pipeline.type <- opt$pipeline

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

source(file.path(dirname(thisFile()), "Functions.R"))

#Merge germline and somatic mutations into a unique file for liquid biopsy
if (pipeline.type == "biopsy") {
  germ <- suppressWarnings(fread(paste0(project.path, "/converted/variants_Germline.txt")))
  som  <- suppressWarnings(fread(paste0(project.path, "/converted/variants_Somatic.txt")))
  if (nrow(germ) == 0) germ <- data.frame(matrix(nrow = 0, ncol = 4))
  if (nrow(som)  == 0) som  <- data.frame(matrix(nrow = 0, ncol = 4))
  names(germ) <- c("Chromosome", "Stop", "Ref_base", "Var_base")
  names(som)  <- c("Chromosome", "Stop", "Ref_base", "Var_base")
  germ$Type <- rep("Germline", nrow(germ))
  som$Type  <- rep("Somatic", nrow(som))
  res <- rbind(som, germ)
  write.table(res, paste0(project.path, "/converted/variants.txt"),
              quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")
  # unlink(paste0(project.path, "/converted/variants_Germline.txt"))
  # unlink(paste0(project.path, "/converted/variants_Somatic.txt"))
}

#Read patient info
pat <- fread(paste0(project.path, "/converted/variants.txt"))
colnames(pat)[1] <- "Chromosome"
colnames(pat)[2] <- "Stop"
colnames(pat)[3] <- "Ref_base"
colnames(pat)[4] <- "Var_base"

## Merge with CIVIC
cat("Annotating with CIVIC...\n")
civic <- join.and.write(
  variants = pat,
  db = "civic_database",
  selected.columns = c("Database", "Gene", "Variant", "Disease", "Drug",
                       "Drug_interaction_type", "Evidence_type", "Evidence_level",
                       "Evidence_direction", "Clinical_significance",
                       "Evidence_statement", "Variant_summary", "PMID", "Citation",
                       "Chromosome", "Start", "Stop", "Ref_base", "Var_base", "Type"),
  output.file = paste0(project.path, "/txt/", sample.name, "_civic.txt"),
  genome = genome,
  db.path = database.path,
  check.for.type = (pipeline.type == "tumnorm")
);

## Merge with Clinvar
cat("Annotating with Clinvar...\n")
d <- join.and.write(
  variants = pat,
  db = "clinvar_database",
  selected.columns = c("Chromosome", "Stop", "Ref_base", "Var_base", "Change_type",
                       "Clinical_significance", "Type"),
  output.file = paste0(project.path, "/txt/", sample.name, "_clinvar.txt"),
  genome = genome,
  db.path = database.path,
  check.for.type = (pipeline.type == "tumnorm")
);

#Merge with COSMIC
cat("Annotating with COSMIC...\n")
cosmic <- join.and.write(
  variants = pat,
  db = "cosmic_database",
  selected.columns = NULL,
  output.file = paste0(project.path, "/txt/", sample.name, "_cosmic.txt"),
  genome = genome,
  db.path = cosmic.path,
  check.for.type = (pipeline.type == "tumnorm")
);

#Merge with PharmGKB
cat("Annotating with PharmGKB...\n")
pharm <- join.and.write(
  variants = pat,
  db = "pharm_database",
  selected.columns = c("Database", "Gene", "Variant_summary", "Evidence_statement",
                       "Evidence_level", "Clinical_significance", "PMID", "Drug",
                       "PharmGKB_ID", "Variant", "Chromosome", "Start", "Stop",
                       "Ref_base", "Var_base", "Type"),
  output.file = paste0(project.path, "/txt/", sample.name, "_pharm.txt"),
  genome = genome,
  db.path = database.path,
  check.for.type = (pipeline.type == "tumnorm")
);

#Merge with RefGene
cat("Annotating with RefGene...\n")
data <- fread(paste0(database.path, "/refgene_database_", genome, ".txt"), quote = "")
tmp.pat <- pat
tmp.pat$exonStarts <- tmp.pat$Stop
tmp.pat$exonEnds   <- tmp.pat$Stop
data <- genome_left_join(
  tmp.pat, data,
  by = c("Chromosome", "exonStarts", "exonEnds")
)
if (pipeline.type == "tumnorm") {
  data$Type <- rep("NA", nrow(data))
}
data <- data[, c("Chromosome.x", "Stop", "Ref_base", "Var_base", "Gene", "Type")]
colnames(data)[1] <- "Chromosome"
data <- unique(data)
write.table(data, paste0(project.path, "/txt/", sample.name, "_refgene.txt"),
            quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")

#Merge with CGI
cat("Annotating with CGI...\n")
cgi <- join.and.write(
  variants = pat,
  db = "cgi_database",
  selected.columns = c("Database", "Gene", "Variant", "Disease", "Drug",
                       "Drug_interaction_type", "Evidence_type", "Evidence_level",
                       "Evidence_direction", "Clinical_significance",
                       "Evidence_statement", "Variant_summary", "PMID", "Citation",
                       "Chromosome", "Start", "Stop", "Ref_base", "Var_base", "Type"),
  output.file = paste0(project.path, "/txt/", sample.name, "_cgi.txt"),
  genome = genome,
  db.path = database.path,
  check.for.type = (pipeline.type == "tumnorm")
);

#Merge CIVIC and CGI info
cat("Combining CIVIC and CGI...\n")
def <- merge(civic, cgi, all = TRUE)
def$Clinical_significance[def$Clinical_significance == "Responsive"] <- "Sensitivity/Response"
def$Clinical_significance[def$Clinical_significance == "Resistant"] <- "Resistance"

cat("Annotating Agency Approval...\n")
drug <- read.csv(paste0(database.path, "/Agency_approval.txt"), sep = "\t",
                 quote = "", na.strings = c("", "NA"),
                 stringsAsFactors = FALSE)
drug.map <- setNames(drug[[2]], drug[[1]])
def$Approved <- unname(sapply(
  def$Drug,
  function(x) (
    ifelse(is.na(x), "", paste0(
      sapply(
        drug.map[unlist(strsplit(x, ",", fixed = TRUE))],
        function(x) (ifelse(is.na(x), "", x))),
      collapse = ",")
    )
  )
))
def$Approved <- gsub("^,*|(?<=,),|,*$", "", def$Approved, perl = T)
def <- def[, c("Database", "Gene", "Variant", "Disease", "Drug", "Drug_interaction_type",
               "Evidence_type", "Evidence_level", "Evidence_direction", "Clinical_significance",
               "Evidence_statement", "Variant_summary", "PMID", "Citation", "Chromosome",
               "Start", "Stop", "Ref_base", "Var_base", "Type", "Approved")]

def$Approved <- gsub("^,*|(?<=,),|,*$", "", def$Approved, perl = T)

#Score
cat("Computing scores with dbNSFP...\n")
def$Start <- as.numeric(def$Start)
def$Stop  <- as.numeric(def$Stop)
a         <- readLines(paste0(database.path, "/Colnames_dbNSFP.txt"))[-1]
a[1:5]    <- c("Chromosome", "Start", "Stop", "Ref_base", "Var_base")
files_db  <- list.files(paste0(database.path, "/", genome, "/dbNSFP"),
                        pattern = "*.gz", full.names = TRUE, recursive = TRUE)

db_join <- function(i, y) {
  x <- fread(i)
  colnames(x) <- a
  x$Chromosome <- paste0("chr", x$Chromosome)
  return (suppressMessages(x %>% inner_join(y)))
}
tot <- lapply(files_db, db_join, def)
tot <- as.data.frame(do.call(rbind, tot))

if (nrow(tot) != 0) {
  matr <- apply(tot, 1, function(row) (sum(
    switch(row["SIFT_pred"],              "D"=1,                   "."=-1, 0),
    switch(row["MutationTaster_pred"],    "A"=1, "D"=0.7, "N"=0.3, "."=-1, 0),
    switch(row["MutationAssessor_pred"],  "H"=1, "M"=0.7, "L"=0.3, "."=-1, 0),
    switch(row["LRT_pred"],               "D"=1,          "U"=-1,  "."=-1, 0),
    switch(row["FATHMM_pred"],            "D"=1,                   "."=-1, 0),
    switch(row["PROVEAN_pred"],           "D"=1,                   "."=-1, 0),
    switch(row["fathmm-MKL_coding_pred"], "D"=1,                   "."=-1, 0),
    switch(row["MetaSVM_pred"],           "D"=1,                   "."=-1, 0),
    switch(row["MetaLR_pred"],            "D"=1,                   "."=-1, 0)
  )))
  tot$Score <- matr
  def <- merge(tot, def, all = TRUE)
  def$Score[is.na(def$Score)] <- 0
  def <- def[, c("Database", "Gene", "Variant", "Disease", "Drug", "Drug_interaction_type",
                 "Evidence_type", "Evidence_level", "Evidence_direction", "Clinical_significance",
                 "Evidence_statement", "Variant_summary", "PMID", "Citation", "Chromosome",
                 "Start", "Stop", "Ref_base", "Var_base", "Type", "Approved", "Score")]
} else {
  def$Score <- rep(0, nrow(def))
}
write.table(def, paste0(project.path, "/txt/", sample.name, "_definitive.txt"),
            quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")
#Food interactions
list.drugs <- unique(unlist(strsplit(c(def$Drug, pharm$Drug), ",")))
drugfood   <- suppressMessages(suppressWarnings(read_csv(paste0(database.path, "/drugfood_database.csv"))))
drugfood   <- drugfood[drugfood$Drug %in% list.drugs,]
write.table(drugfood, paste0(project.path, "/txt/", sample.name, "_drugfood.txt"),
            quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")


#Create Pubmed URLs and links to clinical trials
dis <- read.csv(paste0(database.path, "/Disease.txt"), sep = "\t", stringsAsFactors = FALSE)
#Leading disease
cat("Searching URLs related to the primary disease...\n")
leading.urls(def, leading.disease, dis, project.path, sample.name)
#OFF - Other diseases
cat("Searching URLs related to the other diseases...\n")
off.urls(def, leading.disease, dis, project.path, sample.name)
#Cosmic
cat("Searching COSMIC URLs...\n")
cosmic.urls(cosmic, project.path, sample.name)
#PharmGKB
cat("Searching PharmGKB URLs...\n")
pharm.urls(pharm, project.path, sample.name)
