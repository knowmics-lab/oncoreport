suppressPackageStartupMessages({
  library(xml2)
  library(dplyr)
  library(knitr)
  library(tidyr)
  library(kableExtra)
  library(stringr)
  library(brew)
})

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
source(file.path(dirname(thisFile()), "imports.R"), local = knitr::knit_global())
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



diseases_db              <- read.csv(paste0(path_db, "/Disease.txt"), sep = "\t", stringsAsFactors = FALSE)
colnames(diseases_db)[1] <- "Disease"
diseases_db_simple       <- unique(diseases_db[,c("Disease", "DOID")])
pt_disease_details       <- diseases_db[diseases_db$DOID == pt_tumor,,drop = FALSE]
pt_disease_name          <- unique(pt_disease_details$DO_name)[1]


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

cat("THERAPEUTIC - Mutation Information\n")

therapeutic.references <- read.csv(paste0(path_project, "/txt/reference/", pt_fastq, ".txt"), sep = "\t", stringsAsFactors = FALSE)
therapeutic.references <- therapeutic.references[, c("PMID", "Reference")]
therapeutic.references <- therapeutic.references[!duplicated(therapeutic.references$PMID),]

therapeutic.trials <- read.csv(paste0(path_project, "/txt/trial/", pt_fastq, ".txt"), sep = "\t", stringsAsFactors = FALSE)
list.all.trials    <- unique(therapeutic.trials$Clinical_trial)

all.annotations <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_definitive.txt"), sep = "\t", colClasses = c("character"), stringsAsFactors = FALSE)
all.annotations <- diseases_db_simple %>% inner_join(all.annotations, by = "Disease")
all.annotations[is.na(all.annotations)] <- " "
all.annotations$id <- 1:nrow(all.annotations)


primary.annotations <- all.annotations[all.annotations$Evidence_direction == "Supports" & all.annotations$DOID == pt_tumor, , drop = F]
primary.annotations$DOID <- NULL





print(head(primary.annotations))
stop()



brew(
  file = paste0(path_html_source, "/therapeutic.html"),
  output = paste0(report_output_dir, "therapeutic.html"),
  envir = template.env
)


cat("Copying assets\n")
file.copy(file.path(path_html_source, "assets"), report_output_dir, recursive = TRUE)
cat("OK!\n")
stop()


therapeutic <- (read_html(paste0(path_html_source, "/therapeutic.html")))
drugdrug <- as_list(read_html(paste0(path_html_source, "/drugdrug.html")))
esmoguide <- as_list(read_html(paste0(path_html_source, "/esmoguide.html")))
children_highlight <- xml_children(xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(therapeutic, 2), 1), 2), 4), 1), 1), 1), 2), 1), 1))
children_hidden <- xml_children(xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(therapeutic, 2), 1), 2), 4), 1), 2), 2), 1), 1))
list_therapeutic_indication <- list(children_highlight, children_hidden)


cat("Args:", cargs, "\n")
an_pat <- paste0('<div class="card-body">
           <div class="span4">Surname: ', pt_surname, '<br>
                                        Name: ', pt_name, '<br>
                                        Sex: ', pt_sex, '</div>
           <div class="span4">Age: ', pt_age, '<br>
                                        City: ', pt_city, '<br>
                                        Phone: ', pt_phone, '</div>
           <div class="span3">Sample Name: ', pt_sample_name, '<br>
                                        Cancer Site: ', pt_tumor_site, '<br>
                                        Stage: ', pt_tumor_stage, '</div>
         </div>')
an <- xml_child(xml_child(xml_child(xml_child(xml_child(therapeutic, 2), 1), 1), 2), 2)
an_html <- read_html(an_pat)
an_xml <- (xml_child(xml_child(an_html, 1), 1))
xml_replace(an, an_xml)


#cat(cargs)
dir.create(paste0(path_project, "/", pt_fastq), showWarnings = FALSE)
source(file.path(dirname(thisFile()), "imports.R"), local = knitr::knit_global())
options(knitr.table.format = "html")
#cargs=commandArgs(trailingOnly = TRUE)
if (tumor_type == "tumnorm")
{
  sample.type <- "Tumor and Blood Biopsy"
} else {
  sample.type <- "Liquid Biopsy"
}
pat <- data.frame(Name = pt_name, Surname = pt_surname, ID = pt_sample_name, Gender = pt_sex, Age = pt_age,
                  Sample = sample.type, Tumor = pt_tumor)
patient_info <- kable(pat) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "responsive"))
xml_patient_info <- kable_as_xml(patient_info)


#
###Mutations information
#

cat("THERAPEUTIC - Mutation Information\n")
#```{r Variant_Mutation, echo=FALSE, message=FALSE, warning=FALSE, results='asis'}
options(knitr.table.format = "html")
#cargs=commandArgs(trailingOnly = TRUE)

