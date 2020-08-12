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

files_results1 <- list.files(path=paste0(args[3],"/civic/results/"),
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
  attach(x)
  x1<-subset(x,select= c(Database, Chromosome, Start, Stop, Ref_base, Var_base, Gene, individual_mutation, Type, Drug, Drug.family,
                 Drug.full.name, Drug.status, Clinical_significance, Biomarker, Evidence_level, Disease,
                 PMID, Targeting, strand, info, region, Evidence_statement, Citation))
  hgx<-split(x1, paste(x$Gene, x$individual_mutation))
  xa<-hgx[1:length(hgx)]
  for (n in xa) { split_cgi(n)}



files_cgi <- list.files(path=paste0(args[3], "/cgi/results/"), pattern="*.txt", full.names=TRUE, recursive=TRUE)
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
write.table(e4, paste0(args[3], "/definitive/", tools::file_path_sans_ext(basename(i)) ,".txt"),
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
write.table(e4, paste0(args[3], "/definitive/", tools::file_path_sans_ext(basename(i)) ,".txt"),
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
  write.table(e4,paste0(args[3], "/definitive/", tools::file_path_sans_ext(basename(i)) ,".txt"),
              quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
} else if(dim(cgi)[1]==0 && dim(civic[1])==0){file.copy(i, paste0(args[3], "/definitive/"))}
}}}

#########################################################################################

#URLS documents

#Leading disease
## URL PMID and Clinical Trial

try({
files_definitivi <- list.files(path=paste0(args[3], "/definitive/"), pattern="*.txt", full.names=TRUE, recursive=TRUE)
for (m in files_definitivi) {
  x <- read.csv(m, sep="\t")
  dis<-read.csv(paste0("/Disease.txt"), sep= "\t") #path parametro database
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
write.table(urls_pmid, paste0(args[3], "/Reference/",tools::file_path_sans_ext(basename(m)),".txt"), quote=FALSE,
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
write.table(urls_cli ,paste0(args[3], "/Trial/",tools::file_path_sans_ext(basename(m)) ,".txt"), quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
}}
}, silent = TRUE)


#################################################################################################
#Cosmic

files_cosmic <- list.files(path=paste0(args[3], "/cosmic/"),
                            pattern="*.txt", full.names=TRUE, recursive=FALSE)
try({
for(i in files_cosmic){
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
      write.table(cos, paste0(args[3], "/cosmic/results/", tools::file_path_sans_ext(basename(i)), ".txt") , sep="\t", quote=FALSE,
                  row.names=FALSE, col.names=TRUE, na="NA")

files_results <- list.files(path=paste0(args[3], "/cosmic/results/"),
                                 pattern="*.txt", full.names=TRUE, recursive=FALSE)
for (i in files_cosmic) {
  dir.create(paste0(args[3], "/cosmic/results/", tools::file_path_sans_ext(basename(i)), "/"))
  for (m in files_results) {
    if (tools::file_path_sans_ext(basename(m)) == tools::file_path_sans_ext(basename(i))){
      file.move(paste0(args[3], "/cosmic/results/", tools::file_path_sans_ext(basename(m)), ".txt"),
                paste0(args[3], "/cosmic/results/", tools::file_path_sans_ext(basename(i)), "/"))
    }else next()
  }
    }}else {dir.create(paste0(args[3], "/cosmic/results/", args[1], "/"))
      file.rename(i , paste0(args[3], "/cosmic/results/",args[1],"/",args[1],".txt"))
}}

}, silent = TRUE)

#URL documents

try({
files_definitivi_cosmic <- list.files(path=paste0(args[3], "/cosmic/results/"), pattern="*.txt", full.names=TRUE, recursive=TRUE)
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
  write.table(urls,paste0(args[3], "/Reference/",tools::file_path_sans_ext(basename(m)),"_cosmic.txt"), quote=FALSE,
              row.names = FALSE, na= "NA", sep = "\t")
}
}, silent = TRUE)


########################################################################################

#PharmGKB

files_results <- list.files(path=paste0(args[3], "/pharm/"),
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
  write.table(urls, paste0(args[3], "/Reference/",tools::file_path_sans_ext(basename(m)),"_pharm.txt"), quote=FALSE,
              row.names = FALSE, na= "NA", sep = "\t")
}
}, silent = TRUE)

###########################################################################################

#Food interactions

files_food <- list.files(path=paste0(args[3], "/definitive/"), pattern="*.txt", full.names=TRUE, recursive=TRUE)
files_food_p <- list.files(path=paste0(args[3], "/pharm/results/"), pattern="*.txt", full.names=TRUE, recursive=TRUE)
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
write.table(pc, paste0(args[3], "/Food/", tools::file_path_sans_ext(basename(i)),".txt") , sep="\t", quote=FALSE,
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
  y<-read.csv("/Drug_food.txt", sep="\t") #path_database
  c <- merge(a,y, by="name2")
  write.table(c, paste0(args[3], "/Food/", tools::file_path_sans_ext(basename(i)),".txt") , sep="\t", quote=FALSE,
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
  write.table(d, paste0(args[3], "/Food/", tools::file_path_sans_ext(basename(i)),".txt") , sep="\t", quote=FALSE,
              row.names=FALSE, col.names=TRUE, na="NA")
}else if(dim(z)[1]==0 && dim(u)[1]==0){ break
}
  }}

