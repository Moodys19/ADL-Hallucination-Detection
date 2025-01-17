###############################################################################_
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

check_add_info <- full_data %>%
  mutate(
    fake_summary = gsub("Note.*$", "", fake_summary),
    # ACHTUNG das FALSE wird zu einem string
    fake_summary = ifelse(grepl("I cannot (create|fulfill|provide)", fake_summary, ignore.case = TRUE), FALSE, fake_summary), 
    fake_summary = ifelse(grepl("I can't (create|fulfill|provide)", fake_summary, ignore.case = TRUE), FALSE, fake_summary), 
    fake_summary = ifelse(grepl("I can’t (create|fulfill|provide)", fake_summary, ignore.case = TRUE), FALSE, fake_summary),
    fake_summary = ifelse(grepl("halluci", fake_summary, ignore.case = TRUE), FALSE, fake_summary),
    fake_summary = ifelse(grepl("original passage", fake_summary, ignore.case = TRUE), FALSE, fake_summary),
    fake_summary = ifelse(grepl("i'm unable to", fake_summary, ignore.case = TRUE), FALSE, fake_summary),
    fake_summary = gsub("I've altered .*?:", "", fake_summary)
    
  ) %>%
  filter(
    grepl("halluci", fake_summary, ignore.case = TRUE)
         
  ) %>%
  select(fake_summary)









######### Check additional text ----

#table(grepl("Here is", train_fake$fake_summary_clean))

check_add_info <- full_data %>%
  filter(grepl(, fake_summary) | grepl("hallucination", fake_summary)) %>%
  mutate(
    fake_summary = gsub("Here is the .*?:", "", fake_summary),
    fake_summary = gsub("Here is a .*?:", "", fake_summary),
    fake_summary = gsub("However, I made .*", "", fake_summary)
  ) %>%
  filter(grepl("Summary", fake_summary, ignore.case = TRUE))


full_data_dirty <- full_data

full_data <- full_data_dirty %>%   mutate(
  fake_summary = gsub("Here is (the|a).*?:", "", fake_summary),
  fake_summary = gsub("Here's (the|a).*?:", "", fake_summary),
  fake_summary = gsub("However, I made .*", "", fake_summary),
) 

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
  filter(grepl("Summary", fake_summary, ignore.case = TRUE))


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


full_data <- full_data %>%
  mutate(
    fake_summary = gsub("\\[Original Passage.*?\\] ", "", fake_summary, ignore.case = TRUE),
    fake_summary = gsub("\\[Original Passage.*?\\] ", "", fake_summary, ignore.case = TRUE),
    fake_summary = gsub("\\[Summarized .*?\\]: ", "", fake_summary, ignore.case = TRUE),
    fake_summary = gsub("\\[Summarized .*?\\] ", "", fake_summary, ignore.case = TRUE),
    fake_summary = gsub("\\[Original passage .*?\\]: ", "", fake_summary, ignore.case = TRUE),
    fake_summary = gsub("\\[Hallucinated passage .*?\\]", "", fake_summary, ignore.case = TRUE),
    fake_summary = gsub("\\[Omitted passage .*?\\]", "", fake_summary, ignore.case = TRUE),
    fake_summary = gsub("passage does not exist", "", fake_summary, ignore.case = TRUE),
  ) %>%
  mutate(fake_summary = gsub("Note: I.*?\\]", "", fake_summary, ignore.case = TRUE)) %>%
  mutate(fake_summary = gsub("Note: Hallucinated .*", "", fake_summary, ignore.case = TRUE)) 
# %>%
#   filter(grepl("original|passage|Note", fake_summary, ignore.case = TRUE)) # TODO take closer look

sum(full_data$fake_summary == "")





######### Check Tokens + Remove Tokens for Baseline Model ----


######### Token Issues ----

sum(grepl("\\[|\\]",full_data$highlights)) # 21 haben Eckige Klammern!
sum(grepl("\\[B-hallucinated\\]|\\[E-hallucinated\\]",full_data$fake_summary)) # 8741 beinhalten richtige token

