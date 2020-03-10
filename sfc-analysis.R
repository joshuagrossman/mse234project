library(tidyverse)
library(lubridate)
library(stringi)
library(humaniformat)
options(digits = 3)
options(signif = 3)
options(scipen = 999)

data <- read_csv("data/sfc-copy.csv")
names_df <- read_csv("data/1980_names.csv")
census_df <- read_csv("data/census_2010_cleaned.csv")

AUTHOR_REGEX <- "Author\\: ([^\\|]+)"
PAGE_REGEX <- "Page\\: (.+)Word"
WORD_COUNT_REGEX <- "Word Count\\: ([0-9]+)"

extract_match <- function(s, expr) {
  match <- str_match(s, expr)
  match_length <- ncol(match)
  if (match_length == 1) {
    return(NA_character_)
  }
  if (match_length > 2) {
    print(s)
  }
  return(match[,2])
}

article_df <-
  data %>% 
  rowid_to_column("content_id") %>% 
  mutate(author = str_to_lower(map_chr(metadata, extract_match, AUTHOR_REGEX)),
         page = str_to_lower(map_chr(metadata, extract_match, PAGE_REGEX)),
         word_count = map_chr(metadata, extract_match, WORD_COUNT_REGEX),
         month = as.integer(substr(pub_date, 1, 2)),
         day = as.integer(substr(pub_date, 3, 4)),
         year = as.integer(substr(pub_date, 5, 8)))

has_author_df <- filter(article_df, ! is.na(author))

cleaned_author_df <-
  has_author_df %>% 
  mutate(author = stri_trans_general(author, "Latin-ASCII"),
         author = str_replace_all(author, "posted (by)? ?(on)?", ""),
         author = str_replace_all(author, " (and|&) ", "\\|"),
         author = str_replace_all(author, ", ", "\\|"),
         author = str_replace_all(author, "[a-z]\\. ?", ""),
         author = str_replace_all(author, "van ", "van"),
         author = str_replace_all(author, "o\\'", "o"))

author_split_df <-
  cleaned_author_df %>% 
  separate_rows(author, sep = "\\|") %>% 
  mutate(author = str_squish(author))

author_split_df %>% 
  filter(str_count(author, " ") > 1)

first_last_df <- 
  author_split_df %>% 
  mutate(author = if_else(author == "", NA_character_, author),
         author = if_else(author == "nevius", "charles nevius", author)) %>% 
  mutate(first_names = first_name(author),
         last_names = last_name(author)) %>% 
  mutate(last_names = str_replace_all(last_names, "\\-[a-z]+", ""),
         first_names = str_replace_all(first_names, "\\-", ""))

remove_missing_names_df <-
  first_last_df %>% 
  filter(! (is.na(first_names) | is.na(last_names)))

remove_missing_names_df %>% 
  group_by(first_names, last_names) %>% 
  summarize(n = n()) %>% 
  arrange(desc(n)) 

census_ss_joined_df <-
  remove_missing_names_df %>% 
  left_join(census_df, 
            by = c("last_names" = "name")) %>% 
  left_join(names_df,
            by = c("first_names" = "name"))

# 14.5% of authored content doesn't match the census race data
mean(is.na(census_ss_joined_df$white))

# 4.8% of content doens't match SS baby names
mean(is.na(census_ss_joined_df$pct_male))

census_ss_joined_df %>% 
  group_by(first_names, last_names) %>% 
  summarize(n = n(),
            white = mean(white),
            pct_male = mean(pct_male)) %>% 
  arrange(desc(n))

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
  left_join(article_df, ., by = "content_id")

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
