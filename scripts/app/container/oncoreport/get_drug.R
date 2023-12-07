#!/usr/bin/env Rscript
library(dbparser)
library(dplyr)

cargs <- commandArgs(trailingOnly = TRUE)
db_path <- cargs[1]
setwd(db_path)
read_drugbank_xml_db(file.path(db_path, "drugbank.xml"))

cat("Preparing drug general information\n")
drug_info           <- drug_general_information(
  save_table = FALSE,
  save_csv = FALSE,
  csv_path = ".",
  override_csv = FALSE,
  database_connection = NULL
)
class(drug_info)    <- "data.frame"
drug_info           <- cbind(drug_info$primary_key, drug_info$name)
colnames(drug_info) <- c("id", "name")

# # Process synonyms
# drug_synonyms <- drug_syn(
#   save_table = FALSE,
#   save_csv = FALSE,
#   csv_path = ".",
#   override_csv = FALSE,
#   database_connection = NULL
# )
# class(drug_synonyms) <- "data.frame"
# drug_synonyms <- drug_synonyms[grepl("english", drug_synonyms$language, ignore.case = TRUE),]
# drug_synonyms <- drug_synonyms[,c(4,1)]
# colnames(drug_synonyms) <- c("id", "name")
# drug_info_complete <- rbind(drug_info, drug_synonyms)
# drug_info_complete <- drug_info_complete[order(drug_info_complete[,1]),]
# key <- tolower(paste0(drug_info_complete[,1], gsub("[^A-Za-z0-9]*", "", drug_info_complete[,2], perl = TRUE)))
# keep.rows <- tapply(1:nrow(drug_info_complete), key, function(x) (x[1]))
# drug_info_complete <- drug_info_complete[keep.rows,]
write.csv(drug_info,
  file = paste0(db_path, "/drug_info.csv"),
  quote = FALSE, row.names = FALSE, na = "NA"
)


cat("Preparing drug-drug interactions\n")
# drug-drug interactions
drug_interactions(
  save_table = FALSE,
  save_csv = TRUE,
  csv_path = db_path,
  override_csv = FALSE,
  database_connection = NULL
)

d <- read.csv(paste0(db_path, "/drug_drug_interactions.csv"), sep = ",")
colnames(d)[1] <- "Drug1_code"
colnames(d)[2] <- "Drug1_name"
colnames(d)[3] <- "Effect"
colnames(d)[4] <- "Drug2_code"
d1 <- d[, c("Drug1_code", "Drug1_name")]
colnames(d1)[1] <- "Drug2_code"
colnames(d1)[2] <- "Drug2_name"
d1 <- unique(d1)
c1 <- merge(d1, d)
e1 <- c1[-which(duplicated(c1$Effect) == 1), ]
write.table(e1,
  file = paste0(db_path, "/drug_drug_interactions_light.txt"),
  quote = FALSE, row.names = FALSE, col.names = TRUE,
  na = "NA", sep = "\t"
)

cat("Preparing drug-food interactions\n")
# data for food interactions
drug_food_info <- drug_food_interactions(
  save_table = FALSE,
  save_csv = FALSE,
  csv_path = ".",
  override_csv = FALSE,
  database_connection = NULL
)
class(drug_food_info) <- "data.frame"
drug_gen_info <- data.frame(drug_info)
colnames(drug_gen_info) <- c("Drugbank_ID", "Drug")
colnames(drug_food_info) <- c("Food_interaction", "Drugbank_ID")
food_interaction <- drug_food_info %>% inner_join(drug_gen_info, by = "Drugbank_ID")
# column order for CreateReport analysis
food_interaction <- food_interaction[, c(2, 3, 1)]
write.csv(food_interaction,
  file = paste0(db_path, "/drugfood_database.csv"),
  quote = FALSE, row.names = FALSE, na = "NA"
)
