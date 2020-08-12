#Civic
split_civic <- function(n){
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
  f3$Database.9 <- "Civic"
  f2 <- function(x) {
    for(i in seq_along(x)[-1]) if(is.na(x[i])) x[i] <- x[i-1]
    x
  }
  Chromosome <- f2(f3$Chromosome.9)
  Start <- f2(f3$Start)
  Stop <- f2(f3$Stop)
  Ref_base <- f2(f3$Ref_base)
  Var_base <- f2(f3$Var_base)
  Gene <- f2(f3$Gene)
  Variant <- f2(f3$Variant)
  Type <- f2(f3$Type)
  f3$Chromosome <- Chromosome
  f3$Start <- Start
  f3$Stop <- Stop
  f3$Ref_base <- Ref_base
  f3$Var_base <- Var_base
  f3$Gene <- Gene
  f3$Variant <- Variant
  f3$Type <- Type
  f3$Database.1 <- NULL
  f3$Database.2 <- NULL
  f3$Database.3 <- NULL
  f3$Database.4 <- NULL
  f3$Database.5 <- NULL
  f3$Database.6 <- NULL
  f3$Database.7 <- NULL
  f3$Database.8 <- NULL
  f3$Database <- NULL
  f3$Database.10 <- NULL
  f3$Database.11 <- NULL
  f3$Chromosome.1 <- NULL
  f3$Chromosome.2 <- NULL
  f3$Chromosome.3 <- NULL
  f3$Chromosome.4 <- NULL
  f3$Chromosome.5 <- NULL
  f3$Chromosome.6 <- NULL
  f3$Chromosome.7 <- NULL
  f3$Chromosome.8 <- NULL
  f3$Chromosome.9 <- NULL
  f3$Chromosome.10 <- NULL
  f3$Chromosome.11 <- NULL
  f3$Evidence_statement <-gsub (f3$Evidence_statement, pattern="ï¿½", replace="-")
  colnames(f3)[11] <- "Database"
  write.table(f3, paste0(args[3], "/civic/results/", tools::file_path_sans_ext(basename(i)), "__", n$Gene, ".txt") , sep="\t", quote=FALSE,
              row.names=FALSE, col.names=TRUE, na="NA")
}

#Rename

rename <- function(i, database, files, args[1]){
dir.create(paste0(args[3], "/", database, "/results/", tools::file_path_sans_ext(basename(i)), "/"))
for (m in files) {
  if (tools::file_path_sans_ext(basename(word(m, 1, sep = "__"))) == tools::file_path_sans_ext(basename(i))){
    file.move(paste0(args[3], "/", database, "/results/", tools::file_path_sans_ext(basename(m)), ".txt"),
              paste0(args[3], "/", database, "/results/", tools::file_path_sans_ext(basename(i)), "/"))
  } else next()
}
} } else {
  file.rename(i , paste0(args[3], "/", database, "/results/", args[1], ".txt"))
  }
}

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
  Chromosome <- f2(f3$Chromosome)
  Start <- f2(f3$Start)
  Stop <- f2(f3$Stop)
  Ref_base <- f2(f3$Ref_base)
  Var_base <- f2(f3$Var_base)
  Gene <- f2(f3$Gene)
  individual_mutation <- f2(f3$individual_mutation)
  Type <- f2(f3$Type)
  f3$Chromosome <- Chromosome
  f3$Start <- Start
  f3$Stop <- Stop
  f3$Ref_base <- Ref_base
  f3$Var_base <- Var_base
  f3$Gene <- Gene
  f3$individual_mutation <- individual_mutation
  f3$Type <- Type
  f3$Database.1 <- NULL
  f3$Database.2 <- NULL
  f3$Database.3 <- NULL
  f3$Database.4 <- NULL
  f3$Database.5 <- NULL
  f3$Database.6 <- NULL
  f3$Database.7 <- NULL
  f3$Database.8 <- NULL
  f3$Database.9 <- NULL
  f3$Database.10 <- NULL
  f3$Database.11 <- NULL
  f3$Database.12 <- NULL
  f3$Database.13 <- NULL
  f3$Database.14 <- NULL
  f3$Database.15 <- NULL
  f3$Chromosome.1 <- NULL
  f3$Chromosome.2 <- NULL
  f3$Chromosome.3 <- NULL
  f3$Chromosome.4 <- NULL
  f3$Chromosome.5 <- NULL
  f3$Chromosome.6 <- NULL
  f3$Chromosome.7 <- NULL
  f3$Chromosome.8 <- NULL
  f3$Chromosome.9 <- NULL
  f3$Chromosome.10 <- NULL
  f3$Chromosome.11 <- NULL
  f3$Chromosome.12 <- NULL
  f3$Chromosome.13 <- NULL
  f3$Chromosome.14 <- NULL
  f3$Chromosome.15 <- NULL
  write.table(f3, paste0(args[3], "/cgi/results/", tools::file_path_sans_ext(basename(i)), "__", n$Gene, ".txt") , sep="\t", quote=FALSE,
              row.names=FALSE, col.names=TRUE, na="NA")
}

