args <- commandArgs(trailingOnly = TRUE)

database.path <- args[1]

civic <- read.csv(paste0(database.path,"/civic.txt"), sep="\t", quote="")
df_total <- civic[!is.na(civic$start2),c("chromosome2", "start2", "stop2", 
            "reference_bases", "variant_bases", "gene", "variant", "disease", "drugs", 
            "drug_interaction_type", "evidence_type", "evidence_level", "evidence_direction", 
            "clinical_significance", "evidence_statement", "variant_summary", 
            "citation_id", "citation")]
names(df_total)[names(df_total)=="chromosome2"] <- "chromosome"
names(df_total)[names(df_total)=="start2"] <- "start"
names(df_total)[names(df_total)=="stop2"] <- "stop"
x <- civic[,c("chromosome","start","stop","reference_bases","variant_bases","gene","variant", 
              "disease","drugs","drug_interaction_type","evidence_type","evidence_level",
              "evidence_direction","clinical_significance","evidence_statement","variant_summary",
              "citation_id","citation")]
civic <- do.call("rbind", list(x, df_total))
civic <- civic[complete.cases(civic[,1:5]),]
civic <- unique(civic)
civic$chromosome <- paste("chr",civic$chromosome, sep = "")
civic <- civic[,c("chromosome","start","stop")]
civic$code <- rownames(civic)
write.table(civic, paste0(database.path,"/civic_bed.bed"), sep="\t", col.names = FALSE, 
            row.names = FALSE, quote=FALSE)
