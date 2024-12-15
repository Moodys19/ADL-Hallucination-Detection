###############################################################################_
############### Data Prep & Fake Summary Analysis and Cleanse ----
###############################################################################_

setwd("C:/mahmoud uni/TU/WS2024_2025/ADL/ADL-Hallucination-Detection/cnndm")

library(tidyverse)

######### Data Loading ----


train_fake <- read.csv("fake_summary/train_hallucinated.csv")
test_fake <- read.csv("fake_summary/test_hallucinated.csv")
#valid_fake <- read.csv("fake_summary/.csv")


######### Check additional text ----

table(grepl("Here is", train_fake$fake_summary))

check_add_info <- train_fake %>%
  filter(grepl("Here is", fake_summary) | grepl("hallucination", fake_summary)) %>%
  mutate(
    fake_summary = gsub("^.*Here is the .*?:", "", fake_summary),
    fake_summary = gsub("^.*Here is a .*?:", "", fake_summary),
  ) %>%
  filter(grepl("Here is", fake_summary) | grepl("hallucination", fake_summary))



######### Check Tokens + Remove Tokens for Baseline Model ----






######### Join Data ----

load_src_tgt_file <- function(file_src, file_tgt){
  
  # Function to load source (src) and target (tgt) files into a data frame
  # Args:
  #   file_src (str): The file path to the source file containing one entry per line.
  #   file_tgt (str): The file path to the target file containing one entry per line.
  #
  # Returns:
  #   data.frame: A data frame with two columns:
  #               - src: Contains the lines from the source file.
  #               - tgt: Contains the lines from the target file.
  #
  
  src_lines <- readLines(file_src)
  tgt_lines <- readLines(file_tgt)
  
  df <- data.frame(
    src = src_lines,
    tgt = tgt_lines,
    stringsAsFactors = FALSE
  )
  
  return(df)
}


# Load Source and Target Files
train <- load_src_tgt_file(
  file_src = "subsamples/train_src_7000.src",
  file_tgt = "subsamples/train_tgt_7000.tgt"
)


test <- load_src_tgt_file(
  file_src = "subsamples/test_src_1000.src",
  file_tgt = "subsamples/test_tgt_1000.tgt"
)


valid <- load_src_tgt_file(
  file_src = "subsamples/valid_src_1000.src",
  file_tgt = "subsamples/valid_tgt_1000.tgt"
)