order_id <- c()
order_evidence <- c()
try({
  x_url <- read.csv(paste0(path_project, "/txt/reference/", pt_fastq, ".txt"), sep = "\t")
  x_url <- x_url[, c("PMID", "Reference")]
  x_url <- x_url[!duplicated(x_url[, c("PMID")]),]
  x_url$PMID <- as.character(x_url$PMID)

  x_trial <- read.csv(paste0(path_project, "/txt/trial/", pt_fastq, ".txt"), sep = "\t")
  list.all.trials <- unique(x_trial$Clinical_trial)

  x <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_definitive.txt"), sep = "\t", colClasses = c("character"))
  dis <- read.csv(paste0(path_db, "/Disease.txt"), sep = "\t")
  colnames(dis)[1] <- "Disease"
  x <- merge(dis, x, by = "Disease")
  x$Disease <- NULL
  x$Category <- NULL
  colnames(x)[1] <- "Disease"
  x[is.na(x)] <- " "
  x$id <- 1:nrow(x)
  x <- separate_rows(x, DOID, sep = ",")
  x <- x[x$Evidence_direction == "Supports" & x$DOID == pt_tumor, , drop = F]
  x$DOID <- NULL

  empty <- T
  if (nrow(x) != 0)
  {
    sub <- x[x$Drug_interaction_type == "Substitutes",]
    x <- x[x$Drug_interaction_type != "Substitutes",]
    #NEW
    sub <- sub %>%
      mutate(Drug = strsplit(as.character(Drug), ","), Approved = strsplit(as.character(Approved), ",")) %>%
      unnest(c(Drug, Approved))
    #
    x <- rbind(x, sub)
    x$Drug <- as.character(x$Drug, levels = (x$Drug))
    x$Drug <- gsub(", ", ",", x$Drug, fixed = T)
    x$Drug_interaction_type <- NULL
    x$Evidence_type <- factor(x$Evidence_type, levels = c("Diagnostic", "Prognostic", "Predisposing", "Predictive", "Functional"))
    x$Evidence_level <- factor(x$Evidence_level, levels = c("Validated association", "FDA guidelines", "NCCN guidelines", "Clinical evidence",
                                                            "Late trials", "Early trials", "Case study", "Case report",
                                                            "Preclinical evidence", "Pre-clinical", "Inferential association"))


    evidence_list <- c("Validated association", "FDA guidelines", "NCCN guidelines", "Clinical evidence", "Late trials", "Early trials", "Case study", "Case report", "Preclinical evidence", "Pre-clinical", "Inferential association")


    x <- inner_join(x, x_url)
    x <- x[order(x$Gene, x$Evidence_level, x$Evidence_type, x$Variant, x$Drug,
                 x$Clinical_significance, x$Reference),]
    x <- x %>%
      group_by(Disease, Database, Gene, Variant, Drug, Evidence_type, Evidence_direction, Clinical_significance, Variant_summary, PMID,
               Citation, Chromosome, Start, Stop, Ref_base, Var_base, Type, Approved, Score, Reference, id) %>%
      summarize(Evidence_level = str_c(Evidence_level, collapse = ", "), Evidence_statement = str_c(Evidence_statement, collapse = ", "),
                Citation = str_c(Citation, collapse = ", "), id = str_c(id, collapse = ", "))
    x$Evidence_level <- gsub("(.*),.*", "\\1", x$Evidence_level)
    x$Evidence_statement <- gsub(".,", ".", x$Evidence_statement)
    x <- x[, c("Disease", "Database", "Gene", "Variant", "Drug", "Evidence_type", "Evidence_level", "Evidence_direction", "Clinical_significance",
               "Evidence_statement", "Variant_summary", "PMID", "Citation", "Chromosome", "Start", "Stop", "Ref_base", "Var_base",
               "Type", "Approved", "Score", "Reference", "id")]
    x$Evidence_level <- ordered(x$Evidence_level, levels = c("Validated association", "FDA guidelines", "NCCN guidelines", "Clinical evidence", "Late trials", "Early trials", "Case study", "Case report", "Preclinical evidence", "Pre-clinical", "Inferential association"))
    x <- x[order(x$Evidence_level),]
    #x$Order<- 1:nrow(x)
    pr <- str_count(x$Drug, ',')

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
          } else if (all(grepl("EMA", sb))) { x_url <- x_url[!duplicated(x_url[, c("PMID")]),]
            x$Approved[i] <- "EMA"
          } else {
            x$Approved[i] <- "Not approved"
          }
        }
      }
    }


    #########################################################################################################################
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

    if (nrow(x) > 0)
      x$Reference <- paste0('<a href="Javascript:;" onClick="myFunction1(); return false;" data-id="#ref-', x$Reference, '">', x$Reference, '</a>')
    #
    x$Approved <- NULL
    x$AIFA <- as.character(x$AIFA)
    x$EMA <- as.character(x$EMA)
    x$FDA <- as.character(x$FDA)

    x$Evidence_level <- factor(x$Evidence_level, levels = c("Validated association", "FDA guidelines", "NCCN guidelines", "Clinical evidence",
                                                            "Late trials", "Early trials", "Case study", "Case report",
                                                            "Preclinical evidence", "Pre-clinical", "Inferential association"))


    x <- x[order(x$Gene, x$Evidence_level, x$Evidence_type, x$Variant, x$Drug,
                 x$Clinical_significance, x$Reference),]


    list_evidence <- list(evidence_list[1:4], evidence_list[5:11])
    x_backup <- x
    id_evidence <- 0
    for (q in 1:2)
    {
      x <- x_backup

      if (sum(list_evidence[[q]] %in% x$Evidence_level) >= 1)
      {
        x <- x[which(x$Evidence_level %in% list_evidence[[q]]),]
        hgx <- split(x, x$Gene)
        empty <- T
        for (n in hgx)
        {

          if (nrow(n) > 0)
          {
            gene <- as.character(n$Gene)[1]
            cat("  \n#### Gene", gene, " \n")
            n <- n[, c("Gene", "Variant", "Drug", "Evidence_type", "Clinical_significance", "Evidence_level", "Evidence_statement", "Type",
                       "Reference", "Score", "AIFA", "EMA", "FDA", "year", "id")]
            ui <- n
            ui$Evidence_statement <- NULL
            ui$Reference <- NULL
            ui$year <- NULL
            ui$id <- NULL
            #ui$Order<-NULL
            ui <- aggregate(Score ~ ., data = ui, FUN = mean)
            n$Score <- NULL
            #n$id <- NULL
            n <- merge(n, ui)

            tmp <- group_by(n, Gene, Evidence_level, Evidence_type, Variant, Drug, Clinical_significance, Type, Score, AIFA, EMA, FDA, .add = FALSE)
            tmp2 <- summarise(tmp, Evidence_statement = paste(Evidence_statement, collapse = " "), Reference = paste(sort(Reference), collapse = ", "), year = paste(sort(year), collapse = ", "), id = paste(sort(id), collapse = "-"))
            #Lo ripeto 2 volte perché al primo non lo fa
            #tmp2 <- summarise(tmp2,Evidence_statement=paste(Evidence_statement,collapse=" "), Reference=paste(sort(Reference),collapse=", "), year=paste(sort(year),collapse=", "), id=paste(sort(id),collapse="-"))
            order_id <- c(order_id, tmp2$id)
            ya <- tmp2[, c("Gene", "Variant", "Drug", "Evidence_type", "Clinical_significance", "Evidence_level", "Type", "Reference", "Score",
                           "AIFA", "EMA", "FDA", "year", "id"), drop = F]
            yb <- tmp2[, c("Evidence_statement", "Reference"), drop = F]
            ya$Evidence <- 1:nrow(ya)
            ya$Details <- paste0('[<a href="Javascript:;" class="my_ref_link" data-id="#det-', gene, '-', ya$Evidence, '">+</a>]')
            ya$Details[!complete.cases(yb) |
                         yb$Evidence_statement == " " |
                         yb$Evidence_statement == ""] <- ""
            ya$Evidence <- paste0('<a id="evi-', gene, '-', ya$Evidence, '" name="evi-', gene, '-', ya$Evidence, '"></a>', ya$Evidence + id_evidence)
            list.trials <- paste0("https://clinicaltrials.gov/ct2/results?cond=", ya$Variant, "&term=",
                                  ya$Drug, "&cntry=&state=&city=&dist=")
            ya$Trials <- paste0("[", "<a href=\"", list.trials, "\">+</a>", "]")
            ya$Trials[!list.trials %in% list.all.trials] <- ""
            ya$Drug <- gsub(",", ", ", ya$Drug, fixed = T)
            ya <- ya[, c("Evidence", "Gene", "Variant", "Drug", "Evidence_type", "Clinical_significance", "Evidence_level", "Type", "Details",
                         "Trials", "Reference", "Score", "AIFA", "EMA", "FDA", "year")]
            names(ya) <- c("#", "Gene", "Variant", "Drug", "Evidence Type", "Clinical Significance",
                           "Evidence Level", "Type", "Details", "Trials", "References", "Confidence Score", "AIFA", "EMA", "FDA", "Publication year")


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

            if (tumor_type == "tumnorm")
              ya <- ya[, -which(names(ya) == "Type")]
            order_evidence <- rbind(order_evidence, ya)
            table_therapeutic <-
              kable(ya, "html", escape = FALSE) %>%
                kable_styling(bootstrap_options = c("striped", "hover", "responsive")) %>%
                column_spec(11, bold = T, color = "black", background = veccr)
            empty <- F

            #table_therapeutic<- kable(ya, "html", escape = FALSE) %>%
            #        kable_styling(bootstrap_options = c("striped", "hover","responsive"))
            xml_table_therapeutic <- kable_as_xml(table_therapeutic)

            node_to_be_replaced <- list_therapeutic_indication[[q]]
            xml_replace(node_to_be_replaced, xml_table_therapeutic)

            empty <- F
          }
          id_evidence <- nrow(ya)
        }
      }
      if (empty) {
        table_therapeutic <- paste('<h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
        node_to_be_replaced <- list_therapeutic_indication[[q]]
        xml_replace(node_to_be_replaced, xml_table_therapeutic)
        cat("  \n##### No data available.  \n")
      }
    }

  }
}, silent = FALSE)

