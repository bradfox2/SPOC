#!/usr/bin/env Rscript

library(data.table)
source("interactive.R")

input_file <- "input.csv"
output_file <- "output.csv"

#command line argument parsing
args = commandArgs(trailingOnly=TRUE)

# test if there is at least one argument: if not, display a warning and use
# defaults
if (length(args)==0) {
  warning("default input output files will be used")
} else if (length(args)==2) {
  # default output file
  input_file <- args[1] 
  output_file <- args[2]
}

cr_csv.df <- read.csv(file = input_file, stringsAsFactors = F)
names(cr_csv.df) <- c("CR", "CRTEXT")

#concatenate crtext and crcomment into cr textS
#cr_csv.df$CRTEXT <- paste(cr_csv.df$CRTEXT,cr_csv.df$CRCOMMENT)
#cr_csv.df$CRCOMMENT <- NULL

cr_csv.dt <- data.table(cr_csv.df,stringsAsFactors = F)
names(cr_csv.dt) <- c("SITEUID", "CRTEXT")

text2 <- prepChrData(c("CRTEXT"),
                     cr_csv.dt,
                     "SITEUID",
                     ktt,
                     model = model)

pred2 <- model$predict(text2$CRTEXT)

colnames(pred2) <- pocdecoder#names(pocs.dt)[3:ncol(pocs.dt)]
rownames(pred2) <- cr_csv.df$CR

#view output in % format
#View(round(pred2,3)*100)

write.csv(x = round(pred2,3),
          file = output_file)
