##############################################################################_
############### Data Prep & Fake Summary Analysis and Cleanse ----
###############################################################################_

setwd("C:/mahmoud uni/TU/WS2024_2025/ADL/ADL-Hallucination-Detection/cnndm")

rm(list = ls())
library(tidyverse)
library(stringi)
library(stringr)

######### Data Loading ----

# Load Source and Target Files
train_raw <- read.csv2("subsamples/train_subset_7000.csv", sep = ";")
test_raw <- read.csv2("subsamples/test_subset_1000.csv", sep = ";")
valid_raw <- read.csv2("subsamples/valid_subset_1000.csv", sep = ";")

issues <- rbind(test_raw[c(306, 847),], valid_raw[29, ])
# Probleme mit Zeilen wo die Summary mit # anfängt

test_raw <- test_raw[-c(306, 847), ]
valid_raw <- valid_raw[-29, ]

full_data_raw <- rbind(train_raw, "BEGINN_TEST",
                       test_raw, "BEGINN_VAL", 
                       valid_raw) %>%
  mutate(id = 1:nrow(.)) %>%
  select(highlights, id)


### Load Fake Summaries
train_fake_raw <- read.csv("fake_summary/train_hallucinated_base.csv")
test_fake_raw <- read.csv("fake_summary/test_hallucinated_base.csv")
valid_fake_raw <- read.csv("fake_summary/val_hallucinated_base.csv")

full_data_fake <- rbind(train_fake_raw, "BEGINN_TEST",
                   test_fake_raw, "BEGINN_VAL", 
                   valid_fake_raw)
full_data_fake$id_fake <- 1:nrow(full_data_fake)


full_data <- cbind(full_data_raw, full_data_fake)
sum(full_data$fake_summary == "")

all(full_data$id == full_data$id_fake)


######### Base Analysis ----

cleaned_data <- full_data %>%
  mutate(
    fake_summary_base = gsub("Note.*$", "", fake_summary),
    # ACHTUNG das FALSE wird zu einem string
    fake_summary_base = ifelse(grepl("I cannot (create|fulfill|provide)", fake_summary_base, ignore.case = TRUE), FALSE, fake_summary_base), 
    fake_summary_base = ifelse(grepl("I can't (create|fulfill|provide)", fake_summary_base, ignore.case = TRUE), FALSE, fake_summary_base), 
    fake_summary_base = ifelse(grepl("I can’t (create|fulfill|provide)", fake_summary_base, ignore.case = TRUE), FALSE, fake_summary_base),
    fake_summary_base = ifelse(grepl("halluci", fake_summary_base, ignore.case = TRUE), FALSE, fake_summary),
    fake_summary_base = ifelse(grepl("original passage", fake_summary_base, ignore.case = TRUE), FALSE, fake_summary_base),
    fake_summary_base = ifelse(grepl("i'm unable to", fake_summary_base, ignore.case = TRUE), FALSE, fake_summary_base),
    fake_summary_base = gsub("I've altered .*?:", "", fake_summary_base),
  ) 




######### Join Data ----

all(cleaned_data$id_fake == cleaned_data$id)

full_data <- cleaned_data %>% select(-id_fake, -highlights)

train_fake <- full_data[1:(which(full_data$fake_summary == "BEGINN_TEST") - 1), ]
test_fake <- full_data[(which(full_data$fake_summary == "BEGINN_TEST") + 1):(which(full_data$fake_summary == "BEGINN_VAL") - 1), ]
valid_fake <- full_data[(which(full_data$fake_summary == "BEGINN_VAL") + 1):nrow(full_data), ]

nrow(train_fake) == nrow(train_fake_raw)
nrow(test_fake) == nrow(test_fake_raw)
nrow(valid_fake) == nrow(valid_fake_raw)

### Train Data
train_prep <- cbind(train_raw, train_fake %>% select(-id)) %>%
  filter(fake_summary != "FALSE" & fake_summary_base != "FALSE") 


sum(train_prep$highlights == "")
sum(train_prep$highlights == "")
sum(train_prep$fake_summary_base == "")

dim(train_prep)

train_base <- rbind(
  train_prep %>% select(article, highlights) %>% mutate(label = 0),
  train_prep %>% select(article, fake_summary_base) %>% mutate(label = 1) %>% rename(highlights = fake_summary_base)
)


write.csv2(train_base, "train_data_base.csv")

### Test Data
test_prep <- cbind(test_raw, test_fake %>% select(-id)) %>%
  filter(fake_summary != "FALSE" & fake_summary_base != "FALSE") 


sum(test_prep$highlights == "")
sum(test_prep$highlights == "")
sum(test_prep$fake_summary_base == "")

dim(test_prep)

test_base <- rbind(
  test_prep %>% select(article, highlights) %>% mutate(label = 0),
  test_prep %>% select(article, fake_summary_base) %>% mutate(label = 1) %>% rename(highlights = fake_summary_base)
)

write.csv2(test_base, "test_data_base.csv")


### Valid Data
valid_prep <- cbind(valid_raw, valid_fake %>% select(-id)) %>%
  filter(fake_summary != "FALSE" & fake_summary_base != "FALSE") 


sum(valid_prep$highlights == "")
sum(valid_prep$highlights == "")
sum(valid_prep$fake_summary_base == "")

dim(valid_prep)

valid_base <- rbind(
  valid_prep %>% select(article, highlights) %>% mutate(label = 0),
  valid_prep %>% select(article, fake_summary_base) %>% mutate(label = 1) %>% rename(highlights = fake_summary_base)
)

write.csv2(valid_base, "valid_data_base.csv")



glimpse(train_base)
glimpse(test_base)
glimpse(valid_base)


sum(valid_prep$fake_summary_base == "")
sum(test_prep$fake_summary_base == "")
sum(train_prep$fake_summary_base == "")

colnames(valid_fake)


valid_fake %>%
  filter(fake_summary_base == "") %>%
  select(id)
