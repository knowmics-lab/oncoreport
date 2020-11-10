args <- commandArgs(trailingOnly = TRUE)

suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(RCurl))

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

genome <- args[1]
database.path <- args[2]
cosmic.path <- args[3]
project.path <- args[4]
sample.name <- args[5]
leading.disease <- args[6]
pipeline.type <- args[7]

#Merge germline and somatic mutations into a unique file for liquid biopsy
if (pipeline.type == "biopsy")
{
  germ <- fread(paste0(project.path, "/converted/", sample.name, "_Germline.txt"))
  som <- fread(paste0(project.path, "/converted/", sample.name, "_Somatic.txt"))
  names(germ) <- c("Chromosome", "Stop", "Ref_base", "Var_base")
  names(som) <- c("Chromosome", "Stop", "Ref_base", "Var_base")
  if (dim(germ)[1] != 0)
  {
    germ$Type <- "Germline"
  }else {
    germ$Type <- character()
  }
  if (dim(som)[1] != 0)
  {
    som$Type <- "Somatic"
  }else {
    som$Type <- character()
  }
  res <- merge(som, germ, all = TRUE)
  write.table(res, paste0(project.path, "/converted/", sample.name, ".txt"),
              quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")
  unlink(paste0(project.path, "/converted/", sample.name, "_Germline.txt"))
  unlink(paste0(project.path, "/converted/", sample.name, "_Somatic.txt"))
}

#Read patient info
pat <- fread(paste0(project.path, "/converted/", sample.name, ".txt"))
colnames(pat)[1] <- "Chromosome"
colnames(pat)[2] <- "Stop"
colnames(pat)[3] <- "Ref_base"
colnames(pat)[4] <- "Var_base"

#Merge with CIVIC
data <- fread(paste0(database.path, "/civic_database_", genome, ".txt", quote = ""))
data <- inner_join(data, pat, by = NULL, copy = FALSE)
if (pipeline.type == "tumnorm")
  data <- create.dummy.type(data)
data <- data[, c("Database", "Gene", "Variant", "Disease", "Drug", "Drug_interaction_type",
                 "Evidence_type", "Evidence_level", "Evidence_direction", "Clinical_significance",
                 "Evidence_statement", "Variant_summary", "PMID", "Citation", "Chromosome",
                 "Start", "Stop", "Ref_base", "Var_base", "Type")]
write.table(data, paste0(project.path, "/txt/", sample.name, "_civic.txt"),
            quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")

#Merge with Clinvar
data <- fread(paste0(database.path, "/clinvar_database_", genome, ".txt", quote = ""))
data <- inner_join(data, pat, by = NULL, copy = FALSE)
if (pipeline.type == "tumnorm")
  data <- create.dummy.type(data)
data <- data[, c("Chromosome", "Stop", "Ref_base", "Var_base", "Change_type",
                 "Clinical_significance", "Type")]
write.table(data, paste0(project.path, "/txt/", sample.name, "_clinvar.txt"),
            quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")

#Merge with COSMIC
data <- fread(paste0(cosmic.path, "/cosmic_database_", genome, ".txt"), quote = "")
data <- inner_join(data, pat, by = NULL, copy = FALSE)
if (pipeline.type == "tumnorm")
  data <- create.dummy.type(data)
write.table(data, paste0(project.path, "/txt/", sample.name, "_cosmic.txt"),
            quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")

#Merge with PharmGKB
data <- fread(paste0(database.path, "/pharm_database_", genome, ".txt"), quote = "")
data <- inner_join(data, pat, by = NULL, copy = FALSE)
if (pipeline.type == "tumnorm")
  data <- create.dummy.type(data)
data <- data[, c("Database", "Gene", "Variant_summary", "Evidence_statement",
                 "Evidence_level", "Clinical_significance", "PMID", "Drug", "PharmGKB_ID",
                 "Variant", "Chromosome", "Start", "Stop", "Ref_base", "Var_base", "Type")]
write.table(data, paste0(project.path, "/txt/", sample.name, "_pharm.txt"),
            quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")

#Merge with RefGene
data <- fread(paste0(database.path, "/refgene_database_", genome, ".txt"), quote = "")
data <- pat %>%
  left_join(data, by = c("Chromosome")) %>%
  filter(Stop >= exonStarts & Stop <= exonEnds)
if (pipeline.type == "tumnorm")
  data <- create.dummy.type(data)
data <- data[, c("Chromosome", "Stop", "Ref_base", "Var_base", "Gene", "Type")]
data <- unique(data)
write.table(data, paste0(project.path, "/txt/", sample.name, "_refgene.txt"),
            quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")

#Merge with CGI
data <- fread(paste0(database.path, "/cgi_database_", genome, ".txt"), quote = "")
data <- inner_join(data, pat, by = NULL, copy = FALSE)
if (pipeline.type == "tumnorm")
  data <- create.dummy.type(data)
data <- data[, c("Database", "Gene", "Variant", "Disease", "Drug", "Drug_interaction_type",
                 "Evidence_type", "Evidence_level", "Evidence_direction", "Clinical_significance",
                 "Evidence_statement", "Variant_summary", "PMID", "Citation", "Chromosome",
                 "Start", "Stop", "Ref_base", "Var_base", "Type")]
write.table(data, paste0(project.path, "/txt/", sample.name, "_cgi.txt"),
            quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")

#Merge CIVIC and CGI info
civic <- read.csv(paste0(project.path, "/txt/", sample.name, "_civic.txt"),
                  sep = "\t", colClasses = c("character"))
cgi <- read.csv(paste0(project.path, "/txt/", sample.name, "_cgi.txt"),
                sep = "\t", colClasses = c("character"))
def <- merge(civic, cgi, all = TRUE)
write.table(def, paste0(project.path, "/txt/", sample.name, "_definitive.txt"),
            quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")

#Food interactions
pharm <- read.csv(paste0(project.path, "/txt/", sample.name, "_pharm.txt"),
                  sep = "\t", colClasses = c("character"))
list.drugs <- unique(unlist(strsplit(c(def$Drug, pharm$Drug), ",")))
drugfood <- read.csv(paste0(database.path, "/drugfood_database.txt"),
                     sep = "\t", colClasses = c("character"))
drugfood <- drugfood[drugfood$Drug %in% list.drugs,]
write.table(drugfood, paste0(project.path, "/txt/", sample.name, "_drugfood.txt"),
            quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")


#Create Pubmed URLs and links to clinical trials

#Leading disease
cat("Searching URLs related to leading disease...\n")
leading.urls(def)
#OFF - Other diseases
cat("Searching URLs related to other diseases...\n")
off.urls(def)
#Cosmic
cat("Searching COSMIC URLs...\n")
cosmic <- read.csv(paste0(project.path, "/txt/", sample.name, "_cosmic.txt"),
                   sep = "\t", colClasses = c("character"))
cosmic.urls(cosmic)
#PharmGKB
cat("Searching PharmGKB URLs...\n")
pharm.urls(pharm)