#xml_table_therapeutic<-kable_as_xml(table_therapeutic)
drug_recommended <- unlist(strsplit(x$Drug, ","))
write(drug_recommended, paste0(path_project, "/txt/", pt_fastq, "_drug.txt"))

write_html(therapeutic, paste0(path_project, "/", pt_fastq, "/therapeutic.html"))


#
#### Evidence Details
#
cat("THERAPEUTIC - Evidence Details\n")
children_evidence <- xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(therapeutic, 2), 1), 2), 4), 2), 1)
array_table <- c()
##Mutations information
options(knitr.table.format = "html")
#cargs=commandArgs(trailingOnly = TRUE)
try({
  x_url <- read.csv(paste0(path_project, "/txt/reference/", pt_fastq, ".txt"), sep = "\t")
  x_url <- x_url[, c("PMID", "Reference")]
  x_url <- x_url[!duplicated(x_url[, c("PMID")]),]
  x_url$PMID <- as.character(x_url$PMID)

  x <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_definitive.txt"), sep = "\t", colClasses = c("character"))
  x$Score <- NULL
  dis <- read.csv(paste0(path_db, "/Disease.txt"), sep = "\t")
  colnames(dis)[1] <- "Disease"
  x <- merge(dis, x, by = "Disease")
  x$Disease <- NULL
  x$Category <- NULL
  colnames(x)[1] <- "Disease"
  x[is.na(x)] <- " "
  x$id <- 1:nrow(x)
  x <- separate_rows(x, DOID, sep = ",")
  x <- x[x$Evidence_direction == "Supports" & x$DOID == pt_tumor, , drop = F]
  x$DOID <- NULL
  empty <- T
  if (nrow(x) != 0)
  {
    sub <- x[x$Drug_interaction_type == "Substitutes",]
    x <- x[x$Drug_interaction_type != "Substitutes",]
    sub <- sub %>%
      mutate(Drug = strsplit(as.character(Drug), ",")) %>%
      unnest(Drug)
    x <- rbind(x, sub)
    x$Drug <- as.character(x$Drug, levels = (x$Drug))
    x$Drug_interaction_type <- gsub(" ", "", x$Drug_interaction_type)
    x$Evidence_type <- factor(x$Evidence_type, levels = c("Diagnostic", "Prognostic", "Predisposing", "Predictive", "Functional"))
    x$Evidence_level <- factor(x$Evidence_level, levels = c("Validated association", "FDA guidelines", "NCCN guidelines", "Clinical evidence", "Late trials", "Early trials", "Case study", "Case report", "Preclinical evidence", "Pre-clinical", "Inferential association"))
    x <- inner_join(x, x_url)
    x <- x[order(x$Gene, x$Evidence_level, x$Evidence_type, x$Variant, x$Drug, x$Drug_interaction_type,
                 x$Clinical_significance, x$Reference),]
    x$Database <- NULL
    x <- x %>%
      group_by(Disease, Gene, Variant, Drug, Drug_interaction_type, Evidence_type, Evidence_direction, Clinical_significance, Variant_summary, PMID,
               Chromosome, Start, Stop, Ref_base, Var_base, Type, Approved, Reference, id) %>%
      summarize(Evidence_level = str_c(Evidence_level, collapse = ", "), Evidence_statement = str_c(Evidence_statement, collapse = ", "),
                Citation = str_c(Citation, collapse = ", "), id = str_c(id, collapse = ", "))
    x$Evidence_level <- gsub("(.*),.*", "\\1", x$Evidence_level)
    x$Evidence_statement <- gsub(".,", ".", x$Evidence_statement)
    x <- x[, c("Disease", "Gene", "Variant", "Drug", "Drug_interaction_type", "Evidence_type", "Evidence_level", "Evidence_direction", "Clinical_significance",
               "Evidence_statement", "Variant_summary", "PMID", "Citation", "Chromosome", "Start", "Stop", "Ref_base", "Var_base",
               "Type", "Approved", "Reference", "id")]

    #x <- x[order(x$Reference),]

    if (nrow(x) > 0)
      x$Reference <- paste0('<a href="Javascript:;" class="my_ref_link" data-id="#ref-', x$Reference, '">', x$Reference, '</a>')

    hgx <- split(x, x$Gene)
    empty <- T
    array_table <- c()
    for (n in hgx)
    {
      if (dim(n)[1] != 0)
      {
        gene <- as.character(n$Gene)[1]
        cat("  \n#### Gene", gene, " \n")
        n2 <- n[, c("Variant", "Drug", "Drug_interaction_type", "Evidence_type", "Clinical_significance", "Evidence_level", "Evidence_statement", "Reference", "id")]
        tmp <- group_by(n2, Evidence_level, Evidence_type, Variant, Drug, Clinical_significance)
        tmp2 <- summarise(tmp, Evidence_statement = paste("<li>", Evidence_statement, collapse = "<br>"),
                          Reference = paste(sort(Reference), collapse = ", "), id = paste(sort(id), collapse = "-"))

        #tmp2<-tmp2[order(tmp2$Reference),]
        yb <- tmp2[, c("Evidence_statement", "Reference"), drop = F]
        yb$id <- tmp2$id
        yb <- yb[order(match(yb$id, order_id)),]
        yb$Evidence <- 1:nrow(yb)
        yb$Less <- paste0('[<a href="Javascript:;" class="my_ref_link" data-id="#evi-', gene, '-', yb$Evidence, '">-</a>]')
        yb$Evidence <- paste0('<a id="det-', gene, '-', yb$Evidence, '" name="det-', gene, '-', yb$Evidence, '"></a>', yb$Evidence)
        yb <- yb[complete.cases(yb) &
                   yb$Evidence_statement != " " &
                   yb$Evidence_statement != "", , drop = F]
        yb <- yb %>%
          group_by(Evidence_statement, Reference, id) %>%
          summarize(Evidence = str_c(Evidence, collapse = ", "), Less = str_c(Less, collapse = ", "), id = str_c(id, collapse = "-"))
        yb <- yb[order(match(yb$id, order_id)),]
        #yb <- yb[order(yb$Evidence), ]
        if (nrow(yb) > 0)
        {
          yb <- yb[, c("Evidence", "Evidence_statement", "Reference", "Less"), drop = F]
          yb$Evidence_statement <- iconv(yb$Evidence_statement, to = "ASCII//TRANSLIT")
          names(yb) <- c("#", "Evidence Statement", "References", "")
          array_table <- c(array_table, (kable(yb, "html", escape = FALSE, caption = paste0("<h4><b> Gene - ", gene, "</b></h4>")) %>%
            kable_styling(bootstrap_options = c("striped", "hover", "responsive", align = "justify"))))
        }
        empty <- F
      }
    }
  }
  if (empty) {
    array_table <- paste('<h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
    cat("  \n##### No data available.  \n")
  }
}, silent = FALSE)
#cat("ANCORA ATTIVO\n")
#cat("1-project/report_html/",pt_fastq,"/therapeutic.html\n")
#xml_table_evidence<-kable_as_xml(kable(paste(array_table,collapse=" "), "html", escape = FALSE))
xml_table_evidence <- kable_as_xml(paste(array_table, collapse = " "))
#cat(xml_table_evidence)
node_to_be_replaced <- children_evidence
#cat("1-project/report_html/",pt_fastq,"/therapeutic.html\n")
xml_replace(node_to_be_replaced, xml_table_evidence)
#cat("2-project/report_html/",pt_fastq,"/therapeutic.html\n")
write_html(therapeutic, paste0(path_project, "/", pt_fastq, "/therapeutic.html"))

cat(cargs, "\n")
#
#### Variant Details
#
cat("THERAPEUTIC - Variant Details\n")
array_table <- c()
children_variantdetails <- xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(therapeutic, 2), 1), 2), 4), 3), 1)

