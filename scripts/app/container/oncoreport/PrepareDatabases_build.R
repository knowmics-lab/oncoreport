args <- commandArgs(trailingOnly = TRUE)

suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(stringr))

database.path <- args[1]
genome <- args[2]

cat("Preparing databases for", genome, "genome:\n")

#################################################################################################

#CIVIC

cat(" - CIVIC database...\n")
civic <- read.csv(paste0(database.path, "/civic.txt"), sep = "\t", quote = "")
df_total <- civic[!is.na(civic$start2), c("chromosome2", "start2", "stop2",
                                          "reference_bases", "variant_bases", "gene", "variant", "disease", "drugs",
                                          "drug_interaction_type", "evidence_type", "evidence_level", "evidence_direction",
                                          "clinical_significance", "evidence_statement", "variant_summary",
                                          "citation_id", "citation")]
names(df_total)[names(df_total) == "chromosome2"] <- "chromosome"
names(df_total)[names(df_total) == "start2"] <- "start"
names(df_total)[names(df_total) == "stop2"] <- "stop"
x <- civic[, c("chromosome", "start", "stop", "reference_bases", "variant_bases", "gene", "variant",
               "disease", "drugs", "drug_interaction_type", "evidence_type", "evidence_level",
               "evidence_direction", "clinical_significance", "evidence_statement", "variant_summary",
               "citation_id", "citation")]
civic <- do.call("rbind", list(x, df_total))
civic <- civic[complete.cases(civic[, 1:5]),]
civic <- unique(civic)
names(civic) <- c("Chromosome", "Start", "Stop", "Ref_base", "Var_base", "Gene", "Variant",
                  "Disease", "Drug", "Drug_interaction_type", "Evidence_type", "Evidence_level",
                  "Evidence_direction", "Clinical_significance", "Evidence_statement", "Variant_summary",
                  "PMID", "Citation")
civic$Chromosome <- paste0("chr", civic$Chromosome)
civic$Stop <- as.character(civic$Stop)
civic$Database <- "Civic"
civic$Evidence_statement <- gsub(civic$Evidence_statement, pattern = "â", replace = "-")
civic$Evidence_statement <- gsub(civic$Evidence_statement, pattern = "\\\\x2c", replace = ",")
civic$Evidence_level <- as.character(civic$Evidence_level)
civic$Evidence_level[civic$Evidence_level == "A"] <- "Validated association"
civic$Evidence_level[civic$Evidence_level == "B"] <- "Clinical evidence"
civic$Evidence_level[civic$Evidence_level == "C"] <- "Case study"
civic$Evidence_level[civic$Evidence_level == "D"] <- "Preclinical evidence"
civic$Evidence_level[civic$Evidence_level == "E"] <- "Inferential association"
civic$Drug <- gsub(civic$Drug, pattern = "\\\\x2c", replace = ",")
civic$Citation <- gsub(civic$Citation, pattern = "\\\\x2c", replace = ",")
civic$Variant_summary <- gsub(civic$Variant_summary, pattern = "\\\\x2c", replace = ",")
if (genome == "hg38") {
  civic1 <- civic
  civic1$code <- rownames(civic1)
  civic1$code <- as.integer(civic1$code)
  civic2 <- read.csv(paste0(database.path, "/civic_bed_hg38.bed"), sep = "\t", header = FALSE, quote = "")
  names(civic2) <- c("Chromosome", "Start", "Stop", "code")
  civic1$Start <- NULL
  civic1$Stop <- NULL
  civic <- merge(civic1, civic2, by = c("code", "Chromosome"))
  civic$code <- NULL
  civic <- civic[, c(1, 18, 19, 2:17)]
  unlink(paste0(database.path, "/civic_bed_hg38.txt"))
}
write.table(civic, file = paste0(database.path, "/civic_database_", genome, ".txt"), quote = FALSE,
            row.names = FALSE, na = "NA", sep = "\t", col.names = T)

#################################################################################################

#CGI

cat(" - CGI database...\n")
cgi <- read.csv(paste0(database.path, "/cgi_original_", genome, ".txt"), sep = "\t")
cgi <- cgi[, c("Chromosome", "start", "stop", "ref_base", "alt_base", "Gene", "individual_mutation",
               "Association", "Drug.full.name", "Evidence.level", "Primary.Tumor.type.full.name",
               "Source", "Abstract", "authors_journal_data")]
