args=commandArgs(trailingOnly = TRUE)
files_patients<- list.files(path="/fastq/",
                            pattern="*.varianttable.txt", full.names=TRUE, recursive=TRUE)

for(i in files_patients){
x <- read.csv(i , sep="\t")
x$Strand.Bias <- NULL
x$Variant.Allele.Depth <- NULL
x$Reference.Allele.Depth <- NULL
x$Variant.Quality <- NULL
args.1<-gsub("DP<", "", args[1])
args.2<-gsub("AF>", "", args[2])
z <- subset.data.frame(x,subset = x$Total.Depth>= args.1)
t <- subset.data.frame(z,subset = x$Variant.Frequency<= args.2)
t$Type<-"Somatic"
y <- subset.data.frame(z,subset = x$Variant.Frequency>= args.2)
y$Type<-"Germline"
write.table(t,paste0("/convertiti/", args[3],"_Somatic.txt"),
            quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
write.table(y,paste0("/convertiti/", args[3],"_Germline.txt"),
            quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
}

#merging database
library(dplyr)
library(data.table)
library(filesstrings)

#################################################################################
#banche
#civic
civ <- read.csv(paste0("/civic_database", args[4], ".txt"), sep="\t", quote="")
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

#clinvar
cli <- fread(paste0("/clinvar_database", args[4],".vcf"))
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

#cosmic
c <- fread(paste0("/cosmic_database",args[4],".txt"))
c$Chromosome<-paste0("chr", c$Chromosome) 
c$Stop <- as.character(c$Stop)

#pharm
pharm <- read.csv(paste0("/pharm_database", args[4], ".txt"), sep="\t")
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

#refgene
b <- fread(paste0("/refgene_database", args[4], ".txt"))

#cgi
cgi <- read.csv(paste0("/cgi_database", args[4], ".txt"), sep="\t")
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

#patient
files_patients_def<- list.files(path="/convertiti/",
                                pattern="*.txt", full.names=TRUE, recursive=TRUE)

for(i in files_patients_def){
  pat <- read.csv(i , sep="\t")
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
  pat1<-pat[-c((length(civic1$Database)+1):length(pat$Chromosome)),]
  civic1$Type<-pat1$Type
  write.table(civic1,paste0("/txt_civic/",tools::file_path_sans_ext(basename(i)),".txt"),
              quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
  
  ########################################################
  
  #clinvar
  clinvar <- semi_join(cli, pat, by = NULL, copy = FALSE)
  clinvar$info1<-sub(".*CLNSIG= *(.*?) *;CLNVC.*", "\\1", clinvar$info)
  colnames(clinvar)[6] <- "Clinical Significance"
  clinvar$`Clinical Significance`<-sub(";CLNSIGCONF.*", "\\1", clinvar$`Clinical Significance`)
  clinvar$info<-sub(".*\\| *(.*?) *;ORIGIN.*", "\\1", clinvar$info)
  colnames(clinvar)[5] <- "Change type"
  pat1<-pat[-c((length(clinvar$Chromosome)+1):length(pat$Chromosome)),]
  clinvar$Type<-pat1$Type
  write.table(clinvar,paste0("/txt_clinvar/",tools::file_path_sans_ext(basename(i)),".txt"),
              quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
  
  
  ###################################################################################
  #cgi
  cgi2 <- semi_join(cgi, pat, by = NULL, copy = FALSE)
  cgi3<-subset(cgi2,select= c(Database, Gene, individual_mutation, Biomarker, Clinical_significance,
                              Drug, Drug.family, Drug.full.name, Drug.status, Evidence_level,
                              Disease, PMID, Targeting, info, region, Transcript, strand,
                              Evidence_statement, Citation, Chromosome,
                              Start, Stop, Ref_base, Var_base))
  pat1<-pat[-c((length(cgi3$Database)+1):length(pat$Chromosome)),]
  cgi3$Type<-pat1$Type
  write.table(cgi3,paste0("/txt_cgi/",tools::file_path_sans_ext(basename(i)),".txt"),
              quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
  
  ####################################################################################
  #Pharm
  pharm1 <- semi_join(pharm, pat, by = NULL, copy = FALSE)
  colnames(pharm1)[14] <- "ID"
  pharm2<-subset(pharm1, select= c(Database,  Gene, Sentence, Notes,  
                                   Significance, Phenotype.Category, 
                                   PMID, Drug, Annotation, ID, Chromosome, Start, Stop, Ref_base, Var_base))
  pat1<-pat[-c((length(pharm2$Database)+1):length(pat$Chromosome)),]
  pharm2$Type<-pat1$Type
  write.table(pharm2,paste0("/txt_pharm/",tools::file_path_sans_ext(basename(i)),".txt"),
              quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
  
  
  ####################################################################################
  #refgene 
  df <- pat %>% left_join(b, by = c("Chromosome")) %>% filter(Stop >= ExonStarts & Stop <= ExonEnds)
  df<-subset(df, select = c(Chromosome, Stop, Ref_base, Var_base, gene, Type))
  df<-unique(df)
  write.table(df,paste0("/txt_refgene/",tools::file_path_sans_ext(basename(i)),".txt"),
              quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
  
  #####################################################################################################
  #cosmic
  e <- inner_join(c,pat,by = NULL, copy = FALSE)
  pat1<-pat[-c((length(e$chromosome)+1):length(pat$Chromosome)),]
  e$Type<-pat1$Type
  write.table(e, paste0("/txt_cosmic/", tools::file_path_sans_ext(basename(i)), ".txt"), sep="\t", quote=FALSE,
              row.names=FALSE, col.names=TRUE, na="NA")
}


######################################################################################

#Civic
germ_civ<-read.csv(paste0("/txt_civic/", args[3], "_Germline.txt"), sep= "\t")
som_civ<-read.csv(paste0("/txt_civic/", args[3], "_Somatic.txt"), sep= "\t")
civic <- merge(som_civ, germ_civ, all=TRUE)
write.table(civic,paste0("/civic/",args[3],".txt"),
            quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")

######################################################################################
#CGI
germ_cgi<-read.csv(paste0("/txt_cgi/",args[3],"_Germline.txt"), sep= "\t")
som_cgi<-read.csv(paste0("/txt_cgi/",args[3],"_Somatic.txt"), sep= "\t")
cgi <- merge(som_cgi, germ_cgi, all=TRUE)
write.table(cgi,paste0("/cgi/",args[3],".txt"),
            quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")

######################################################################################

#PharmGKB
germ_pha<-read.csv(paste0("/txt_pharm/",args[3],"_Germline.txt"), sep= "\t")
som_pha<-read.csv(paste0("/txt_pharm/",args[3],"_Somatic.txt"), sep= "\t")
pharm <- merge(som_pha, germ_pha, all=TRUE)
write.table(pharm,paste0("/pharm/",args[3],".txt"),
            quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")

######################################################################################

#Refgene
germ_ex<-read.csv(paste0("/txt_refgene/",args[3],"_Germline.txt"), sep= "\t")
som_ex<-read.csv(paste0("/txt_refgene/",args[3],"_Somatic.txt"), sep= "\t")
ex <- merge(som_ex, germ_ex, all=TRUE)
write.table(ex,paste0("/refgene/",args[3],".txt"),
            quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")


######################################################################################

#Cosmic
germ_cos<-read.csv(paste0("/txt_cosmic/",args[3],"_Germline.txt"), sep= "\t")
som_cos<-read.csv(paste0("/txt_cosmic/",args[3],"_Somatic.txt"), sep= "\t")
cosmic <- merge(som_cos, germ_cos, all=TRUE)
write.table(cosmic,paste0("/cosmic/",args[3],".txt"),
            quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")

######################################################################################

#Clinvar
germ_clin<-read.csv(paste0("/txt_clinvar/",args[3],"_Germline.txt"), sep= "\t")
som_clin<-read.csv(paste0("/txt_clinvar/",args[3],"_Somatic.txt"), sep= "\t")
clinvar <- merge(som_clin, germ_clin, all=TRUE)
write.table(clinvar,paste0("/clinvar/",args[3],".txt"),
            quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")





