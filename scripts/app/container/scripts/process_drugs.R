#!/usr/bin/env Rscript
library(readr)
library(rvest)
library(data.table)
library(readxl)
library(fuzzyjoin)
library(webchem)
library(googleLanguageR)
library(dbparser)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  cat(
    "Usage: process_approvals.R <drugbank_database_zip_file>",
    "<output_directory> [<google_translate_json_file>]\n"
  )
  quit(status = 1)
}
drugbank_zip_path <- args[1]
output_directory  <- args[2]
if (length(args) >= 3 && file.exists(args[3])) {
  gl_auth(args[3])
}

if (!file.exists(drugbank_zip_path)) {
  cat("Drugbank Full Database ZIP file not found!")
  cat(
    "Usage: process_approvals.R <drugbank_database_zip_file>",
    "<output_directory>\n"
  )
  quit(status = 2)
}

ema_url      <- "https://www.ema.europa.eu/system/files/documents/other/medicines_output_european_public_assessment_reports_en.xlsx"
ema_columns  <- c("Medicine.name", "Active.substance")
aifa_a_h_url <- "https://www.aifa.gov.it/liste-farmaci-a-h"
aifa_base    <- "https://www.aifa.gov.it"
aifa_cnn_url <- "https://www.aifa.gov.it/web/guest/liste-dei-farmaci"

###############################################################################
# DrugBank database
cached_db_file <- paste0("drugbank_",format(Sys.Date(), "%Y%m%d"),".rda")

if (!file.exists(cached_db_file)) {
  cat("Reading DrugBank database...\n")
  dvobj <- parseDrugBank(db_path            = drugbank_zip_path,
                         drug_options       = drug_node_options(),
                         parse_salts        = TRUE,
                         parse_products     = TRUE,
                         references_options = references_node_options(),
                         cett_options       = cett_nodes_options())
  cat("Processing vocabulary...\n")
  salts_ids      <- unique(dvobj$salts[,c("drugbank-id", "parent_key")])
  salts_names    <- unique(dvobj$salts[,c("name", "parent_key")])
  products_names <- unique(dvobj$products[,c("name", "parent_key")])
  mixtures       <- unique(dvobj$drugs$mixtures[,c("name", "parent_key")])
  synonyms       <- unique(dvobj$drugs$synonyms[,c("synonym", "drugbank-id")])
  general_names  <- unique(dvobj$drugs$general_information[,c("name", "primary_key")])
  general_ids    <- unique(dvobj$drugs$general_information[,c("primary_key", "primary_key")])
  
  colnames(salts_ids)      <- c("synonym", "common_name")
  colnames(salts_names)    <- c("synonym", "common_name")
  colnames(products_names) <- c("synonym", "common_name")
  colnames(mixtures)       <- c("synonym", "common_name")
  colnames(synonyms)       <- c("synonym", "common_name")
  colnames(general_names)  <- c("synonym", "common_name")
  colnames(general_ids)    <- c("synonym", "common_name")
  drugbank_vocab_map       <- rbind(salts_ids, salts_names, products_names, 
                                    mixtures, synonyms, general_names, 
                                    general_ids) %>% unique()
  rm(salts_ids, salts_names, products_names, mixtures, synonyms, 
     general_names, general_ids)
  cat("Processing approvals...\n")
  drugbank_approvals <- dvobj$products %>% 
    dplyr::filter(approved == "true") %>% 
    dplyr::group_by(parent_key) %>% 
    dplyr::summarise(approved_by=paste(unique(unlist(strsplit(source, " "))), collapse = "/")) %>%
    unique()
  cat("Saving cached data...\n")
  save(dvobj, drugbank_vocab_map, drugbank_approvals, file = cached_db_file)
} else {
  cat("Loading cached DrugBank data...\n")
  load(cached_db_file)
}

drugbank_vocab_map$key <- gsub("[^[:alnum:] ]|\\s+", "", tolower(drugbank_vocab_map$synonym))
drugbank_vocab_map     <- na.omit(unique(drugbank_vocab_map[nchar(drugbank_vocab_map$key) > 2,]))

###############################################################################
# Function definitions

to_key <- function(column)(gsub("[^[:alnum:] ]|\\s+", "", tolower(column)))

