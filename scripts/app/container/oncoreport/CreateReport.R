thisFile <- function() {
  cmdArgs <- commandArgs(trailingOnly = FALSE)
  needle <- "--file="
  match <- grep(needle, cmdArgs)
  if (length(match) > 0) {
    # Rscript
    return(normalizePath(sub(needle, "", cmdArgs[match])))
  } else {
    # 'source'd via R console
    return(normalizePath(sys.frames()[[1]]$ofile))
  }
}
source(file.path(dirname(thisFile()), "report", "imports.R"), local = knitr::knit_global())
source(file.path(dirname(thisFile()), "report", "commons.R"), local = knitr::knit_global())
options(knitr.table.format = "html")

cargs <- commandArgs(trailingOnly = TRUE)

pt_name <- cargs[1]
pt_surname <- cargs[2]
pt_sample_name <- cargs[3]
pt_sex <- cargs[4]
pt_age <- cargs[5]
pt_tumor <- cargs[6]
pt_fastq <- cargs[7]
path_project <- cargs[8]
path_db <- cargs[9]
tumor_type <- cargs[10]
pt_tumor_site <- cargs[11]
pt_city <- cargs[12]
pt_phone <- cargs[13]
pt_tumor_stage <- cargs[14]
pt_path_file_comorbid <- cargs[15]
path_html_source <- cargs[16]

if (tumor_type == "lb") {
  depth <- cargs[17]
  af <- cargs[18]
}

report_output_dir <- paste0(path_project, "/report/")
dir.create(report_output_dir, showWarnings = FALSE)


imported_diseases        <- read.diseases(path_db)
diseases_db              <- imported_diseases[[1]]
diseases_db_simple       <- imported_diseases[[2]]
pt_disease_details       <- diseases_db[diseases_db$DOID == pt_tumor,,drop = FALSE]
pt_disease_name          <- unique(pt_disease_details$DO_name)[1]

evidence_list <- c("Validated association", "FDA guidelines", "NCCN guidelines", "Clinical evidence", "Late trials", 
                   "Early trials", "Case study", "Case report", "Preclinical evidence", "Pre-clinical", 
                   "Inferential association")


template.env <- new.env()
template.env$pt_surname      <- pt_surname
template.env$pt_name         <- pt_name
template.env$pt_sex          <- ifelse(pt_sex == "m", "Male", "Female")
template.env$pt_age          <- pt_age
template.env$pt_city         <- pt_city
template.env$pt_phone        <- pt_phone
template.env$pt_sample_name  <- pt_sample_name
template.env$pt_disease_name <- pt_disease_name
template.env$pt_tumor_stage  <- pt_tumor_stage


suppressMessages(source(file.path(dirname(thisFile()), "report", "therapeutic.R")))
# suppressMessages(source(file.path(dirname(thisFile()), "report", "drugInteractions.R")))
suppressMessages(source(file.path(dirname(thisFile()), "report", "drugFoodInteractions.R")))
suppressMessages(source(file.path(dirname(thisFile()), "report", "mutations.R")))
suppressMessages(source(file.path(dirname(thisFile()), "report", "esmo.R")))
suppressMessages(source(file.path(dirname(thisFile()), "report", "pharmgkb.R")))
suppressMessages(source(file.path(dirname(thisFile()), "report", "cosmic.R")))
suppressMessages(source(file.path(dirname(thisFile()), "report", "offlabel.R")))
suppressMessages(source(file.path(dirname(thisFile()), "report", "references.R")))


stop()


cat("Copying assets\n")
file.copy(file.path(path_html_source, "assets"), report_output_dir, recursive = TRUE)
cat("OK!\n")
stop()


if (tumor_type == "tumnorm") {
  sample.type <- "Tumor and Blood Biopsy"
} else {
  sample.type <- "Liquid Biopsy"
}
pat <- data.frame(Name = pt_name, Surname = pt_surname, ID = pt_sample_name, Gender = pt_sex, Age = pt_age,
                  Sample = sample.type, Tumor = pt_tumor)
patient_info <- kable(pat) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "responsive"))
xml_patient_info <- kable_as_xml(patient_info)




