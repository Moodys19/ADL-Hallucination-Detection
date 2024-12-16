###############################################################################_
############### Data Prep & Fake Summary Analysis and Cleanse ----
###############################################################################_

setwd("C:/mahmoud uni/TU/WS2024_2025/ADL/ADL-Hallucination-Detection/cnndm")

rm(list = ls())
library(tidyverse)



######### Data Loading ----


train_fake_raw <- read.csv("fake_summary/train_hallucinated_alt.csv")
test_fake_raw <- read.csv("fake_summary/test_hallucinated_alt.csv")
valid_fake_raw <- read.csv("fake_summary/val_hallucinated_alt.csv")

full_data <- rbind(train_fake_raw, "BEGINN_TEST",
                   test_fake_raw, "BEGINN_VAL", 
                   valid_fake_raw)
full_data$id <- 1:nrow(full_data)

######### Check additional text ----

#table(grepl("Here is", train_fake$fake_summary_clean))

check_add_info <- full_data %>%
  filter(grepl("Here is", fake_summary) | grepl("hallucination", fake_summary)) %>%
  mutate(
    fake_summary = gsub("Here is the .*?:", "", fake_summary),
    fake_summary = gsub("Here is a .*?:", "", fake_summary),
    fake_summary = gsub("However, I made .*", "", fake_summary)
  ) %>%
  filter(grepl("Here is", fake_summary, ignore.case = TRUE))



full_data <- full_data %>%   mutate(
  fake_summary = gsub("^.*Here is the .*?:", "", fake_summary),
  fake_summary = gsub("^.*Here is a .*?:", "", fake_summary),
  fake_summary = gsub("However, I made .*", "", fake_summary),
  fake_summary = gsub("Here's a .*", "", fake_summary),
  fake_summary = gsub("Here's the .*", "", fake_summary),
) 



######### Check Special Cases ----

full_data <- full_data %>%
  mutate(
    # ACHTUNG das FALSE wird zu einem string
    fake_summary = ifelse(grepl("I cannot", fake_summary, ignore.case = TRUE), FALSE, fake_summary), 
    fake_summary = ifelse(grepl("I can't", fake_summary, ignore.case = TRUE), FALSE, fake_summary), 
    fake_summary = ifelse(grepl("I can’t", fake_summary, ignore.case = TRUE), FALSE, fake_summary)
  )



######### Check Tokens + Remove Tokens for Baseline Model ----

check_tokens <- full_data %>%
  mutate(
    
    fake_summary = gsub("E\\[hallucinated", "\\[E-hallucinated", fake_summary),
    fake_summary = gsub("B\\[hallucinated", "\\[B-hallucinated", fake_summary),
    
    
    fake_summary = gsub(" B-hallucinated", "B-hallucinated", fake_summary),
    fake_summary = gsub("B-hallucinated ", "B-hallucinated", fake_summary),
    fake_summary = gsub(" E-hallucinated", "E-hallucinated", fake_summary),
    fake_summary = gsub("E-hallucinated ", "E-hallucinated", fake_summary),
    
    fake_summary = gsub("\\/E-hallucinated", "E-hallucinated", fake_summary),
    fake_summary = gsub("\\/B-hallucinated", "B-hallucinated", fake_summary),
    
    # TODO
    
    fake_summary = gsub("(?<!\\[)E-hallucinated", "[E-hallucinated", fake_summary, perl = TRUE),
    fake_summary = gsub("E-hallucinated(?!\\])", "E-hallucinated]", fake_summary, perl = TRUE),
    fake_summary = gsub("(?<!\\[)B-hallucinated", "[B-hallucinated", fake_summary, perl = TRUE),
    fake_summary = gsub("B-hallucinated(?!\\])", "B-hallucinated]", fake_summary, perl = TRUE),
    
    fake_summary_base = gsub("\\[B-hallucinated\\]", "", fake_summary), 
    fake_summary_base = gsub("\\[E-hallucinated\\]", "", fake_summary_base),
    
  ) %>%
  #filter(grepl("\\[|\\]", fake_summary_base))
  filter(grepl("halluc", fake_summary_base))
  

write.csv2(check_tokens, file = "fake_summary/check_tokens.csv")



full_data <- full_data %>%
  mutate(
    
    fake_summary = gsub("E\\[hallucinated", "\\[E-hallucinated", fake_summary),
    fake_summary = gsub("B\\[hallucinated", "\\[B-hallucinated", fake_summary),
    
    
    fake_summary = gsub(" B-hallucinated", "B-hallucinated", fake_summary),
    fake_summary = gsub("B-hallucinated ", "B-hallucinated", fake_summary),
    fake_summary = gsub(" E-hallucinated", "E-hallucinated", fake_summary),
    fake_summary = gsub("E-hallucinated ", "E-hallucinated", fake_summary),
    
    fake_summary = gsub("\\/E-hallucinated", "E-hallucinated", fake_summary),
    fake_summary = gsub("\\/B-hallucinated", "B-hallucinated", fake_summary),
    
    # TODO
    
    fake_summary = gsub("(?<!\\[)E-hallucinated", "[E-hallucinated", fake_summary, perl = TRUE),
    fake_summary = gsub("E-hallucinated(?!\\])", "E-hallucinated]", fake_summary, perl = TRUE),
    fake_summary = gsub("(?<!\\[)B-hallucinated", "[B-hallucinated", fake_summary, perl = TRUE),
    fake_summary = gsub("B-hallucinated(?!\\])", "B-hallucinated]", fake_summary, perl = TRUE),
    
    fake_summary_base = gsub("\\[B-hallucinated\\]", "", fake_summary), 
    fake_summary_base = gsub("\\[E-hallucinated\\]", "", fake_summary_base),
    
  )

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
train <- read.csv2("subsamples/train_subset_7000.csv", sep = ";")
test <- read.csv2("subsamples/train_subset_7000.csv", sep = ";")
valid <- read.csv2("subsamples/train_subset_7000.csv", sep = ";")



train_fake <- full_data[1:(which(full_data$fake_summary == "BEGINN_TEST") - 1), ]
test_fake <- full_data[(which(full_data$fake_summary == "BEGINN_TEST") + 1):(which(full_data$fake_summary == "BEGINN_VAL") - 1), ]
valid_fake <- full_data[(which(full_data$fake_summary == "BEGINN_VAL") + 1):nrow(full_data), ]

nrow(train_fake) == nrow(train_fake_raw)
nrow(test_fake) == nrow(test_fake_raw)
nrow(valid_fake) == nrow(valid_fake_raw)

### Train Data
train_prep <- cbind(train, train_fake %>% select(-id)) %>%
  filter(fake_summary != "FALSE") %>% 
  filter(fake_summary != "")


train_base <- rbind(
  train_prep %>% select(article, highlights) %>% mutate(label = 0),
  train_prep %>% select(article, fake_summary_base) %>% mutate(label = 1) %>% rename(highlights = fake_summary_base)
)


write.csv2(train_base, "train_data_base.csv")

sum(train$highlights == "")
sum(train_base$highlights == "")
sum(train_prep$fake_summary_base == "")

glimpse(train_base)


test <- cbind(test, test_fake) %>%
  filter(fake_summary != "FALSE") %>%
  select(-id)

valid <- cbind(test, valid_fake) %>%
  filter(fake_summary != "FALSE")%>%
  select(-id)







write.csv2(test, "test_data_clean.csv")
write.csv2(valid, "valid_data_clean.csv")


