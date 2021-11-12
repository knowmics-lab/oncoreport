suppressPackageStartupMessages({
  library(optparse)
  library(readr)
  library(dplyr)
})

option_list <- list(
  make_option(c("-c", "--civic"), type="character", default=NULL, help="CIVIC hg19 database file", metavar="character"),
  make_option(c("-g", "--cgi"), type="character", default=FALSE, help="CGI hg19 database file", metavar="character"),
  make_option(c("-d", "--diseases"), type="character", default=FALSE, help="diseases map file", metavar="character"),
  make_option(c("-o", "--output"), type="character", default=NULL, help="output file", metavar="character")
); 

opt_parser <- OptionParser(option_list=option_list)
opt        <- parse_args(opt_parser)

if (is.null(opt$civic) || !file.exists(opt$civic)) {
  print_help(opt_parser)
  stop("Invalid CIVIC db file", call.=FALSE)
}
if (is.null(opt$cgi) || !file.exists(opt$cgi)) {
  print_help(opt_parser)
  stop("Invalid CGI db file", call.=FALSE)
}
if (is.null(opt$diseases) || !file.exists(opt$diseases)) {
  print_help(opt_parser)
  stop("Invalid diseases map file", call.=FALSE)
}
if (is.null(opt$output)) {
  print_help(opt_parser)
  stop("Invalid output file", call.=FALSE)
}

tmp.file <- tempfile()
download.file("https://raw.githubusercontent.com/DiseaseOntology/HumanDiseaseOntology/main/src/ontology/doid.obo", tmp.file)

onto <- get_ontology(tmp.file)

df.onto <- data.frame(doid=gsub("DOID:", "", names(onto$name)), name=unname(onto$name), key=gsub("'s", "", gsub("ö", "oe", tolower(unname(onto$name)), fixed = TRUE), fixed = TRUE), doid.orig=names(onto$name))


civic       <- read_delim(opt$civic, delim = "\t", escape_double = FALSE, trim_ws = TRUE)
cgidb       <- read_delim(opt$cgi, delim = "\t", escape_double = FALSE, trim_ws = TRUE)
disease.map <- read_delim(opt$diseases, delim = "\t", escape_double = FALSE, trim_ws = TRUE)

civic.diseases <- unique(civic[,c("disease", "doid")])
civic.diseases$key <- gsub("'s", "", gsub("ö", "oe", tolower(civic.diseases$disease), fixed = TRUE), fixed = TRUE)
cgidb.diseases <- data.frame(disease=unique(cgidb$Disease))
cgidb.diseases$key <- gsub("'s", "", gsub("ö", "oe", tolower(cgidb.diseases$disease), fixed = TRUE), fixed = TRUE)
cgidb.diseases <- cgidb.diseases %>% left_join(civic.diseases, by="key") %>% select(disease.x, doid, key)
colnames(cgidb.diseases) <- c("disease", "doid", "key")
tmp <- cgidb.diseases %>% left_join(disease.map, by=c("disease"="Disease"))
tmp$key[is.na(tmp$doid)] <- gsub("'s", "", gsub("ö", "oe", tolower(tmp$Disease1[is.na(tmp$doid)]), fixed = TRUE), fixed = TRUE)
tmp <- tmp %>% left_join(df.onto, by=c("key"="key"))
tmp$doid.x[is.na(tmp$doid.x)] <- tmp$doid.y[is.na(tmp$doid.x)]
cgidb.diseases <- tmp %>% select(disease, doid.x)
rm(tmp)
colnames(cgidb.diseases) <- c("disease", "doid")
civic.diseases <- civic.diseases[,c("disease", "doid")]

tumor.doid <- paste0("DOID:", trimws(na.omit(unique(c(cgidb.diseases$doid, civic.diseases$doid, "0050869", "0060108")))))

recursive.child.finder <- function (doid) {
  children <- onto$children[[doid]]
  if (length(children) == 0) return (doid)
  return (unique(c(doid, unname(unlist(lapply(children, recursive.child.finder))))))
}

tumor.doid.list <- setNames(lapply(tumor.doid, recursive.child.finder), tumor.doid)
all.tumors.doid <- unique(unname(unlist(tumor.doid)))
df.tumor.doid   <- data.frame(doid=gsub("DOID:", "", rep(tumor.doid, sapply(tumor.doid.list, length))), rdoid=unname(unlist(tumor.doid.list)))
all.db.diseases <- rbind(civic.diseases, cgidb.diseases)
all.db.diseases$doid[all.db.diseases$disease == "Villous Adenoma"] <- "0050869"
all.db.diseases$doid[all.db.diseases$disease == "Glioma"] <- "0060108"
all.db.diseases <- all.db.diseases[order(all.db.diseases$disease),]
all.db.diseases <- all.db.diseases %>% left_join(df.tumor.doid, by="doid") %>% left_join(df.onto, by=c("rdoid"="doid.orig")) %>% select(disease, name, rdoid)
all.db.diseases$tumor <- 1
all.db.diseases$general <- 0
all.db.diseases$general[is.na(all.db.diseases$name)] <- 1
all.db.diseases$name[is.na(all.db.diseases$name)] <- all.db.diseases$disease[is.na(all.db.diseases$name)]
all.db.diseases <- all.db.diseases[!is.na(all.db.diseases$name), ]
onto.remaining  <- df.onto[!(df.onto$doid.orig %in% na.omit(all.db.diseases$rdoid)),]
all.onto.diseases <- data.frame(disease=onto.remaining$name, name=onto.remaining$name, rdoid=onto.remaining$doid.orig, tumor=0, general=0)
final.db.diseases <- rbind(all.db.diseases, all.onto.diseases)
colnames(final.db.diseases) <- c("Database_name", "DO_name", "DOID", "tumor", "general")
write.table(final.db.diseases, file = opt$output, append = FALSE, quote = FALSE, sep = "\t", row.names = FALSE, col.names = TRUE)

unlink(tmp.file)