do_exact_match <- function (df_data, field) {
  df_data$key      <- to_key(df_data[[field]])
  df_exact_match   <- df_data %>% dplyr::left_join(drugbank_vocab_map)
  exact_matched    <- complete.cases(df_exact_match)
  df_no_match      <- df_exact_match[!exact_matched, c("Medicine.name", "Active.substance")]
  df_exact_match   <- unique(df_exact_match[exact_matched, c("Medicine.name", "Active.substance", "common_name")])
  
  return(list(df_exact_match, df_no_match))
}

do_approx_match <- function (df_data, field) {
  df_data$key         <- to_key(df_data[[field]])
  df_approx_match     <- df_data %>% stringdist_left_join(drugbank_vocab_map, distance_col = "distance")
  approx_matched      <- complete.cases(df_approx_match)
  df_no_match         <- df_approx_match[!approx_matched, c("Medicine.name", "Active.substance")]
  df_approx_match     <- unique(df_approx_match[approx_matched,c("Medicine.name","Active.substance","common_name", "distance")]) %>%
    dplyr::group_by(Medicine.name, Active.substance) %>%
    dplyr::summarise(common_name=common_name[which.min(distance)[1]])
  
  return(list(df_approx_match, df_no_match))
}

do_webchem_match <- function (df_data, field) {
  tmp              <- get_wdid(unique(df_data[[field]]), verbose = TRUE)
  tmp1             <- wd_ident(tmp$wdid, verbose = TRUE)
  rownames(tmp1)   <- tmp$query
  tmp1             <- tmp1[!is.na(tmp1$drugbank),]
  tmp1$common_name <- setNames(drugbank_vocab_map[[2]], 
                               drugbank_vocab_map[[1]])[paste0("DB", tmp1$drugbank)]
  tmp1             <- tmp1[!is.na(tmp1$common_name),]
  tmp2             <- setNames(tmp1$common_name, rownames(tmp1))
  
  df_data$common_name <- unname(tmp2[df_data[[field]]])
  webchem_matched     <- !is.na(df_data$common_name)
  df_webchem_match    <- df_data[webchem_matched, c("Medicine.name","Active.substance","common_name")]
  df_no_match         <- df_data[!webchem_matched, c("Medicine.name","Active.substance")]
  
  return(list(df_webchem_match, df_no_match))
}

do_translate_match <- function (df_data, field, source="it") {
  translated         <- gl_translate(unique(df_data[[field]]), source = source, target = "en")
  translated$key     <- to_key(translated$translatedText)
  translated_matched <- translated %>% stringdist_left_join(drugbank_vocab_map, distance_col = "distance")  %>%
    dplyr::group_by(translatedText, text) %>%
    dplyr::summarise(common_name=common_name[which.min(distance)[1]])
  
  mapped_common_names <- setNames(translated_matched$common_name, translated_matched$text)
  df_data$common_name <- mapped_common_names[df_data[[field]]]
  transl_matched      <- !is.na(df_data$common_name)
  df_transl_match     <- df_data[transl_matched, c("Medicine.name","Active.substance","common_name")]
  df_no_match         <- df_data[!transl_matched, c("Medicine.name","Active.substance")]
  
  return (list(df_transl_match, df_no_match))
}

do_matches <- function (df_data, match_funs, fields) {
  df_data_matched     <- setNames(vector("list", length(fields)), fields)
  df_data_not_matched <- setNames(vector("list", length(fields)), fields)
  for(field in fields) {
    df_data_match    <- NULL
    df_data_no_match <- df_data
    for (fn in match_funs) {
      tmp <- do.call(fn, list(df_data_no_match, field))
      
      if (is.null(df_data_match)) {
        df_data_match <- tmp[[1]]
      } else if (is.data.frame(tmp[[2]]) && nrow(tmp[[2]]) > 0) {
        df_data_match <- rbind(df_data_match, tmp[[1]])
      }
      
      df_data_no_match <- tmp[[2]]
    }
    df_data_matched[[field]]     <- df_data_match
    df_data_not_matched[[field]] <- df_data_no_match
  }
  
  return(list(df_data_matched, df_data_not_matched))
}

###############################################################################
# AIFA data

cached_aifa_file <- paste0("aifa_data_matched_",format(Sys.Date(), "%Y%m%d"),".rda")

