###############################################################################_
############### Data Prep & Fake Summary Analysis and Cleanse ----
###############################################################################_

setwd("C:/mahmoud uni/TU/WS2024_2025/ADL/ADL-Hallucination-Detection/cnndm")

rm(list = ls())
library(tidyverse)

######### Data Loading ----


train_fake_raw <- read.csv("fake_summary/train_hallucinated.csv")
test_fake_raw <- read.csv("fake_summary/test_hallucinated.csv")
valid_fake_raw <- read.csv("fake_summary/val_hallucinated.csv")

full_data <- rbind(train_fake_raw, "BEGINN_TEST",
                   test_fake_raw, "BEGINN_VAL", 
                   valid_fake_raw)
full_data$id <- 1:nrow(full_data)

sum(full_data$fake_summary == "")


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


full_data_dirty <- full_data

full_data <- full_data_dirty %>%   mutate(
  fake_summary = gsub("Here is (the|a).*?:", "", fake_summary),
  fake_summary = gsub("Here's (the|a).*?:", "", fake_summary),
  fake_summary = gsub("However, I made .*", "", fake_summary),
) 

sum(full_data$fake_summary == "")

######### Check Special Cases ----

full_data <- full_data %>%
  mutate(
    # ACHTUNG das FALSE wird zu einem string
    fake_summary = ifelse(grepl("I cannot", fake_summary, ignore.case = TRUE), FALSE, fake_summary), 
    fake_summary = ifelse(grepl("I can't", fake_summary, ignore.case = TRUE), FALSE, fake_summary), 
    fake_summary = ifelse(grepl("I can’t", fake_summary, ignore.case = TRUE), FALSE, fake_summary)
  )



check_option <- full_data %>%
  filter(grepl("option", fake_summary)) # the korea one is weird - fliegt aber dann raus 
# TODO: tell system prompt to always give one option



######### Check Tokens + Remove Tokens for Baseline Model ----

nrow(full_data %>% mutate( fake_summary_base = gsub("\\[B-hallucinated\\]", "", fake_summary), 
                           fake_summary_base = gsub("\\[E-hallucinated\\]", "", fake_summary_base)) 
     %>% filter(grepl("halluc", fake_summary_base))) # 2238

full_data_dirty <- full_data

