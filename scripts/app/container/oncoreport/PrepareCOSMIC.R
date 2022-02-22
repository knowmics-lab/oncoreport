args <- commandArgs(trailingOnly = TRUE)

suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(stringr))

cosmic.path <- args[1]
genome <- args[2]

#################################################################################################

#COSMIC

cat("Setup COSMIC Resistance Mutations database...\n")
a <- fread(paste0(cosmic.path, "/CosmicResistanceMutations_", genome, ".txt.gz"))
b <- fread(paste0(cosmic.path, "/CosmicCodMutDef_", genome, ".txt"))
a$`Gene Name` <- gsub("_ENST.*", "", a$`Gene Name`)
colnames(a)[8] <- "ID"
names(b) <- c("Chromosome", "Stop", "ID", "Ref_base", "Alt_base")
cosm <- inner_join(a, b, by = NULL, copy = FALSE)
names(cosm)[grep("Genome Coordinates", names(cosm))] <- "Genome Coordinates"
cosm <- cosm[, c("Gene Name", "Drug Name", "AA Mutation", "Primary Tissue", "Tissue Subtype 1",
                 "Tissue Subtype 2", "Histology", "Histology Subtype 1", "Histology Subtype 2",
                 "Pubmed Id", "Somatic Status", "Sample Type", "Zygosity", "Genome Coordinates",
                 "HGVSP", "HGVSC", "HGVSG", "Chromosome", "Stop", "Ref_base", "Alt_base")]
cosm$Chromosome <- paste0("chr", cosm$Chromosome)
cosm$Stop <- as.character(cosm$Stop)
names(cosm)[names(cosm) == "Pubmed Id"] <- "PMID"
names(cosm)[names(cosm) == "AA Mutation"] <- "Variant"
names(cosm)[names(cosm) == "Gene Name"] <- "Gene"
names(cosm)[names(cosm) == "Drug Name"] <- "Drug"
cosm$Variant <- gsub(cosm$Variant, pattern = "p.", replace = "")
cosm$Stop <- sub('.*\\.', '', cosm$`Genome Coordinates`)
a <- sub('.*\\:', '', cosm$`Genome Coordinates`)
cosm$Start <- gsub("\\..*", "", a)
cosm$`Genome Coordinates` <- NULL
write.table(cosm, paste0(cosmic.path, "/cosmic_database_", genome, ".txt"), sep = "\t",
            quote = FALSE, row.names = FALSE, col.names = TRUE, na = "NA")
rm(a,b,cosm)

cat("Setup COSMIC All Variants database...\n")
a <- na.omit(fread(paste0(cosmic.path, "/CosmicVariantsRaw_", genome, ".tsv.gz")))
colnames(a) <- c("ID", "GeneName", "Mutation", "Chromosome", "Start", "Stop", "Effect", "PMID")
b <- fread(paste0(cosmic.path, "/CosmicCodMutDef_", genome, ".txt"))
colnames(b) <- c("Chromosome", "Start", "ID", "Ref_base", "Var_base")
b <- b[,c("ID", "Ref_base", "Var_base")]
a <- a %>% 
  group_by(ID, GeneName, Mutation, Chromosome, Start, Stop) %>% 
  summarise(Effect=paste0(unique(Effect), collapse=", "), PMID=paste0(unique(PMID), collapse=", ")) %>%
  inner_join(b, by = "ID") %>%
  ungroup() %>%
  select(Chromosome, Start, Stop, Ref_base, Var_base, GeneName, Mutation, Effect, PMID) %>%
  filter(Effect %in% c("PATHOGENIC", "NEUTRAL")) %>%
  arrange(Chromosome, Start, Stop) %>%
  mutate(Chromosome=paste0("chr", Chromosome))
write.table(a, paste0(cosmic.path, "/cosmic_all_variants_database_", genome, ".txt"), sep = "\t",
            quote = FALSE, row.names = FALSE, col.names = TRUE, na = "NA")