# conservative Cleanse - excessive Regex usage lead to unwanted Artifacts
manual_check_prep <- full_data %>%
  mutate(
    # fix white space
    fake_summary_base = gsub("E-hallucinated ", "E-hallucinated", fake_summary, ignore.case = TRUE),
    fake_summary_base = gsub(" E-hallucinated", "E-hallucinated", fake_summary_base, ignore.case = TRUE),

    fake_summary_base = gsub("B-hallucinated ", "B-hallucinated", fake_summary_base, ignore.case = TRUE),
    fake_summary_base = gsub(" B-hallucinated", "B-hallucinated", fake_summary_base, ignore.case = TRUE),
   
    # fix case
    fake_summary_base = gsub("b-hallucinated", "B-hallucinated", fake_summary_base),
    fake_summary_base = gsub("e-hallucinated", "B-hallucinated", fake_summary_base),
    
    # remove healthy tokens - these are not needed for baseline training
    fake_summary_base = gsub("\\[B-hallucinated\\]", "", fake_summary_base), 
    fake_summary_base = gsub("\\[E-hallucinated\\]", "", fake_summary_base),
  )
  



# check for all sorts of typos of the tokens
extract_hallucinated_misspellings <- function(text, pattern = "(?i)(?=.*h)(?=.*l)(?=.*u)(?=.*c)") {
  # Split into words, filter words containing h, l, u, and c
  words <- unlist(stri_extract_all_words(text))
  hallucinated_words <- words[
    stri_detect_regex(words, pattern)
  ]
    
  return(unlist(hallucinated_words))
}

# Apply the function to the column
misspelled <- lapply(manual_check_prep$fake_summary_base, extract_hallucinated_misspellings)
table(unlist(misspelled))
write.csv2(data.frame(names(table(unlist(misspelled)))), file = "data_checks/misspellings_pre.csv", row.names = FALSE)

misspelled_words <- c(
  "bhallucianted", "bhallucinaetd", "bhallucinated", "bHallucinated", "Bhallucinated",
  "bhhllucitated", "Bhhlucidated", "Bhlluciated", "Bhallucinated", "CNHALLUCINATED",
  "dhallucinated", "ehallucinated", "Ehallucinated", "Ehallucination", "Ehullcinated",
  "Ehulluciated", "EThallucinated", "halaucination", "halaunicatioidnd", "hallaucinated",
  "hallaucination", "hallaunicatinadn", "hallaunicatiodne", "hallcinuation", "hallcuated",
  "hallcuation", "hallculated", "hallcunated", "halleducated", "Halleucinated",
  "hallicuated", "halllucinated", "halllucinaTed", "halluacted", "halluc", "halluccianted",
  "halluccinated", "halluccination", "halluced", "hallucedated", "hallucediated",
  "hallucedinatd", "halluci", "halluciated", "Halluciated", "hallucicated", "hallucina",
  "hallucinate", "hallucinated", "Hallucinated", "HALLUCINATED", "hallucinated.",
  "hallucinated:", "HALLUCINATED", "hallucinated100", "hallucinatedasterS",
  "hallucinatedbest", "hallucinatedI'd", "hallucinatedlast", "hallucinatedphotography",
  "hallucinatedpublic", "hallucinatedSeveral", "hallucinatedshe", "hallucinatedthe",
  "hallucinatied", "hallucination", "Hallucination", "HallucinatioN", "HALlUcination",
  "hallucinations", "Hallucinations", "HALLUCINATORY", "halluclinated", "halluclination",
  "halluclnated", "halluclnciatied", "halluicated", "halluication", "halluicinated",
  "halluicnation", "halluincated", "halluINcated", "halluinced", "halluncated",
  "hallunciated", "halluncinations", "halucinated", "hhalluacinated", "hhallucinated",
  "hhallucinatedwhen", "hhallucinationated", "hlaulcnation", "hllaunciation",
  "hllluclinated", "hullacinated", "hullcinated", "hullcination", "hulllcinated",
  "hullucidation", "hullucinafed", "hullucinated", "Jhallucinated", "lhulcinciated",
  "lhullucinated", "OBSHALLUCINATED", "rpoaeunnaaicnhallcinuatied", "RyanJhallucinated",
  "Ehalu", "hallucinationE", "Bhalls", "Bhallu", "hallacinated", "hallacination", "hallaication", 
  "hallasinator", "hallcinated", "hallciniated", "hallicinated", 
  "hallincated", "hallincinated", "halllcinatinatd", "hallu", 
  "halluated", "hallucinated", "halluinated", "halluinatiojn", 
  "halluination", "hhalluinated"
)

