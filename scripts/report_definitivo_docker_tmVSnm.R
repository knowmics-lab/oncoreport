args=commandArgs(trailingOnly = TRUE)

library(filesstrings)

source(paste0(args[3], "/Functions.R")) #Vedi se così funziona
###################################################################################

#Civic
#lines division

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
  e11<- cbind(n[rep(1:nrow(n), lengths(t11)), 1:8], Citation = unlist(t11))
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
  f3$Database<-"Civic"
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
  f3$Chromosome<-Chromosome
  f3$Start<-Start
  f3$Stop<-Stop
  f3$Ref_base<-Ref_base
  f3$Var_base<-Var_base
  f3$Gene<-Gene
  f3$Variant<-Variant
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
  f3$Evidence_statement<-gsub(f3$Evidence_statement, pattern="â", replace="-")
  write.table(f3, paste0(args[3], "/txt_civic/results/", tools::file_path_sans_ext(basename(i)), "__", n$Gene, ".txt") , sep="\t", quote=FALSE,
              row.names=FALSE, col.names=TRUE, na="NA")
}

files_results <- list.files(path=paste0(args[3], "/txt_civic/"),
                            pattern="*.txt", full.names=TRUE, recursive=TRUE)
for(i in files_results){
  x<-read.csv(i, sep="\t", stringsAsFactors = FALSE)
  if (dim(x)[1]!=0){
  attach(x)
  x1<-subset(x, select= c(Database, Chromosome,Start, Stop, Ref_base, Var_base, Gene, Variant, Disease, Drug,
                          Drug_interaction_type, Evidence_type, Evidence_level, Evidence_direction,
                          Clinical_significance, Evidence_statement, Variant_summary,
                          Citation_id, Citation))
  hgx<-split(x1, paste(x$Gene, x$Variant))
  xa<-hgx[1:length(hgx)]
  for (n in xa) {split_civic(n)}

files_results <- list.files(path=paste0(args[3], "/txt_civic/results/"),
                            pattern="*.txt", full.names=TRUE, recursive=TRUE)

for(i in files_results){evidence_level(i)}

files_civic <- list.files(path=paste0(args[3], "/txt_civic/"),
                          pattern="*.txt", full.names=TRUE, recursive=FALSE)
files_civic2 <-list.files(path=paste0(args[3], "/txt_civic/results/"),
                          pattern="*.txt", full.names=TRUE, recursive=TRUE)

for (i in files_civic) {rename(i, txt_civic, files_civic2, args[1])}

##########################################################################################

#CGI
#lines division
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
  e1<- cbind(n[rep(1:nrow(n), lengths(t1)), 1:8], Drug = unlist(t1))
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
  f3$Chromosome<-Chromosome
  f3$Start<-Start
  f3$Stop<-Stop
  f3$Ref_base<-Ref_base
  f3$Var_base<-Var_base
  f3$Gene<-Gene
  f3$individual_mutation<-individual_mutation
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
  write.table(f3, paste0(args[3], "/txt_cgi/results/", tools::file_path_sans_ext(basename(i)), "__", n$Gene, ".txt") , sep="\t", quote=FALSE,
              row.names=FALSE, col.names=TRUE, na="NA")
}

files_results <- list.files(path=paste0(args[3], "/txt_cgi/"),
                            pattern="*.txt", full.names=TRUE, recursive=TRUE)
for(i in files_results){
  x<-read.csv(i, sep="\t")
  if(dim(x)[1]!=0){
  attach(x)
  x1<-subset(x,select= c(Database, Chromosome,Start, Stop, Ref_base, Var_base, Gene, individual_mutation, Drug, Drug.family,
                 Drug.full.name, Drug.status, Clinical_significance, Biomarker, Evidence_level, Disease,
                 PMID, Targeting, strand, info, region, Evidence_statement, Citation))
  hgx<-split(x1, paste(x$Gene, x$individual_mutation))
  xa<-hgx[1:length(hgx)]
  for (n in xa) {split_cgi(n)}

files_cgi <- list.files(path=paste0(args[3],"/txt_cgi/results/"), pattern="*.txt", full.names=TRUE, recursive=TRUE)
for (i in files_cgi){cgi(i)}

files_cgi <- list.files(path=paste0(args[3], "/txt_cgi/"), pattern="*.txt", full.names=TRUE, recursive=FALSE)
files_cgi2 <- list.files(path=paste0(args[3], "/txt_cgi/results/"), pattern="*.txt", full.names=TRUE, recursive=TRUE)
for (i in files_cgi) {rename(i, txt_cgi, files_cgi2, args[1])}

########################################################################################

#Merging file geni
#Civic
files_civic <- list.files(path=paste0(args[3], "/txt_civic/"),
                          pattern="*.txt", full.names=TRUE, recursive=FALSE)
files_civic2 <-list.files(path=paste0(args[3], "/txt_civic/results/"),
                          pattern="*.txt", full.names=TRUE, recursive=TRUE)

try({for (i in files_civic) {merging_genes(i, txt_civic, files_civic2)}}, silent = TRUE)

#CGI

files_cgi <- list.files(path=paste0(args[3], "/txt_cgi/"), pattern="*.txt", full.names=TRUE, recursive=FALSE)
files_cgi2 <- list.files(path=paste0(args[3], "/txt_cgi/results/"), pattern="*.txt", full.names=TRUE, recursive=TRUE)

try({for (i in files_cgi) {merging_genes(i, txt_cgi, files_cgi2)}}, silent = TRUE)

###########################################################################################
#merging civic e cgi

files_civic_results <- list.files(path="/txt_civic/results/",
                          pattern="*.txt", full.names=TRUE, recursive=TRUE)
files_cgi_results <- list.files(path="/txt_cgi/results/",
                          pattern="*.txt", full.names=TRUE, recursive=TRUE)

for(i in files_civic_results){
for (m in files_cgi_results){
  if (basename(i) == basename(m)){
  civic <- read.csv(i, sep="\t")
  cgi <- read.csv(m, sep="\t")
  if(dim(cgi)[1]!=0 && dim(civic[1])!=0){
  z<-merge(civic,cgi, by=c("Chromosome", "Ref_base", "Var_base", "Start", "Stop", "Gene", "Drug",
                     "Variant", "Evidence_level", "Evidence_type","PMID", "Disease",
                     "Clinical_significance", "Evidence_direction",
                     "Citation", "Evidence_statement"), all=TRUE)
  s<- gsub(",([A-Za-z])", ", \\1", z$Drug)
  z["Drug"]<-s
  attach(z)
  z<-subset(z, select= c(Chromosome,Start, Stop, Ref_base, Var_base, Gene, Variant, Drug, Drug_interaction_type,
                Evidence_level, Evidence_type,
                PMID, Clinical_significance, Evidence_direction, Evidence_statement, Variant_summary,
                Database.x, Database.y,Citation,Disease))
  disease(z, 19)
  e1<-subset(e1, select= c(Chromosome,Start, Stop, Ref_base, Var_base, Gene, Variant, Drug, Drug_interaction_type,
                 Evidence_level, Evidence_type,
                 Clinical_significance, Evidence_direction, Disease, Variant_summary,
                 Database.x, Database.y, Citation,PMID, Evidence_statement))
  definitive(18, 20, 19)
  write.table(e4,paste0("/definitive/", tools::file_path_sans_ext(basename(i)) ,".txt"),
              quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
  }else if (dim(cgi)[1]==0 && dim(civic[1])!=0){
    s<- gsub(",([A-Za-z])", ", \\1", civic$Drug)
    civic["Drug"]<-s
    attach(civic)
    civic<-subset(civic, select= c(Chromosome,Start, Stop, Ref_base, Var_base, Gene, Variant, Drug, Drug_interaction_type,
                                   Evidence_level, Evidence_type,
                                   PMID, Clinical_significance, Evidence_direction, Evidence_statement, Variant_summary,
                                   Database, Citation, Disease))
    disease(civic, 18)
    e1<-subset(e1, select= c(Chromosome,Start, Stop, Ref_base, Var_base, Gene, Variant, Drug, Drug_interaction_type,
                             Evidence_level, Evidence_type,
                             Clinical_significance, Evidence_direction, Disease, Variant_summary,
                             Database, Citation, PMID, Evidence_statement))
    definitive(17, 19, 18)
    write.table(e4,paste0("/definitive/", tools::file_path_sans_ext(basename(i)) ,".txt"),
                quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
  } else if (dim(cgi)[1]!=0 && dim(civic[1])==0){
    s<- gsub(",([A-Za-z])", ", \\1", cgi$Drug)
    cgi["Drug"]<-s
    attach(cgi)
    cgi<-subset(cgi, select= c(Chromosome,Start, Stop, Ref_base, Var_base, Gene, Variant, Drug,
                               Evidence_level, Evidence_type,
                               PMID, Clinical_significance, Evidence_direction, Evidence_statement,
                               Database,Citation,  Disease))
    disease(cgi, 16)
    e1<-subset(e1, select= c(Chromosome,Start, Stop, Ref_base, Var_base, Gene, Variant, Drug,
                             Evidence_level, Evidence_type,
                             Clinical_significance, Evidence_direction, Disease,
                             Database, Citation,PMID, Type, Evidence_statement))
    definitive(15, 17, 17)
    e4$Drug_interaction_type <- " "
    e4$Variant_summary<- " "
    write.table(e4,paste0("/definitive/", tools::file_path_sans_ext(basename(i)) ,".txt"),
                quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
  } else if(dim(cgi)[1]==0 && dim(civic[1])==0){file.copy(i, "/definitive/")}
  }}}



#########################################################################################
#Leading disease


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
x <- subset.data.frame(x,subset = x$Disease==args[2])
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
hgx<-split(x, paste(x$Gene, x$Variant, x$Disease==args[2]))
xa<-hgx[1:length(hgx)]
link <- data.frame()
urls <- data.frame()
#i <- 1
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
        df <- data.frame(Drug = n$Drug[i], Gene= n$Gene[i], Variant= n$Variant[i], Clinical_trial=a, Reference= n$Reference[i])
        link <- rbind(link,df)
        #i <- i+1
      }}}}
for (t in 1:length(link$Clinical_trial)){
  url <- as.character(link$Clinical_trial[t])
  y <- lapply(url, readUrl)
  if (is.na(y)){next()
  }else { df <- data.frame(Clinical_trial=url, Gene= n$Gene[t], Variant= n$Variant[t], Reference=link$Reference[t], Drug=link$Drug[t])
  urls <- rbind(urls,df)
  }}
  write.table(urls,paste0("/Trial/",tools::file_path_sans_ext(basename(m)) ,".txt"), quote=FALSE,
              row.names = FALSE, na= "NA", sep = "\t")
}
}, silent = TRUE)