if (!file.exists(cached_aifa_file)) {
  aifa    <- xml2::read_html(aifa_a_h_url)
  aifa_release_date_a_h   <- (function() {
    headers <- aifa %>% html_elements("h2.portlet-title-text") %>% html_text2()
    matches <- gregexpr("Liste(.*)\\s+(?<date>[0-9]{2,2}/[0-9]{2,2}/[0-9]{4,4})", text = headers, perl = TRUE)
    element <- which(sapply(matches, function(x)(any(x != -1))))
    
    aifa_release_date <- NULL
    
    if (length(element) > 0) {
      match  <- matches[[element[1]]]
      header <- headers[element[1]]
      start  <- attr(match, "capture.start")[1,"date"]
      len    <- attr(match, "capture.length")[1,"date"]
      
      return (substr(header, start, start + len - 1))
    }
    return (NULL)
  })()
  cat("Downloading AIFA data...\n")
  aifa_files_by_class <- (function() {
    download_links          <- aifa %>% html_elements("a[title='Scarica']")
    download_link_labels    <- html_attr(download_links, "aria-label")
    download_link_addresses <- html_attr(download_links, "href")
    
    csv_files <- grepl(".csv$", download_link_addresses, perl = TRUE)
    matches   <- gregexpr("Elenco[A-Za-z\\s]+\\s+(?<class>A|H)\\s+[A-Za-z\\s]+commerciale", download_link_labels, perl = TRUE) 
    elements  <- sapply(matches, function(x)(any(x != -1))) & csv_files
    
    selected_labels <- download_link_labels[elements]
    selected_addrs  <- paste0(aifa_base, download_link_addresses[elements])
    selected_captrs <- sapply(matches[elements], function(x)(attr(x, "capture.start")[1,"class"]))
    
    selected_classes <- sapply(1:length(selected_labels), 
                               function(i)(substr(selected_labels[i], selected_captrs[i], selected_captrs[i])))
    
    local_files <- setNames(character(length(selected_classes)), selected_classes)
    for (i in 1:length(selected_addrs)) {
      local_files[i] <- paste0("aifa_class_", selected_classes[i], ".tsv")
      download.file(selected_addrs[i], local_files[i])
    }
    return(local_files)
  })()
  rm(aifa)
  
  tmp_data <- (function () {
    aifa1 <- xml2::read_html(aifa_cnn_url)
    download_links <- aifa1 %>% html_elements("a") %>% html_attr("href")
    download_link  <- grep("classe_Cnn", download_links, value = TRUE)
    capture <- gregexpr("(?<date>[0-9]{2,2}\\.[0-9]{2,2}\\.[0-9]{4,4})\\.csv$", download_link, perl = TRUE)[[1]]
    capture_start <- attr(capture, "capture.start")[,"date"]
    capture_length <- attr(capture, "capture.length")[, "date"]
    aifa_release_date_c <- gsub(".", "/", substr(download_link, capture_start, capture_start + capture_length - 1), fixed = TRUE)
    local_file <- c("C"="aifa_class_C.tsv")
    download.file(paste0(aifa_base, download_link), local_file)
    aifa_release_dates_by_class <- 
      setNames(character(length(aifa_files_by_class) + 1), c(names(aifa_files_by_class), "C"))
    aifa_release_dates_by_class[names(aifa_files_by_class)] <- aifa_release_date_a_h
    aifa_release_dates_by_class["C"] <- aifa_release_date_c
    aifa_files_by_class <- c(aifa_files_by_class, local_file)
    
    data_by_class <- setNames(vector("list", length(aifa_files_by_class)), names(aifa_files_by_class))
    for (cls in names(aifa_files_by_class)) {
      data <- fread(aifa_files_by_class[cls], sep = ";")
      tmp  <- make.names(iconv(colnames(data),"WINDOWS-1252","UTF-8"))
      tmp[tmp == "PRINCIPIO.ATTIVO"] <- "Principio.Attivo"
      tmp[tmp == "AIC.Farmaco"] <- "AIC"
      tmp[tmp == "Codice..AIC"] <- "AIC"
      tmp[grep("^DENOMINAZIONE\\.FARMACO", tmp)] <- "Denominazione.e.Confezione"
      colnames(data) <- tmp
      data <- data[,c("AIC", "Principio.Attivo", "Denominazione.e.Confezione")]
      for (cn in colnames(data)) {
        data[[cn]] <- iconv(data[[cn]],"WINDOWS-1252","UTF-8")
      }
      data$Class <- cls
      data <- unique(data)
      data_by_class[[cls]] <- data
    }
    all_data <- do.call(rbind, data_by_class)
    all_data <- unique(all_data[,c("Denominazione.e.Confezione", "Principio.Attivo")])
    colnames(all_data) <- ema_columns
    all_data <- unique(all_data %>% tidyr::separate_rows(Active.substance, sep="/"))
    all_data <- unique(all_data %>% tidyr::separate_rows(Active.substance, sep=" e "))
    all_data <- unique(all_data %>% tidyr::separate_rows(Active.substance, sep=" and "))
    all_data$Medicine.name <- gsub("\\*.*", "", all_data$Medicine.name)
    all_data <- unique(all_data %>% tidyr::separate_rows(Medicine.name, sep=" E "))
    all_data$Medicine.name    <- gsub("\\s+\\(.*", "", all_data$Medicine.name)
    all_data$Medicine.name    <- trimws(all_data$Medicine.name)
    all_data$Active.substance <- trimws(all_data$Active.substance)
    unlink(aifa_files_by_class)
    all_data$key <- gsub("[^[:alnum:] ]|\\s+", "", tolower(all_data$Active.substance))
    return (list(all_data, aifa_release_dates_by_class))
  })()
  
  aifa_data <- tmp_data[[1]]
  aifa_release_dates <- tmp_data[[2]]
  rm(tmp_data, aifa_release_date_a_h, aifa_files_by_class)
  cat("Matching AIFA data with DrugBank Vocabulary...\n")
  tmp               <- do_matches(
    aifa_data,
    c(do_exact_match, do_webchem_match, do_approx_match, do_translate_match),
    c("Medicine.name", "Active.substance")
  )
  aifa_data_matched <- unique(do.call(rbind, tmp[[1]]))
  save(aifa_data, aifa_release_dates, aifa_data_matched, file = cached_aifa_file)
} else {
  cat("Loading cached AIFA data...\n")
  load(cached_aifa_file)
}

