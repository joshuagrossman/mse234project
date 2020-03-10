library(tidyverse)
library(lubridate)
library(stringi)
options(digits = 3)
options(signif = 3)
options(scipen = 999)

# word count by gender
# demographic breakdown by first page and section

data <- read_csv("data/nyt-copy.csv")
names_df <- read_csv("data/1980_names.csv")
census_df <- read_csv("data/census_2010_cleaned.csv")

nyt_df <- 
  data %>% 
  rowid_to_column("content_id") %>% 
  mutate(day = day(pub_date),
         month = month(pub_date),
         year = year(pub_date),
         day_of_week = wday(pub_date),
         first_names = if_else(first_names == "none", 
                               NA_character_, first_names),
         last_names = if_else(last_names == "none", 
                              NA_character_, last_names),
         has_author = ! (is.na(first_names) & is.na(last_names)))

################## NO AUTHOR EXPLORATION ######################

# 27% of material doesn't have an author
nyt_df %>% 
  group_by(has_author) %>% 
  summarize(n = n()) %>% 
  ungroup %>% 
  mutate(p = n / sum(n))

nyt_df %>% 
  group_by(has_author) %>% 
  summarize(mean(word_count, na.rm = T))

nyt_df %>% 
  group_by(has_author, document_type) %>% 
  summarize(n())

nyt_df %>% 
  group_by(has_author, type_of_material) %>% 
  summarize(n = n()) %>% 
  arrange(desc(n))

# ~40% of unauthored is Paid Death Notices, sports, and opinion (anonymous?)
nyt_df %>% 
  group_by(has_author, section_name) %>% 
  summarize(n = n()) %>% 
  ungroup %>% 
  group_by(has_author) %>% 
  mutate(p = n / sum(n)) %>% 
  arrange(desc(p))

################ JOINING TO CENSUS AND SEX DATA #################

has_author_df <- filter(nyt_df, has_author)

# Just over 90% of content has only one author
has_author_df %>% 
  mutate(multiple_authors = str_detect(first_names, "\\|")) %>% 
  group_by(multiple_authors) %>% 
  summarize(n = n()) %>% 
  ungroup %>% 
  mutate(p = n / sum(n))

# All content has identical first and last name counts
has_author_df %>% 
  mutate(first_name_count = 1 + str_count(first_names, "\\|"),
         last_name_count = 1 + str_count(first_names, "\\|"),
         same_count = first_name_count == last_name_count) %>% 
  group_by(same_count) %>% 
  summarize(n = n()) %>% 
  ungroup %>% 
  mutate(p = n / sum(n))

# Write function to separate rows with multiple authors
# join census and sex to resulting data frame
# group by content_id and average gender/census columns to reconstruct

authors_split_over_rows_df <- 
  separate_rows(has_author_df, 
                c(first_names, last_names), 
                sep = "\\|")

authors_split_over_rows_df %>% 
  group_by(first_names) %>% 
  summarize(n = n()) %>% 
  arrange(desc(n))

authors_split_over_rows_df %>% 
  group_by(last_names) %>% 
  summarize(n = n()) %>% 
  arrange(desc(n))

census_ss_joined_df <-
  authors_split_over_rows_df %>% 
  mutate(first_names = stri_trans_general(first_names,"Latin-ASCII"),
         last_names = stri_trans_general(last_names,"Latin-ASCII"),
         last_names = str_replace(last_names, "van ", "van"),
         last_names = str_replace(last_names, "o\\'", "o"),
         last_names = str_replace_all(last_names, "\\-[a-z]+", "")) %>% 
  left_join(census_df, 
            by = c("last_names" = "name")) %>% 
  left_join(names_df,
            by = c("first_names" = "name"))

# 21% of content doesn't match the census race data
mean(is.na(census_ss_joined_df$white))

# 8.3% of content doens't match SS baby names
mean(is.na(census_ss_joined_df$pct_male))

census_ss_joined_df %>% 
  group_by(first_names, last_names) %>% 
  summarize(n = n(),
            white = mean(white),
            pct_male = mean(pct_male)) %>% 
  arrange(desc(n)) %>% View()

