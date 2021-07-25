# here we are taking a set of words and hitting the google ngram
# api

# sampling frame: moby dick text
# take a pilot survey to get a sense of the S for each stratum
# also find out what is the N for each stratum
# then we will do a neyman allocation to do a sample

library(rjson)
library(ggplot2)
library(dplyr)
library(lubridate)
library(purrr)

options(scipen = 999)

get_google_ngram_url <- function(words_vec, date1, date2) {
  paste0(
    "https://books.google.com/ngrams/json?content=",
    paste0(words_vec, collapse ="%2C"),
    paste0("&year_start=",date1,"&year_end=",date2,"&corpus=26&smoothing=0&direct_url=t1%3B%2C"),
    paste0(words_vec, collapse ="%3B%2Cc0%3B.t1%3B%2C"),
    "%3B%2Cc0"
  )
}

# read in the pilot sample
words <- read.csv("moby_dick_sample.csv")
# read in entire book
full_words <- read.csv("moby_dick.csv") %>% 
  filter(!(part_of_speech %in% c("PUNCT","NUM","CCONJ","SYM"))) %>% 
  select(-X) %>% 
  distinct()

words <- words %>% 
  filter(!(part_of_speech %in% c("PUNCT","NUM","CCONJ","SYM"))) %>% 
  select(-X) %>% 
  distinct()

words_split <- split(words,words$part_of_speech)

# hit the API for the old timey data
words_ngram_data_1851 <- map(
  words_split,
  function(data) {
    words_url <- get_google_ngram_url(data$word,"1850","1851")
    words_ngram_data <- rjson::fromJSON(file = words_url)
    return(words_ngram_data)
  }
)

# hit the API for the contemporary data
words_ngram_data_2021 <- map(
  words_split,
  function(data) {
    words_url <- get_google_ngram_url(data$word,"2018","2019")
    words_ngram_data <- rjson::fromJSON(file = words_url)
    return(words_ngram_data)
  }
)

# data wrangle the API results to a convenvenient data frame
ngram_data_old <- data.frame()  

for (i in 1:length(words_ngram_data_1851)) {
  for (j in 1:length(words_ngram_data_1851[[i]])) {
    tmp <- data.frame(
      word = words_ngram_data_1851[[i]][[j]]$ngram,
      time = c("1850-01-01","1851-01-01"),
      val = as.numeric(words_ngram_data_1851[[i]][[j]]$timeseries)
    )
    ngram_data_old <- ngram_data_old %>% 
      bind_rows(tmp)
    
  }
}

ngram_data_recent <- data.frame()  

for (i in 1:length(words_ngram_data_2021)) {
  for (j in 1:length(words_ngram_data_2021[[i]])) {
    
    tmp <- data.frame(
      word = words_ngram_data_2021[[i]][[j]]$ngram,
      time = c("2018-01-01","2019-01-01"),
      val = as.numeric(words_ngram_data_2021[[i]][[j]]$timeseries)
    )
    ngram_data_recent <- ngram_data_recent %>% 
      bind_rows(tmp)
    
  }
}

ngram_data_recent2 <- ngram_data_recent %>% 
  filter(time == "2019-01-01")

ngram_data_old2 <- ngram_data_old %>% 
  filter(time == "1851-01-01")

recent_mean <- ngram_data_recent2 %>% 
  summarise(val = mean(val))
old_mean <- ngram_data_old2 %>% 
  summarise(val = mean(val))

# calculate the change in the prevalence of the word over the time
# this will be the data used
df_diff <- ngram_data_old2 %>% 
  left_join(ngram_data_recent2, by = "word") %>% 
  mutate(
    val.x = if_else(val.x == 0.0000000000000000,old_mean$val,val.x),
    val.y = if_else(val.y == 0.0000000000000000,recent_mean$val,val.y)
    ) %>% 
  mutate(diff = (val.y - val.x)/val.x)


df_diff_summary <- df_diff %>% 
  left_join(words, by = "word") %>% 
  group_by(part_of_speech) %>% 
  summarise(
    count = n(),
    diff_mean = mean(diff),
    sd_diff = sd(diff),
    S = var(diff)
  )

# we need to change the strata so that some are not too small


full_words_strat <- full_words %>% 
  mutate(
    part_of_speech = if_else(
      part_of_speech %in% c("ADP","AUX","DET","INTJ","PART","PRON","SCONJ","X","SYM"),
      "OTHER",
      part_of_speech
    )
  ) 

words_strat <- words %>% 
  mutate(
    part_of_speech = if_else(
      part_of_speech %in% c("ADP","AUX","DET","INTJ","PART","PRON","SCONJ","X","SYM"),
      "OTHER",
      part_of_speech
    )
  ) 