#off

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
}
write.table(urls,paste0("/Trial/",tools::file_path_sans_ext(basename(m)),"_off.txt"), quote=FALSE,
            row.names = FALSE, na= "NA", sep = "\t")
}
}, silent = TRUE)

## Url PMID

try({
files_definitivi <- list.files(path="/definitive/", pattern="*.txt", full.names=TRUE, recursive=TRUE)
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
x <- subset.data.frame(x,subset = x$Disease==args[2])
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
hgx<-split(x, paste(x$Gene, x$Variant, x$Disease==args[2]))
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
      for (i in 1:length(n$PMID)) {
        a <-paste0("https://www.ncbi.nlm.nih.gov/pubmed/", n$PMID[i])
        df <- data.frame(Citation = n$Citation[i], Gene=n$Gene[i], PMID=a, Cod=n$PMID[i], Reference= n$Reference[i])
        link <- rbind(link,df)
        #i <- i+1
      }}}
#link<-data.frame(link, Reference=1:length(link$Clinical_trial))
for (t in 1:length(link$PMID)){
  url <- as.character(link$PMID[t])
  y <- lapply(url, readUrl)
  if (is.na(y)){next()
  }else { df <- data.frame(PMID=url, Cod=link$Cod[t], Gene=link$Gene[t], Citation=link$Citation[t], Reference=link$Reference[t])
  urls <- rbind(urls,df)
  }
}
write.table(urls,paste0("/Reference/",tools::file_path_sans_ext(basename(m)),".txt"), quote=FALSE,
            row.names = FALSE, na= "NA", sep = "\t")
}
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
#i <- 1
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
}
write.table(urls,paste0("/Reference/",tools::file_path_sans_ext(basename(m)),"_off",".txt"),
            quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
}
}, silent = TRUE)

