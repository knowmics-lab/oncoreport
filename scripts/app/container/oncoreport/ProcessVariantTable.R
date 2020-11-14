args <- commandArgs(trailingOnly = TRUE)

dp <- args[1]
af <- args[2]
vartable.file <- args[3]
sample.name <- args[4]
project.path <- args[5]

data <- read.csv(vartable.file, sep = "\t")
data <- data[, c("Chromosome", "Position", "Reference.Allele", "Variant.Allele", "Variant.Type",
                 "Sequence.Context", "Consequence", "dbSNP.ID", "COSMIC.ID", "ClinVar", "Gene.ID",
                 "Variant.Frequency", "Total.Depth")]
dp <- gsub("DP<", "", dp)
af <- gsub("AF>=", "", af)
data <- data[data$Total.Depth >= dp,]
if (nrow(data) > 0)
{
  data$Type <- "Somatic"
  data[data$Variant.Frequency >= af, "Type"] <- "Germline"
} else {
  data$Type <- character()
}
write.table(data, paste0(project.path, "/converted/variants.txt"),
            quote = FALSE, row.names = FALSE, na = "NA", sep = "\t")