df_diff_summary2 <- df_diff %>% 
  left_join(words_strat, by = "word") %>% 
  group_by(part_of_speech) %>% 
  summarise(
    count = n(),
    diff_mean = mean(diff),
    sd_diff = sd(diff),
    S = var(diff)
  )

N <- full_words_strat %>% 
  count(part_of_speech) %>% 
  rename(N = n)

n <- 250

neyman_alloc <- df_diff_summary2 %>% 
  filter(!(part_of_speech %in% c("SYM"))) %>% 
  left_join(N, by = "part_of_speech") %>% 
  mutate(
    neyman_alloc = n*(N*S/sum(N*S)),
    neyman_alloc_round = ceiling(neyman_alloc)
  )


# we then sample again from the full text with this amount

full_words_ney <- full_words_strat %>% 
  left_join(neyman_alloc, by = "part_of_speech") %>% 
  filter(!(word %in% c("j","krusensterns")))

full_words_split <- split(full_words_ney, full_words_ney$part_of_speech)


full_sample <- map_df(
  full_words_split,
  function(data) {
    print(unique(data$part_of_speech))
    print(mean(data$neyman_alloc_round))
    data %>% 
      sample_n(mean(.$neyman_alloc_round))
  }
)


full_sample_split <- split(full_sample,full_sample$part_of_speech)

# hit the API for the contemporary data
words_ngram_data_full_sample_old <- map(
  full_sample_split,
  function(data) {
    words_url <- get_google_ngram_url(data$word,"1850","1851")
    print(nrow(data))
    words_ngram_data <- rjson::fromJSON(file = words_url)
    return(words_ngram_data)
  }
)

words_ngram_data_full_sample_recent <- map(
  full_sample_split,
  function(data) {
    words_url <- get_google_ngram_url(data$word,"2018","2019")
    words_ngram_data <- rjson::fromJSON(file = words_url)
    return(words_ngram_data)
  }
)

# data wrangle the API results to a convenvenient data frame
ngram_data_full_sample_recent <- data.frame()  

for (i in 1:length(words_ngram_data_full_sample_recent)) {
  for (j in 1:length(words_ngram_data_full_sample_recent[[i]])) {
    tmp <- data.frame(
      word = words_ngram_data_full_sample_recent[[i]][[j]]$ngram,
      time = c("2018-01-01","2019-01-01"),
      val = as.numeric(words_ngram_data_full_sample_recent[[i]][[j]]$timeseries)
    )
    ngram_data_full_sample_recent <- ngram_data_full_sample_recent %>% 
      bind_rows(tmp)
    
  }
}

ngram_data_full_sample_old <- data.frame()  

for (i in 1:length(words_ngram_data_full_sample_old)) {
  for (j in 1:length(words_ngram_data_full_sample_old[[i]])) {
    tmp <- data.frame(
      word = words_ngram_data_full_sample_old[[i]][[j]]$ngram,
      time = c("1850-01-01","1851-01-01"),
      val = as.numeric(words_ngram_data_full_sample_old[[i]][[j]]$timeseries)
    )
    ngram_data_full_sample_old <- ngram_data_full_sample_old %>% 
      bind_rows(tmp)
    
  }
}



ngram_data_full_sample_recent2 <- ngram_data_full_sample_recent %>% 
  filter(time == "2019-01-01")

ngram_data_full_sample_old2 <- ngram_data_full_sample_old %>% 
  filter(time == "1851-01-01")


full_recent_mean <- ngram_data_full_sample_recent2 %>% 
  summarise(val = mean(val))
full_old_mean <- ngram_data_full_sample_old2 %>% 
  summarise(val = mean(val))

# calculate the change in the prevalence of the word over the time
# this will be the data used
full_df_diff <- ngram_data_full_sample_old2 %>% 
  left_join(ngram_data_full_sample_recent2, by = "word") %>% 
  mutate(
    val.x = if_else(val.x == 0.0000000000000000,old_mean$val,val.x),
    val.y = if_else(val.y == 0.0000000000000000,recent_mean$val,val.y)
  ) %>% 
  mutate(diff = (val.y - val.x)/val.x)


full_diff_summary <- full_df_diff %>% 
  left_join(full_words_strat, by = "word") %>% 
  group_by(part_of_speech) %>% 
  summarise(
    count = n(),
    diff_mean = mean(diff),
    sd_diff = sd(diff),
    S = var(diff)
  ) %>% 
  left_join(N)

full_diff_summary %>% 
  summarise(
    y_bar_strat = sum(N * diff_mean) / sum(N)
  )