#################################################################################################
#Cosmic

files_cosmic <- list.files(path="/txt_cosmic/",
                           pattern="*.txt", full.names=TRUE, recursive=FALSE)
try({for(i in files_cosmic){
  cos<-read.csv(i, sep="\t")
  if(nrow(cos)!=0){
    cos$Sample.Name<-NULL
    cos$Sample.ID<-NULL
    cos$Transcript<-NULL
    cos$Census.Gene<-NULL
    cos$MUTATION_ID<-NULL
    cos$ID<-NULL
    cos$LEGACY_MUTATION_ID<-NULL
    cos$CDS.Mutation<-NULL
    cos$CGP.Study<-NULL
    cos$Tier<-NULL
    cos$Variant<-gsub(cos$AA.Mutation, pattern="p.", replace="")
    cos$AA.Mutation<-NULL
    colnames(cos)[9]<- "Pubmed"
    cos$Stop<-NULL
    cos$Stop<-sub('.*\\.', '', cos$Genome.Coordinates..GRCh37.)
    a<-sub('.*\\:', '', cos$Genome.Coordinates..GRCh37.)
    cos$Start<-gsub("\\..*","",a)
    colnames(cos)[1]<-"Gene"
    colnames(cos)[2]<-"Drug"
    cos$Genome.Coordinates..GRCh37. <- NULL
    write.table(cos, paste0("/txt_cosmic/results/", tools::file_path_sans_ext(basename(i)), ".txt") , sep="\t", quote=FALSE,
                row.names=FALSE, col.names=TRUE, na="NA")

    files_results <- list.files(path="/txt_cosmic/results/",
                                pattern="*.txt", full.names=TRUE, recursive=FALSE)
    for (i in files_cosmic) {
      dir.create(paste0("/txt_cosmic/results/", tools::file_path_sans_ext(basename(i)), "/"))
      for (m in files_results) {
        if (tools::file_path_sans_ext(basename(m)) == tools::file_path_sans_ext(basename(i))){
          file.move(paste0("/txt_cosmic/results/", tools::file_path_sans_ext(basename(m)), ".txt"),
                    paste0("/txt_cosmic/results/", tools::file_path_sans_ext(basename(i)), "/"))
        }else next()
      }
    }}else {dir.create(paste0("/txt_cosmic/results/", args[1], "/"))
      file.rename(i , paste0("/txt_cosmic/results/",args[1],"/",args[1],".txt"))
    }}

}, silent = TRUE)

