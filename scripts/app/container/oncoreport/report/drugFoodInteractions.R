cat("Building Drug-Food Interactions File\n")

.variables.to.keep <- ls()

drug_food_interactions <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_drugfood.txt"), sep = "\t")
drug_food_interactions <- unique(drug_food_interactions[, c("Drug", "Food_interaction"), drop=FALSE])

if (nrow(drug_food_interactions) > 0) {
  drug_food_interactions <- drug_food_interactions %>%
    group_by(Drug) %>%
    summarise(Food_interaction = paste0("<ul>", paste0("<li>", Food_interaction, "</li>", collapse = "")  ,"</ul>"))
  names(drug_food_interactions) <- c("Drug", "Food Interaction")
  table <- kable(drug_food_interactions, "html", escape = FALSE) %>% 
    kable_styling(bootstrap_options = c("striped", "hover", "condensed"))
  template.env$drug_food_interactions <- table
} else {
  template.env$drug_food_interactions <- NULL
}

brew(
  file = paste0(path_html_source, "/drugfood.html"),
  output = paste0(report_output_dir, "drugfood.html"),
  envir = template.env
)

#####################################################################################################################

rm(list = setdiff(ls(), .variables.to.keep))