## Off labels Drug  {.tabset}
cat("OFFLABEL - drug\n")
offlabel <- (read_html(paste0(path_html_source, "/offlabel.html")))
children_offlabel_vm <- xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(offlabel, 2), 1), 2), 4), 1), 1)
array_table <- c()
an <- xml_child(xml_child(xml_child(xml_child(xml_child(offlabel, 2), 1), 1), 2), 2)
xml_replace(an, an_xml)
### Variant Mutation
##Mutations information
options(knitr.table.format = "html")
#cargs=commandArgs(trailingOnly = TRUE)
try({
  x_url <- read.csv(paste0(path_project, "/txt/reference/", pt_fastq, "_off.txt"), sep = "\t")
  x_url <- x_url[, c("PMID", "Reference")]
  x_url <- x_url[!duplicated(x_url[, c("PMID")]),]
  x_url$PMID <- as.character(x_url$PMID)
  
  x_trial <- read.csv(paste0(path_project, "/txt/trial/", pt_fastq, "_off.txt"), sep = "\t")
  list.all.trials <- unique(x_trial$Clinical_trial)
  
  x <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_definitive.txt"), sep = "\t", colClasses = c("character"))
  dis <- read.csv(paste0(path_db, "/Disease.txt"), sep = "\t")
  colnames(dis)[1] <- "Disease"
  x <- merge(dis, x, by = "Disease")
  x$Disease <- NULL
  x$Category <- NULL
  colnames(x)[1] <- "Disease"
  x <- separate_rows(x, DOID, sep = ",")
  x <- x[x$Evidence_direction == "Supports" & x$DOID != pt_tumor, , drop = F]
  x$DOID <- NULL
  sub <- x[x$Drug_interaction_type == "Substitutes",]
  x <- x[x$Drug_interaction_type != "Substitutes",]
  sub <- sub %>%
    mutate(Drug = strsplit(as.character(Drug), ",")) %>%
    unnest(Drug)
  x <- rbind(x, sub)
  x[is.na(x)] <- " "
  x$Drug <- as.character(x$Drug, levels = (x$Drug))
  x$Drug <- gsub(", ", ",", x$Drug, fixed = T)
  x$Drug_interaction_type <- NULL
  x$Evidence_type <- factor(x$Evidence_type, levels = c("Diagnostic", "Prognostic", "Predisposing", "Predictive", "Functional"))
  x$Evidence_level <- factor(x$Evidence_level, levels = c("Validated association", "FDA guidelines", "NCCN guidelines", "Clinical evidence", "Late trials", "Early trials", "Case study", "Case report", "Preclinical evidence", "Pre-clinical", "Inferential association"))
  x$Disease <- as.character(x$Disease, levels = (x$Disease))
  x <- inner_join(x, x_url)
  
  x <- x[order(x$Disease, x$Evidence_level, x$Evidence_type, x$Gene, x$Variant, x$Drug,
               x$Clinical_significance, x$Reference, x$Score, x$Approved),]
  x$Database <- NULL
  x <- unique(x)
  x$Variant_summary[x$Variant_summary == "" | x$Variant_summary == " "] <- NA
  x <- x %>%
    group_by(Disease, Gene, Variant, Drug, Evidence_type, Evidence_direction, Clinical_significance, Variant_summary, PMID,
             Chromosome, Start, Stop, Ref_base, Var_base, Type, Approved, Score, Reference) %>%
    summarize(Evidence_level = str_c(Evidence_level, collapse = ", "), Evidence_statement = str_c(Evidence_statement, collapse = ", "),
              Citation = str_c(Citation, collapse = ", "))
  x$Evidence_level <- gsub("(.*),.*", "\\1", x$Evidence_level)
  x$Evidence_statement <- gsub(".,", ".", x$Evidence_statement)
  x <- x[, c("Disease", "Gene", "Variant", "Drug", "Evidence_type", "Evidence_level", "Evidence_direction", "Clinical_significance",
             "Evidence_statement", "Variant_summary", "PMID", "Citation", "Chromosome", "Start", "Stop", "Ref_base", "Var_base",
             "Type", "Approved", "Score", "Reference")]
  x$Variant_summary[is.na(x$Variant_summary)] <- ""
  
  pr <- str_count(x$Drug, ',')
  if (length(pr) != 0)
  {
    for (i in 1:length(pr)) {
      if (pr[i] >= 1) {
        sb <- unlist(strsplit(x$Approved[i], ","))
        if (length(unique(sb)) == 1) {
          x$Approved[i] <- sb[1]
        } else {
          if (all(grepl("EMA/FDA", sb))) {
            x$Approved[i] <- "EMA/FDA"
          } else if (all(grepl("AIFA/EMA", sb))) {
            x$Approved[i] <- "AIFA/EMA"
          } else if (all(grepl("AIFA/FDA", sb))) {
            x$Approved[i] <- "AIFA/FDA"
          } else if (all(grepl("AIFA", sb))) {
            x$Approved[i] <- "AIFA"
          } else if (all(grepl("FDA", sb))) {
            x$Approved[i] <- "FDA"
          } else if (all(grepl("EMA", sb))) {
            x$Approved[i] <- "EMA"
          } else {
            x$Approved[i] <- "Not approved"
          }
        }
      }
    }
    
    
    if (nrow(x) > 0)
    {
      #Score
      x$Citation <- gsub("(,)([0-9]+)", "\\1 \\2,", x$Citation)
      x$year <- gsub(".*, (\\w+),.*", "\\1", x$Citation)
      x$y_score <- apply(x, 1, function(row) {
        if (row["year"] == 2021 |
            row["year"] == 2020 |
            row["year"] == 2019) {
          3 #Deleterio
        } else if (row["year"] == 2018 |
                   row["year"] == 2017 |
                   row["year"] == 2016) {
          2
        }  else if (row["year"] == 2015 |
                    row["year"] == 2014 |
                    row["year"] == 2013) {
          1
        }  else if (row["year"] == 2012 |
                    row["year"] == 2011 |
                    row["year"] == 2010) {
          0.5
        } else {
          0 #Tolerate/Benign/Unknown
        }
      })
      
      sp <- split(x, x$Gene)
      b <- list()
      if (length(sp) > 1) {
        for (i in 1:length(sp)) {
          a <- sp[[i]]
          a <- unique(a)
          a <- a[!a$Drug == "",]
          if (dim(a)[1] != 0) {
            b <- c(list(a), b)
          }
        }
      }
      
      if (length(b) > 1) {
        tot <- data.frame()
        for (i in 1:length(b)) {
          for (o in 1:length(b)) {
            if (o != i) {
              data <- b[[i]]
              data$d_score <- b[[i]]$Drug %in% b[[o]]$Drug
              data$cp <- paste(o, " - ", i)
              data <- as.data.frame(data)
              tot <- rbind(data, tot)
            }
          } }
        tot$d_score[tot$d_score == TRUE] <- 1
        tot$d_score[tot$d_score == FALSE] <- 0
        tot3 <- tot %>%
          rowwise() %>%
          mutate(cp = paste(sort(unlist(strsplit(cp, "  -  ", fixed = TRUE))), collapse = "  -  "))
        tot3 <- tot3[, c("Drug", "cp", "d_score")]
        tot3 <- unique(tot3)
        tot3$cp <- NULL
        tot3 <- aggregate(d_score ~ Drug, tot3, sum)
        m1 <- merge(tot3, x, all.y = TRUE)
        m1[is.na(m1)] <- 0
        m1 <- m1[, c("Drug", "Score", "y_score", "d_score")]
        m1 <- unique(m1)
        m1 <- m1[-which(m1$Drug == ""),]
        m1$Score <- as.numeric(m1$Score)
        m1$tot <- rowSums(m1[, c("Score", "y_score", "d_score")])
        drug_score <- aggregate(tot ~ Drug, m1, mean)
        x <- merge(drug_score, x, all.y = TRUE)
        x$Score <- NULL
        colnames(x)[2] <- "Score"
      } else {
        x$Score <- as.numeric(x$Score)
        x$tot <- rowSums(x[, c("Score", "y_score")])
        x$Score <- NULL
        colnames(x)[length(x)] <- "Score"
      }
      
      x$y_score <- NULL
      x[is.na(x)] <- 0
      #Alphabetic order of the drug name
      x$Drug <- as.character(x$Drug)
      x <- x %>%
        rowwise() %>%
        mutate(Drug = paste(sort(unlist(strsplit(Drug, ",", fixed = TRUE))), collapse = ","))
      x <- unique(x)
      
      ###
      g <- apply(x, 1, function(row) {
        if (grepl("AIFA/EMA/FDA", row["Approved"])) {
          row["AIFA"] <- "&#9989;"
          row["FDA"] <- "&#9989;"
          row["EMA"] <- "&#9989;"
        } else if (grepl("AIFA/FDA", row["Approved"])) {
          row["AIFA"] <- "&#9989;"
          row["FDA"] <- "&#9989;"
          row["EMA"] <- "&#10060;"
        } else if (grepl("EMA/FDA", row["Approved"])) {
          row["AIFA"] <- "&#10060;"
          row["FDA"] <- "&#9989;"
          row["EMA"] <- "&#9989;"
        } else if (grepl("AIFA/EMA", row["Approved"])) {
          row["AIFA"] <- "&#9989;"
          row["FDA"] <- "&#10060;"
          row["EMA"] <- "&#9989;"
        } else if (grepl("AIFA", row["Approved"])) {
          row["AIFA"] <- "&#9989;"
          row["FDA"] <- "&#10060;"
          row["EMA"] <- "&#10060;"
        } else if (grepl("EMA", row["Approved"])) {
          row["AIFA"] <- "&#10060;"
          row["FDA"] <- "&#10060;"
          row["EMA"] <- "&#9989;"
        } else if (grepl("FDA", row["Approved"])) {
          row["AIFA"] <- "&#10060;"
          row["FDA"] <- "&#9989;"
          row["EMA"] <- "&#10060;"
        } else {
          row["AIFA"] <- "&#10060;"
          row["FDA"] <- "&#10060;"
          row["EMA"] <- "&#10060;"
        }
        g <- list(row["AIFA"], row["FDA"], row["EMA"])
        return(g)
      })
      g <- as.data.frame(do.call(rbind, g))
      colnames(g) <- c("AIFA", "FDA", "EMA")
      x <- cbind(x, g)
      
      x$Approved <- NULL
      x$AIFA <- as.character(x$AIFA)
      x$EMA <- as.character(x$EMA)
      x$FDA <- as.character(x$FDA)
      
      #if(nrow(x)>0)
      #{
      x$Reference <- paste0(x$Reference, "a")
      x$Reference <- paste0('<a href="Javascript:;" onClick="linktoref(); return false;" data-id="#ref-', x$Reference, '">', x$Reference, '</a>')
      
      ui <- x
      ui$Evidence_statement <- NULL
      ui$Reference <- NULL
      ui$year <- NULL
      ui <- aggregate(Score ~ ., data = ui, FUN = mean)
      x$Score <- NULL
      x <- merge(x, ui)
      
      
      x <- x[, c("Disease", "Gene", "Variant", "Drug", "Evidence_type", "Clinical_significance", "Evidence_level",
                 "Evidence_statement", "Type", "Reference", "Score", "AIFA", "EMA", "FDA", "year")]
      
      x$Evidence_level <- factor(x$Evidence_level, levels = c("Validated association", "FDA guidelines", "NCCN guidelines",
                                                              "Clinical evidence", "Late trials", "Early trials", "Case study",
                                                              "Case report", "Preclinical evidence", "Pre-clinical", "Inferential association"))
      x <- x[order(x$Gene, x$Evidence_level, x$Evidence_type, x$Variant, x$Drug,
                   x$Clinical_significance, x$Reference),]
      
      tmp <- group_by(x, Disease, Evidence_level, Evidence_type, Gene, Variant, Drug, Clinical_significance, Type, Score, AIFA, EMA, FDA, year)
      tmp2 <- summarise(tmp, Evidence_statement = paste(Evidence_statement, collapse = " "), Reference = paste(Reference, collapse = ", "),
                        year = paste(sort(year), collapse = ", "))
      tmp2 <- summarise(tmp2, Evidence_statement = paste(Evidence_statement, collapse = " "), Reference = paste(Reference, collapse = ", "),
                        year = paste(sort(year), collapse = ", "))
      ya <- tmp2[, c("Disease", "Gene", "Variant", "Drug", "Evidence_type", "Clinical_significance", "Evidence_level", "Type",
                     "Reference", "Score", "AIFA", "EMA", "FDA", "year"), drop = F]
      yb <- tmp2[, c("Evidence_statement", "Reference"), drop = F]
      tmp <- unname(unlist(lapply(split(ya, ya$Disease), nrow)))
      ya$Evidence <- unlist(sapply(tmp, seq, from = 1))
      dis.without.spaces <- gsub(" ", "", ya$Disease)
      ya$Details <- paste0('[<a href="Javascript:;" class="my_ref_link" data-id="#det-', dis.without.spaces, '-', ya$Evidence, 'a">+</a>]')
      ya$Details[!complete.cases(yb) |
                   yb$Evidence_statement == " " |
                   yb$Evidence_statement == ""] <- ""
      ya$Evidence <- paste0('<a id="evi-', dis.without.spaces, '-', ya$Evidence, 'a" name="evi-', dis.without.spaces, '-', ya$Evidence, 'a"></a>', ya$Evidence)
      list.trials <- paste0("https://clinicaltrials.gov/ct2/results?cond=", ya$Variant, "&term=",
                            ya$Drug, "&cntry=&state=&city=&dist=")
      ya$Trials <- paste0("[", "<a href=\"", list.trials, "\">+</a>", "]")
      ya$Trials[!list.trials %in% list.all.trials] <- ""
      ya$Drug <- gsub(",", ", ", ya$Drug, fixed = T)
      ya <- ya[, c("Evidence", "Disease", "Gene", "Variant", "Drug", "Evidence_type", "Clinical_significance", "Evidence_level", "Type", "Details",
                   "Trials", "Reference", "Score", "AIFA", "EMA", "FDA", "year")]
      names(ya) <- c("#", "Disease", "Gene", "Variant", "Drug", "Evidence Type", "Clinical Significance",
                     "Evidence Level", "Type", "Details", "Trials", "References", "Confidence Score", "AIFA", "EMA", "FDA", "year")
      
      if (tumor_type == "tumnorm")
        ya <- ya[, -which(names(ya) == "Type")]
      df_total <- ya[, -which(names(ya) == "Disease")]
      if (nrow(df_total) > 0)
      {
        
        colfunc <- colorRampPalette(c("red", "yellow"))
        ya$`Confidence Score` <- as.numeric(ya$`Confidence Score`)
        ya$`Confidence Score` <- round(ya$`Confidence Score`, digits = 2)
        cr <- ya$`Confidence Score`
        cr_or <- cr[order(-cr)]
        cr1 <- unique(cr_or)
        counts <- table(-cr)
        veccr <- colfunc(length(cr1))
        veccr <- rep(veccr, counts)
        vec_df <- data.frame(score = cr_or, col = veccr)
        vec_df <- vec_df[match(cr, vec_df$score),]
        veccr <- as.vector(vec_df$col)
        
        t <- kable(df_total, "html", escape = F) %>%
          kable_styling(bootstrap_options = c("striped", "hover", "responsive")) %>%
          column_spec(11, bold = T, color = "black", background = veccr)
        ya$Disease <- as.factor(ya$Disease)
        lvl <- levels(ya$Disease)
        for (l in lvl)
        {
          a <- which(ya$Disease == l)
          # if (length(a)!=0)
          t <- t %>% pack_rows(l, min(a), max(a), indent = FALSE)
        }
        array_table <- c(array_table, t)
        print(t)
      } else
      {
        array_table <- paste('<div id="no-data-available." class="section level5">
                        <h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
        cat("  \n##### No data available.  \n")
      }
    }
  } else
  {
    array_table <- paste('<div id="no-data-available." class="section level5">
                        <h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
    cat("  \n##### No data available.  \n")
  }
}, silent = FALSE)
xml_table_evidence <- kable_as_xml(paste(array_table, collapse = " "))
node_to_be_replaced <- children_offlabel_vm
xml_replace(node_to_be_replaced, xml_table_evidence)
write_html(offlabel, paste0(path_project, "/", pt_fastq, "/offlabel.html"))


### Evidence Detail
cat("OFFLABEL - Evidence details\n")
children_offlabel_ed <- xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(offlabel, 2), 1), 2), 4), 2), 1)
array_table <- c()
##Mutations information
options(knitr.table.format = "html")
#cargs=commandArgs(trailingOnly = TRUE)
try({
  x_url <- read.csv(paste0(path_project, "/txt/reference/", pt_fastq, "_off.txt"), sep = "\t")
  x_url <- x_url[!duplicated(x_url[, c("PMID")]),]
  x_url <- x_url[, c("PMID", "Reference")]
  x_url$PMID <- as.character(x_url$PMID)
  
  x <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_definitive.txt"), sep = "\t", colClasses = c("character"))
  dis <- read.csv(paste0(path_db, "/Disease.txt"), sep = "\t")
  colnames(dis)[1] <- "Disease"
  x <- merge(dis, x, by = "Disease")
  x$Disease <- NULL
  x$Category <- NULL
  colnames(x)[1] <- "Disease"
  x[is.na(x)] <- " "
  x <- separate_rows(x, DOID, sep = ",")
  x <- x[x$Evidence_direction == "Supports" & x$DOID != pt_tumor, , drop = F]
  x$DOID <- NULL
  sub <- x[x$Drug_interaction_type == "Substitutes",]
  x <- x[x$Drug_interaction_type != "Substitutes",]
  sub <- sub %>%
    mutate(Drug = strsplit(as.character(Drug), ",")) %>%
    unnest(Drug)
  x <- rbind(x, sub)
  x$Drug <- as.character(x$Drug, levels = (x$Drug))
  x$Evidence_type <- factor(x$Evidence_type, levels = c("Diagnostic", "Prognostic", "Predisposing", "Predictive", "Functional"))
  x$Evidence_level <- factor(x$Evidence_level, levels = c("Validated association", "FDA guidelines", "NCCN guidelines", "Clinical evidence", "Late trials", "Early trials", "Case study", "Case report", "Preclinical evidence", "Pre-clinical", "Inferential association"))
  x$Disease <- as.character(x$Disease, levels = (x$Disease))
  x <- inner_join(x, x_url)
  x$Database <- NULL
  x <- unique(x)
  x$Variant_summary[x$Variant_summary == "" | x$Variant_summary == " "] <- NA
  x <- x %>%
    group_by(Disease, Gene, Variant, Drug, Evidence_type, Evidence_direction, Clinical_significance, Variant_summary, PMID,
             Chromosome, Start, Stop, Ref_base, Var_base, Type, Approved, Score, Reference) %>%
    summarize(Evidence_level = str_c(Evidence_level, collapse = ", "), Evidence_statement = str_c(Evidence_statement, collapse = ", "),
              Citation = str_c(Citation, collapse = ", "))
  x$Evidence_level <- gsub("(.*),.*", "\\1", x$Evidence_level)
  x$Evidence_statement <- gsub(".,", ".", x$Evidence_statement)
  x <- x[, c("Disease", "Gene", "Variant", "Drug", "Evidence_type", "Evidence_level", "Evidence_direction", "Clinical_significance",
             "Evidence_statement", "Variant_summary", "PMID", "Citation", "Chromosome", "Start", "Stop", "Ref_base", "Var_base",
             "Type", "Approved", "Score", "Reference")]
  x$Variant_summary[is.na(x$Variant_summary)] <- ""
  x <- x[order(x$Disease, x$Evidence_level, x$Evidence_type, x$Gene, x$Variant, x$Drug,
               x$Clinical_significance, x$Reference),]
  
  if (nrow(x) > 0)
  {
    x$Reference <- paste0(x$Reference, "a")
    x$Reference <- paste0('<a href="reference.html#off-label-drug" class="my_ref_link" data-id="#ref-', x$Reference, '">', x$Reference, '</a>')
    x2 <- x[, c("Disease", "Gene", "Variant", "Drug", "Evidence_type", "Clinical_significance", "Evidence_level", "Evidence_statement", "Reference")]
    tmp <- group_by(x2, Disease, Evidence_level, Evidence_type, Gene, Variant, Drug, Clinical_significance)
    tmp2 <- summarise(tmp, Evidence_statement = paste(Evidence_statement, collapse = " "),
                      Reference = paste(sort(Reference), collapse = ", "))
    yb <- tmp2[, c("Disease", "Evidence_statement", "Reference"), drop = F]
    tmp <- unname(unlist(lapply(split(yb, yb$Disease), nrow)))
    yb$Evidence <- unlist(sapply(tmp, seq, from = 1))
    dis.without.spaces <- gsub(" ", "", yb$Disease)
    yb$Less <- paste0('[<a href="Javascript:;" class="my_ref_link" data-id="#evi-', dis.without.spaces, '-', yb$Evidence, 'a">-</a>]')
    yb$Evidence <- paste0('<a id="det-', dis.without.spaces, '-', yb$Evidence, 'a" name="det-', dis.without.spaces, '-', yb$Evidence, 'a"></a>', yb$Evidence)
    yb <- yb[complete.cases(yb) &
               yb$Evidence_statement != " " &
               yb$Evidence_statement != "", , drop = F]
    yb <- yb %>%
      group_by(Evidence_statement, Reference, Disease) %>%
      summarize(Evidence = str_c(Evidence, collapse = ", "), Less = str_c(Less, collapse = ", "))
    yb <- yb[order(yb$Evidence),]
    
    if (nrow(yb) > 0)
    {
      yb2 <- yb[, c("Evidence", "Evidence_statement", "Reference", "Less"), drop = F]
      names(yb2) <- c("#", "Evidence Statement", "References", "")
      t <- kable(yb2, "html", escape = FALSE) %>%
        kable_styling(bootstrap_options = c("striped", "hover", "responsive", align = "justify"))
      yb$Disease <- as.factor(yb$Disease)
      lvl <- levels(yb$Disease)
      for (l in lvl)
      {
        a <- which(yb$Disease == l)
        t <- t %>% pack_rows(l, min(a), max(a), indent = FALSE)
      }
      array_table <- c(array_table, t)
      print(t)
    } else
    {
      array_table <- paste('<div id="no-data-available." class="section level5">
                        <h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
      cat("  \n##### No data available.  \n")
    }
  } else
  {
    array_table <- paste('<div id="no-data-available." class="section level5">
                        <h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
    cat("  \n##### No data available.  \n")
  }
}, silent = TRUE)
xml_table_evidence <- kable_as_xml(paste(array_table, collapse = " "))
node_to_be_replaced <- children_offlabel_ed
xml_replace(node_to_be_replaced, xml_table_evidence)
write_html(offlabel, paste0(path_project, "/", pt_fastq, "/offlabel.html"))


cat("OFFLABEL - Variants details\n")
### Variant Details
children_offlabel_vd <- xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(offlabel, 2), 1), 2), 4), 3), 1)
array_table <- c()
##Mutations information
options(knitr.table.format = "html")
#cargs=commandArgs(trailingOnly = TRUE)
try({
  x <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_definitive.txt"), sep = "\t", colClasses = c("character"))
  dis <- read.csv(paste0(path_db, "/Disease.txt"), sep = "\t")
  colnames(dis)[1] <- "Disease"
  x <- merge(dis, x, by = "Disease")
  x$Disease <- NULL
  x$Category <- NULL
  colnames(x)[1] <- "Disease"
  x[is.na(x)] <- " "
  cat("OFFLABEL-VD-1\n")
  x <- separate_rows(x, DOID, sep = ",")
  x <- x[x$Evidence_direction == "Supports" & x$DOID != pt_tumor, , drop = F]
  x$DOID <- NULL
  x$Var_base <- as.character(x$Var_base)
  x$Ref_base <- as.character(x$Ref_base)
  if (nrow(x) > 0)
  {
    cat("funziona\n")
    x[is.na(x$Var_base), "Var_base"] <- "T"
    cat("non funziona\n")
    x[is.na(x$Ref_base), "Ref_base"] <- "T"
    x <- x[order(x$Gene, x$Variant),]
    #if(nrow(x)>0)
    #{
    ya <- x[, c("Gene", "Variant", "Chromosome", "Ref_base", "Var_base", "Start", "Stop")]
    ya <- unique(ya)
    row.names(ya) <- NULL
    print(kable(ya) %>%
            kable_styling(bootstrap_options = c("striped", "hover", "responsive")))
    
    yc <- x[, c("Gene", "Variant", "Variant_summary"), drop = F]
    yc <- yc[complete.cases(yc),]
    yc <- unique(yc)
    yc <- yc[!(yc$Variant_summary == " "),]
    yc <- yc[!(yc$Variant_summary == ""),]
    if (nrow(yc) > 0)
    {
      tmp <- group_by(yc, Gene, Variant)
      tmp2 <- summarise(tmp, Variant_summary = paste(Variant_summary, collapse = " "))
      array_table <- rbind(array_table, tmp2)
    }
    cat("if ->")
  } else
  {
    cat("else prima ->", array_table)
    array_table <- paste('<div id="no-data-available." class="section level5"><h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
    cat("else dopo ->", array_table)
    cat("  \n##### No data available.  \n")
    
  }
})
array_table <- kable(array_table) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "responsive"))
#cat("OFFLABEL-VD-2\n")
#cat(pt_fastq,"\n")
xml_table_evidence <- kable_as_xml(paste(array_table, collapse = " "))
#cat("OFFLABEL-VD-2.1\n")
node_to_be_replaced <- children_offlabel_vd
xml_replace(node_to_be_replaced, xml_table_evidence)
#cat("OFFLABEL-VD-3\n")
write_html(offlabel, paste0(path_project, "/", pt_fastq, "/offlabel.html"))
#cat("OFFLABEL-VD-4\n")