averaged_df <- 
  census_ss_joined_df %>% 
  group_by(content_id) %>% 
  summarize(white = mean(white),
            black = mean(black),
            asian = mean(asian),
            hispanic = mean(hispanic),
            other = mean(other),
            nonwhite = mean(nonwhite),
            pct_male = mean(pct_male),
            pct_female = mean(pct_female)) %>% 
  ungroup %>% 
  left_join(has_author_df, ., by = "content_id")

averaged_df %>% 
  group_by(year) %>% 
  summarize_at(vars(white:pct_female), mean, na.rm = T) %>%
  pivot_longer(c(pct_male, pct_female), names_to = "stat", values_to = "pct") %>% 
  ggplot() +
  geom_line(aes(x = year, y = pct, color = stat)) + 
  scale_x_continuous(labels = 2010:2020,
                     breaks = 2010:2020) + 
  theme_bw()

averaged_df %>% 
  group_by(year) %>% 
  summarize_at(vars(white:pct_female), mean, na.rm = T) %>%
  pivot_longer(c(white,nonwhite), names_to = "race", values_to = "pct") %>% 
  ggplot() +
  geom_line(aes(x = year, y = pct, color = race)) + 
  scale_x_continuous(labels = 2010:2020,
                     breaks = 2010:2020) + 
  theme_bw()

averaged_df %>% 
  group_by(year) %>% 
  summarize_at(vars(white:pct_female), mean, na.rm = T) %>%
  pivot_longer(white:other, names_to = "race", values_to = "pct") %>% 
  ggplot() +
  geom_line(aes(x = year, y = pct, color = race)) + 
  scale_x_continuous(labels = 2010:2020,
                     breaks = 2010:2020) + 
  theme_bw()

# “Names are not distributed among racial and ethnic groups the same
# way the population is distributed,” Comenetz said. “Also, it takes
# fewer names to cover a large segment of the Hispanic, Asian or black
# populations, compared to the white population, which has higher
# surname diversity.”

# zip_vectors <- function(v1, v2) {
#   n1 <- length(v1)
#   n2 <- length(v2)
#   if (n1 != n2) {
#     warning("Vector lengths differ. Returning NA.")
#     return(NA)
#   }
#   zipped_list = list()
#   for (i in 1:n1) {
#     zipped_list[[i]] = c(v1[i], v2[i])
#   }
#   return(zipped_list)
# }
# 
# names_split_df <-
#   has_author_df %>% 
#   mutate(first_names_list = str_split(first_names, "\\|"),
#          last_names_list = str_split(last_names, "\\|"),
#          full_name_list = map2(first_names_list, 
#                                last_names_list, 
#                                zip_vectors))
# 
# authors_split_over_rows_df <- 
#   names_split_df %>% 
#   unnest(full_name_list)
  




# remove bloomberg from author names, look up most common authors
# and remove generic news sources
# bloomberg, international, dealbook, photographs

# add columns for expected fraction male and expected fraction female
# sum(prob_male)/n_male and sum(prob_female)/n_female

data %>% 
  group_by(news_desk) %>% 
  summarize(n = n()) %>% 
  ungroup() %>% 
  mutate(p = n / sum(n)) %>% 
  arrange(desc(n)) %>% 
  View()

data %>% 
  group_by(section_name) %>% 
  summarize(n = n()) %>% 
  ungroup() %>% 
  mutate(p = n / sum(n)) %>% 
  arrange(desc(n)) %>% 
  View()

data %>% 
  group_by(print_page) %>% 
  summarize(n = n()) %>% 
  ungroup() %>% 
  mutate(p = n / sum(n)) %>% 
  arrange(desc(n)) %>% 
  View()

data %>% 
  group_by(document_type) %>% 
  summarize(n = n()) %>% 
  ungroup() %>% 
  mutate(p = n / sum(n)) %>% 
  arrange(desc(n)) %>% 
  View()

data %>% 
  group_by(type_of_material) %>% 
  summarize(n = n()) %>% 
  ungroup() %>% 
  mutate(p = n / sum(n)) %>% 
  arrange(desc(n)) %>% 
  View()
  
