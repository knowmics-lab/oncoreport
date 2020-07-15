#Modifica CIVIC per Annovar
civic<-read.csv("./civic.txt", sep="\t", quote="")
attach(civic)
df_total = data.frame()
for (i in 1:length(civic$gene)){
if(!is.na(civic$start2[i])){
  x1 <- data.frame(chromosome= civic$chromosome2[i], start= civic$start2[i], stop= civic$stop2[i],
                   reference_bases = civic$reference_bases[i], variant_bases= civic$variant_bases[i],
                   gene= civic$gene[i], variant= civic$variant[i], disease= civic$disease[i],
                   drugs=civic$drugs[i], drug_interaction_type= civic$drug_interaction_type[i], 
                   evidence_type=civic$evidence_type[i], 
                   evidence_level=civic$evidence_level[i], 
                   evidence_direction=civic$evidence_direction[i], 
                   clinical_significance=civic$clinical_significance[i], 
                   evidence_statement=civic$evidence_statement[i], 
                   variant_summary=civic$variant_summary[i], 
                   citation_id=civic$citation_id[i], citation=civic$citation[i])
  df <- data.frame(x1)
  df_total <- rbind(df_total,df)
}}

x<-subset(civic, select= c(chromosome,start, stop, reference_bases, variant_bases, gene, variant, disease, drugs, 
                           drug_interaction_type, evidence_type, evidence_level, evidence_direction, clinical_significance, evidence_statement, variant_summary,
                           citation_id, citation))
library(dplyr)
x2 <- do.call("rbind", list(x, df_total))
attach(x2)
civic1<-x2 %>% 
  group_by(chromosome, start, stop, reference_bases, variant_bases, gene, variant) %>% 
  summarise_all(funs(trimws(paste(., collapse = ';;'))))
civic2<-civic1[complete.cases(civic1[ , 1:5]),]
write.table(civic2,file="./civic_databasehg19.txt", quote=FALSE,
        row.names = FALSE, na= "NA", sep = "\t")

#################################################################################################
#Cosmic

library(data.table)
library(dplyr)
a <- fread("/Cosmic_downloads/CosmicResistanceMutations.txt")
b <- fread("/Cosmic_downloads/CosmicCodMutDef.txt") 
colnames(a)[8] <- "ID"
colnames(b)[1] <- "Chromosome"
colnames(b)[2] <- "Stop"
colnames(b)[3] <- "ID"
colnames(b)[4] <- "Ref_base"
colnames(b)[5] <- "Alt_base"
c <- inner_join(a,b,by = NULL, copy = FALSE)
write.table(c,"./cosmic_databasehg19.txt" , sep="\t", quote=FALSE,
            row.names=FALSE, col.names=TRUE, na="NA")

###############################################################################################
#Refgene
ref <- read.csv("./ncbiRefSeq.txt", sep="\t", header=FALSE)
colnames(ref)[1] <- "bin"
colnames(ref)[2] <- "name"
colnames(ref)[3] <- "Chromosome"
colnames(ref)[4] <- "strand"
colnames(ref)[5] <- "txStart"
colnames(ref)[6] <- "txEnd"
colnames(ref)[7] <- "cdsStart"
colnames(ref)[8] <- "cdsEnd"
colnames(ref)[9] <- "exonCount"
colnames(ref)[10] <- "exonStarts"
colnames(ref)[11] <- "exonEnds"
colnames(ref)[12] <- "score"
colnames(ref)[13] <- "gene"
attach(ref)
ref<-subset(ref, select= c(bin, name, Chromosome, strand, txStart, txEnd, cdsStart, cdsEnd, exonCount,
                           score, gene, exonStarts, exonEnds))
t1<-strsplit(as.character(ref$exonEnds), ",", fixed = T)
e1<- cbind(ref[rep(1:nrow(ref), lengths(t1)), 1:12], ExonEnds = unlist(t1))
t2<-strsplit(as.character(ref$exonStarts), ",", fixed = T)
e2<- cbind(ref[rep(1:nrow(ref), lengths(t2)), 1:12], ExonStarts = unlist(t2))
e1$ExonStarts <- e2$ExonStarts
e1$exonStarts <- NULL
e1$ExonStarts<- as.character(e1$ExonStarts)
e1$ExonEnds <- as.character(e1$ExonEnds)
e1$Chromosome  <- as.character(e1$Chromosome)
write.table(e1,"./refgene_databasehg19.txt",
            quote=FALSE, row.names = FALSE, na= "NA", sep = "\t")
