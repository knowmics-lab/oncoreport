civic1 <- read.csv("./civic_database.txt", sep="\t")
  civic1$code<-rownames(civic1)
civic2 <- read.csv("./civic_bed_hg38.bed", sep="\t", header = FALSE)
colnames(civic2)[1]<- "chromosome"
colnames(civic2)[2]<- "start"
colnames(civic2)[3]<- "stop"
colnames(civic2)[4]<- "code"
civic2$chromosome<-gsub("chr", "", civic2$chromosome)
civic1$start <- NULL
civic1$stop <- NULL
x <- merge(civic1, civic2, by=c("code", "chromosome"))
x$code <- NULL
x <- x[, c(1, 17, 18, 2:16)]
write.table(x, "./civic_databasehg38.txt", sep="\t", col.names = TRUE, row.names = FALSE, quote=FALSE)

