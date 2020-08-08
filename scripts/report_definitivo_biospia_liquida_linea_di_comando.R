args=commandArgs(trailingOnly = TRUE)

library(filesstrings)
library(data.table)
library(dplyr)

######################################################################################

germ_som <- function(database, args[1]){
germ<-read.csv(paste0("/txt_", database, "/", args[1], "_Germline.txt"), sep= "\t")
som<-read.csv(paste0("/txt_", database, "/", args[1], "_Somatic.txt"), sep= "\t")
if (dim(germ)[1]!=0){
  germ$Type <- "Germline"}else{germ$Type <- character(0)}
if (dim(som)[1]!=0){
  som$Type <- "Somatic"
}
res <- merge(som, germ, all=TRUE)
write.table(res, paste0("/", database, "/", args[1],".txt"),
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

#Civic

split_civic<- function(n){
  t1<-strsplit(as.character(n$Drug), ";;", fixed = T)
  t2<-strsplit(as.character(n$Disease), ";;", fixed = T)
  t3<-strsplit(as.character(n$Drug_interaction_type), ";;", fixed = T)
  t4<-strsplit(as.character(n$Evidence_type), ";;", fixed = T)
  t5<-strsplit(as.character(n$Evidence_level), ";;", fixed = T)
  t6<-strsplit(as.character(n$Evidence_direction), ";;", fixed = T)
  t7<-strsplit(as.character(n$Clinical_significance), ";;", fixed = T)
  t8<-strsplit(as.character(n$Evidence_statement), ";;", fixed = T)
  t9<-strsplit(as.character(n$Variant_summary), ";;", fixed = T)
  t10<-strsplit(as.character(n$Citation_id), ";;", fixed = T)
  t11<-strsplit(as.character(n$Citation), ";;", fixed = T)
  e1<- cbind(n[rep(1:nrow(n), lengths(t1)), 1:2], Drug = unlist(t1))
  e2<- cbind(n[rep(1:nrow(n), lengths(t2)), 1:2], Disease = unlist(t2))
  e3<- cbind(n[rep(1:nrow(n), lengths(t3)), 1:2], Drug_interaction_type = unlist(t3))
  e4<- cbind(n[rep(1:nrow(n), lengths(t4)), 1:2], Evidence_type = unlist(t4))
  e5<- cbind(n[rep(1:nrow(n), lengths(t5)), 1:2], Evidence_level = unlist(t5))
  e6<- cbind(n[rep(1:nrow(n), lengths(t6)), 1:2], Evidence_direction = unlist(t6))
  e7<- cbind(n[rep(1:nrow(n), lengths(t7)), 1:2], Clinical_significance = unlist(t7))
  e8<- cbind(n[rep(1:nrow(n), lengths(t8)), 1:2], Evidence_statement = unlist(t8))
  e9<- cbind(n[rep(1:nrow(n), lengths(t9)), 1:2], Variant_summary = unlist(t9))
  e10<- cbind(n[rep(1:nrow(n), lengths(t10)), 1:2], Citation_id = unlist(t10))
  e11<- cbind(n[rep(1:nrow(n), lengths(t11)), 1:9], Citation = unlist(t11))
  m<-max(nrow(e1),nrow(e2),nrow(e3),nrow(e4),nrow(e5),nrow(e6),
         nrow(e7),nrow(e8),nrow(e9),nrow(e10),nrow(e11))
  if (nrow(e1)<m) e1[nrow(e1)+(m-nrow(e1)),] <- NA
  if (nrow(e2)<m) e2[nrow(e2)+(m-nrow(e2)),] <- NA
  if (nrow(e3)<m) e3[nrow(e3)+(m-nrow(e3)),] <- NA
  if (nrow(e4)<m) e4[nrow(e4)+(m-nrow(e4)),] <- NA
  if (nrow(e5)<m) e5[nrow(e5)+(m-nrow(e5)),] <- NA
  if (nrow(e6)<m) e6[nrow(e6)+(m-nrow(e6)),] <- NA
  if (nrow(e7)<m) e7[nrow(e7)+(m-nrow(e7)),] <- NA
  if (nrow(e8)<m) e8[nrow(e8)+(m-nrow(e8)),] <- NA
  if (nrow(e9)<m) e9[nrow(e9)+(m-nrow(e9)),] <- NA
  if (nrow(e10)<m) e10[nrow(e10)+(m-nrow(e10)),] <- NA
  if (nrow(e11)<m) e11[nrow(e11)+(m-nrow(e11)),] <- NA
  f3<-data.frame(e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11)
  f3$Database.9<-"Civic"
  f2 <- function(x) {
    for(i in seq_along(x)[-1]) if(is.na(x[i])) x[i] <- x[i-1]
    x
  }
  Chromosome<-f2(f3$Chromosome.9)
  Start<-f2(f3$Start)
  Stop<-f2(f3$Stop)
  Ref_base<-f2(f3$Ref_base)
  Var_base<-f2(f3$Var_base)
  Gene<-f2(f3$Gene)
  Variant<-f2(f3$Variant)
  Type <- f2(f3$Type)
  f3$Chromosome<-Chromosome
  f3$Start<-Start
  f3$Stop<-Stop
  f3$Ref_base<-Ref_base
  f3$Var_base<-Var_base
  f3$Gene<-Gene
  f3$Variant<-Variant
  f3$Type <- Type
  f3$Database.1<-NULL
  f3$Database.2<-NULL
  f3$Database.3<-NULL
  f3$Database.4<-NULL
  f3$Database.5<-NULL
  f3$Database.6<-NULL
  f3$Database.7<-NULL
  f3$Database.8<-NULL
  f3$Database<-NULL
  f3$Database.10<-NULL
  f3$Database.11<-NULL
  f3$Chromosome.1<-NULL
  f3$Chromosome.2<-NULL
  f3$Chromosome.3<-NULL
  f3$Chromosome.4<-NULL
  f3$Chromosome.5<-NULL
  f3$Chromosome.6<-NULL
  f3$Chromosome.7<-NULL
  f3$Chromosome.8<-NULL
  f3$Chromosome.9<-NULL
  f3$Chromosome.10<-NULL
  f3$Chromosome.11<-NULL
  f3$Evidence_statement<-gsub(f3$Evidence_statement, pattern="ï¿½", replace="-")
  colnames(f3)[11] <- "Database"
  write.table(f3, paste0("/civic/results/", tools::file_path_sans_ext(basename(i)), "__", n$Gene, ".txt") , sep="\t", quote=FALSE,
              row.names=FALSE, col.names=TRUE, na="NA")
}

files_results <- list.files(path="/civic/",
                            pattern="*.txt", full.names=TRUE, recursive=TRUE)


for(i in files_results){
  x<-read.csv(i, sep="\t", stringsAsFactors = FALSE)
  if (dim(x)[1]!=0){
  attach(x)
  x1<-subset(x, select= c(Database, Chromosome,Start, Stop, Ref_base, Var_base, Gene, Variant, Type, Disease, Drug,
                          Drug_interaction_type, Evidence_type, Evidence_level, Evidence_direction,
                          Clinical_significance, Evidence_statement, Variant_summary,
                          Citation_id, Citation))
  hgx<-split(x1, paste(x$Gene, x$Variant))
  xa<-hgx[1:length(hgx)]
  for (n in xa) {split_civic(n)}

files_results1 <- list.files(path="/civic/results/",
                            pattern="*.txt", full.names=TRUE, recursive=TRUE)
for(i in files_results1){
  t<-read.csv(i, sep="\t")
  d<-gsub(t$Evidence_level, pattern = "C", replace="Case study")
  t["Evidence_level"]<-d
  e<-gsub(t$Evidence_level, pattern = "D", replace="Preclinical evidence")
  t["Evidence_level"]<-e
  f<-gsub(t$Evidence_level, pattern = "A", replace="Validated association")
  t["Evidence_level"]<-f
  g<-gsub(t$Evidence_level, pattern = "B", replace="Clinical evidence")
  t["Evidence_level"]<-g
  h<-gsub(t$Evidence_level, pattern = "E", replace="Inferential association")
  t["Evidence_level"]<-h
  r<-gsub(t$Drug, pattern="\\\\x2c", replace=",")
  t["Drug"]<-r
  r<-gsub(t$Evidence_statement, pattern="\\\\x2c", replace=",")
  t["Evidence_statement"]<-r
  v<-gsub(t$Citation, pattern="\\\\x2c", replace=",")
  t["Citation"]<-v
  u<-gsub(t$Variant_summary, pattern="\\\\x2c", replace=",")
  t["Variant_summary"]<-u
  colnames(t)[12]<-"PMID"
  write.table(t, i , sep="\t", quote=FALSE, row.names=FALSE, col.names=TRUE, na="NA")
}

rename <- function(i, database, files, args[1]){
dir.create(paste0("/", database, "/results/", tools::file_path_sans_ext(basename(i)), "/"))
for (m in files) {
  if (tools::file_path_sans_ext(basename(word(m, 1, sep = "__"))) == tools::file_path_sans_ext(basename(i))){
    file.move(paste0("/", database, "/results/", tools::file_path_sans_ext(basename(m)), ".txt"),
              paste0("/", database, "/results/", tools::file_path_sans_ext(basename(i)), "/"))
  } else next()
}
} } else {
  file.rename(i , paste0("/", database, "/results/",args[1],".txt"))
  }
}


files_civic <- list.files(path="/civic/",
                          pattern="*.txt", full.names=TRUE, recursive=FALSE)
files_civic2 <-list.files(path="/civic/results/",
                          pattern="*.txt", full.names=TRUE, recursive=TRUE)


for (i in files_civic) {rename(i, civic, files_civic2, args[1])}

##########################################################################################

#CGI

split_cgi<- function(n){
  n$ann1<- NULL
  n$ann2<-NULL
  n$het<- NULL
  t1<-strsplit(as.character(n$Drug), ";;", fixed = T)
  t2<-strsplit(as.character(n$Clinical_significance), ";;", fixed = T)
  t3<-strsplit(as.character(n$Biomarker), ";;", fixed = T)
  t4<-strsplit(as.character(n$Drug.family), ";;", fixed = T)
  t5<-strsplit(as.character(n$Drug.full.name), ";;", fixed = T)
  t6<-strsplit(as.character(n$Drug.status), ";;", fixed = T)
  t7<-strsplit(as.character(n$Evidence_level), ";;", fixed = T)
  t8<-strsplit(as.character(n$Disease), ";;", fixed = T)
  t9<-strsplit(as.character(n$PMID), ";;", fixed = T)
  t10<-strsplit(as.character(n$Targeting), ";;", fixed = T)
  t11<-strsplit(as.character(n$info), ";;", fixed = T)
  t12<-strsplit(as.character(n$region), ";;", fixed = T)
  t13<-strsplit(as.character(n$strand), ";;", fixed = T)
  t14<-strsplit(as.character(n$Evidence_statement), ";;", fixed = T)
  t15<-strsplit(as.character(n$Citation), ";;", fixed = T)
  e1<- cbind(n[rep(1:nrow(n), lengths(t1)), 1:9], Drug = unlist(t1))
  e2<- cbind(n[rep(1:nrow(n), lengths(t2)), 1:2], Clinical_significance = unlist(t2))
  e3<- cbind(n[rep(1:nrow(n), lengths(t3)), 1:2], Biomarker = unlist(t3))
  e4<- cbind(n[rep(1:nrow(n), lengths(t4)), 1:2], Drug.family = unlist(t4))
  e5<- cbind(n[rep(1:nrow(n), lengths(t5)), 1:2], Drug.full.name = unlist(t5))
  e6<- cbind(n[rep(1:nrow(n), lengths(t6)), 1:2], Drug.status = unlist(t6))
  e7<- cbind(n[rep(1:nrow(n), lengths(t7)), 1:2], Evidence_level = unlist(t7))
  e8<- cbind(n[rep(1:nrow(n), lengths(t8)), 1:2], Disease = unlist(t8))
  e9<- cbind(n[rep(1:nrow(n), lengths(t9)), 1:2], PMID = unlist(t9))
  e10<- cbind(n[rep(1:nrow(n), lengths(t10)), 1:2], Targeting = unlist(t10))
  e11<- cbind(n[rep(1:nrow(n), lengths(t11)), 1:2], info = unlist(t11))
  e12<- cbind(n[rep(1:nrow(n), lengths(t12)), 1:2], region = unlist(t12))
  e13<- cbind(n[rep(1:nrow(n), lengths(t13)), 1:2],  strand= unlist(t13))
  e14<- cbind(n[rep(1:nrow(n), lengths(t14)), 1:2], Evidence_statement = unlist(t14))
  e15<- cbind(n[rep(1:nrow(n), lengths(t15)), 1:2],  Citation= unlist(t15))
  m<-max(nrow(e1),nrow(e2),nrow(e3),nrow(e4),nrow(e5),nrow(e6),
         nrow(e7),nrow(e8),nrow(e9),nrow(e10),nrow(e11), nrow(e12), nrow(e13))
  if (nrow(e1)<m) e1[nrow(e1)+(m-nrow(e1)),] <- NA
  if (nrow(e2)<m) e2[nrow(e2)+(m-nrow(e2)),] <- NA
  if (nrow(e3)<m) e3[nrow(e3)+(m-nrow(e3)),] <- NA
  if (nrow(e4)<m) e4[nrow(e4)+(m-nrow(e4)),] <- NA
  if (nrow(e5)<m) e5[nrow(e5)+(m-nrow(e5)),] <- NA
  if (nrow(e6)<m) e6[nrow(e6)+(m-nrow(e6)),] <- NA
  if (nrow(e7)<m) e7[nrow(e7)+(m-nrow(e7)),] <- NA
  if (nrow(e8)<m) e8[nrow(e8)+(m-nrow(e8)),] <- NA
  if (nrow(e9)<m) e9[nrow(e9)+(m-nrow(e9)),] <- NA
  if (nrow(e10)<m) e10[nrow(e10)+(m-nrow(e10)),] <- NA
  if (nrow(e11)<m) e11[nrow(e11)+(m-nrow(e11)),] <- NA
  if (nrow(e12)<m) e12[nrow(e12)+(m-nrow(e12)),] <- NA
  if (nrow(e13)<m) e13[nrow(e13)+(m-nrow(e13)),] <- NA
  if (nrow(e14)<m) e12[nrow(e14)+(m-nrow(e14)),] <- NA
  if (nrow(e15)<m) e13[nrow(e15)+(m-nrow(e15)),] <- NA
  f3<-data.frame(e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12,e13,e14,e15)
  f3$Database<-"Cancer Genome Interpreter"
  f2 <- function(x) {
    for(i in seq_along(x)[-1]) if(is.na(x[i])) x[i] <- x[i-1]
    x
  }
  Chromosome<-f2(f3$Chromosome)
  Start<-f2(f3$Start)
  Stop<-f2(f3$Stop)
  Ref_base<-f2(f3$Ref_base)
  Var_base<-f2(f3$Var_base)
  Gene<-f2(f3$Gene)
  individual_mutation<-f2(f3$individual_mutation)
  Type <- f2(f3$Type)
  f3$Chromosome<-Chromosome
  f3$Start<-Start
  f3$Stop<-Stop
  f3$Ref_base<-Ref_base
  f3$Var_base<-Var_base
  f3$Gene<-Gene
  f3$individual_mutation<-individual_mutation
  f3$Type <- Type
  f3$Database.1<-NULL
  f3$Database.2<-NULL
  f3$Database.3<-NULL
  f3$Database.4<-NULL
  f3$Database.5<-NULL
  f3$Database.6<-NULL
  f3$Database.7<-NULL
  f3$Database.8<-NULL
  f3$Database.9<-NULL
  f3$Database.10<-NULL
  f3$Database.11<-NULL
  f3$Database.12<-NULL
  f3$Database.13<-NULL
  f3$Database.14<-NULL
  f3$Database.15<-NULL
  f3$Chromosome.1<-NULL
  f3$Chromosome.2<-NULL
  f3$Chromosome.3<-NULL
  f3$Chromosome.4<-NULL
  f3$Chromosome.5<-NULL
  f3$Chromosome.6<-NULL
  f3$Chromosome.7<-NULL
  f3$Chromosome.8<-NULL
  f3$Chromosome.9<-NULL
  f3$Chromosome.10<-NULL
  f3$Chromosome.11<-NULL
  f3$Chromosome.12<-NULL
  f3$Chromosome.13<-NULL
  f3$Chromosome.14<-NULL
  f3$Chromosome.15<-NULL
  write.table(f3, paste0("/cgi/results/", tools::file_path_sans_ext(basename(i)), "__", n$Gene, ".txt") , sep="\t", quote=FALSE,
              row.names=FALSE, col.names=TRUE, na="NA")
}

files_results <- list.files(path="/cgi/",
                            pattern="*.txt", full.names=TRUE, recursive=TRUE)

for(i in files_results){
  x<-read.csv(i, sep="\t")
  if(dim(x)[1]!=0){
  attach(x)
  x1<-subset(x,select= c(Database, Chromosome, Start, Stop, Ref_base, Var_base, Gene, individual_mutation, Type, Drug, Drug.family,
                 Drug.full.name, Drug.status, Clinical_significance, Biomarker, Evidence_level, Disease,
                 PMID, Targeting, strand, info, region, Evidence_statement, Citation))
  hgx<-split(x1, paste(x$Gene, x$individual_mutation))
  xa<-hgx[1:length(hgx)]
  for (n in xa) { split_cgi(n)}



files_cgi <- list.files(path="/cgi/results/", pattern="*.txt", full.names=TRUE, recursive=TRUE)
for (i in files_cgi) {
  n<-read.csv(i, sep="\t")
  if(dim(n)[1]!=0){
  Variant<-gsub(".*:(.*)", "\\1", n$individual_mutation)
  n$Variant<-Variant
  n$individual_mutation<-NULL
  a<-gsub(n$Drug, pattern=" *\\[.*?\\] *", replace=" ")
  n["Drug"]<-a
  n$info<-NULL
  n$Evidence_type<-"Predictive"
  n$Drug<- NULL
  colnames(n)[12]<-"Drug"
  n$strand <- NULL
  n$Transcript <- NULL
  n$region <- NULL
  n$Biomarker <- NULL
  n$Targeting <- NULL
  n$Drug.status <- NULL
  n$Drug.family <- NULL
  n$Evidence_direction<-"Supports"
  a<-gsub(n$Drug, pattern=" *\\(.*?\\) *", replace=" ")
  n["Drug"]<-a
  nx<-gsub(n$PMID, pattern="PMID:", replace=" ")
  n["PMID"]<-nx
    write.table(n, i , sep="\t", quote=FALSE, row.names=FALSE, col.names=TRUE, na="NA")
}}


  files_cgi <- list.files(path="/cgi/", pattern="*.txt", full.names=TRUE, recursive=FALSE)
  files_cgi2 <- list.files(path="/cgi/results/", pattern="*.txt", full.names=TRUE, recursive=TRUE)
  for (i in files_cgi) {rename(i, cgi, files_cgi2, args[1])}


########################################################################################

#Merging file genes

merging_genes <- function(i, database, files){
setwd(paste0("/", database, "/results/", tools::file_path_sans_ext(basename(i)), "/"))
temp <- list.files(path=paste0("/", database, "/results/", tools::file_path_sans_ext(basename(i)), "/"), pattern="*.txt")
myfiles <- lapply(temp, read.delim)
file <- do.call("rbind", myfiles)
for(m in files) {
  unlink(paste0("/", database, "/results/", tools::file_path_sans_ext(basename(i)), "/", tools::file_path_sans_ext(basename(m)), ".txt"))
}
write.table(file, paste0("/", database, "/results/",  tools::file_path_sans_ext(basename(i)), "/", tools::file_path_sans_ext(basename(i)), ".txt"), sep="\t",quote=FALSE, row.names=FALSE, na="NA")
}

#Civic
files_civic <- list.files(path="/civic/",
                          pattern="*.txt", full.names=TRUE, recursive=FALSE)
files_civic2 <-list.files(path="/civic/results/",
                          pattern="*.txt", full.names=TRUE, recursive=TRUE)
try({for(i in files_civic) {merging_genes(i, civic, files_civic2)}}, silent = TRUE)
#CGI
files_cgi <- list.files(path="/cgi/", pattern="*.txt", full.names=TRUE, recursive=FALSE)
files_cgi2 <- list.files(path="/cgi/results/", pattern="*.txt", full.names=TRUE, recursive=TRUE)
try({for(i in files_cgi) {merging_genes(i, cgi, files_cgi2)}}, silent = TRUE)


###########################################################################################
#merging civic and cgi

disease <- function(df, val_dis){
t1 <- strsplit(as.character(df$Disease), ";", fixed = T)
e1 <- cbind(df[rep(1:nrow(df), lengths(t1)), 1:val_dis], Disease = unlist(t1))
e1 <- data.frame(e1)
r <- gsub(e1$Evidence_statement, pattern="\\\\x2c", replace=",")
e1["Evidence_statement"] <- r
t <- gsub(e1$Citation, pattern="\\\\x2c", replace=",")
e1["Citation"] <- t
attach(e1)
e1 <<- e1
}

definitive <- function(val_cit, len_dat, val_ev){
colnames(e1)[val_cit] <- "citation"
  t2 <- strsplit(as.character(e1$citation), ",,", fixed = T)
  e2 <- cbind(e1[rep(1:nrow(e1), lengths(t2)), 1:len_dat], Citation = unlist(t2))
  e2$citation <- NULL
  colnames(e2)[val_ev] <- "Evidence_Statement"
  t3 <-strsplit(as.character(e2$Evidence_Statement), ",,", fixed = T)
  e3 <- cbind(e2[rep(1:nrow(e2), lengths(t3)), 1:len_dat], Evidence_statement = unlist(t3))
  e3$Evidence_Statement <- NULL
  colnames(e3)[val_cit] <- "pmid"
  t4<-strsplit(as.character(e3$pmid), ";", fixed = T)
  e4<- cbind(e3[rep(1:nrow(e3), lengths(t4)), 1:len_dat], PMID = unlist(t4))
  e4$pmid <- NULL
  e4 <- unique(e4)
  e4 <<- e4
}

files_civic_results <- list.files(path="/civic/results/",
                          pattern="*.txt", full.names=TRUE, recursive=TRUE)
files_cgi_results <- list.files(path="/cgi/results/",
                          pattern="*.txt", full.names=TRUE, recursive=TRUE)

for(i in files_civic_results){
for (m in files_cgi_results){
  if (basename(i) == basename(m)){
  civic <- read.csv(i, sep="\t")
  cgi <- read.csv(m, sep="\t")
  if(dim(cgi)[1]!=0 && dim(civic[1])!=0){
  z <- merge(civic,cgi, by=c("Chromosome", "Ref_base", "Var_base", "Start", "Stop", "Gene", "Drug",
                     "Variant", "Type", "Evidence_level", "Evidence_type","PMID", "Disease",
                     "Clinical_significance", "Evidence_direction",
                     "Citation", "Evidence_statement"), all=TRUE)
  s <- gsub(",([A-Za-z])", ", \\1", z$Drug)
  z["Drug"] <- s
  attach(z)
  z <- subset(z, select= c(Chromosome,Start, Stop, Ref_base, Var_base, Gene, Variant, Drug, Drug_interaction_type,
                Evidence_level, Evidence_type,
                PMID, Clinical_significance, Evidence_direction, Evidence_statement, Variant_summary,
                Database.x, Database.y, Type, Citation,Disease))
  disease(z, 20)
  e1 <- subset(e1, select= c(Chromosome,Start, Stop, Ref_base, Var_base, Gene, Variant, Drug, Drug_interaction_type,
                 Evidence_level, Evidence_type,
                 Clinical_significance, Evidence_direction, Disease, Variant_summary,
                 Database.x, Database.y, Type, Citation, PMID, Evidence_statement))
definitive(19, 21, 20)
write.table(e4,paste0("/definitive/", tools::file_path_sans_ext(basename(i)) ,".txt"),
              quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
} else if (dim(cgi)[1]==0 && dim(civic[1])!=0){
s <- gsub(",([A-Za-z])", ", \\1", civic$Drug)
civic["Drug"] <- s
attach(civic)
civic <- subset(civic, select= c(Chromosome,Start, Stop, Ref_base, Var_base, Gene, Variant, Drug, Drug_interaction_type,
                       Evidence_level, Evidence_type,
                       PMID, Clinical_significance, Evidence_direction, Evidence_statement, Variant_summary,
                       Database, Citation, Type, Disease))
disease(civic, 19)
e1 <- subset(e1, select= c(Chromosome,Start, Stop, Ref_base, Var_base, Gene, Variant, Drug, Drug_interaction_type,
                         Evidence_level, Evidence_type,
                         Clinical_significance, Evidence_direction, Disease, Variant_summary,
                         Database, Citation, PMID, Type, Evidence_statement))
definitive(17, 20, 19)
write.table(e4, paste0("/definitive/", tools::file_path_sans_ext(basename(i)) ,".txt"),
              quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
} else if (dim(cgi)[1]!=0 && dim(civic[1])==0){
  s<- gsub(",([A-Za-z])", ", \\1", cgi$Drug)
  cgi["Drug"]<-s
  attach(cgi)
  cgi<-subset(cgi, select= c(Chromosome,Start, Stop, Ref_base, Var_base, Gene, Variant, Drug,
                             Evidence_level, Evidence_type,
                             PMID, Clinical_significance, Evidence_direction, Evidence_statement,
                             Database,Citation, Type, Disease))
  disease(cgi, 17)
  e1<-subset(e1, select= c(Chromosome,Start, Stop, Ref_base, Var_base, Gene, Variant, Drug,
                           Evidence_level, Evidence_type,
                           Clinical_significance, Evidence_direction, Disease,
                           Database, Citation,PMID, Type, Evidence_statement))
  definitive(15, 18, 17)
  e4$Drug_interaction_type <- " "
  e4$Variant_summary<- " "
  write.table(e4,paste0("/definitive/", tools::file_path_sans_ext(basename(i)) ,".txt"),
              quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
} else if(dim(cgi)[1]==0 && dim(civic[1])==0){file.copy(i, "/definitive/")}
}}}

#########################################################################################

#URLS documents

readUrl <- function(url) {
  out <- tryCatch(
    {
      message("This is the 'try' part")
      readLines(con=url, warn=FALSE)
    },
    error=function(cond) {
      message(paste("URL does not seem to exist:", url))
      message("Here's the original error message:")
      message(cond)
      return(NA)
    },
    warning=function(cond) {
      message(paste("URL caused a warning:", url))
      message("Here's the original warning message:")
      message(cond)
      return(NA)
    },
    finally={
      message(paste("Processed URL:", url))
      message("Ok")
    }
  )
  return(out)
}

#Leading disease
## URL PMID and Clinical Trial

try({
files_definitivi <- list.files(path="/definitive/", pattern="*.txt", full.names=TRUE, recursive=TRUE)
for (m in files_definitivi) {
  x <- read.csv(m, sep="\t")
  dis<-read.csv("/Disease.txt", sep= "\t")
  attach(x)
  if(dim(x)[1]!=0){
  x <- merge(dis, x, by= "Disease")
  x$Disease <- NULL
  colnames(x)[1] <- "Disease"
  x <- sapply(x, as.character)
  x[is.na(x)] <- " "
  x <- as.data.frame(x)
  x <- subset.data.frame(x,subset = x$Evidence_direction=="Supports")
  x <- subset.data.frame(x,subset = x$Disease==args[2])
    x$Drug <- as.character(x$Drug , levels=(x$Drug))
    x<-x[order(x$Drug), ]
    x$Evidence_type <- factor(x$Evidence_type , levels = c("Diagnostic", "Prognostic","Predisposing","Predictive"))
    x <- x[order(x$Evidence_type), ]
    x$Evidence_level  <- factor(x$Evidence_level , levels = c("Validated association","FDA guidelines", "NCCN guidelines", "Clinical evidence","Late trials", "Early trials",  "Case study","Case report","Preclinical evidence", "Pre-clinical", "Inferential association"))
    x <- x[order(x$Evidence_level), ]
    x$Disease <- as.character(x$Disease , levels=(x$Disease))
    x <- x[order(x$Disease), ]
    x <- data.frame(x, Reference=1:length(x$Disease))
    row.names(x) <- NULL
    hgx <- split(x, paste(x$Gene, x$Variant, x$Disease==args[2]))
    xa <- hgx[1:length(hgx)]
    link_pmid <- data.frame()
    link_cli <- data.frame()
    for(n in xa){
      n <- subset.data.frame(n,subset = n$Evidence_direction=="Supports")
        if (dim(n)[1]!=0){
        row.names(n) <- NULL
        n$Drug <- as.character(n$Drug , levels=(n$Drug))
        n<-n[order(n$Drug), ]
        n$Evidence_type  <- factor(n$Evidence_type , levels = c("Diagnostic", "Prognostic","Predisposing","Predictive"))
        n <- n[order(n$Evidence_type), ]
        n$Evidence_level  <- factor(n$Evidence_level , levels = c("Validated association","FDA guidelines", "NCCN guidelines", "Clinical evidence","Late trials", "Early trials",  "Case study","Case report","Preclinical evidence", "Pre-clinical", "Inferential association"))
        n <- n[order(n$Evidence_level), ]
          for (i in 1:length(n$PMID)) {
          a <- paste0("https://www.ncbi.nlm.nih.gov/pubmed/", n$PMID[i])
          df_pm <- data.frame(Citation = n$Citation[i], Gene=n$Gene[i], PMID=a, Cod=n$PMID[i], Reference= n$Reference[i])
          link_pmid <- rbind(link_pmid, df_pm)
          }
          for (i in 1:length(n$Drug)) {
          cltr <- paste0("https://clinicaltrials.gov/ct2/results?cond=", n$Variant[i],"&term=", gsub(" ", "", n$Drug[i], fixed = TRUE), "&cntry=&state=&city=&dist=")
          df_cli <- data.frame(Drug = n$Drug[i], Gene= n$Gene[i], Variant= n$Variant[i], Clinical_trial=cltr, Reference= n$Reference[i])
          link_cli <- rbind(link_cli, df_cli)
          }
    }
  }
  urls_pmid <- data.frame()
  for (t in 1:length(link_pmid$PMID)){
    url <- as.character(link_pmid$PMID[t])
    y <- lapply(url, readUrl)
      if (is.na(y)){next()
      } else {
        df <- data.frame(PMID=url, Cod=link_pmid$Cod[t], Gene=link_pmid$Gene[t], Citation=link_pmid$Citation[t], Reference=link_pmid$Reference[t])
        urls_pmid <- rbind(urls_pmid,df)
        }
  }
write.table(urls_pmid, paste0("/Reference/",tools::file_path_sans_ext(basename(m)),".txt"), quote=FALSE,
            row.names = FALSE, na= "NA", sep = "\t")

    urls_cli <- data.frame()
    for (t in 1:length(link_cli$Clinical_trial)){
      url <- as.character(link_cli$Clinical_trial[t])
      y <- lapply(url, readUrl)
        if (is.na(y)){next()
        } else {
        df <- data.frame(Clinical_trial=url, Gene= n$Gene[t], Variant= n$Variant[t], Reference=link_cli$Reference[t], Drug=link_cli$Drug[t])
        urls_cli <- rbind(urls_cli,df)
        }
    }
write.table(urls_cli ,paste0("/Trial/",tools::file_path_sans_ext(basename(m)) ,".txt"), quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
}}
}, silent = TRUE)


#################################################################################################
#Cosmic

files_cosmic <- list.files(path="/cosmic/",
                            pattern="*.txt", full.names=TRUE, recursive=FALSE)
try({for(i in files_cosmic){
  cos<-read.csv(i, sep="\t")
  if(nrow(cos)!=0){
      cos$Sample.Name <- NULL
      cos$Sample.ID <- NULL
      cos$Transcript <- NULL
      cos$Census.Gene <- NULL
      cos$MUTATION_ID <- NULL
      cos$ID <- NULL
      cos$LEGACY_MUTATION_ID <- NULL
      cos$CDS.Mutation <- NULL
      cos$CGP.Study <- NULL
      cos$Tier <- NULL
      cos$Variant <- gsub(cos$AA.Mutation, pattern="p.", replace="")
      cos$AA.Mutation <- NULL
      colnames(cos)[9] <- "Pubmed"
      cos$Stop <- NULL
      cos$Stop <- sub('.*\\.', '', cos$Genome.Coordinates..GRCh37.)
      a <- sub('.*\\:', '', cos$Genome.Coordinates..GRCh37.)
      cos$Start <- gsub("\\..*","",a)
      colnames(cos)[1] <- "Gene"
      colnames(cos)[2] <- "Drug"
      cos$Genome.Coordinates..GRCh37. <- NULL
      write.table(cos, paste0("/cosmic/results/", tools::file_path_sans_ext(basename(i)), ".txt") , sep="\t", quote=FALSE,
                  row.names=FALSE, col.names=TRUE, na="NA")

files_results <- list.files(path="/cosmic/results/",
                                 pattern="*.txt", full.names=TRUE, recursive=FALSE)
for (i in files_cosmic) {
  dir.create(paste0("/cosmic/results/", tools::file_path_sans_ext(basename(i)), "/"))
  for (m in files_results) {
    if (tools::file_path_sans_ext(basename(m)) == tools::file_path_sans_ext(basename(i))){
      file.move(paste0("/cosmic/results/", tools::file_path_sans_ext(basename(m)), ".txt"),
                paste0("/cosmic/results/", tools::file_path_sans_ext(basename(i)), "/"))
    }else next()
  }
    }}else {dir.create(paste0("/cosmic/results/", args[1], "/"))
      file.rename(i , paste0("/cosmic/results/",args[1],"/",args[1],".txt"))
}}

}, silent = TRUE)

#URL documents

try({
files_definitivi_cosmic <- list.files(path="/cosmic/results/", pattern="*.txt", full.names=TRUE, recursive=TRUE)
for (m in files_definitivi_cosmic) {
  x <- read.csv(m, sep="\t")
  attach(x)
  x[is.na(x)] <- " "
  x$Drug <- as.character(x$Drug , levels=(x$Drug))
  x <- x[order(x$Drug), ]
  x$Gene <- as.character(x$Gene , levels=(x$Gene))
  x <- x[order(x$Gene), ]
  x$Pubmed <- as.character(x$Pubmed , levels=(x$Pubmed))
  x <- x[order(x$Pubmed),]
  x <- data.frame(x, Reference=1:length(x$Drug))
  row.names(x) <- NULL
  hgx <- split(x, paste(x$Gene))
  xa <- hgx[1:length(hgx)]
  link <- data.frame()
  urls <- data.frame()
  #i <- 1
  for (n in xa){
    if (dim(n)[1]!=0){
      row.names(n)<-NULL
      n$Drug <- as.character(n$Drug , levels=(n$Drug))
      n<-n[order(n$Drug), ]
      n$Gene <- as.character(n$Gene , levels=(n$Gene))
      n<-n[order(n$Gene), ]
      for (i in 1:length(n$Pubmed)) {
        a <-paste0("https://www.ncbi.nlm.nih.gov/pubmed/", n$Pubmed[i])
        df <- data.frame(Gene=n$Gene[i], PMID=a, Cod=n$Pubmed[i], Reference= n$Reference[i])
        link <- rbind(link,df)
      }}}
  for (t in 1:length(link$PMID)){
    url <- as.character(link$PMID[t])
    y <- lapply(url, readUrl)
    if (is.na(y)){next()
    }else { df <- data.frame(PMID=url, Cod=link$Cod[t], Gene=link$Gene[t], Reference=link$Reference[t])
    urls <- rbind(urls,df)
    }
  }
  write.table(urls,paste0("/Reference/",tools::file_path_sans_ext(basename(m)),"_cosmic.txt"), quote=FALSE,
              row.names = FALSE, na= "NA", sep = "\t")
}
}, silent = TRUE)


########################################################################################

#PharmGKB

split_pharm<- function(n){
  t1<-strsplit(as.character(n$ID), ";;", fixed = T)
  t2<-strsplit(as.character(n$Drug), ";;", fixed = T)
  t3<-strsplit(as.character(n$Significance), ";;", fixed = T)
  t4<-strsplit(as.character(n$Phenotype.Category), ";;", fixed = T)
  t5<-strsplit(as.character(n$Sentence), ";;", fixed = T)
  t6<-strsplit(as.character(n$Notes), ";;", fixed = T)
  t7<-strsplit(as.character(n$PMID), ";;", fixed = T)
  t8<-strsplit(as.character(n$Annotation), ";;", fixed = T)
  e1<- cbind(n[rep(1:nrow(n), lengths(t1)), 1:8], Variant = unlist(t1))
  e2<- cbind(n[rep(1:nrow(n), lengths(t2)), 1:2], Drug = unlist(t2))
  e3<- cbind(n[rep(1:nrow(n), lengths(t3)), 1:2], Evidence_level = unlist(t3))
  e4<- cbind(n[rep(1:nrow(n), lengths(t4)), 1:2], Clinical_significance = unlist(t4))
  e5<- cbind(n[rep(1:nrow(n), lengths(t5)), 1:2], Variant_summary = unlist(t5))
  e6<- cbind(n[rep(1:nrow(n), lengths(t6)), 1:2], Evidence_statement = unlist(t6))
  e7<- cbind(n[rep(1:nrow(n), lengths(t7)), 1:2], PMID = unlist(t7))
  e8<- cbind(n[rep(1:nrow(n), lengths(t8)), 1:2], PharmGKB_ID = unlist(t8))
  m<-max(nrow(e1),nrow(e2),nrow(e3),nrow(e4),nrow(e5),nrow(e6),
         nrow(e7),nrow(e8))
  if (nrow(e1)<m) e1[nrow(e1)+(m-nrow(e1)),] <- NA
  if (nrow(e2)<m) e2[nrow(e2)+(m-nrow(e2)),] <- NA
  if (nrow(e3)<m) e3[nrow(e3)+(m-nrow(e3)),] <- NA
  if (nrow(e4)<m) e4[nrow(e4)+(m-nrow(e4)),] <- NA
  if (nrow(e5)<m) e5[nrow(e5)+(m-nrow(e5)),] <- NA
  if (nrow(e6)<m) e6[nrow(e6)+(m-nrow(e6)),] <- NA
  if (nrow(e7)<m) e7[nrow(e7)+(m-nrow(e7)),] <- NA
  if (nrow(e8)<m) e8[nrow(e8)+(m-nrow(e8)),] <- NA
  f3<-data.frame(e1,e2,e3,e4,e5,e6,e7,e8)
  f3$Database<-"PharmGKB"
  f2 <- function(x) {
    for(i in seq_along(x)[-1]) if(is.na(x[i])) x[i] <- x[i-1]
    x
  }
  Chromosome<-f2(f3$Chromosome)
  Start<-f2(f3$Start)
  Stop<-f2(f3$Stop)
  Ref_base<-f2(f3$Ref_base)
  Var_base<-f2(f3$Var_base)
  Gene<-f2(f3$Gene)
  Type <-f2(f3$Type)
  f3$Chromosome<-Chromosome
  f3$Start<-Start
  f3$Stop<-Stop
  f3$Ref_base<-Ref_base
  f3$Var_base<-Var_base
  f3$Gene<-Gene
  f3$Type <- Type
  f3$Database.1<-NULL
  f3$Database.2<-NULL
  f3$Database.3<-NULL
  f3$Database.4<-NULL
  f3$Database.5<-NULL
  f3$Database.6<-NULL
  f3$Database.7<-NULL
  f3$Database.8<-NULL
  f3$Chromosome.1<-NULL
  f3$Chromosome.2<-NULL
  f3$Chromosome.3<-NULL
  f3$Chromosome.4<-NULL
  f3$Chromosome.5<-NULL
  f3$Chromosome.6<-NULL
  f3$Chromosome.7<-NULL
  f3$Chromosome.8<-NULL
  f3$Drug<-gsub(f3$Drug, pattern="\\\\x2c", replace=",")
  f3$Drug<-gsub(f3$Drug, pattern="*\\(.*?\\) *", replace="")
  f3$Gene<-gsub(f3$Gene, pattern="*\\(.*?\\) *", replace="")
  f3$Variant_summary<-gsub(f3$Variant_summary, pattern="\\\\x2c", replace=",")
  write.table(f3, paste0("/pharm/results/", tools::file_path_sans_ext(basename(i)), "__", n$Gene[1], ".txt") , sep="\t", quote=FALSE,
              row.names=FALSE, col.names=TRUE, na="NA")
}

files_results <- list.files(path="/pharm/",
                            pattern="*.txt", full.names=TRUE, recursive=TRUE)
for(i in files_results){
  x <- read.csv(i, sep="\t")
  if(nrow(x)!=0){
  attach(x)
  x1 <- subset(x, select= c(Database, Chromosome,Start, Stop, Ref_base, Var_base, Gene, Type, ID, Drug,
                          Significance, Phenotype.Category, Sentence, Notes,
                          PMID, Annotation))
  hgx <- split(x1, paste(x$Gene))
  xa <- hgx[1:length(hgx)]
  for (n in xa) {split_pharm(n)}

files_pharm2 <- list.files(path="/pharm/results/",
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

files_pharm <- list.files(path="/pharm/",
                           pattern="*.txt", full.names=TRUE, recursive=FALSE)
files_pharm2 <-list.files(path="/pharm/results/",
                           pattern="*.txt", full.names=TRUE, recursive=FALSE)
for (i in files_pharm) {rename(i, pharm, files_pharm2, args[1])}


#merge genes PharmGKB

files_pharm <- list.files(path="/pharm/",
                           pattern="*.txt", full.names=TRUE, recursive=FALSE)
files_pharm2 <-list.files(path="/pharm/results/",
                           pattern="*.txt", full.names=TRUE, recursive=TRUE)
try({for (i in files_pharm) {merging_genes(i, pharm, files_pharm2)}}, silent = TRUE)

try({files_definitivi <- list.files(path="/pharm/results/", pattern="*.txt", full.names=TRUE, recursive=TRUE)
for (m in files_definitivi) {
  x <- read.csv(m, sep="\t")
  attach(x)
  x <- sapply(x, as.character)
  x[is.na(x)] <- " "
  x <- as.data.frame(x)
  x$Drug <- as.character(x$Drug , levels=(x$Drug))
  x<-x[order(x$Drug), ]
  x$Gene <- as.character(x$Gene , levels=(x$Gene))
  x<-x[order(x$Gene), ]
  x<-data.frame(x, Reference=1:length(x$Drug))
  row.names(x)<-NULL
  hgx<-split(x, paste(x$Gene))
  xa<-hgx[1:length(hgx)]
  link <- data.frame()
  urls <- data.frame()
  for (n in xa){
    if (dim(n)[1]!=0){
      row.names(n)<-NULL
      n$Drug <- as.character(n$Drug , levels=(n$Drug))
      n<-n[order(n$Drug), ]
      n$Gene <- as.character(n$Gene , levels=(n$Gene))
      n<-n[order(n$Gene), ]
      for (i in 1:length(n$PMID)) {
        a <-paste0("https://www.ncbi.nlm.nih.gov/pubmed/", n$PMID[i])
        df <- data.frame(Gene=n$Gene[i], PMID=a, Cod=n$PMID[i], Reference= n$Reference[i])
        link <- rbind(link,df)
        #i <- i+1
      }}}
  for (t in 1:length(link$PMID)){
    url <- as.character(link$PMID[t])
    y <- lapply(url, readUrl)
    if (is.na(y)){next()
    }else { df <- data.frame(PMID=url, Cod=link$Cod[t], Gene=link$Gene[t], Reference=link$Reference[t])
    urls <- rbind(urls,df)
    }
  }
  write.table(urls,paste0("/Reference/",tools::file_path_sans_ext(basename(m)),"_pharm.txt"), quote=FALSE,
              row.names = FALSE, na= "NA", sep = "\t")
}
}, silent = TRUE)

###########################################################################################

#Food interactions

files_food <- list.files(path="/definitive/", pattern="*.txt", full.names=TRUE, recursive=TRUE)
files_food_p <- list.files(path="/pharm/results/", pattern="*.txt", full.names=TRUE, recursive=TRUE)
for (i in files_food) {
z<-read.csv(i, sep="\t")
  for (m in files_food_p) {
  u<-read.csv(m, sep="\t")
  if(dim(z)[1]!=0 && dim(u)[1]!=0){
a<-unique(z$Drug)
a <- as.data.frame(a)
colnames(a)[1]<- "name2"
a<-gsub(a$name2, pattern=" *\\(.*?\\) *", replace=" ")
a<- as.data.frame(a)
colnames(a)[1]<- "name2"
if (!is.na(a$name2)){
  t1<-strsplit(as.character(a$name2), ",", fixed = T)
  e1<- cbind(a[rep(1:nrow(a), lengths(t1)), 1], name2 = unlist(t1))
  e1 <- data.frame(name2=e1)
  e1 <- na.omit(e1)
  e1$name2.V1 <- NULL
  colnames(e1)[1]<- "name2"
  t2<-strsplit(as.character(e1$name2), "+", fixed = T)
  e2<- cbind(e1[rep(1:nrow(e1), lengths(t2)), 1], name2 = unlist(t2))
  a <- data.frame(name2=e2)
  a$name2.V1 <- NULL
  colnames(a)[1]<- "name2"
  a$name2 <- trimws(a$name2)
  a <- unique(a)
}
#pharm
b<-unique(u$Drug)
b <- as.data.frame(b)
colnames(b)[1]<- "name2"
b<-gsub(b$name2, pattern=" *\\(.*?\\) *", replace=" ")
b<- as.data.frame(b)
colnames(b)[1]<- "name2"
t1<-strsplit(as.character(b$name2), ",", fixed = T)
e1<- cbind(b[rep(1:nrow(b), lengths(t1)), 1], name2 = unlist(t1))
e1 <- data.frame(name2=e1)
e1 <- na.omit(e1)
e1$name2.V1 <- NULL
colnames(e1)[1]<- "name2"
t2<-strsplit(as.character(e1$name2), "+", fixed = T)
e2<- cbind(e1[rep(1:nrow(e1), lengths(t2)), 1], name2 = unlist(t2))
b <- data.frame(name2=e2)
b$name2.V1 <- NULL
colnames(b)[1]<- "name2"
b$name2 <- trimws(b$name2)
b <- unique(b)
firstup <- function(x) {
  substr(x, 1, 1) <- toupper(substr(x, 1, 1))
  x
}
b$name2<-firstup(b$name2)
y<-read.csv("/Drug_food.txt", sep="\t")
c <- merge(a,y, by="name2")
d <- merge(b,y, by="name2")
pc <- merge (c,d,by="name2", all=TRUE)
if(dim(d)[1]==0){
  pc$drugbank_id.y<- NULL
  pc$food_interaction.y <- NULL
  colnames(pc)[2] <- "drugbank_id"
  colnames(pc)[3] <- "food_interaction"
} else if(dim(c)[1]==0){
  pc$drugbank_id.x <- NULL
  pc$food_interaction.x <- NULL
  colnames(pc)[2] <- "drugbank_id"
  colnames(pc)[3] <- "food_interaction"
}
write.table(pc, paste0("/Food/", tools::file_path_sans_ext(basename(i)),".txt") , sep="\t", quote=FALSE,
            row.names=FALSE, col.names=TRUE, na="NA")
}else if (dim(z)[1]!=0){
  a<-unique(z$Drug)
  a <- as.data.frame(a)
  colnames(a)[1]<- "name2"
  a<-gsub(a$name2, pattern=" *\\(.*?\\) *", replace=" ")
  a<- as.data.frame(a)
  colnames(a)[1]<- "name2"
  t1<-strsplit(as.character(a$name2), ",", fixed = T)
  e1<- cbind(a[rep(1:nrow(a), lengths(t1)), 1], name2 = unlist(t1))
  e1 <- data.frame(name2=e1)
  e1 <- na.omit(e1)
  e1$name2.V1 <- NULL
  colnames(e1)[1]<- "name2"
  t2<-strsplit(as.character(e1$name2), "+", fixed = T)
  e2<- cbind(e1[rep(1:nrow(e1), lengths(t2)), 1], name2 = unlist(t2))
  a <- data.frame(name2=e2)
  a$name2.V1 <- NULL
  colnames(a)[1]<- "name2"
  a$name2 <- trimws(a$name2)
  a <- unique(a)
  y<-read.csv("/Drug_food.txt", sep="\t")
  c <- merge(a,y, by="name2")
  write.table(c, paste0("/Food/", tools::file_path_sans_ext(basename(i)),".txt") , sep="\t", quote=FALSE,
              row.names=FALSE, col.names=TRUE, na="NA")
}else if(dim(u)[1]!=0){
  b<-unique(u$Drug)
  b <- as.data.frame(b)
  colnames(b)[1]<- "name2"
  b<-gsub(b$name2, pattern=" *\\(.*?\\) *", replace=" ")
  b<- as.data.frame(b)
  colnames(b)[1]<- "name2"
  t1<-strsplit(as.character(b$name2), ",", fixed = T)
  e1<- cbind(b[rep(1:nrow(b), lengths(t1)), 1], name2 = unlist(t1))
  e1 <- data.frame(name2=e1)
  e1 <- na.omit(e1)
  e1$name2.V1 <- NULL
  colnames(e1)[1]<- "name2"
  t2<-strsplit(as.character(e1$name2), "+", fixed = T)
  e2<- cbind(e1[rep(1:nrow(e1), lengths(t2)), 1], name2 = unlist(t2))
  b <- data.frame(name2=e2)
  b$name2.V1 <- NULL
  colnames(b)[1]<- "name2"
  b$name2 <- trimws(b$name2)
  b <- unique(b)
  firstup <- function(x) {
    substr(x, 1, 1) <- toupper(substr(x, 1, 1))
    x
  }
  b$name2<-firstup(b$name2)
  y<-read.csv("/Drug_food.txt", sep="\t")
  d <- merge(b,y, by="name2")
  write.table(d, paste0("/Food/", tools::file_path_sans_ext(basename(i)),".txt") , sep="\t", quote=FALSE,
              row.names=FALSE, col.names=TRUE, na="NA")
}else if(dim(z)[1]==0 && dim(u)[1]==0){ break
}
  }}

################################################################################

try({files_definitivi <- list.files(path="/definitive/", pattern="*.txt", full.names=TRUE, recursive=TRUE)
for (m in files_definitivi) {
  x <- read.csv(m, sep="\t")
  dis<-read.csv("/Disease.txt", sep= "\t")
  attach(x)
  if(dim(x)[1]!=0){
    x<- merge(dis, x, by= "Disease")
    x$Disease <- NULL
    colnames(x)[1] <- "Disease"
    x <- sapply(x, as.character)
    x[is.na(x)] <- " "
    x <- as.data.frame(x)
    x<-subset.data.frame(x,subset = x$Evidence_direction=="Supports")
    x <- subset.data.frame(x,subset = x$Disease!=args[2])
    x$Drug <- as.character(x$Drug , levels=(x$Drug))
    x<-x[order(x$Drug), ]
    x$Evidence_type  <- factor(x$Evidence_type , levels = c("Diagnostic", "Prognostic","Predisposing","Predictive"))
    x<-x[order(x$Evidence_type), ]
    x$Evidence_level  <- factor(x$Evidence_level , levels = c("Validated association","FDA guidelines", "NCCN guidelines", "Clinical evidence","Late trials", "Early trials",  "Case study","Case report","Preclinical evidence", "Pre-clinical", "Inferential association"))
    x<-x[order(x$Evidence_level), ]
    x$Disease <- as.character(x$Disease , levels=(x$Disease))
    x<-x[order(x$Disease), ]
    x<-data.frame(x, Reference=1:length(x$Disease))
    row.names(x)<-NULL
    hgx<-split(x, paste(x$Gene, x$Variant, x$Disease!=args[2]))
    xa<-hgx[1:length(hgx)]
    link <- data.frame()
    urls <- data.frame()
    for (n in xa){
        n<-subset.data.frame(n,subset = n$Evidence_direction=="Supports")
        if (dim(n)[1]!=0){
          row.names(n)<-NULL
          n$Drug <- as.character(n$Drug , levels=(n$Drug))
          n<-n[order(n$Drug), ]
          n$Evidence_type  <- factor(n$Evidence_type , levels = c("Diagnostic", "Prognostic","Predisposing","Predictive"))
          n<-n[order(n$Evidence_type), ]
          n$Evidence_level  <- factor(n$Evidence_level , levels = c("Validated association","FDA guidelines", "NCCN guidelines", "Clinical evidence","Late trials", "Early trials",  "Case study","Case report","Preclinical evidence", "Pre-clinical", "Inferential association"))
          n<-n[order(n$Evidence_level), ]
          for (i in 1:length(n$Drug)) {
            a <-paste0("https://clinicaltrials.gov/ct2/results?cond=", n$Variant[i],"&term=", gsub(" ", "", n$Drug[i], fixed = TRUE), "&cntry=&state=&city=&dist=")
            df <- data.frame(Drug = n$Drug[i], Clinical_trial=a,
                             Reference= n$Reference[i], Disease=n$Disease[i], Gene= n$Gene[i], Variant= n$Variant[i]) #Aggiungi il Reference
            link <- rbind(link,df)
          }}}
  for (t in 1:length(link$Clinical_trial)){
    url <- as.character(link$Clinical_trial[t])
    y <- lapply(url, readUrl)
    if (is.na(y)){next()
    }else { df <- data.frame(Clinical_trial=url, Reference=link$Reference[t],
                             Drug=link$Drug[t], Disease=link$Disease[t], Gene= link$Gene[t], Variant= link$Variant[t])
    urls <- rbind(urls,df)
    }
  write.table(urls,paste0("/Trial/",tools::file_path_sans_ext(basename(m)),"_off",".txt"), quote=FALSE,
              row.names = FALSE, na= "NA", sep = "\t")
}}}
}, silent = TRUE)


#URL PMID off

try({files_definitivi <- list.files(path="/definitive/", pattern="*.txt", full.names=TRUE, recursive=TRUE)
for (m in files_definitivi) {
  x <- read.csv(m, sep="\t")
  dis<-read.csv("/Disease.txt", sep= "\t")
  attach(x)
  x<- merge(dis, x, by= "Disease")
  x$Disease <- NULL
  colnames(x)[1] <- "Disease"
  x <- sapply(x, as.character)
  x[is.na(x)] <- " "
  x <- as.data.frame(x)
  x<-subset.data.frame(x,subset = x$Evidence_direction=="Supports")
  x <- subset.data.frame(x,subset = x$Disease!=args[2])
  x$Drug <- as.character(x$Drug , levels=(x$Drug))
  x<-x[order(x$Drug), ]
  x$Evidence_type  <- factor(x$Evidence_type , levels = c("Diagnostic", "Prognostic","Predisposing","Predictive"))
  x<-x[order(x$Evidence_type), ]
  x$Evidence_level  <- factor(x$Evidence_level , levels = c("Validated association","FDA guidelines", "NCCN guidelines", "Clinical evidence","Late trials", "Early trials",  "Case study","Case report","Preclinical evidence", "Pre-clinical", "Inferential association"))
  x<-x[order(x$Evidence_level), ]
  x$Disease <- as.character(x$Disease , levels=(x$Disease))
  x<-x[order(x$Disease), ]
  x<-data.frame(x, Reference=1:length(x$Disease))
  x$PMID<- gsub(" ", "", x$PMID, fixed = TRUE)
  row.names(x)<-NULL
  hgx<-split(x, paste(x$Gene, x$Variant, x$Disease!=args[2]))
  xa<-hgx[1:length(hgx)]
  link <- data.frame()
  for (n in xa){
      n<-subset.data.frame(n,subset = n$Evidence_direction=="Supports")
      if (dim(n)[1]!=0){
        row.names(n)<-NULL
        n$Drug <- as.character(n$Drug , levels=(n$Drug))
        n<-n[order(n$Drug), ]
        n$Evidence_type  <- factor(n$Evidence_type , levels = c("Diagnostic", "Prognostic","Predisposing","Predictive"))
        n<-n[order(n$Evidence_type), ]
        n$Evidence_level  <- factor(n$Evidence_level , levels = c("Validated association","FDA guidelines",
                                                                  "NCCN guidelines", "Clinical evidence","Late trials", "Early trials",  "Case study","Case report","Preclinical evidence", "Pre-clinical", "Inferential association"))
        n<-n[order(n$Evidence_level), ]
        for (i in 1:length(n$PMID)) {
          a <-paste0("https://www.ncbi.nlm.nih.gov/pubmed/", n$PMID[i])
          df <- data.frame(Citation = n$Citation[i], Disease=n$Disease[i], PMID=a, Cod=n$PMID[i], Reference= n$Reference[i])
          link <- rbind(link,df)
        }}}
  link$Disease <- as.character(link$Disease , levels=(link$Disease))
  link<-link[order(link$Disease), ]
  urls <- data.frame()
  for (t in 1:length(link$PMID)){
    url <- as.character(link$PMID[t])
    y <- lapply(url, readUrl)
    if (is.na(y)){next()
    }else { df <- data.frame(PMID=url, Cod=link$Cod[t], Disease=link$Disease[t], Citation=link$Citation[t], Reference=link$Reference[t])
    urls <- rbind(urls,df)
    }
  write.table(urls,paste0("/Reference/",tools::file_path_sans_ext(basename(m)),"_off.txt"),
              quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
}}
}, silent = TRUE)