try({
files_definitivi_cosmic <- list.files(path="/txt_cosmic/results/", pattern="*.txt", full.names=TRUE, recursive=TRUE)
for (m in files_definitivi_cosmic) {
  x <- read.csv(m, sep="\t")
  attach(x)
  x[is.na(x)] <- " "
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
  #i <- 1
  for (n in xa){
    if (dim(n)[1]!=0){
      row.names(n)<-NULL
      n$Drug <- as.character(n$Drug , levels=(n$Drug))
      n<-n[order(n$Drug), ]
      n$Gene <- as.character(n$Gene , levels=(n$Gene))
      n<-n[order(n$Gene), ]
      n$Pubmed <- as.character(n$Pubmed , levels=(n$Pubmed))
      n<-n[order(n$Pubmed),]
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
  e1<- cbind(n[rep(1:nrow(n), lengths(t1)), 1:7], Variant = unlist(t1))
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
  f3$Chromosome<-Chromosome
  f3$Start<-Start
  f3$Stop<-Stop
  f3$Ref_base<-Ref_base
  f3$Var_base<-Var_base
  f3$Gene<-Gene
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
  write.table(f3, paste0("/txt_pharm/results/", tools::file_path_sans_ext(basename(i)), "__", n$Gene[1], ".txt") , sep="\t", quote=FALSE,
              row.names=FALSE, col.names=TRUE, na="NA")
}

files_results <- list.files(path="/txt_pharm/",
                            pattern="*.txt", full.names=TRUE, recursive=TRUE)
for(i in files_results){
  x<-read.csv(i, sep="\t")
  if(nrow(x)!=0){
  attach(x)
  x1<-subset(x, select= c(Database, Chromosome,Start, Stop, Ref_base, Var_base, Gene, ID, Drug,
                          Significance, Phenotype.Category, Sentence, Notes,
                          PMID, Annotation))
  hgx<-split(x1, paste(x$Gene))
  xa<-hgx[1:length(hgx)]
  for (n in xa) { split_pharm(n)}

files_pharm2 <-list.files(path="/txt_pharm/results/",
                           pattern="*.txt", full.names=TRUE, recursive=TRUE)
for(i in files_pharm2){
    x<-read.csv(i, sep="\t", stringsAsFactors = FALSE)
  x<-subset.data.frame(x,subset = x$Evidence_level=="yes")
  # avvicina due parole e la loro virgola, esempio: cetux ,panitub => cetux,panitub
  s<- gsub("\\s+", "", gsub("^\\s+|\\s+$", "", x$Drug))
  x["Drug"]<-s
  s1<- gsub(",", ", ", x$Drug)
  x["Drug"]<-s1
  x$Evidence_statement<-gsub(x$Evidence_statement, pattern="\\\\x2c", replace=",")
  write.table(x, i , sep="\t", quote=FALSE, row.names=FALSE, col.names=TRUE, na="NA")
}

files_pharm <- list.files(path="/txt_pharm/",
                           pattern="*.txt", full.names=TRUE, recursive=FALSE)
files_pharm2 <-list.files(path="/txt_pharm/results/",
                           pattern="*.txt", full.names=TRUE, recursive=TRUE)

for (i in files_pharm) {rename(i, txt_pharm, files_pharm2, args[1])}

#merge geni pharm

try({for (i in files_pharm) {merging_genes(i, txt_pharm, files_pharm2)}}, silent = TRUE)


try({
files_definitivi <- list.files(path="/txt_pharm/results/", pattern="*.txt", full.names=TRUE, recursive=TRUE)
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
  #i <- 1
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
files_food_p <- list.files(path="/txt_pharm/results/", pattern="*.txt", full.names=TRUE, recursive=TRUE)

for (i in files_food) {food_interaction(i, files_food_p)}