##
##
##
## Reference {.tabset}
##
##
##
cat("REFERENCE - Mutations\n")
reference <- (read_html(paste0(path_html_source, "/reference.html")))
children_reference_mut <- xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(reference, 2), 1), 2), 4), 1), 1)
array_table <- c()
an <- xml_child(xml_child(xml_child(xml_child(xml_child(reference, 2), 1), 1), 2), 2)
xml_replace(an, an_xml)
### Mutation

options(knitr.table.format = "html")
#cargs=commandArgs(trailingOnly = TRUE)
try({
  x_url <- read.csv(paste0(path_project, "/txt/reference/", pt_fastq, ".txt"), sep = "\t")
  link1 <- x_url[, c("Reference", "PMID", "Citation")]
  link1 <- link1[!duplicated(x_url[, c("PMID")]),]
  if (nrow(link1) > 0)
  {
    link1$Reference <- as.character(link1$Reference)
    link1$Reference <- paste0('<a id="ref-', link1$Reference, '" name="ref-', link1$Reference, '"></a>', link1$Reference)
    link1$PMID <- paste0('<a href=\"https://www.ncbi.nlm.nih.gov/pubmed/', link1$PMID, '\" style=\"     \" >', link1$PMID, '</a>')
    
    t <- link1 %>%
      #mutate(PMID = cell_spec(link1$PMID, "html", link = x_url$URL)) %>%
      kable("html", escape = FALSE) %>%
      kable_styling(bootstrap_options = c("hover", "condensed"))
    x_url$Gene <- as.factor(x_url$Gene)
    lvl <- levels(x_url$Gene)
    for (l in lvl)
    {
      a <- which(x_url$Gene == l)
      if (length(a) != 0)
        t <- t %>% pack_rows(l, min(a), max(a), indent = FALSE)
    }
    array_table <- (t)
  } else {
    array_table <- paste('<div id="no-data-available." class="section level5">
                        <h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
    cat("  \n##### No data available.  \n")
    
  }
  
}, silent = TRUE)
xml_table_evidence <- kable_as_xml(paste(array_table, collapse = " "))
node_to_be_replaced <- children_reference_mut
xml_replace(node_to_be_replaced, xml_table_evidence)
write_html(reference, paste0(path_project, "/", pt_fastq, "/reference.html"))


### Pharm
cat("REFERENCE - Pharm\n")
children_reference_pharm <- xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(reference, 2), 1), 2), 4), 2), 1)
array_table <- c()