names(cgi) <- c("Chromosome", "Start", "Stop", "Ref_base", "Var_base", "Gene", "Variant",
                "Clinical_significance", "Drug", "Evidence_level", "Disease",
                "PMID", "Evidence_statement", "Citation")
cgi$Database <- "Cancer Genome Interpreter"
tmp <- apply(cgi, 2, function(col)
{
  lapply(col, function(str)
  {
    x <- paste0(str, ";;")
    x <- unlist(strsplit(x, ";;", fixed = T))
    x
  })
})
lengths <- unlist(lapply(tmp[["PMID"]], length))
tmp3 <- lapply(tmp, function(col)
{
  unlist(sapply(1:length(lengths), function(i)
  {
    rep(col[[i]], lengths[i] / length(col[[i]]))
  }))
})
cgi <- data.frame(tmp3)
cgi$PMID <- gsub(";", ",,", cgi$PMID)
tmp <- apply(cgi, 2, function(col)
{
  lapply(col, function(str)
  {
    x <- paste0(str, ",,")
    x <- unlist(strsplit(x, ",,", fixed = T))
    x
  })
})
lengths <- unlist(lapply(tmp[["PMID"]], length))
tmp3 <- lapply(tmp, function(col)
{
  unlist(sapply(1:length(lengths), function(i)
  {
    rep(col[[i]], lengths[i] / length(col[[i]]))
  }))
})
cgi <- data.frame(tmp3)
tmp <- strsplit(as.character(cgi$Disease), ";", fixed = T)
cgi <- cbind(cgi[rep(1:nrow(cgi), lengths(tmp)), -which(names(cgi) == "Disease")],
             Disease = unlist(tmp))
tmp <- strsplit(as.character(cgi$PMID), ",", fixed = T)
cgi <- cbind(cgi[rep(1:nrow(cgi), lengths(tmp)), -which(names(cgi) == "PMID")],
             PMID = unlist(tmp))
cgi <- cgi[grep("PMID:", cgi$PMID),]
cgi$PMID <- gsub(cgi$PMID, pattern = "PMID:", replace = "")
cgi$Variant <- gsub(".*:(.*)", "\\1", cgi$Variant)
cgi$Drug <- gsub(cgi$Drug, pattern = " *\\[.*?\\] *", replace = "")
cgi$Drug <- gsub(cgi$Drug, pattern = " *\\(.*?\\) *", replace = "")
cgi$Drug <- gsub(cgi$Drug, pattern = ";", replace = ",", fixed = T)
cgi$Evidence_type <- "Predictive"
cgi$Evidence_direction <- "Supports"
cgi$Evidence_statement <- gsub(cgi$Evidence_statement, pattern = "\\\\x2c", replace = ",")
cgi$Citation <- gsub(cgi$Citation, pattern = "\\\\x2c", replace = ",")
cgi$Drug_interaction_type <- ""
cgi$Drug_interaction_type[grep(" + ", cgi$Drug, fixed = T)] <- "Combination"
cgi$Drug <- gsub(cgi$Drug, pattern = " + ", replace = ",", fixed = T)
cgi$Variant_summary <- ""
cgi <- cgi[, c(1:7, 14, 9, 18, 16, 10, 17, 8, 11, 19, 15, 12, 13)]
write.table(cgi, file = paste0(database.path, "/cgi_database_", genome, ".txt"), quote = FALSE,
            row.names = FALSE, na = "NA", sep = "\t", col.names = T)
unlink(paste0(database.path, "/cgi_original_", genome, ".txt"))


#################################################################################################

#Clinvar

