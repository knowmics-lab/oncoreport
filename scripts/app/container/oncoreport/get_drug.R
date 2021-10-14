#Drug Information
if (!require("dbparser")) install.packages("dbparser")

cargs <- commandArgs(trailingOnly = TRUE)
db_path<-cargs[1]
setwd(db_path)

drug_general_information(
  save_table = FALSE,
  save_csv = TRUE,
  csv_path = ".",
  override_csv = FALSE,
  database_connection = NULL
)
drug_info <- read.csv(paste0(db_path,"/drug.csv"), sep= ",")
drug_info<-cbind(drug_info$primary_key,drug_info$name)
colnames(drug_info)<-c("id","name")
write.csv(drug_info, file=paste0(db_path,"/drug_info.csv"), quote=FALSE, row.names = FALSE,na= "NA")


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
e1<-c1[-which(duplicated(c1$Effect)==1),]
write.table(e1, file=paste0(db_path,"/drug_drug_interactions_light.txt"), quote=FALSE,
            row.names = FALSE, col.names = TRUE, na= "NA", sep = "\t")