options(knitr.table.format = "html")
#cargs=commandArgs(trailingOnly = TRUE)
#pharm
try({
  x_url_p <- read.csv(paste0(path_project, "/txt/reference/", pt_fastq, "_pharm.txt"), sep = "\t")
  link1 <- x_url_p[, c("Reference", "PMID")]
  if (nrow(link1) > 0)
  {
    link1$Reference <- paste0(link1$Reference, "p")
    link1$Reference <- paste0('<a id="ref-', link1$Reference, '" name="ref-', link1$Reference, '"></a>', link1$Reference)
    link1$PMID <- paste0('<a href=\"https://www.ncbi.nlm.nih.gov/pubmed/', link1$PMID, '\" style=\"     \" >', link1$PMID, '</a>')
    t <- link1 %>%
      #mutate(PMID = cell_spec(PMID, "html", link = x_url_p$URL)) %>%
      kable("html", escape = FALSE) %>%
      kable_styling(bootstrap_options = c("hover", "condensed"))
    x_url_p$Gene <- as.factor(x_url_p$Gene)
    lvl <- levels(x_url_p$Gene)
    for (l in lvl)
    {
      a <- which(x_url_p$Gene == l)
      if (length(a) != 0)
        t <- t %>% pack_rows(l, min(a), max(a), indent = FALSE)
    }
    array_table <- (t)
  } else
  {
    array_table <- paste('<div id="no-data-available." class="section level5">
                        <h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
    cat("  \n##### No data available.  \n")
    
  }
  
}, silent = TRUE)
xml_table_evidence <- kable_as_xml(paste(array_table, collapse = " "))
node_to_be_replaced <- children_reference_pharm
xml_replace(node_to_be_replaced, xml_table_evidence)
write_html(reference, paste0(path_project, "/", pt_fastq, "/reference.html"))


### Off label Drug
cat("REFERENCE - Offlabel\n")
children_reference_drug <- xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(reference, 2), 1), 2), 4), 3), 1)
array_table <- c()
options(knitr.table.format = "html")
#cargs=commandArgs(trailingOnly = TRUE)
#Off label
try({
  x_url <- read.csv(paste0(path_project, "/txt/reference/", pt_fastq, "_off.txt"), sep = "\t")
  dis <- read.csv(paste0(path_db, "/Disease.txt"), sep = "\t")
  colnames(dis)[1] <- "Disease"
  x_url <- merge(dis, x_url, by = "Disease")
  x$Category <- NULL
  x$DOID <- NULL
  x_url$Disease <- NULL
  colnames(x_url)[1] <- "Disease"
  x_url <- x_url[!duplicated(x_url[, c("PMID")]),]
  link1 <- x_url[, c("Reference", "PMID", "Citation")]
  if (nrow(link1) > 0)
  {
    link1$Reference <- paste0(link1$Reference, "a")
    link1$Reference <- paste0('<a id="ref-', link1$Reference, '" name="ref-', link1$Reference, '"></a>', link1$Reference)
    link1$PMID <- paste0('<a href=\"https://www.ncbi.nlm.nih.gov/pubmed/', link1$PMID, '\" style=\"     \" >', link1$PMID, '</a>')
    
    t <- link1 %>%
      #mutate(PMID = cell_spec(PMID, "html", link = x_url$URL)) %>%
      kable("html", escape = FALSE) %>%
      kable_styling(bootstrap_options = c("hover", "condensed"))
    x_url$Disease <- as.factor(x_url$Disease)
    lvl <- levels(x_url$Disease)
    for (l in lvl)
    {
      a <- which(x_url$Disease == l)
      if (length(a) != 0)
        t <- t %>% pack_rows(l, min(a), max(a), indent = FALSE)
    }
    array_table <- (t)
  } else
  {
    array_table <- paste('<div id="no-data-available." class="section level5">
                        <h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
    cat("  \n##### No data available.  \n")
    
  }
  
}, silent = TRUE)
xml_table_evidence <- kable_as_xml(paste(array_table, collapse = " "))
node_to_be_replaced <- children_reference_drug
xml_replace(node_to_be_replaced, xml_table_evidence)
write_html(reference, paste0(path_project, "/", pt_fastq, "/reference.html"))


### Cosmic
cat("REFERENCE - Cosmic\n")
children_reference_cosmic <- xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(reference, 2), 1), 2), 4), 4), 1)
array_table <- c()
options(knitr.table.format = "html")
#cargs=commandArgs(trailingOnly = TRUE)
#Cosmic
try({
  cosm <- read.csv(paste0(path_project, "/txt/reference/", pt_fastq, "_cosmic.txt"), sep = "\t")
  link1 <- cosm[, c("Reference", "PMID")]
  if (nrow(link1) > 0)
  {
    link1$Reference <- paste0(link1$Reference, "c")
    link1$Reference <- paste0('<a id="ref-', link1$Reference, '" name="ref-', link1$Reference, '"></a>', link1$Reference)
    link1$PMID <- paste0('<a href=\"https://www.ncbi.nlm.nih.gov/pubmed/', link1$PMID, '\" style=\"     \" >', link1$PMID, '</a>')
    
    t <- link1 %>%
      #mutate(PMID = cell_spec(PMID, "html", link = cosm$URL)) %>%
      kable("html", escape = FALSE) %>%
      kable_styling(bootstrap_options = c("hover", "condensed"))
    cosm$Gene <- as.factor(cosm$Gene)
    lvl <- levels(cosm$Gene)
    for (l in lvl)
    {
      a <- which(cosm$Gene == l)
      if (length(a) != 0)
        t <- t %>% pack_rows(l, min(a), max(a), indent = FALSE)
    }
    array_table <- (t)
  } else {
    array_table <- paste('<div id="no-data-available." class="section level5">
                        <h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
    cat("  \n##### No data available.  \n")
    
  }
  
}, silent = TRUE)
xml_table_evidence <- kable_as_xml(paste(array_table, collapse = " "))
node_to_be_replaced <- children_reference_cosmic
xml_replace(node_to_be_replaced, xml_table_evidence)
write_html(reference, paste0(path_project, "/", pt_fastq, "/reference.html"))

cat("Copying assets\n")
file.copy(file.path(path_html_source, "assets"), file.path(path_project, pt_fastq), recursive = TRUE)
cat("OK!\n")
