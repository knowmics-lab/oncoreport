args=commandArgs(trailingOnly = TRUE)

library(filesstrings)
library(data.table)
library(dplyr)

source(paste0(args[3], "/Functions.R")) #Vedi se così funziona
######################################################################################

germ_som <- function(database, args[1]){
germ<-read.csv(paste0(args[3], "/txt_", database, "/", args[1], "_Germline.txt"), sep= "\t")
som<-read.csv(paste0(args[3], "/txt_", database, "/", args[1], "_Somatic.txt"), sep= "\t")
if (dim(germ)[1]!=0){
  germ$Type <- "Germline"}else{germ$Type <- character(0)}
if (dim(som)[1]!=0){
  som$Type <- "Somatic"
}
res <- merge(som, germ, all=TRUE)
write.table(res, paste0(args[3], "/", database, "/", args[1],".txt"),
            quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
}

#Civic
germ_som(civic, args[1])
#CGI
germ_som(cgi, args[1])
#PharmGKB
germ_som(pharm, args[1])
#Refgene
germ_som(refgene, args[1])
#Cosmic
germ_som(cosmic, args[1])
#Clinvar
germ_som(clinvar, args[1])

#####################################################################################

#CIVIc

files_results <- list.files(path=paste0(args[3], "/civic/"),
                            pattern="*.txt", full.names=TRUE, recursive=TRUE)

for(i in files_results){
  x <- read.csv(i, sep="\t", stringsAsFactors = FALSE)
  if (dim(x)[1]!=0){
  x1 <- x1[,c("Database", "Chromosome","Start", "Stop", "Ref_base", "Var_base", "Gene", "Variant", "Type", "Disease", "Drug",
                          "Drug_interaction_type", "Evidence_type", "Evidence_level", "Evidence_direction",
                          "Clinical_significance", "Evidence_statement", "Variant_summary",
                          "Citation_id", "Citation")]
  hgx <- split(x1, paste(x$Gene, x$Variant))
  xa <- hgx[1:length(hgx)]
  for (n in xa) {split_civic(n)}

files_results1 <- list.files(path=paste0(args[3], "/civic/results/"),
                            pattern="*.txt", full.names=TRUE, recursive=TRUE)

for(i in files_results1){evidence_level(i)}

files_civic <- list.files(path=paste0(args[3], "/civic/"),
                          pattern="*.txt", full.names=TRUE, recursive=FALSE)
files_civic2 <-list.files(path=paste0(args[3], "/civic/results/"),
                          pattern="*.txt", full.names=TRUE, recursive=TRUE)


for (i in files_civic) {rename(i, civic, files_civic2, args[1])}

##########################################################################################
#CGI

files_results <- list.files(path=paste0(args[3], "/cgi/"),
                            pattern="*.txt", full.names=TRUE, recursive=TRUE)

for(i in files_results){
  x<-read.csv(i, sep="\t")
  if(dim(x)[1]!=0){
  x1 <- x1[,c("Database", "Chromosome", "Start", "Stop", "Ref_base", "Var_base", "Gene", "individual_mutation", "Type", "Drug", "Drug.family",
                 "Drug.full.name", "Drug.status", "Clinical_significance", "Biomarker", "Evidence_level", "Disease",
                 "PMID", "Targeting", "strand", "info", "region", "Evidence_statement", "Citation"))
  hgx <- split(x1, paste(x$Gene, x$individual_mutation))
  xa <- hgx[1:length(hgx)]
  for (n in xa) { split_cgi(n)}

files_cgi <- list.files(path=paste0(args[3], "/cgi/results/"), pattern="*.txt", full.names=TRUE, recursive=TRUE)

for (i in files_cgi) {cgi(i)}

files_cgi <- list.files(path=paste0(args[3], "/cgi/"), pattern="*.txt", full.names=TRUE, recursive=FALSE)
files_cgi2 <- list.files(path=paste0(args[3], "/cgi/results/"), pattern="*.txt", full.names=TRUE, recursive=TRUE)
for (i in files_cgi) {rename(i, cgi, files_cgi2, args[1])}


########################################################################################

#Merging file genes

#Civic
files_civic <- list.files(path=paste0(args[3], "/civic/"),
                          pattern="*.txt", full.names=TRUE, recursive=FALSE)
files_civic2 <-list.files(path=paste0(args[3], "/civic/results/"),
                          pattern="*.txt", full.names=TRUE, recursive=TRUE)
try({for(i in files_civic) {merging_genes(i, civic, files_civic2)}}, silent = TRUE)
#CGI
files_cgi <- list.files(path=paste0(args[3], "/cgi/"), pattern="*.txt", full.names=TRUE, recursive=FALSE)
files_cgi2 <- list.files(path=paste0(args[3], "/cgi/results/"), pattern="*.txt", full.names=TRUE, recursive=TRUE)
try({for(i in files_cgi) {merging_genes(i, cgi, files_cgi2)}}, silent = TRUE)


###########################################################################################
#merging civic and cgi

files_civic_results <- list.files(path=paste0(args[3], "/civic/results/"),
                          pattern="*.txt", full.names=TRUE, recursive=TRUE)
files_cgi_results <- list.files(path=paste0(args[3], "/cgi/results/"),
                          pattern="*.txt", full.names=TRUE, recursive=TRUE)

for(i in files_civic_results){
for (m in files_cgi_results){
  if (basename(i) == basename(m)){
  civic <- read.csv(i, sep="\t")
  cgi <- read.csv(m, sep="\t")
  if(dim(cgi)[1]!=0 && dim(civic[1])!=0){
  z <- merge(civic,cgi, by=c("Chromosome", "Ref_base", "Var_base", "Start", "Stop", "Gene", "Drug",
                     "Variant", "Type", "Evidence_level", "Evidence_type", "PMID", "Disease",
                     "Clinical_significance", "Evidence_direction",
                     "Citation", "Evidence_statement"), all=TRUE)
  s <- gsub(",([A-Za-z])", ", \\1", z$Drug)
  z["Drug"] <- s
  z <- z[,c("Chromosome","Start", "Stop", "Ref_base", "Var_base", "Gene", "Variant", "Drug", "Drug_interaction_type",
               "Evidence_level", "Evidence_type",
               "PMID", "Clinical_significance", "Evidence_direction", "Evidence_statement", "Variant_summary",
               "Database.x", "Database.y", "Type", "Citation","Disease")]
  disease(z, 20)
  e1 <- e1[,c("Chromosome","Start", "Stop", "Ref_base", "Var_base", "Gene", "Variant", "Drug", "Drug_interaction_type",
               "Evidence_level", "Evidence_type",
                 "Clinical_significance", "Evidence_direction", "Disease", "Variant_summary",
                 "Database.x", "Database.y", "Type", "Citation", "PMID", "Evidence_statement")]
definitive(19, 21, 20)
write.table(e4, paste0(args[3], "/definitive/", tools::file_path_sans_ext(basename(i)) ,".txt"),
              quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
} else if (dim(cgi)[1]==0 && dim(civic[1])!=0){
s <- gsub(",([A-Za-z])", ", \\1", civic$Drug)
civic["Drug"] <- s
civic <- civic[,c("Chromosome","Start", "Stop", "Ref_base", "Var_base", "Gene", "Variant", "Drug", "Drug_interaction_type","Evidence_level", "Evidence_type", "PMID", "Clinical_significance", "Evidence_direction", "Evidence_statement", "Variant_summary", "Database","Citation", "Type", "Disease")]
disease(civic, 19)
e1 <- e1[,c("Chromosome","Start", "Stop", "Ref_base", "Var_base", "Gene", "Variant", "Drug", "Drug_interaction_type","Evidence_level", "Evidence_type",
                        " Clinical_significance", "Evidence_direction", "Disease", "Variant_summary",
                         "Database", "Citation", "PMID", "Type", "Evidence_statement")]
definitive(17, 20, 19)
write.table(e4, paste0(args[3], "/definitive/", tools::file_path_sans_ext(basename(i)) ,".txt"),
              quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
} else if (dim(cgi)[1]!=0 && dim(civic[1])==0){
  s<- gsub(",([A-Za-z])", ", \\1", cgi$Drug)
  cgi["Drug"]<-s
  attach(cgi)
  cgi <- cgi[,c("Chromosome","Start", "Stop", "Ref_base", "Var_base", "Gene", "Variant", "Drug",
                             "Evidence_level", "Evidence_type",
                             "PMID", "Clinical_significance", "Evidence_direction", "Evidence_statement",
                             "Database","Citation", "Type", "Disease")]
  disease(cgi, 17)
  e1 <- e1[,c("Chromosome","Start", "Stop", "Ref_base", "Var_base", "Gene", "Variant", "Drug", "Evidence_level", "Evidence_type", "Clinical_significance", "Evidence_direction", "Disease", "Database", "Citation","PMID", "Type", "Evidence_statement")]
  definitive(15, 18, 17)
  e4$Drug_interaction_type <- " "
  e4$Variant_summary<- " "
  write.table(e4, paste0(args[3], "/definitive/", tools::file_path_sans_ext(basename(i)) ,".txt"),
              quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
} else if(dim(cgi)[1]==0 && dim(civic[1])==0){file.copy(i, paste0(args[3], "/definitive/"))}
}}}

#########################################################################################

#URLS documents

#Leading disease
## URL PMID and Clinical Trial

try({
files_definitivi <- list.files(path=paste0(args[3], "/definitive/"), pattern="*.txt", full.names=TRUE, recursive=TRUE)
for (m in files_definitivi) {URL_creation(m)}
}, silent = TRUE)


#################################################################################################
#Cosmic

files_cosmic <- list.files(path=paste0(args[3], "/cosmic/"),
                            pattern="*.txt", full.names=TRUE, recursive=FALSE)

try({
for(i in files_cosmic){cosmic(i, cosmic)}
}, silent = TRUE)

#URL documents
try({
files_definitivi_cosmic <- list.files(path=paste0(args[3], "/cosmic/results/"), pattern="*.txt", full.names=TRUE, recursive=TRUE)
for (m in files_definitivi_cosmic) {cosmic_url(m)}
}, silent = TRUE)


########################################################################################

#PharmGKB

files_results <- list.files(path=paste0(args[3], "/pharm/"),
                            pattern="*.txt", full.names=TRUE, recursive=TRUE)
for(i in files_results){
  x <- read.csv(i, sep="\t")
  if(nrow(x)!=0){
  attach(x)
  x1 <- x1[,c("Database", "Chromosome","Start", "Stop", "Ref_base", "Var_base", "Gene", "Type", "ID", "Drug", "Significance", "Phenotype.Category", "Sentence", "Notes", "PMID", "Annotation")]
  hgx <- split(x1, paste(x$Gene))
  xa <- hgx[1:length(hgx)]
  for (n in xa) {split_pharm(n)}

files_pharm2 <- list.files(path=paste0(args[3], "/pharm/results/"),
                           pattern="*.txt", full.names=TRUE, recursive=TRUE)
for(i in files_pharm2){
  x <- read.csv(i, sep="\t", stringsAsFactors = FALSE)
  x <- subset.data.frame(x,subset = x$Evidence_level=="yes")
  s <- gsub("\\s+", "", gsub("^\\s+|\\s+$", "", x$Drug))
  x["Drug"] <- s
  s1 <- gsub(",", ", ", x$Drug)
  x["Drug"] <- s1
  x$Evidence_statement<-gsub(x$Evidence_statement, pattern="\\\\x2c", replace=",")
  write.table(x, i , sep="\t", quote=FALSE, row.names=FALSE, col.names=TRUE, na="NA")
}

files_pharm <- list.files(path=paste0(args[3], "/pharm/"),
                           pattern="*.txt", full.names=TRUE, recursive=FALSE)
files_pharm2 <-list.files(path=paste0(args[3], "/pharm/results/"),
                           pattern="*.txt", full.names=TRUE, recursive=FALSE)
for (i in files_pharm) {rename(i, pharm, files_pharm2, args[1])}
#merge genes PharmGKB
try({for (i in files_pharm) {merging_genes(i, pharm, files_pharm2)}}, silent = TRUE)

try({
files_definitivi <- list.files(path=paste0(args[3], "/pharm/results/"), pattern="*.txt", full.names=TRUE, recursive=TRUE)
for (m in files_definitivi) {pharm_url(m)}
}, silent = TRUE)

###########################################################################################

#Food interactions

files_food <- list.files(path=paste0(args[3], "/definitive/"), pattern="*.txt", full.names=TRUE, recursive=TRUE)
files_food_p <- list.files(path=paste0(args[3], "/pharm/results/"), pattern="*.txt", full.names=TRUE, recursive=TRUE)

for (i in files_food) {food_interaction(i, files_food_p)}

################################################################################
#URL PMID/Clinical Trial off

try({
files_definitivi <- list.files(path=paste0(args[3], "/definitive/"), pattern="*.txt", full.names=TRUE, recursive=TRUE)
for (m in files_definitivi) {URL_off(m)}
}, silent = TRUE)
