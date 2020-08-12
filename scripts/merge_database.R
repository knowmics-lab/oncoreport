args=commandArgs(trailingOnly = TRUE)

#merging database
library(dplyr)
library(data.table)
library(filesstrings)

#################################################################################
#Civic
civ <- read.csv(paste0(args[2], "/civic_database", args[1], ".txt"), sep="\t", quote="")
colnames(civ)[1] <- "Chromosome"
colnames(civ)[2] <- "Start"
colnames(civ)[3] <- "Stop"
colnames(civ)[4] <- "Ref_base"
colnames(civ)[5] <- "Var_base"
colnames(civ)[6] <- "Gene"
colnames(civ)[7] <- "Variant"
colnames(civ)[8] <- "Disease"
colnames(civ)[9] <- "Drug"
colnames(civ)[10] <- "Drug_interaction_type"
colnames(civ)[11] <- "Evidence_type"
colnames(civ)[12] <- "Evidence_level"
colnames(civ)[13] <- "Evidence_direction"
colnames(civ)[14] <- "Clinical_significance"
colnames(civ)[15] <- "Evidence_statement"
colnames(civ)[16] <- "Variant_summary"
colnames(civ)[17] <- "Citation_id"
colnames(civ)[18] <- "Citation"
civ$Chromosome<-as.character(civ$Chromosome)
civ$Chromosome <- as.character(paste0("chr", civ$Chromosome))
civ$Stop<-as.character(civ$Stop)
civ$Ref_base<-as.character(civ$Ref_base)
civ$Var_base<-as.character(civ$Var_base)
civ$Database<- "generic"

#Clinvar
cli <- fread(paste0(args[2], "/clinvar_database", args[1],".vcf"))
colnames(cli)[1] <- "Chromosome"
colnames(cli)[2] <- "Stop"
colnames(cli)[4] <- "Ref_base"
colnames(cli)[5] <- "Var_base"
cli$Chromosome<-as.character(cli$Chromosome)
cli$Chromosome <- as.character(paste0("chr", cli$Chromosome))
cli$Stop<-as.character(cli$Stop)
cli$Ref_base<-as.character(cli$Ref_base)
cli$Var_base<-as.character(cli$Var_base)
cli$ID <- NULL
cli$QUAL <- NULL
colnames(cli)[6]<-"info"
cli$FILTER <-NULL

#Cosmic
c <- fread(paste0(args[3], "/cosmic_database", args[1], ".txt"))
c$Chromosome <- paste0("chr", c$Chromosome)
c$Stop <- as.character(c$Stop)

#PharmaGKB
pharm <- read.csv(paste0(args[2], "/pharm_database", args[1], ".txt"), sep="\t")
colnames(pharm)[4] <- "Ref_base"
colnames(pharm)[5] <- "Var_base"
colnames(pharm)[12] <- "Drug"
colnames(pharm)[13] <- "Annotation"
colnames(pharm)[14] <- "id"
pharm$Chromosome<-as.character(pharm$Chromosome)
pharm$Stop<-as.character(pharm$Stop)
pharm$Ref_base<-as.character(pharm$Ref_base)
pharm$Var_base<-as.character(pharm$Var_base)
pharm$Database<-"generic"

#Refgene
b <- fread(paste0(args[2], "/refgene_database", args[1], ".txt"))

#Cancer Genome Interpreter
cgi <- read.csv(paste0(args[2], "/cgi_database", args[1], ".txt"), sep="\t")
colnames(cgi)[4] <- "Ref_base"
colnames(cgi)[5] <- "Var_base"
colnames(cgi)[3] <- "Stop"
colnames(cgi)[2] <- "Start"
colnames(cgi)[9] <- "Clinical_significance"
colnames(cgi)[14] <- "Evidence_level"
colnames(cgi)[15] <- "Disease"
colnames(cgi)[16] <- "PMID"
colnames(cgi)[20] <- "Transcript"
colnames(cgi)[22] <- "Evidence_statement"
colnames(cgi)[23] <- "Citation"
cgi$Chromosome<-as.character(cgi$Chromosome)
cgi$Stop<-as.character(cgi$Stop)
cgi$Ref_base<-as.character(cgi$Ref_base)
cgi$Var_base<-as.character(cgi$Var_base)
cgi$Database<-"generic"