##Mutations information
options(knitr.table.format = "html")
#cargs=commandArgs(trailingOnly = TRUE)
try({
  cat(paste0(path_project, "/txt/", pt_fastq, "_definitive.txt"), "\n")
  x <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_definitive.txt"), sep = "\t", colClasses = c("character"))
  cat(paste0(path_db, "/Disease.txt"), "\n")
  dis <- read.csv(paste0(path_db, "/Disease.txt"), sep = "\t")
  colnames(dis)[1] <- "Disease"
  x <- merge(dis, x, by = "Disease")
  x$Disease <- NULL
  x$Category <- NULL
  colnames(x)[1] <- "Disease"
  #cat("2\n")
  x[is.na(x)] <- " "
  x <- separate_rows(x, DOID, sep = ",")
  x <- x[x$Evidence_direction == "Supports" & x$DOID == pt_tumor, , drop = F]
  x$DOID <- NULL
  if (nrow(x) > 0) {
    x$Var_base <- as.character(x$Var_base)
    x$Ref_base <- as.character(x$Ref_base)
    #cat("3\n")
    cat(x$Var_base)
    x[is.na(x$Var_base), "Var_base"] <- "T"
    #cat(x$Ref_base)
    x[is.na(x$Ref_base), "Ref_base"] <- "T"
    #cat("4\n")
    x <- x[order(x$Gene, x$Variant),]

    hgx <- split(x, x$Gene)
    empty <- T
    for (n in hgx) {
      if (dim(n)[1] != 0) {
        gene <- as.character(n$Gene)[1]
        cat("  \n#### Gene", gene, " \n")
        ya <- n[, c("Variant", "Chromosome", "Ref_base", "Var_base", "Start", "Stop")]
        ya <- unique(ya)
        #ya$Variant <- paste0('<a id="var-',gene,'-',ya$Variant,'" name="var-',gene,'-',ya$Variant,'"></a>',ya$Variant)
        row.names(ya) <- NULL
        array_table <- c(array_table, (kable(ya, "html", escape = FALSE, caption = paste0("<h4><b> Gene - ", gene, "</b></h4>")) %>%
          kable_styling(bootstrap_options = c("striped", "hover", "responsive"))))
        yc <- n[, c("Variant", "Variant_summary"), drop = F]
        yc <- yc[complete.cases(yc),]
        yc <- unique(yc)
        yc <- yc[!(yc$Variant_summary == " "),]
        yc <- yc[!(yc$Variant_summary == ""),]
        if (nrow(yc) > 0) {
          tmp <- group_by(yc, Variant)
          tmp2 <- summarise(tmp, Variant_summary = paste(Variant_summary, collapse = " "))
          array_table <- c(array_table, kable(tmp2) %>%
            kable_styling(bootstrap_options = c("striped", "hover", "responsive")))
        }
        empty <- F
      }
    }
  }
  if (empty)
  {
    array_table <- paste('<h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
    cat("  \n##### No data available.  \n")
  }
}, silent = TRUE)


xml_table_evidence <- kable_as_xml(paste(array_table, collapse = " "))
node_to_be_replaced <- children_variantdetails
xml_replace(node_to_be_replaced, xml_table_evidence)
write_html(therapeutic, paste0(path_project, "/", pt_fastq, "/therapeutic.html"))


#
#DRUG INTERACTIONS TAB
#
if (!require("DT")) install.packages("DT")
cat("DRUG INTERACTIONS - ", cargs, "\n")
drugs <- read.csv(paste0(path_db, "/drug_drug_interactions_light.txt"), sep = "\t")
drug_ind <- drug_recommended
#Drug_com fa riferimento alle drug che il paziente assume per delle comorbidità. Le drug relative alle comorbidità inserite nell'interfaccia dovranno essere
#salvate in un file individuato nel path come commento seguente.
#drug_com<-tryCatch(read.table(paste0("project/txt/",pt_name,"_drug_com.txt"), sep = "\n"), error=function(e) NULL)
drug_com <- tryCatch(read.table(paste0(pt_path_file_comorbid), sep = "\n"), error = function(e) NULL)
drug_ind <- unique(drug_ind)
drug_com <- unique(drug_com)
drug_com <- unlist(drug_com)

unique_id_drugs <- unique(drugs[, 1:2])
drug_ind <- unique_id_drugs$Drug2_code[which(unique_id_drugs$Drug2_name %in% drug_ind)]
#drug_com<-unique_id_drugs$Drug2_code[which(unique_id_drugs$Drug2_name %in% drug_com)]
drugs_comorbidities <- drugs[which(drugs$Drug2_code %in% drug_com),]
drug_indications <- drugs[which(drugs$Drug2_code %in% drug_ind),]
interactions_comorbidities <- drugs_comorbidities[which(drugs_comorbidities$Drug1_code %in% drug_com),]
interactions_indications <- drug_indications[which(drug_indications$Drug1_code %in% drug_ind),]
all_interactions <- rbind(drugs_comorbidities, drug_indications)
exist_interactions <- all_interactions[which(all_interactions$Drug1_code %in% c(drug_com, drug_ind)),]


#Drug interactions
library(DT)
options(knitr.table.format = "html")
drug_drug_int <- (read_html(paste0(path_html_source, "/drugdrug.html")))
# an<-xml_child(xml_child(xml_child(xml_child(xml_child(drug_drug_int, 2), 1), 1), 2), 2)
# an_pat<- paste0('<div class="card-body">
#            <div class="span4">Surname: ',pt_sample_name,'<br>
#                                         Name: ',pt_surname,'<br>
#                                         Sex: ',pt_sex,'</div>
#            <div class="span4">Age: ',pt_age,'<br>
#                                         City: ',pt_fastq,'<br>
#                                         Phone: ',path_project,'</div>
#            <div class="span3">Sample Name: ',tumor_type,'<br>
#                                         Cancer Site: ',pt_tumor,'<br>
#                                         Stage: ',path_db,'</div>
#          </div>')

an <- xml_child(xml_child(xml_child(xml_child(xml_child(drug_drug_int, 2), 1), 1), 2), 2)
xml_replace(an, an_xml)


#substitute 1 div and 1 script to connect table existent drug interaction
children_drugdrug <- xml_child(xml_child(xml_child(drug_drug_int, 2), 1), 3)
b <- exist_interactions[, c(2, 4, 5)]
if (nrow(b) > 0)
{
  xml_remove(xml_child(xml_child(xml_child(xml_child(drug_drug_int, 2), 1), 2), 2))
  colnames(b)[1] <- "Drug"
  colnames(b)[2] <- "interact with drug"
  rownames(b) <- 1:nrow(b)
  html_drug <- datatable(b, width = "100%")
  htmlwidgets::saveWidget(html_drug, paste0(path_project, "/", pt_fastq, "/exs_drug.html"))
  drug_table <- (read_html(paste0(path_project, "/", pt_fastq, "/exs_drug.html")))
  xml_table_drugdrug <- xml_child(xml_child(drug_table, 2), 1)
  node_to_be_replaced <- children_drugdrug
  xml_replace(node_to_be_replaced, xml_table_drugdrug)
  children_drugdrug <- xml_child(xml_child(xml_child(drug_drug_int, 2), 1), 4)
  xml_table_drugdrug <- xml_child(xml_child(drug_table, 2), 2)
  node_to_be_replaced <- children_drugdrug
  xml_replace(node_to_be_replaced, xml_table_drugdrug)
}

children_drugdrug <- xml_child(xml_child(xml_child(drug_drug_int, 2), 1), 6)
b <- all_interactions[, c(2, 4, 5)]
if (nrow(b) > 0)
{
  xml_remove(xml_child(xml_child(xml_child(xml_child(drug_drug_int, 2), 1), 5), 2))
  colnames(b)[1] <- "Drug"
  colnames(b)[2] <- "interact with drug"
  rownames(b) <- 1:nrow(b)
  html_drug <- datatable(b, width = "100%")
  htmlwidgets::saveWidget(html_drug, paste0(path_project, "/", pt_fastq, "/all_drug.html"))
  drug_table <- (read_html(paste0(path_project, "/", pt_fastq, "/all_drug.html")))
  #substitute 1 div and 1 script to connect table drug interaction
  xml_table_drugdrug <- xml_child(xml_child(drug_table, 2), 1)
  node_to_be_replaced <- children_drugdrug
  xml_replace(node_to_be_replaced, xml_table_drugdrug)
  children_drugdrug <- xml_child(xml_child(xml_child(drug_drug_int, 2), 1), 7)
  xml_table_drugdrug <- xml_child(xml_child(drug_table, 2), 2)
  node_to_be_replaced <- children_drugdrug
  xml_replace(node_to_be_replaced, xml_table_drugdrug)
}

system(paste0("chmod -R 777 project/report_html/"))
write_html(drug_drug_int, paste0(path_project, "/", pt_fastq, "/drugdrug.html"))


#
## PharmGKB variant {.tabset}
#
cat("PHARMGKB - Variant Mutation\n")
pharmgkb <- (read_html(paste0(path_html_source, "/pharmgkb.html")))
children_phgkb <- xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(pharmgkb, 2), 1), 2), 4), 1), 1), 1)
array_table <- c()
an <- xml_child(xml_child(xml_child(xml_child(xml_child(pharmgkb, 2), 1), 1), 2), 2)
xml_replace(an, an_xml)
id_evidence <- 0
### Variant Mutation
##Mutations information
options(knitr.table.format = "html")
#cargs=commandArgs(trailingOnly = TRUE)
try({
  x_url <- read.csv(paste0(path_project, "/txt/reference/", pt_fastq, "_pharm.txt"), sep = "\t")
  x_url <- x_url[, c("PMID", "Reference")]
  x_url$PMID <- as.character(x_url$PMID)

  x <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_pharm.txt"), sep = "\t", colClasses = c("character"))
  x[is.na(x)] <- " "
  x$Drug <- as.character(x$Drug, levels = (x$Drug))
  x$Drug <- gsub(", ", ",", x$Drug, fixed = T)
  x$Gene <- as.character(x$Gene, levels = (x$Gene))
  x$Clinical_significance <- gsub(pattern = " ", replace = "", x$Clinical_significance)

  x <- inner_join(x, x_url)
  x <- x[order(x$Gene, x$Variant, x$Drug, x$Clinical_significance, x$Reference),]
  x <- x[!duplicated(x[, c("PMID")]),]  # Delete rows
  if (nrow(x) > 0)
  {
    x$Reference <- paste0(x$Reference, "p")
    x$Reference <- paste0('<a href="reference.html#pharm" class="my_ref_link" data-id="#ref-', x$Reference, '">', x$Reference, '</a>')
  }
  hgx <- split(x, paste(x$Gene))
  empty <- T
  for (n in hgx)
  {
    if (dim(n)[1] != 0)
    {
      gene <- as.character(n$Gene)[1]
      cat("  \n#### Gene", gene, " \n")
      n <- n[, c("Gene", "Variant", "Drug", "Clinical_significance", "Evidence_statement", "Type", "Reference")]
      tmp <- group_by(n, Variant, Drug, Clinical_significance, Type, Gene)
      tmp2 <- summarise(tmp, Evidence_statement = paste(Evidence_statement, collapse = " "), Reference = paste(Reference, collapse = ", "))
      ya <- tmp2[, c("Gene", "Variant", "Drug", "Clinical_significance", "Type", "Reference"), drop = F]
      yb <- tmp2[, c("Gene", "Evidence_statement", "Reference"), drop = F]
      ya$Evidence <- 1:nrow(ya)
      ya$Details <- paste0('[<a href="Javascript:;" class="my_ref_link" data-id="#det-', gene, '-', ya$Evidence, 'p">+</a>]')
      ya$Details[!complete.cases(yb) |
                   yb$Evidence_statement == " " |
                   yb$Evidence_statement == ""] <- ""
      ya$Evidence <- paste0('<a id="evi-', gene, '-', ya$Evidence, 'p" name="evi-', gene, '-', ya$Evidence, 'p"></a>', ya$Evidence + id_evidence)
      ya$Drug <- gsub(",", ", ", ya$Drug, fixed = T)
      ya <- ya[, c("Evidence", "Gene", "Variant", "Drug", "Clinical_significance", "Type", "Details", "Reference")]
      names(ya) <- c("#", "Gene", "Variant", "Drug", "Clinical Significance", "Type", "Details", "References")
      if (tumor_type == "tumnorm")
        ya <- ya[, -which(names(ya) == "Type")]
      array_table <- rbind(array_table, ya)
      empty <- F
    }
    id_evidence <- nrow(ya) + id_evidence
  }
  if (empty)
  {
    array_table <- paste('<div id="no-data-available." class="section level5">
                        <h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
    cat("  \n##### No data available.  \n")

  }
}, silent = FALSE)
array_table <- kable(array_table, "html", escape = FALSE) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "responsive"))
xml_table_evidence <- kable_as_xml(paste((array_table), collapse = " "))
node_to_be_replaced <- children_phgkb
xml_replace(node_to_be_replaced, xml_table_evidence)
write_html(pharmgkb, paste0(path_project, "/", pt_fastq, "/pharmgkb.html"))


