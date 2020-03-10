library(tidyverse)

census <- read_csv("data/census_2010.csv")
ss_male <- read_tsv("data/male_names.tsv")
ss_female <- read_tsv("data/female_names.tsv")

census_cleaned <- 
  census %>% 
  mutate(name = str_to_lower(name)) %>% 
  mutate_at(vars(pctwhite:pcthispanic), ~ as.numeric(.x) / 100) %>% 
  mutate(nonwhite = 1 - pctwhite) %>% 
  # low counts were replaced with "(S)" in the original data
  mutate_at(vars(pctwhite:pcthispanic), 
            ~ if_else(is.na(.x), 0, .x)) %>% 
  transmute(name,
            white = pctwhite,
            black = pctblack,
            asian = pctapi,
            hispanic = pcthispanic,
            other = pctaian + pct2prace,
            nonwhite)

# Looks ok for most common names, potential bias from "inflating" other pcts
census_cleaned %>% 
  rowid_to_column("rank") %>% 
  mutate(tot_pct = white + black + asian + hispanic + other) %>% 
  ggplot() +
  geom_point(aes(x = rank, y = tot_pct), alpha = 0.01)

write_csv(census_cleaned, "data/census_2010_cleaned.csv")

ss_male_1980 <-
  ss_male %>% 
  mutate(name = str_to_lower(name)) %>% 
  filter(year == 1980) %>% 
  select(-year)

ss_female_1980 <-
  ss_female %>% 
  mutate(name = str_to_lower(name)) %>% 
  filter(year == 1980) %>% 
  select(-year)

ss_all_1980 <-
  full_join(ss_male_1980, ss_female_1980, 
            by = "name", suffix = c("_male", "_female")) %>% 
  mutate_at(vars(c(count_male, count_female)), 
            ~ if_else(is.na(.x), 0, .x)) %>% 
  mutate(pct_male = count_male / (count_male + count_female),
         pct_female = 1 - pct_male)

# 1980 names are pretty "gendered" 
ss_all_1980 %>%
  ggplot() +
  geom_histogram(aes(x = pct_male), bins = 100)

ss_all_1980 %>% 
  select(name, pct_male, pct_female) %>% 
  write_csv("data/1980_names.csv")
  