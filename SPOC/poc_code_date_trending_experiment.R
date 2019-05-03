#!/usr/bin/env Rscript

here::here()

library(data.table)
library(dplyr)
library(zoo)
source("interactive.R")
print("here2")
input_file <- "data/crs/test_crs.csv"
output_file <- "output.csv"
date_back <- "2017-01-01"
short_time <- 30
long_time <- 365

#command line argument parsing
args = commandArgs(trailingOnly=TRUE)
print("here")
print(args)

# test if there is at least one argument: if not, display a warning and use
# defaults
if (length(args)==0) {
  warning("default input output files will be used, and a 30 day and 1 year moving average for trending")
} else if (length(args)==5) {
  # default output file
  input_file <- args[1] 
  output_file <- args[2]
  short_time <- args[3]
  long_time <-args[4]
  date_back <-args[5]
}
print(input_file)
cr_csv.df <- read.csv(file = input_file, stringsAsFactors = F)
names(cr_csv.df) <- c("SITEUID","DATE", 'CRTEXT')

#concatenate crtext and crcomment into cr textS
#cr_csv.df$CRTEXT <- paste(cr_csv.df$CRTEXT,cr_csv.df$CRCOMMENT)
#cr_csv.df$CRCOMMENT <- NULL

cr_csv.dt <- data.table(cr_csv.df,stringsAsFactors = F)
names(cr_csv.dt) <- c("SITEUID","DATE","CRTEXT")

text2 <- prepChrData(c("CRTEXT"),
                     cr_csv.dt,
                     "SITEUID",
                     ktt,
                     model = model)

pred2 <- model$predict(text2$CRTEXT)

rownames(pred2) <- cr_csv.df$SITEUID

colnames(pred2) <- pocdecoder

poc_output.df <- as.data.frame(pred2)

poc_output.df$SITEUID <- rownames(poc_output.df)

poc_output.df <- merge(x = poc_output.df, y = cr_csv.df, by = 'SITEUID')

poc_output.df$DATE <- as.POSIXct(poc_output.df$DATE, format = "%m/%d/%y %H:%M")

poc_output_f.df <- poc_output.df %>%
  filter(DATE > date_back) %>%
  mutate(short_date = format(DATE, "%Y-%m-%d")) %>%
  group_by(short_date) %>%
  summarise_at(funs(sum), .vars = vars(-SITEUID, -DATE, -CRTEXT, -short_date))
  
poc_output_10.df <- poc_output_f.df %>%
  read.zoo %>%
  rollapplyr(short_time, mean, by.column = TRUE, fill = 0) %>%
  fortify.zoo

poc_output_200.df <- poc_output_f.df %>%
  read.zoo %>%
  rollapplyr(long_time, mean, by.column = TRUE, fill = 0) %>%
  fortify.zoo

poc_output_10.df$short_date <- poc_output_f.df$short_date
poc_output_200.df$short_date <- poc_output_f.df$short_date

filter_cols <- c("Index", "short_date")
poc_output_short_200.df <- tail(poc_output_200.df,1) %>% select(-one_of(filter_cols))
poc_output_short_10.df <- tail(poc_output_10.df,1) %>% select(-one_of(filter_cols))

diff.df <- (poc_output_short_10.df - poc_output_short_200.df)

diff.df <- diff.df[,order(diff.df,decreasing = FALSE)]

#get the top 5 rows from diff.df corresponding to the best performing codes
getting_better <- diff.df[,1:5]

#get the last 5 rows from diff.df corresponding to the worst performing codes
getting_worse <- diff.df[,(ncol(diff.df)-5):ncol(diff.df)]

codes_to_plot <- cbind(getting_better,getting_worse)