################################################################################
#URL PMID/Clinical Trial off

try({
files_definitivi <- list.files(path=paste0(args[3], "/definitive/"), pattern="*.txt", full.names=TRUE, recursive=TRUE)
for (m in files_definitivi) {
  x <- read.csv(m, sep="\t")
  dis <- read.csv("/Disease.txt", sep= "\t")
  attach(x)
  if(dim(x)[1]!=0){
    x<- merge(dis, x, by= "Disease")
    x$Disease <- NULL
    colnames(x)[1] <- "Disease"
    x <- sapply(x, as.character)
    x[is.na(x)] <- " "
    x <- as.data.frame(x)
    x <- subset.data.frame(x,subset = x$Evidence_direction=="Supports")
    x <- subset.data.frame(x,subset = x$Disease!=args[2])
    x$Drug <- as.character(x$Drug , levels=(x$Drug))
    x <- x[order(x$Drug), ]
    x$Evidence_type  <- factor(x$Evidence_type , levels = c("Diagnostic", "Prognostic","Predisposing","Predictive"))
    x <- x[order(x$Evidence_type), ]
    x$Evidence_level  <- factor(x$Evidence_level , levels = c("Validated association","FDA guidelines", "NCCN guidelines", "Clinical evidence","Late trials", "Early trials",  "Case study","Case report","Preclinical evidence", "Pre-clinical", "Inferential association"))
    x <- x[order(x$Evidence_level), ]
    x$Disease <- as.character(x$Disease , levels=(x$Disease))
    x <- x[order(x$Disease), ]
    x <- data.frame(x, Reference=1:length(x$Disease))
    row.names(x) <- NULL
    hgx <- split(x, paste(x$Gene, x$Variant, x$Disease!=args[2]))
    xa <- hgx[1:length(hgx)]
    link_cltr <- data.frame()
    urls_cltr <- data.frame()
    link_pm <- data.frame()
    for (n in xa){
        n<-subset.data.frame(n,subset = n$Evidence_direction=="Supports")
        if (dim(n)[1]!=0){
          row.names(n)<-NULL
          n$Drug <- as.character(n$Drug , levels=(n$Drug))
          n <- n[order(n$Drug), ]
          n$Evidence_type  <- factor(n$Evidence_type , levels = c("Diagnostic", "Prognostic","Predisposing","Predictive"))
          n <- n[order(n$Evidence_type), ]
          n$Evidence_level  <- factor(n$Evidence_level , levels = c("Validated association","FDA guidelines", "NCCN guidelines", "Clinical evidence","Late trials", "Early trials",  "Case study","Case report","Preclinical evidence", "Pre-clinical", "Inferential association"))
          n <- n[order(n$Evidence_level), ]
          for (i in 1:length(n$Drug)) {
            cltr <-paste0("https://clinicaltrials.gov/ct2/results?cond=", n$Variant[i],"&term=", gsub(" ", "", n$Drug[i], fixed = TRUE), "&cntry=&state=&city=&dist=")
            df_cltr <- data.frame(Drug = n$Drug[i], Clinical_trial=cltr,
                             Reference= n$Reference[i], Disease=n$Disease[i], Gene= n$Gene[i], Variant= n$Variant[i])
            link_cltr <- rbind(link_cltr,df_cltr)
          }
          for (i in 1:length(n$PMID)) {
          pm <-paste0("https://www.ncbi.nlm.nih.gov/pubmed/", n$PMID[i])
          df_pm <- data.frame(Citation = n$Citation[i], Disease=n$Disease[i], PMID=pm, Cod=n$PMID[i], Reference= n$Reference[i])
          link_pm <- rbind(link_pm,df_pm)
          }
        }
      }
  for (t in 1:length(link_cltr$Clinical_trial)){
    url <- as.character(link_cltr$Clinical_trial[t])
    y <- lapply(url, readUrl)
    if (is.na(y)){next()
    }else { df_pm <- data.frame(Clinical_trial=url, Reference=link_cltr$Reference[t],
                             Drug=link_cltr$Drug[t], Disease=link_cltr$Disease[t], Gene= link_cltr$Gene[t], Variant= link_cltr$Variant[t])
    urls_cltr <- rbind(urls_cltr,df_pm)
    }
  write.table(urls_cltr,paste0(args[3], "/Trial/",tools::file_path_sans_ext(basename(m)),"_off",".txt"), quote=FALSE,
              row.names = FALSE, na= "NA", sep = "\t")
}
link_pm$Disease <- as.character(link_pm$Disease , levels=(link_pm$Disease))
link_pm<-link_pm[order(link_pm$Disease), ]
urls_pm <- data.frame()
for (t in 1:length(link_pm$PMID)){
  url <- as.character(link_pm$PMID[t])
  y <- lapply(url, readUrl)
  if (is.na(y)){next()
  } else {
  df <- data.frame(PMID=url, Cod=link_pm$Cod[t], Disease=link_pm$Disease[t], Citation=link_pm$Citation[t], Reference=link_pm$Reference[t])
  urls_pm <- rbind(urls_pm,df)
  }
write.table(urls_pm,paste0(args[3], "/Reference/",tools::file_path_sans_ext(basename(m)),"_off.txt"),
            quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")

}
}}
}, silent = TRUE)
