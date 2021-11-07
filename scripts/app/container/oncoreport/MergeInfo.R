args <- commandArgs(trailingOnly = TRUE)

suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(RCurl))
suppressPackageStartupMessages(library(tidyr))

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
  germ <- fread(paste0(project.path, "/converted/variants_Germline.txt"))
  som <- fread(paste0(project.path, "/converted/variants_Somatic.txt"))
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
  write.table(res, paste0(project.path, "/converted/variants.txt"),
              quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")
  unlink(paste0(project.path, "/converted/variants_Germline.txt"))
  unlink(paste0(project.path, "/converted/variants_Somatic.txt"))
}

#Read patient info
pat <- fread(paste0(project.path, "/converted/variants.txt"))
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
def <- merge(civic,cgi,all=TRUE)
def$Clinical_significance[def$Clinical_significance == "Responsive"] <- "Sensitivity/Response"
def$Clinical_significance[def$Clinical_significance == "Resistant"] <- "Resistance"
drug <- read.csv(paste0(database.path, "/Agency_approval.txt"), sep="\t", quote="", na.strings = c("","NA"))
def$Drug <- as.character(def$Drug)
m <- max(sapply(strsplit(def$Drug, ","), length))
b <- vector()
for(i in 1:m){
  a <- paste0("Drug_", i)
  b <- c(b,a)
}
def <- suppressWarnings(separate(def, Drug, b, sep=",", remove=FALSE))

for(i in 1:m){
  colnames(drug)[1] <- paste0("Drug_", i)
  colnames(drug)[2] <-  paste0("approved_",i)
  drug[,2] <- as.character(drug[,2])
  def <- merge(def,drug, all.x=TRUE)
  def[length(def)][is.na(def[length(def)])] <- ""
}

x1 <- grepl("approved",colnames(def))
x1 <- def[x1]
a <- colnames(x1)
def <- def %>%
  unite(Approved, all_of(a), sep=",", na.rm = FALSE)
def <- def[,c("Database", "Gene", "Variant", "Disease", "Drug", "Drug_interaction_type", 
              "Evidence_type", "Evidence_level", "Evidence_direction", "Clinical_significance", 
              "Evidence_statement", "Variant_summary", "PMID", "Citation", "Chromosome", 
              "Start", "Stop", "Ref_base", "Var_base", "Type", "Approved")]

def$Approved <- gsub("^,*|(?<=,),|,*$", "", def$Approved, perl=T)

#Score
def$Chromosome <- gsub("chr", "", def$Chromosome)
def$Chromosome <- as.numeric(def$Chromosome)
def$Start <- as.numeric(def$Start)
def$Stop <- as.numeric(def$Stop)
a <- read.csv(paste0(database.path, "/Colnames_dbNSFP.txt"), sep="\t")
a <- as.vector(t(a))
a[1:5] <- c("Chromosome", "Start", "Stop", "Ref_base", "Var_base")

#cat(database.path,"/dbNSFP_hg38")
files_db <- list.files(paste0(project.path,"/",database.path, "/dbNSFP_hg38"),  full.names=TRUE, recursive=TRUE)
tot <- data.frame()
db_join <- function(i, y){
  x <- fread(i)
  colnames(x) <- a
  colnames(x)[1] <- "Chromosome"
  x$Chromosome <- as.numeric(x$Chromosome)
  z <- inner_join(x,y)
  tot <- rbind(tot,z)
}
tot <- lapply(files_db, db_join, def)
tot <- as.data.frame(do.call(rbind, tot))

if(dim(tot)[1]!=0)
{
  matr <- apply(tot, 1, function(row){
    var0 <- if(row["SIFT_pred"] == "D"){
      1  #Deleterio
    } else if (row["SIFT_pred"] == "."){
      -1
    } else {
      0 #Tolerate/Benign/Unknown
    }
    var1 <- if(row["MutationTaster_pred"] == "A"){
      1
    } else if (row["MutationTaster_pred"] == "D"){
      0.7
    } else if (row["MutationTaster_pred"] == "N"){
      0.3
    } else if (row["MutationTaster_pred"] == "."){
      -1
    } else {
      0
    }
    var2 <- if(row["MutationAssessor_pred"] == "H"){
      1
    } else if (row["MutationAssessor_pred"] == "M"){
      0.7
    } else if (row["MutationAssessor_pred"] == "L"){
      0.3
    } else if (row["MutationAssessor_pred"] == "."){
      -1
    } else {
      0
    }
    var3 <- if(row["LRT_pred"] == "D"){
      1
    } else if (row["LRT_pred"] == "." | row["LRT_pred"] == "U"){
      -1
    } else {
      0
    }
    var4 <- if(row["FATHMM_pred"] == "D"){
      1
    } else if (row["FATHMM_pred"] == "."){
      -1
    }else {
      0
    }
    var5 <- if(row["PROVEAN_pred"] == "D"){
      1
    } else if (row["PROVEAN_pred"] == "."){
      -1
    } else {
      0
    }
    var6 <- if(row["fathmm-MKL_coding_pred"] == "D"){
      1
    } else if (row["fathmm-MKL_coding_pred"] == "."){
      -1
    } else {
      0
    }
    var7 <- if(row["MetaSVM_pred"] == "D"){
      1
    } else if (row["MetaSVM_pred"] == "."){
      -1
    } else {
      0
    }
    var8 <- if(row["MetaLR_pred"] == "D"){
      1
    } else if (row["MetaSVM_pred"] == "."){
      -1
    } else {
      0
    }
    matr <- sum(var0, var1, var2, var3, var4, var5, var6, var7, var8)
    return(matr)
  })
  
  tot$Score <- matr
  def <- merge(tot,def, all= TRUE)
  def$Score[is.na(def$Score)] <- 0
  def <- def[,c("Database", "Gene", "Variant", "Disease", "Drug", "Drug_interaction_type", 
                "Evidence_type", "Evidence_level", "Evidence_direction","Clinical_significance", 
                "Evidence_statement", "Variant_summary", "PMID", "Citation", "Chromosome", 
                "Start", "Stop", "Ref_base", "Var_base","Type", "Approved", "Score")]
} else {
  def$Score<-0
}
def$Chromosome <- paste0("chr", def$Chromosome)
write.table(def, paste0(project.path, "/txt/", sample.name ,"_definitive.txt"),
            quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
#Food interactions
pharm <- read.csv(paste0(project.path, "/txt/", sample.name, "_pharm.txt"),
                  sep = "\t", colClasses = c("character"))
list.drugs <- unique(unlist(strsplit(c(def$Drug, pharm$Drug), ",")))
drugfood <- suppressMessages(suppressWarnings(read_csv(paste0(database.path, "/drugfood_database.csv"))))
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