## PharmGKB variant {.tabset}
### Evidence Details
##Mutations information
cat("PHARMGKB - Evidence Details\n")
children_phgkb_ed <- xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(pharmgkb, 2), 1), 2), 4), 2), 1)
array_table <- c()
options(knitr.table.format = "html")
id_evidence <- 0
#cargs=commandArgs(trailingOnly = TRUE)
try({
  x_url <- read.csv(paste0(path_project, "/txt/reference/", pt_fastq, "_pharm.txt"), sep = "\t")
  x_url <- x_url[, c("PMID", "Reference")]
  x_url$PMID <- as.character(x_url$PMID)

  x <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_pharm.txt"), sep = "\t", colClasses = c("character"))
  x[is.na(x)] <- " "
  x$Drug <- as.character(x$Drug, levels = (x$Drug))
  x$Gene <- as.character(x$Gene, levels = (x$Gene))
  x$Clinical_significance <- gsub(pattern = " ", replace = "", x$Clinical_significance)

  x <- inner_join(x, x_url)
  x <- x[order(x$Gene, x$Variant, x$Drug, x$Clinical_significance, x$Reference),]
  x <- x[!duplicated(x[, c("PMID")]),]  # Delete rows
  if (nrow(x) > 0)
  {
    x$Reference <- paste0(x$Reference, "p")
    x$Reference <- paste0('<a href="reference.html#pharm" class="my_ref_link" data-id="#ref-', x$Reference, '">', x$Reference, '</a>')
  }
  hgx <- split(x, paste(x$Gene))
  empty <- T
  for (n in hgx)
  {
    if (dim(n)[1] != 0)
    {
      gene <- as.character(n$Gene)[1]
      cat("  \n#### Gene", gene, " \n")
      n2 <- n[, c("Variant", "Drug", "Clinical_significance", "Evidence_statement", "Reference")]
      tmp <- group_by(n2, Variant, Drug, Clinical_significance)
      tmp2 <- summarise(tmp, Evidence_statement = paste(Evidence_statement, collapse = " "),
                        Reference = paste(sort(Reference), collapse = ", "))
      yb <- tmp2[, c("Evidence_statement", "Reference"), drop = F]
      yb$Evidence <- 1:nrow(yb)
      yb$Less <- paste0('[<a href="Javascript:;" class="my_ref_link" data-id="#evi-', gene, '-', yb$Evidence, 'p">-</a>]')
      yb$Evidence <- paste0('<a id="det-', gene, '-', yb$Evidence, 'p" name="det-', gene, '-', yb$Evidence, 'p"></a>', yb$Evidence + id_evidence)
      yb <- yb[complete.cases(yb) &
                 yb$Evidence_statement != " " &
                 yb$Evidence_statement != "", , drop = F]
      if (nrow(yb) > 0)
      {
        yb <- yb[, c("Evidence", "Evidence_statement", "Reference", "Less"), drop = F]
        names(yb) <- c("#", "Evidence Statement", "References", "")
        array_table <- rbind(array_table, yb)
      }
      empty <- F
    }
    id_evidence <- nrow(tmp2) + id_evidence
  }
  if (empty)
  {
    array_table <- paste('<div id="no-data-available." class="section level5">
                        <h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
    cat("  \n##### No data available.  \n")
  }
}, silent = TRUE)
array_table <- kable(array_table, "html", escape = FALSE) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "responsive", align = "justify"))
xml_table_evidence <- kable_as_xml(paste(array_table, collapse = " "))
node_to_be_replaced <- children_phgkb_ed
xml_replace(node_to_be_replaced, xml_table_evidence)
write_html(pharmgkb, paste0(path_project, "/", pt_fastq, "/pharmgkb.html"))