miss_pattern <- paste0("\\b(", paste(misspelled_words, collapse = "|"), ")\\b")

# fixes of some issues that have nothing to do with the tokens

manual_check_prep <- manual_check_prep %>%
  mutate(
    fake_summary_base = gsub("([.,:'])(\\S)", "\\1 \\2", fake_summary_base, perl = TRUE), # make sure there is a space after commas, dots etc.
    fake_summary_base = gsub(miss_pattern, "hallucinated ", fake_summary_base, perl = TRUE),
    
    # apply old filters
    fake_summary_base = gsub("\\[E-hallucinated \\]", "\\[E-hallucinated\\]", fake_summary_base, ignore.case = TRUE),
    fake_summary_base = gsub("\\[ E-hallucinated\\]", "\\[E-hallucinated\\]", fake_summary_base, ignore.case = TRUE),
    fake_summary_base = gsub("\\[B-hallucinated \\]", "\\[B-hallucinated\\]", fake_summary_base, ignore.case = TRUE),
    fake_summary_base = gsub("\\[ B-hallucinated\\]", "\\[B-hallucinated\\]", fake_summary_base, ignore.case = TRUE),
    fake_summary_base = gsub("\\[b-hallucinated\\]", "\\[B-hallucinated\\]", fake_summary_base),
    fake_summary_base = gsub("\\[e-hallucinated\\]", "\\[B-hallucinated\\]", fake_summary_base),
    fake_summary_base = gsub("\\[B-hallucinated\\]", "", fake_summary_base), 
    fake_summary_base = gsub("\\[E-hallucinated\\]", "", fake_summary_base),
    
    fake_summary_base = gsub("hallucinated", "hallucinated ", fake_summary_base)
  )


misspelled_post <- lapply(manual_check_prep$fake_summary_base, extract_hallucinated_misspellings)
#write.csv2(data.frame(names(table(unlist(misspelled_post)))), file = "data_checks/misspellings.csv", row.names = FALSE)

# hard check
misspelled_rem <- lapply(manual_check_prep$fake_summary_base, extract_hallucinated_misspellings, pattern = "(?i)(?=.*h)(?=.*l)")
table(unlist(misspelled_rem))


#write.csv2(data.frame(names(table(unlist(misspelled_rem)))), file = "data_checks/hard_check.csv", row.names = FALSE)


