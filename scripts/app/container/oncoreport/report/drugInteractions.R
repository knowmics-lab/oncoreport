cat("Building Drug-Drug Interactions File\n")

.variables.to.keep <- ls()
interactions_db <- unique(read.csv(paste0(path_db, "/drug_drug_interactions_light.txt"), sep = "\t"))
interactions_db$key <- mapply(
  function (i1,i2) (paste(sort(c(i1,i2)), collapse = ",")), interactions_db$Drug2_code, interactions_db$Drug1_code)
pt_drugs <- unique(tryCatch(readLines(pt_path_file_comorbid), error = function(e) (character(0))))
unique_drugs <- unique(data.frame(
  code=c(interactions_db$Drug2_code, interactions_db$Drug1_code),
  name=c(interactions_db$Drug2_name, interactions_db$Drug1_name)
))

primary_drugs <- unique(c(unique_drugs$code[unique_drugs$name %in% recommended_drugs$primary], pt_drugs))
other_drugs   <- unique(unique_drugs$code[unique_drugs$name %in% recommended_drugs$others])
#####################################################################################################################
primary_interactions <- interactions_db[interactions_db$Drug2_code %in% primary_drugs & 
                                          interactions_db$Drug1_code %in% primary_drugs,,drop=FALSE] %>%
  group_by(key) %>%
  summarise(Drug2_code=Drug2_code[1], Drug2_name=Drug2_name[1],
            Drug1_code=Drug1_code[1], Drug1_name=Drug1_name[1],
            Effect=Effect[1])

#####################################################################################################################
other_interactions <- interactions_db[(interactions_db$Drug2_code %in% primary_drugs | 
                                         interactions_db$Drug1_code %in% primary_drugs) &
                                        !(interactions_db$key %in% primary_interactions$key), ] %>%
  group_by(key) %>%
  summarise(Drug2_code=Drug2_code[1], Drug2_name=Drug2_name[1],
            Drug1_code=Drug1_code[1], Drug1_name=Drug1_name[1],
            Effect=Effect[1])
tmp <- other_interactions[other_interactions$Drug1_code %in% primary_drugs &
                            !(other_interactions$Drug2_code %in% primary_drugs),,drop=FALSE]
if (nrow(tmp) > 0) {
  other_interactions <- rbind(
    other_interactions[other_interactions$Drug2_code %in% primary_drugs,,drop=FALSE],
    data.frame(key=tmp$key, Drug2_code=tmp$Drug1_code, Drug2_name=tmp$Drug1_name,
               Drug1_code=tmp$Drug2_code, Drug1_name=tmp$Drug2_name,
               Effect=tmp$Effect)
  )
}
primary_interactions <- as.data.frame(unique(primary_interactions %>% select(Drug2_name, Drug1_name, Effect)))
other_interactions   <- as.data.frame(unique(other_interactions %>% select(Drug2_name, Drug1_name, Effect)))
colnames(primary_interactions) <- c("Drug", "Interacts with", "Effect")
colnames(other_interactions)   <- c("Drug", "Interacts with", "Effect")

#####################################################################################################################
rownames(primary_interactions) <- seq_len(nrow(primary_interactions))
suppressWarnings({
  table <- datatable(primary_interactions, width = "100%")
  htmlwidgets::saveWidget(table, paste0(report_output_dir, "primary_drugs_interactions.html"))
})

rownames(other_interactions) <- seq_len(nrow(other_interactions))
suppressWarnings({
  table <- datatable(other_interactions, width = "100%")
  htmlwidgets::saveWidget(table, paste0(report_output_dir, "other_primary_interactions.html"))
})

brew(
  file = paste0(path_html_source, "/drugdrug.html"),
  output = paste0(report_output_dir, "drugdrug.html"),
  envir = template.env
)

#####################################################################################################################
all_drugs <- unique(c(primary_drugs, other_drugs))
complete_interactions <- interactions_db[interactions_db$Drug2_code %in% all_drugs | 
                                           interactions_db$Drug1_code %in% all_drugs,,drop=FALSE] %>%
  group_by(key) %>%
  summarise(Drug2_code=Drug2_code[1], Drug2_name=Drug2_name[1],
            Drug1_code=Drug1_code[1], Drug1_name=Drug1_name[1],
            Effect=Effect[1])
complete_interactions   <- as.data.frame(unique(complete_interactions %>% select(Drug2_name, Drug1_name, Effect)))
colnames(complete_interactions) <- c("Drug", "Interacts with", "Effect")
rownames(complete_interactions) <- seq_len(nrow(complete_interactions))
suppressWarnings({
  table <- datatable(complete_interactions, width = "100%")
  htmlwidgets::saveWidget(table, paste0(report_output_dir, "all_drugs_interactions.html"))
})


rm(list = setdiff(ls(), .variables.to.keep))