#Merging genes

merging_genes <- function(i, database, files){
setwd(paste0(args[3], "/", database, "/results/", tools::file_path_sans_ext(basename(i)), "/"))
temp <- list.files(path=paste0(args[3], "/", database, "/results/", tools::file_path_sans_ext(basename(i)), "/"), pattern="*.txt")
myfiles <- lapply(temp, read.delim)
file <- do.call("rbind", myfiles)
for(m in files) {
  unlink(paste0(args[3], "/", database, "/results/", tools::file_path_sans_ext(basename(i)), "/", tools::file_path_sans_ext(basename(m)), ".txt"))
}
write.table(file, paste0(args[3], "/", database, "/results/",  tools::file_path_sans_ext(basename(i)), "/", tools::file_path_sans_ext(basename(i)), ".txt"), sep="\t",quote=FALSE, row.names=FALSE, na="NA")
}

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

#URLS

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

#PHARM

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
  Chromosome <- f2(f3$Chromosome)
  Start <- f2(f3$Start)
  Stop <- f2(f3$Stop)
  Ref_base <- f2(f3$Ref_base)
  Var_base <- f2(f3$Var_base)
  Gene <- f2(f3$Gene)
  Type <- f2(f3$Type)
  f3$Chromosome <- Chromosome
  f3$Start <- Start
  f3$Stop <- Stop
  f3$Ref_base <- Ref_base
  f3$Var_base <- Var_base
  f3$Gene <- Gene
  f3$Type <- Type
  f3$Database.1 <- NULL
  f3$Database.2 <- NULL
  f3$Database.3 <- NULL
  f3$Database.4 <- NULL
  f3$Database.5 <- NULL
  f3$Database.6 <- NULL
  f3$Database.7 <- NULL
  f3$Database.8 <- NULL
  f3$Chromosome.1 <- NULL
  f3$Chromosome.2 <- NULL
  f3$Chromosome.3 <- NULL
  f3$Chromosome.4 <- NULL
  f3$Chromosome.5 <- NULL
  f3$Chromosome.6 <- NULL
  f3$Chromosome.7 <- NULL
  f3$Chromosome.8<-NULL
  f3$Drug<-gsub(f3$Drug, pattern="\\\\x2c", replace=",")
  f3$Drug<-gsub(f3$Drug, pattern="*\\(.*?\\) *", replace="")
  f3$Gene<-gsub(f3$Gene, pattern="*\\(.*?\\) *", replace="")
  f3$Variant_summary<-gsub(f3$Variant_summary, pattern="\\\\x2c", replace=",")
  write.table(f3, paste0(args[3], "/pharm/results/", tools::file_path_sans_ext(basename(i)), "__", n$Gene[1], ".txt") , sep="\t", quote=FALSE,
              row.names=FALSE, col.names=TRUE, na="NA")
}