# fix some obvious cases
manual_check_prep <- manual_check_prep %>%
  mutate(
    fake_summary_base = gsub("hallucinated\\s*\\]", "hallucinated\\]", fake_summary_base, ignore.case = TRUE),
    
    fake_summary_base = gsub("\\[/E-hallucinated\\]", "\\[E-hallucinated\\]", fake_summary_base, ignore.case = TRUE),
    fake_summary_base = gsub("\\[/B-hallucinated\\]", "\\[B-hallucinated\\]", fake_summary_base, ignore.case = TRUE),
    
    fake_summary_base = gsub("\\[\\.\\s*E-hallucinated\\]", "\\[E-hallucinated\\]", fake_summary_base, ignore.case = TRUE),
    fake_summary_base = gsub("\\[\\.\\s*B-hallucinated\\]", "\\[B-hallucinated\\]", fake_summary_base, ignore.case = TRUE),
        
    # apply old filters
    fake_summary_base = gsub("\\[E-hallucinated\\s*\\]", "\\[E-hallucinated\\]", fake_summary_base, ignore.case = TRUE),
    fake_summary_base = gsub("\\[\\s*E-hallucinated\\]", "\\[E-hallucinated\\]", fake_summary_base, ignore.case = TRUE),
    fake_summary_base = gsub("\\[B-hallucinated\\s*\\]", "\\[B-hallucinated\\]", fake_summary_base, ignore.case = TRUE),
    fake_summary_base = gsub("\\[\\s*B-hallucinated\\]", "\\[B-hallucinated\\]", fake_summary_base, ignore.case = TRUE),
    fake_summary_base = gsub("\\[b-hallucinated\\]", "\\[B-hallucinated\\]", fake_summary_base),
    fake_summary_base = gsub("\\[e-hallucinated\\]", "\\[B-hallucinated\\]", fake_summary_base),
    fake_summary_base = gsub("\\[B-hallucinated\\]", "", fake_summary_base), 
    fake_summary_base = gsub("\\[E-hallucinated\\]", "", fake_summary_base),
  )

# extract remaining hallucinated


b_vers <- c("anB-hallucinated", "\\/B-hallucinated", "BB-hallucinated",
            "aB-hallucinated", "dB-hallucinated", "50B-hallucinated", 
            "B-B-hallucinated", "\\$B-hallucinated"
)

e_vers <- c("Es-hallucinated", "hallucinated", "\\/E-hallucinated",
            "\\/hallucinated", "-E-hallucinated", "a\\/E-hallucinated",
            "EB-hallucinated", "E-E-hallucinated", "BE-hallucinated", 
            "B-E-hallucinated", "EE-hallucinated", "\\(E-hallucinated", 
            "cE-hallucinated", "EB-hallucinated", "\\$E-hallucinated"
)

b_pattern <- paste0("\\b(", paste(b_vers, collapse = "|"), ")\\b")
e_pattern <- paste0("\\b(", paste(e_vers, collapse = "|"), ")\\b")


b_brackets <- c("\\]B-hallucinated", "\\[Some\\]B-hallucinated")
                
e_brackets <-  c("E\\[hallucinated\\]", "\\]E-hallucinated")


b_bracket_pattern <- paste0("(", paste(b_brackets, collapse = "|"), ")")
e_bracket_pattern <- paste0("(", paste(e_brackets, collapse = "|"), ")")



manual_check_prep <- manual_check_prep %>%
  mutate(
    fake_summary_base = gsub(b_pattern, "B-hallucinated", fake_summary_base, perl = TRUE, ignore.case = TRUE),
    fake_summary_base = gsub(e_pattern, "E-hallucinated", fake_summary_base, perl = TRUE, ignore.case = TRUE),
    
    fake_summary_base = gsub(e_bracket_pattern, "\\[E-hallucinated\\]", fake_summary_base, perl = TRUE, ignore.case = TRUE),
    fake_summary_base = gsub(b_bracket_pattern, "\\[B-hallucinated\\]", fake_summary_base, perl = TRUE, ignore.case = TRUE),
    
    
    fake_summary_base = gsub(" hallucinated ", "E-hallucinated", fake_summary_base, perl = TRUE, ignore.case = TRUE),
    fake_summary_base = gsub("[A,C,D,F-Z]-hallucinated", "E-hallucinated", fake_summary_base, perl = TRUE, ignore.case = TRUE),
    fake_summary_base = gsub("[A-Z]-E-hallucinated", "E-hallucinated", fake_summary_base, perl = TRUE, ignore.case = TRUE),
    fake_summary_base = gsub("[A-Z]-E-hallucinated", "E-hallucinated", fake_summary_base, perl = TRUE, ignore.case = TRUE),

    fake_summary_base = gsub("[A-Z]E-hallucinated", "E-hallucinated", fake_summary_base, perl = TRUE, ignore.case = TRUE),
    fake_summary_base = gsub("[A-Z]B-hallucinated", "B-hallucinated", fake_summary_base, perl = TRUE, ignore.case = TRUE),
    
    # Fix partial or missing brackets for E-hallucinated
    fake_summary_base = gsub("\\[?E-hallucinated\\]?", "[E-hallucinated]", fake_summary_base, perl = TRUE),
    
    # Fix partial or missing brackets for B-hallucinated
    fake_summary_base = gsub("\\[?B-hallucinated\\]?", "[B-hallucinated]", fake_summary_base, perl = TRUE),
    
    
    # apply old filters
    fake_summary_base = gsub("\\[E-hallucinated \\]", "\\[E-hallucinated\\]", fake_summary_base, ignore.case = TRUE),
    fake_summary_base = gsub("\\[ E-hallucinated\\]", "\\[E-hallucinated\\]", fake_summary_base, ignore.case = TRUE),
    fake_summary_base = gsub("\\[B-hallucinated \\]", "\\[B-hallucinated\\]", fake_summary_base, ignore.case = TRUE),
    fake_summary_base = gsub("\\[ B-hallucinated\\]", "\\[B-hallucinated\\]", fake_summary_base, ignore.case = TRUE),
    fake_summary_base = gsub("\\[b-hallucinated\\]", "\\[B-hallucinated\\]", fake_summary_base),
    fake_summary_base = gsub("\\[e-hallucinated\\]", "\\[B-hallucinated\\]", fake_summary_base),
    fake_summary_base = gsub("\\[B-hallucinated\\]", "", fake_summary_base), 
    fake_summary_base = gsub("\\[E-hallucinated\\]", "", fake_summary_base),
    
  )