cat(" - Clinvar database...\n")
cli <- fread(paste0(database.path, "/clinvar_", genome, ".vcf"), skip = 27)
cli <- cli[, c("#CHROM", "POS", "REF", "ALT", "INFO")]
names(cli) <- c("Chromosome", "Stop", "Ref_base", "Var_base", "info")
cli$Chromosome <- paste0("chr", cli$Chromosome)
cli$Stop <- as.character(cli$Stop)
cli$info1 <- sub(".*CLNSIG= *(.*?) *;CLNVC.*", "\\1", cli$info)
names(cli)[6] <- "Clinical_significance"
cli$Clinical_significance <- sub(";CLNSIGCONF.*", "\\1", cli$Clinical_significance)
cli$info <- sub(".*\\| *(.*?) *;ORIGIN.*", "\\1", cli$info)
names(cli)[5] <- "Change_type"
cli$Change_type <- gsub("_variant", "", cli$Change_type, fixed = T)
cli$Change_type <- str_to_title(cli$Change_type)
cli$Clinical_significance <- gsub("_", " ", cli$Clinical_significance, fixed = T)
cli$Clinical_significance <- str_to_title(cli$Clinical_significance)
write.table(cli, file = paste0(database.path, "/clinvar_database_", genome, ".txt"),
            quote = FALSE, row.names = FALSE, na = "NA", sep = "\t", col.names = T)
unlink(paste0(database.path, "/clinvar_", genome, ".vcf"))

###############################################################################################

#Refgene

cat(" - RefSeq database...\n")
ref <- read.csv(paste0(database.path, "/ncbiRefSeq_", genome, ".txt"), sep = "\t", header = FALSE)
names(ref) <- c("bin", "name", "Chromosome", "strand", "txStart", "txEnd", "cdsStart", "cdsEnd",
                "exonCount", "exonStarts", "exonEnds", "score", "Gene")
ref <- ref[, c("bin", "name", "Chromosome", "strand", "txStart", "txEnd", "cdsStart", "cdsEnd", "exonCount",
               "score", "Gene", "exonStarts", "exonEnds")]
t1 <- strsplit(as.character(ref$exonEnds), ",", fixed = T)
t2 <- strsplit(as.character(ref$exonStarts), ",", fixed = T)
ref <- cbind(ref[rep(1:nrow(ref), lengths(t1)), 1:11], exonEnds = unlist(t1), exonStarts = unlist(t2))
write.table(ref, paste0(database.path, "/refgene_database_", genome, ".txt"),
            quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")
unlink(paste0(database.path, "/ncbiRefSeq_", genome, ".txt"))

#################################################################################

#PharmGKB

cat(" - PharmGKB database...\n")
pharm <- fread(paste0(database.path, "/pharm_database_", genome, ".txt"))
if (genome == "hg19") {
  names(pharm) <- c("Chromosome", "Start", "Stop", "Ref_base", "Var_base", "Gene",
                    "Variant_summary", "Evidence_statement", "Evidence_level",
                    "Clinical_significance", "PMID", "Drug", "PharmGKB_ID", "Variant")
} else {
  names(pharm) <- c("Chromosome", "Start", "Stop", "Ref_base", "Var_base", "Gene",
                    "Variant_summary", "Evidence_statement", "Evidence_level",
                    "Clinical_significance", "PMID", "Drug", "PharmGKB_ID", "Variant",
                    "Chromosome.1")
}
pharm$Database <- "PharmGKB"
pharm <- separate_rows(pharm, Variant_summary, Evidence_statement, Evidence_level, Clinical_significance, PMID, Drug,
                       PharmGKB_ID, Variant, sep = ";;")
pharm$Gene <- gsub("\\s+\\(.*\\)", "", pharm$Gene)
pharm$Gene <- gsub(pharm$Gene, pattern = "*\\(.*?\\) *", replace = "")
pharm$Drug <- gsub(pharm$Drug, pattern = "\\\\x2c", replace = ",")
pharm$Drug <- gsub(pharm$Drug, pattern = "*\\(.*?\\) *", replace = "")
pharm$Drug <- gsub("\\s+", "", gsub("^\\s+|\\s+$", "", pharm$Drug))
pharm$Drug <- unname(sapply(pharm$Drug, function(x) (paste0(str_to_title(strsplit(x, ",")[[1]]), collapse = ","))))
pharm$Variant_summary <- gsub(pharm$Variant_summary, pattern = "\\\\x2c", replace = ",")
pharm$Clinical_significance <- gsub(pattern = " ", replace = "", pharm$Clinical_significance)
pharm$Evidence_statement <- gsub(pharm$Evidence_statement, pattern = "\\\\x2c", replace = ",")
pharm <- subset.data.frame(pharm, Evidence_level == "yes")
write.table(pharm, paste0(database.path, "/pharm_database_", genome, ".txt"),
            quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")

#################################################################################
