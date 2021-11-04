#Drug Information
library(dbparser)

cargs <- commandArgs(trailingOnly = TRUE)
db_path <- cargs[1]
setwd(db_path)
read_drugbank_xml_db(file.path(db_path, "drugbank.xml"))

# data for drug-drug interactions
drug_general_information(
  save_table = FALSE,
  save_csv = TRUE,
  csv_path = ".",
  override_csv = FALSE,
  database_connection = NULL
)

# data for food interactions
drug_food_interactions(
  save_table = FALSE,
  save_csv = TRUE,
  csv_path = ".",
  override_csv = FALSE,
  database_connection = NULL
)

# Prepares drug list
drug_info <- read.csv(paste0(db_path,"/drug.csv"), sep= ",")
drug_info <- cbind(drug_info$primary_key,drug_info$name)
colnames(drug_info) <- c("id","name")
write.csv(drug_info, file=paste0(db_path,"/drug_info.csv"), quote=FALSE, row.names = FALSE,na= "NA")

# drug-drug interactions
drug_interactions(save_table = FALSE,save_csv = TRUE,csv_path = db_path ,override_csv = FALSE,database_connection = NULL)
d <- read.csv(paste0(db_path,"/drug_drug_interactions.csv"), sep= ",")
colnames(d)[1] <- "Drug1_code"
colnames(d)[2] <- "Drug1_name"
colnames(d)[3] <- "Effect"
colnames(d)[4] <- "Drug2_code"
d1 <- d[,c("Drug1_code","Drug1_name")]
colnames(d1)[1] <- "Drug2_code"
colnames(d1)[2] <- "Drug2_name"
d1 <- unique(d1)
c1 <- merge(d1,d)
e1 <- c1[-which(duplicated(c1$Effect)==1),]
write.table(e1, file=paste0(db_path,"/drug_drug_interactions_light.txt"), quote = FALSE,
            row.names = FALSE, col.names = TRUE, na = "NA", sep = "\t")


# join db to build tuple like ("id" "drug_name" "food_interactions" ) for drug-food
drug_food_info <- read.csv(paste0(db_path,"/drug_food_interactions.csv"), sep = ",")
drug_gen_info <- drug_info
colnames(drug_gen_info) <- c("Drugbank_ID", "Drug")
colnames(drug_food_info) <- c("Food_interaction","Drugbank_ID")
food_interaction <- inner_join(drug_food_info,drug_gen_info)
# column order for CreateReport analysis
food_interaction <- food_interaction[,c(2,3,1)]
write.csv(food_interaction, file = paste0(db_path,"/drugfood_database.csv"), 
          quote = FALSE, row.names = FALSE, na = "NA")