rem_hal <- unlist(str_extract_all(manual_check_prep$fake_summary_base, "\\S*hallucinated\\S*"))
#write.csv2(data.frame(unique(rem_hal)), file = "data_checks/rem_tokens.csv", row.names = FALSE)


######## Check Remaining brackets ----

manual_check_prep <- manual_check_prep %>%
  mutate(
    fake_summary_base = gsub("\\[original.*?\\]", "", fake_summary_base, perl = TRUE, ignore.case = TRUE),
    fake_summary_base = gsub("\\[original text altered to include", "", fake_summary_base, perl = TRUE, ignore.case = TRUE),
    fake_summary_base = gsub("\\[No changes here.*?\\]", "", fake_summary_base, perl = TRUE, ignore.case = TRUE),
    fake_summary_base = gsub("\\[WASTE-REMOVED FROM ORIGINAL TEXT AND ADDED BY ME BUT WILL BE.*?\\]\\[/WASTE-REMOVED.*?\\]\\$", "", 
                             fake_summary_base, perl = TRUE, ignore.case = TRUE),
    fake_summary_base = ifelse(grepl("summary", fake_summary_base, ignore.case = TRUE), FALSE, fake_summary_base),
    fake_summary_base = gsub("\\[", "\\(", fake_summary_base, perl = TRUE, ignore.case = TRUE),
    fake_summary_base = gsub("\\]", "\\)", fake_summary_base, perl = TRUE, ignore.case = TRUE),
    fake_summary_base = gsub("\\( ", "", fake_summary_base, perl = TRUE, ignore.case = TRUE),
    fake_summary_base = gsub(" \\)", "", fake_summary_base, perl = TRUE, ignore.case = TRUE)
    ) 

write.csv2(manual_check_prep %>% select(fake_summary_base, id_fake), file = "data_checks/data.csv", row.names = FALSE)


# Final Clean Up
cleaned_data <- manual_check_prep %>%
  mutate(
    # Remove unclosed brackets: "(" without a matching ")"
    fake_summary_base = str_replace_all(fake_summary_base, "\\($", ""),
    
    # Remove standalone special characters like / or $, not connected to words or dashes
    fake_summary_base = str_replace_all(fake_summary_base, "(?<!\\w|-)\\$|/|\\$(?!\\w|-)", ""),
    
    # Remove extra spaces caused by replacements
    fake_summary_base = str_trim(str_squish(fake_summary_base))
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