###############################################################################
# EMA data
cached_ema_file <- paste0("ema_data_matched_",format(Sys.Date(), "%Y%m%d"),".rda")

if (!file.exists(cached_ema_file)) {
  cat("Downloading EMA data...\n")
  download.file(ema_url, "ema_medicines.xlsx")
  ema_data <- read_excel("ema_medicines.xlsx", skip = 8)
  ema_report_date <- read_excel("ema_medicines.xlsx", range = "D1", col_names = FALSE)
  unlink("ema_medicines.xlsx")
  ema_report_date <- ema_report_date$...1
  ema_report_date <- as.character(as.Date(ema_report_date, tryFormats = "%a, %d/%m/%Y"))
  
  colnames(ema_data) <- make.names(colnames(ema_data))
  ema_data <- ema_data[tolower(ema_data$Category) == "human" &
                         tolower(ema_data$Authorisation.status) == "authorised", ema_columns]
  ema_data <- unique(ema_data)
  ema_data_no_divide <- grep("strain|live|recombinant|subgroup|conjugate|inactivated|rotavirus|encoding", ema_data$Active.substance)
  ema_data_kept      <- ema_data[ema_data_no_divide, ]
  
  ema_data_divided   <- ema_data[-ema_data_no_divide,] %>% 
    tidyr::separate_rows(Active.substance, sep=", ") %>%
    tidyr::separate_rows(Medicine.name, sep="/") %>%
    unique() %>%
    na.omit()
  
  ema_data <- rbind(ema_data_divided, ema_data_kept)
  
  ema_data$Medicine.name    <- trimws(ema_data$Medicine.name)
  ema_data$Active.substance <- trimws(ema_data$Active.substance)
  ema_data$Medicine.name    <- gsub("\\s+\\(.*", "", ema_data$Medicine.name)
  cat("Matching EMA data with DrugBank Vocabulary...\n")
  tmp                    <- do_matches(
    ema_data,
    c(do_exact_match, do_webchem_match, do_approx_match),
    c("Medicine.name", "Active.substance")
  )
  ema_data_match    <- unique(do.call(rbind, tmp[[1]]))
  ema_data_match$common_name[ema_data_match$Active.substance == "aclidinium bromide"] <- "Aclidinium"
  save(ema_data,ema_data_match,ema_report_date,file=cached_ema_file)
} else {
  load(cached_ema_file)
}

###############################################################################
# Build approval data
cat("Matching AIFA and EMA data with DrugBank Approvals...\n")
aifa_drugs_approval <- data.frame(
  parent_key=unique(aifa_data_matched$common_name),
  aifa=TRUE
)
ema_drugs_approval  <- data.frame(
  parent_key=unique(ema_data_match$common_name),
  ema=TRUE
)

supported_agencies  <- c("AIFA", "EMA", "FDA")