full_data <- full_data_dirty %>%
  mutate(

    fake_summary = gsub("hallucination", "hallucinated", fake_summary), 
    fake_summary = gsub("hallucation", "hallucinated", fake_summary), 
    fake_summary = gsub("halluination", "hallucinated", fake_summary),
    fake_summary = gsub("hallucinations", "hallucinated", fake_summary),
    fake_summary = gsub("halllucinated", "hallucinated", fake_summary),
    fake_summary = gsub("halluccinated", "hallucinated", fake_summary),
    fake_summary = gsub("bhallucianted", "hallucinated", fake_summary),
    fake_summary = gsub("hallucinatied", "hallucinated", fake_summary),
    fake_summary = gsub("hallucina ted.", "hallucinated", fake_summary),
    fake_summary = gsub("halluciated", "hallucinated", fake_summary),
    fake_summary = gsub("hallucicated", "hallucinated", fake_summary),
    fake_summary = gsub("halaunicatioidnd", "hallucinated", fake_summary),
    fake_summary = gsub("rpoaeunnaaicnhallcinuatied", "hallucinated", fake_summary),
    fake_summary = gsub("hallaunicatiodne", "hallucinated", fake_summary),
    fake_summary = gsub("halluccination", "hallucinated", fake_summary),
    fake_summary = gsub("hallaunicatinadn", "hallucinated", fake_summary),
    fake_summary = gsub("halluclnated", "hallucinated", fake_summary),
    fake_summary = gsub("Eh halluci nated", "hallucinated", fake_summary),
    fake_summary = gsub("halluccianted", "hallucinated", fake_summary),
    fake_summary = gsub("hallucedinatd", "hallucinated", fake_summary),
    fake_summary = gsub("halluclinated", "hallucinated", fake_summary),
    fake_summary = gsub("hallucedated", "hallucinated", fake_summary),
    fake_summary = gsub("hallaucination", "hallucinated", fake_summary),
    
    fake_summary = gsub("bhallucinaetd", "B-hallucinated", fake_summary),
    
    fake_summary = gsub("(?<![EB]-)hallucinated", "E-hallucinated", fake_summary, perl = TRUE), # konservativer Ansatz
  
    # typos
    fake_summary = gsub("(?<!B)-(hallucinated)", "-E-hallucinated", fake_summary, perl = TRUE),
    fake_summary = gsub("B-Ehallucinated", "E-hallucinated", fake_summary), # konservativer Ansatz
    fake_summary = gsub("EThallucinated", "E-hallucinated", fake_summary),
    fake_summary = gsub("EShallucinated", "E-hallucinated", fake_summary),
    fake_summary = gsub("BThallucinated", "B-hallucinated", fake_summary),
    fake_summary = gsub("BShallucinated", "B-hallucinated", fake_summary),
    fake_summary = gsub("hhallucinated", "hallucinated", fake_summary),
    fake_summary = gsub("ehallucinated", "E-hallucinated", fake_summary),
    fake_summary = gsub("e hallucinated", "E-hallucinated", fake_summary),
    fake_summary = gsub("bhallucinated", "B-hallucinated", fake_summary),
    fake_summary = gsub("b hallucinated", "B-hallucinated", fake_summary),
    fake_summary = gsub("b hallucinated", "B-hallucinated", fake_summary),
    fake_summary = gsub("b hallucinated", "B-hallucinated", fake_summary),
    
    fake_summary = gsub("E-halluced", "E-hallucinated", fake_summary),
    fake_summary = gsub("E halluced", "E-hallucinated", fake_summary),
    fake_summary = gsub("B-halluced", "B-hallucinated", fake_summary),
    fake_summary = gsub("B halluced", "B-hallucinated", fake_summary),
    
    
    fake_summary = gsub("ehallucinated", "E-hallucinated", fake_summary),
    fake_summary = gsub("bhallucinated", "B-hallucinated", fake_summary),
    fake_summary = gsub("b-hallucinated", "B-hallucinated", fake_summary),
    fake_summary = gsub("e-hallucinated", "E-hallucinated", fake_summary),
    
    fake_summary = gsub("E-token 1", "E-hallucinated", fake_summary),
    fake_summary = gsub("E-token", "E-hallucinated", fake_summary),
    fake_summary = gsub("B-token", "B-hallucinated", fake_summary),
    fake_summary = gsub("E-MOD", "B-hallucinated", fake_summary),
    fake_summary = gsub("halluclination token 2", "E-hallucinated", fake_summary),
    
    
    
    fake_summary = gsub("Es-hallucinated", "E-hallucinated", fake_summary), #  wurde hier wie hallucinations verwendet
    fake_summary = gsub("\\[hallucinated\\]", "\\[E-hallucinated\\]", fake_summary), #  wurde hier wie hallucinations verwendet
    
    
    fake_summary = gsub("E\\[hallucinated", "\\[E-hallucinated", fake_summary),
    fake_summary = gsub("B\\[hallucinated", "\\[B-hallucinated", fake_summary),
    fake_summary = gsub("B - hallucinated", "B-hallucinated", fake_summary),
    fake_summary = gsub("E - hallucinated", "E-hallucinated", fake_summary),
 
    
    fake_summary = gsub("(?<!\\[)E-hallucinated", "[E-hallucinated", fake_summary, perl = TRUE),
    fake_summary = gsub("E-hallucinated(?!\\])", "E-hallucinated]", fake_summary, perl = TRUE),
    fake_summary = gsub("(?<!\\[)B-hallucinated", "[B-hallucinated", fake_summary, perl = TRUE),
    fake_summary = gsub("B-hallucinated(?!\\])", "B-hallucinated]", fake_summary, perl = TRUE),
    
    
    # fix white space
    fake_summary = gsub("\\s+\\[E-hallucinated\\]", "[E-hallucinated]", fake_summary),
    fake_summary = gsub("\\[E-hallucinated\\]\\s+", "[E-hallucinated]", fake_summary),
    fake_summary = gsub("\\s+\\[B-hallucinated\\]", "[B-hallucinated]", fake_summary),
    fake_summary = gsub("\\[B-hallucinated\\]\\s+", "[B-hallucinated]", fake_summary),
    
    # remove useless backslashes
    fake_summary = gsub("\\/E-hallucinated", "E-hallucinated", fake_summary),
    fake_summary = gsub("\\/B-hallucinated", "B-hallucinated", fake_summary),
    
    
    
    # Ensure '[' precedes 'E-hallucinated'
    fake_summary = gsub("(?<!\\[)E-hallucinated", "[E-hallucinated", fake_summary, perl = TRUE),
    fake_summary = gsub("(?<!\\[)B-hallucinated", "[B-hallucinated", fake_summary, perl = TRUE),
    
    # Ensure ']' follows 'E-hallucinated'
    fake_summary = gsub("E-hallucinated(?!\\])", "E-hallucinated]", fake_summary, perl = TRUE),
    fake_summary = gsub("B-hallucinated(?!\\])", "B-hallucinated]", fake_summary, perl = TRUE),
    
    
    # Fix embedded tokens
    fake_summary = gsub("(\\w)\\[E-hallucinated\\](\\w)", "\\1 \\[E-hallucinated\\] \\2", fake_summary),
    fake_summary = gsub("(\\w)\\[B-hallucinated\\](\\w)", "\\1 \\[B-hallucinated\\] \\2", fake_summary),
    
    fake_summary_base = gsub("\\[B-hallucinated\\]", "", fake_summary), 
    fake_summary_base = gsub("\\[E-hallucinated\\]", "", fake_summary_base),
    
    # säubere Artifakte
    fake_summary_base = gsub("\\[[A-Za-z]-$", "", fake_summary_base), 
    fake_summary_base = gsub("\\[[A-Za-z]-\\]$", "", fake_summary_base),
    fake_summary_base = gsub("\\[[A-Za-z]-\\.$", "", fake_summary_base),
    fake_summary_base = gsub("\\[[A-Za-z]-\\,$", "", fake_summary_base),
    fake_summary_base = gsub("\\[[A-Za-z]-[A-Za-z]-$", "", fake_summary_base),
    fake_summary_base = gsub("\\[[A-Za-z]-[A-Za-z]-[A-Za-z]$", "", fake_summary_base),
    
    # TODO: Artifakte auch für fake_summary -> relevant für token level classification
    
    fake_summary_base = ifelse(grepl("halluc", fake_summary_base), FALSE, fake_summary_base) # 5 weird cases
    
  ) 




  
######### Join Data ----

# Load Source and Target Files
train_raw <- read.csv2("subsamples/train_subset_7000.csv", sep = ";")
test_raw <- read.csv2("subsamples/test_subset_1000.csv", sep = ";")
valid_raw <- read.csv2("subsamples/valid_subset_1000.csv", sep = ";")

issues <- rbind(test_raw[c(306, 847),], valid_raw[29, ])
# Probleme mit Zeilen wo die Summary mit # anfängt

test_raw <- test_raw[-c(306, 847), ]
valid_raw <- valid_raw[-29, ]


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