## PharmGKB variant {.tabset}
### Variant Details
cat("PHARMGKB - Variant Details\n")
children_phgkb_vd <- xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(pharmgkb, 2), 1), 2), 4), 3), 1)
array_table <- c()
##Mutations information
options(knitr.table.format = "html")
#cargs=commandArgs(trailingOnly = TRUE)
try({

  x <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_pharm.txt"), sep = "\t", colClasses = c("character"))
  x[is.na(x)] <- " "
  x$Gene <- as.character(x$Gene, levels = (x$Gene))
  x$Var_base <- as.character(x$Var_base)
  x$Ref_base <- as.character(x$Ref_base)
  x[is.na(x$Var_base), "Var_base"] <- "T"
  x[is.na(x$Ref_base), "Ref_base"] <- "T"

  x <- inner_join(x, x_url)
  x <- x[order(x$Gene, x$Variant),]

  hgx <- split(x, paste(x$Gene))
  empty <- T
  for (n in hgx)
  {
    if (dim(n)[1] != 0)
    {
      cat("  \n#### Gene", as.character(n$Gene)[1], " \n")
      ya <- n[, c("Variant", "Chromosome", "Ref_base", "Var_base", "Start", "Stop")]
      ya <- unique(ya)
      row.names(ya) <- NULL
      print(kable(ya[1,]) %>%
              kable_styling(bootstrap_options = c("striped", "hover", "responsive")))
      yc <- n[, c("Variant", "Variant_summary"), drop = F]
      yc <- yc[complete.cases(yc),]
      yc <- unique(yc)
      yc <- yc[!(yc$Variant_summary == " "),]
      yc <- yc[!(yc$Variant_summary == ""),]
      if (nrow(yc) > 0)
      {
        tmp <- group_by(yc, Variant)
        tmp2 <- summarise(tmp, Variant_summary = paste(Variant_summary, collapse = " "))
        array_table <- rbind(array_table, tmp2)
      }
      empty <- F
    }
  }
  if (empty)
  {
    array_table <- paste('<div id="no-data-available." class="section level5">
                        <h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
    cat("  \n##### No data available.  \n")
  }
}, silent = TRUE)
array_table <- kable(array_table, "html", escape = FALSE) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "responsive", align = "justify"))
xml_table_evidence <- kable_as_xml(paste(array_table, collapse = " "))
node_to_be_replaced <- children_phgkb_vd
xml_replace(node_to_be_replaced, xml_table_evidence)
write_html(pharmgkb, paste0(path_project, "/", pt_fastq, "/pharmgkb.html"))