build_approval_string <- function (approved_by, aifa, ema) {
  approvals <- strsplit(approved_by, "/")
  return (sapply(seq_along(approvals), function(i) {
    a <- approvals[[i]]
    if (!is.na(aifa[i]) && aifa[i]) a <- c(a, "AIFA")
    if (!is.na(ema[i]) && ema[i])  a <- c(a, "EMA")
    a <- sort(unique(a[a %in% supported_agencies]))
    if (length(a) == 0) {
      return("Not approved")
    }
    return(paste0(a, collapse = "/"))
  }))
}

complete_approvals <- drugbank_approvals %>% 
  dplyr::full_join(aifa_drugs_approval) %>% 
  dplyr::full_join(ema_drugs_approval) %>%
  dplyr::mutate(approvals = build_approval_string(approved_by, aifa, ema)) %>%
  dplyr::select(parent_key, approvals)
cat("Saving approvals...\n")
approved_drug_names <- complete_approvals %>% 
  dplyr::full_join(dvobj$drugs$general_information, by=c("parent_key"="primary_key")) %>%
  dplyr::select(name, approvals) %>%
  unique()
approved_drug_names$approvals[is.na(approved_drug_names$approvals)] <- "Not approved"
colnames(approved_drug_names) <- c("Drug_name", "approved")
write_tsv(approved_drug_names, file.path(output_directory, "Agency_approval.txt"), 
          col_names = TRUE, quote = "needed")

###############################################################################
# Build version data
cat("Saving versions...\n")
df_version <- data.frame(
  name = c("EMA", paste("AIFA Class", names(aifa_release_dates))),
  release = c(ema_report_date, unname(aifa_release_dates)),
  date = format(Sys.Date(), "%Y-%m-%d")
)
versions_path <- file.path(output_directory, "versions.txt")
if (file.exists(versions_path)) {
  v_data <- read_delim(versions_path, delim = "\t", 
                       escape_double = FALSE, col_names = FALSE, 
                       col_types = cols(X1 = col_character(), 
                                        X2 = col_character(), X3 = col_character()), 
                       trim_ws = TRUE)
  
  colnames(v_data) <- c("name", "release", "date")
  class(v_data)    <- "data.frame"
  df_version       <- rbind(v_data, df_version)
}
write_tsv(df_version, versions_path, col_names = FALSE)

###############################################################################
# Build drug info
cat("Preparing drug general information\n")
drug_info           <- dvobj$drugs$general_information
class(drug_info)    <- "data.frame"
drug_info           <- as.data.frame(cbind(drug_info$primary_key, drug_info$name))
colnames(drug_info) <- c("id", "name")
atc_codes           <- dvobj$drugs$atc_codes
drug_info           <- drug_info %>% 
  dplyr::left_join(atc_codes, by=c("id" = "drugbank-id")) %>%
  dplyr::select(id, name, atc_code) %>%
  unique()

write_csv(
  drug_info,
  file = file.path(output_directory, "drug_info.csv"),
  quote = "needed"
)

###############################################################################
# Build drug-drug interactions
cat("Preparing drug-drug interactions\n")
drug_info_unique  <- drug_info %>% dplyr::select("id", "name") %>% unique()
drug_interactions <- dvobj$drugs$drug_interactions %>%
  dplyr::inner_join(drug_info_unique, by=c("parent_key" = "id")) %>%
  unique() %>%
  na.omit()
colnames(drug_interactions) <- c(
  "Drug1_code", "Drug1_name", "Effect", "Drug2_code", "Drug2_name"
)

write_tsv(
  drug_interactions,
  file = file.path(output_directory, "drug_drug_interactions_light.txt"),
  quote = "needed"
)
###############################################################################
# Build drug-food interactions
cat("Preparing drug-food interactions\n")
# data for food interactions
drug_food_info           <- dvobj$drugs$food_interactions
colnames(drug_food_info) <- c("Food_interaction", "Drugbank_ID")
food_interaction         <- drug_food_info %>% 
  dplyr::inner_join(drug_info_unique, by = c("Drugbank_ID" = "id")) %>%
  unique() %>%
  na.omit() %>%
  dplyr::select(Drugbank_ID, Drug=name, Food_interaction)

write_csv(
  food_interaction,
  file = file.path(output_directory, "drugfood_database.csv"),
  quote = "needed"
)
###############################################################################
# Clean up
unlink(cached_db_file)
unlink(cached_aifa_file)
unlink(cached_ema_file)
cat("Done!\n")