files_patients<- list.files(path=paste0(args[4], "/convertiti/"),
                            pattern="*.txt", full.names=TRUE, recursive=TRUE)

for(i in files_patients){
  pat <- read.csv(i , sep="\t", header=FALSE)
  colnames(pat)[1] <- "Chromosome"
  colnames(pat)[2] <- "Stop"
  colnames(pat)[3] <- "Ref_base"
  colnames(pat)[4] <- "Var_base"
  pat$Chromosome<-as.character(pat$Chromosome)
  pat$Stop<-as.character(pat$Stop)
  pat$Ref_base<-as.character(pat$Ref_base)
  pat$Var_base<-as.character(pat$Var_base)


  ################################################################################

  #civic
  civic <- semi_join(civ, pat, by = NULL, copy = FALSE)
  civic1<-subset(civic,select= c(Database, Gene, Variant, Disease, Drug, Drug_interaction_type,
                                 Evidence_type, Evidence_level, Evidence_direction, Clinical_significance,
                                 Evidence_statement, Variant_summary, Citation_id, Citation, Chromosome, Start, Stop,
                                 Ref_base, Var_base))
  write.table(civic1, paste0(args[4], "/txt_civic/",tools::file_path_sans_ext(basename(i)),".txt"),
              quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")

  ########################################################

  #clinvar
  clinvar <- semi_join(cli, pat, by = NULL, copy = FALSE)
  clinvar$info1<-sub(".*CLNSIG= *(.*?) *;CLNVC.*", "\\1", clinvar$info)
  colnames(clinvar)[6] <- "Clinical Significance"
  clinvar$`Clinical Significance`<-sub(";CLNSIGCONF.*", "\\1", clinvar$`Clinical Significance`)
  clinvar$info<-sub(".*\\| *(.*?) *;ORIGIN.*", "\\1", clinvar$info)
  colnames(clinvar)[5] <- "Change type"
  write.table(clinvar, paste0(args[4], "/txt_clinvar/",tools::file_path_sans_ext(basename(i)),".txt"),
              quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")


  ###################################################################################
  #cgi
  cgi2 <- semi_join(cgi, pat, by = NULL, copy = FALSE)
  cgi3<-subset(cgi2,select= c(Database, Gene, individual_mutation, Biomarker, Clinical_significance,
                              Drug, Drug.family, Drug.full.name, Drug.status, Evidence_level,
                              Disease, PMID, Targeting, info, region, Transcript, strand,
                              Evidence_statement, Citation, Chromosome,
                              Start, Stop, Ref_base, Var_base))
  write.table(cgi3, paste0(args[4], "/txt_cgi/",tools::file_path_sans_ext(basename(i)),".txt"),
              quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")

  ####################################################################################
  #PharmGKB
  pharm1 <- semi_join(pharm, pat, by = NULL, copy = FALSE)
  colnames(pharm1)[14] <- "ID"
  pharm2<-subset(pharm1, select= c(Database,  Gene, Sentence, Notes,
                                   Significance, Phenotype.Category,
                                   PMID, Drug, Annotation, ID, Chromosome, Start, Stop, Ref_base, Var_base))
  write.table(pharm2, paste0(args[4], "/txt_pharm/",tools::file_path_sans_ext(basename(i)),".txt"),
              quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")


  ####################################################################################
  #refgene
  df <- pat %>% left_join(b, by = c("Chromosome")) %>% filter(Stop >= ExonStarts & Stop <= ExonEnds)
  df$name <- NULL
  df$txEnd <- NULL
  df$txStart <- NULL
  df$cdsStart <- NULL
  df$cdsEnd <- NULL
  df$exonCount <- NULL
  df$bin <- NULL
  df$ExonEnds <- NULL
  df$ExonStarts <- NULL
  df$strand <- NULL
  df$score <- NULL
  df<-unique(df)
  write.table(df, paste0(args[4], "/txt_refgene/",tools::file_path_sans_ext(basename(i)),".txt"),
              quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")

  #####################################################################################################
  #cosmic
  e <- inner_join(c,pat,by = NULL, copy = FALSE)
  write.table(e, paste0(args[4], "/txt_cosmic/", tools::file_path_sans_ext(basename(i)), ".txt"), sep="\t", quote=FALSE,
              row.names=FALSE, col.names=TRUE, na="NA")

}