##
## Mutations' annotations
##

cat("MUTATIONS - Annotations\n")
mutations <- (read_html(paste0(path_html_source, "/mutations.html")))
children_mutations <- xml_child(xml_child(xml_child(xml_child(mutations, 2), 1), 2), 3)
array_table <- c()
an <- xml_child(xml_child(xml_child(xml_child(xml_child(mutations, 2), 1), 1), 2), 2)
xml_replace(an, an_xml)
#cargs=commandArgs(trailingOnly = TRUE)
try({
  xref <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_refgene.txt"), sep = "\t", colClasses = c("character"))
  xclin <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_clinvar.txt"), sep = "\t", colClasses = c("character"))
  xcr <- merge(xref, xclin, all.x = TRUE)
  xcr <- format.data.frame(xcr, digits = NULL, na.encode = FALSE)
  xcr[is.na(xcr)] <- " "
  xcr <- xcr[, c("Gene", "Chromosome", "Stop", "Ref_base", "Var_base", "Change_type", "Clinical_significance", "Type")]
  names(xcr) <- c("Gene", "Chromosome", "Position", "Ref_base", "Var_base",
                  "Change Type", "Clinical Significance", "Type")
  if (tumor_type != "tumnorm")
    xcr$Type <- factor(xcr$Type, levels = c("Somatic", "Germline"))
  xcr <- xcr[order(xcr$Type, xcr$Gene, as.integer(xcr$Position)),]
  rownames(xcr) <- NULL
  if (nrow(xcr) > 0)
  {
    if (tumor_type == "tumnorm")
      xcr <- xcr[, -which(names(xcr) == "Type")]
    array_table <- c(array_table, kable(xcr) %>%
      kable_styling(bootstrap_options = c("striped", "hover", "responsive")) %>%
      column_spec(1, bold = T, border_right = T))
  } else
  {
    array_table <- paste('<div id="no-data-available." class="section level5">
                        <h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
    cat("  \n##### No data available.  \n")
  }
}, silent = TRUE)
xml_table_evidence <- kable_as_xml(paste(array_table, collapse = " "))
node_to_be_replaced <- children_mutations
xml_replace(node_to_be_replaced, xml_table_evidence)
write_html(mutations, paste0(path_project, "/", pt_fastq, "/mutations.html"))


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


cat("COSMIC - Resistant mutations\n")
## Cosmic {.tabset}
cosmic <- (read_html(paste0(path_html_source, "/cosmic.html")))
children_cosmic_drm <- xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(cosmic, 2), 1), 2), 4), 1), 1)
array_table <- c()
an <- xml_child(xml_child(xml_child(xml_child(xml_child(cosmic, 2), 1), 1), 2), 2)
xml_replace(an, an_xml)
### Drug resistant mutations
##Mutations information
options(knitr.table.format = "html")
#cargs=commandArgs(trailingOnly = TRUE)
try({
  x_url <- read.csv(paste0(path_project, "/txt/reference/", pt_fastq, "_cosmic.txt"), sep = "\t")
  x_url <- x_url[, c("PMID", "Reference")]
  x_url$PMID <- as.character(x_url$PMID)

  cosm <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_cosmic.txt"), sep = "\t", colClasses = c("character"))
  cosm <- cosm[, c("Gene", "Variant", "Drug", "Primary.Tissue", "PMID")]
  cosm <- unique(cosm)

  cosm <- inner_join(cosm, x_url)
  cosm <- cosm[order(cosm$Gene, cosm$Variant, cosm$Drug, cosm$Primary.Tissue, cosm$Reference),]
  if (nrow(cosm) > 0)
  {
    cosm$Reference <- paste0(cosm$Reference, "c")
    cosm$Reference <- paste0('<a href="reference.html#cosmic-1" class="my_ref_link" data-id="#ref-', cosm$Reference, '">', cosm$Reference, '</a>')
  }
  hgx <- split(cosm, paste(cosm$Gene))
  empty <- T
  for (n in hgx)
  {
    if (dim(n)[1] != 0)
    {
      cat("  \n#### Gene", as.character(n$Gene)[1], " \n")
      n <- n[, c("Gene", "Variant", "Drug", "Primary.Tissue", "Reference")]
      tmp <- group_by(n, Gene, Variant, Drug, Primary.Tissue)
      tmp2 <- summarise(tmp, Reference = paste(Reference, collapse = ","))
      tmp2$Number <- 1:nrow(tmp2)
      tmp2$Number <- as.character(tmp2$Number)
      tmp2 <- tmp2[, c("Number", "Gene", "Variant", "Drug", "Primary.Tissue", "Reference")]
      names(tmp2) <- c("#", "Gene", "Variant", "Drug", "Primary Tissue", "References")
      array_table <- c(array_table, kable(tmp2, "html", escape = F) %>%
        kable_styling(bootstrap_options = c("striped", "hover", "responsive")))
      empty <- F
    }
  }
  if (empty)
  {
    array_table <- paste('<div id="no-data-available." class="section level5">
                        <h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
    cat("  \n##### No data available.  \n")

  }

})
xml_table_evidence <- kable_as_xml(paste(array_table, collapse = " "))
node_to_be_replaced <- children_cosmic_drm
xml_replace(node_to_be_replaced, xml_table_evidence)
write_html(cosmic, paste0(path_project, "/", pt_fastq, "/cosmic.html"))

cat("COSMIC - Variant details\n")
### Variant Details
children_cosmic_vd <- xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(cosmic, 2), 1), 2), 4), 2), 1)
array_table <- c()
##Mutations information
options(knitr.table.format = "html")
#cargs=commandArgs(trailingOnly = TRUE)
try({
  x <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_cosmic.txt"), sep = "\t", colClasses = c("character"))
  if (nrow(x) > 0)
  {
    x[is.na(x$Var_base), "Var_base"] <- "T"
    x[is.na(x$Ref_base), "Ref_base"] <- "T"
  }
  x <- x[order(x$Gene, x$Variant),]
  hgx <- split(x, x$Gene)
  empty <- T
  for (n in hgx)
  {
    if (dim(n)[1] != 0)
    {
      cat("  \n#### Gene", as.character(n$Gene)[1], " \n")
      ya <- n[, c("Gene", "Variant", "Chromosome", "Ref_base", "Var_base", "Start", "Stop")]
      ya <- unique(ya)
      row.names(ya) <- NULL
      array_table <- c(array_table, kable(ya) %>%
        kable_styling(bootstrap_options = c("striped", "hover", "responsive")))
      empty <- F
    }
  }
  if (empty)
  {
    array_table <- paste('<div id="no-data-available." class="section level5">
                        <h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
    cat("  \n##### No data available.  \n")

  }

}, silent = TRUE)
xml_table_evidence <- kable_as_xml(paste(array_table, collapse = " "))
node_to_be_replaced <- children_cosmic_vd
xml_replace(node_to_be_replaced, xml_table_evidence)
write_html(cosmic, paste0(path_project, "/", pt_fastq, "/cosmic.html"))


##
## Drug-Food Interactions
##
cat("DRUGFOOD - Food Interactions\n")
drugfood <- (read_html(paste0(path_html_source, "/drugfood.html")))
children_drugfood <- xml_child(xml_child(xml_child(xml_child(drugfood, 2), 1), 2), 3)
array_table <- c()
an <- xml_child(xml_child(xml_child(xml_child(xml_child(drugfood, 2), 1), 1), 2), 2)
xml_replace(an, an_xml)
#Food interactions
#cargs=commandArgs(trailingOnly = TRUE)
try({
  k <- read.csv(paste0(path_project, "/txt/", pt_fastq, "_drugfood.txt"), sep = "\t")
  k <- k[, c("Drug", "Food_interaction")]
  if (nrow(k) > 0) {
    k <- unique(k)
    tmp <- group_by(k, Drug)
    tmp2 <- summarise(tmp, Food_interaction = paste(Food_interaction, collapse = " "))
    names(tmp2) <- c("Drug", "Food Interaction")
    array_table <- c(array_table, kable(tmp2) %>%
      kable_styling(bootstrap_options = c("striped", "hover", "responsive")))
  } else {
    array_table <- paste('<div id="no-data-available." class="section level5">
                        <h5 class="hasAnchor">No data available.<a href="#no-data-available." class="anchor-section"></a>\n</h5>')
    cat("  \n##### No data available.  \n")

  }
}, silent = TRUE)
xml_table_evidence <- kable_as_xml(paste(array_table, collapse = " "))
node_to_be_replaced <- children_drugfood
xml_replace(node_to_be_replaced, xml_table_evidence)
write_html(drugfood, paste0(path_project, "/", pt_fastq, "/drugfood.html"))
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
  } else
  {
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

##
## ESMO Guidelines
##
cat("ESMOGUIDELINES\n")
esmoguide <- (read_html(paste0(path_html_source, "/esmoguide.html")))
an <- xml_child(xml_child(xml_child(xml_child(xml_child(esmoguide, 2), 1), 1), 2), 2)
xml_replace(an, an_xml)
children_esmoguide <- xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(xml_child(esmoguide, 2), 1), 2), 1), 1), 1), 1)
cat(path_project, "/", pt_fastq, "/esmo_", pt_tumor_site, ".html\n")
# esmo_personalized <- read_html(paste0(path_project, "/esmo_parsed.html"))
xml_esmo <- read_xml(paste0(path_project, "/esmo_parsed.html")) # xml_child(xml_child(esmo_personalized, 1), 1)
xml_replace(children_esmoguide, xml_esmo)
write_html(esmoguide, paste0(path_project, "/", pt_fastq, "/esmoguide.html"))

cat("Copying assets\n")
file.copy(file.path(path_html_source, "assets"), file.path(path_project, pt_fastq), recursive = TRUE)
cat("OK!\n")
