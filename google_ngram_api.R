# here we are taking a set of words and hitting the google ngram
# api

library(rjson)
library(ggplot2)
library(dplyr)
library(lubridate)

options(scipen = 999)

get_google_ngram_url <- function(words_vec) {
  paste0(
    "https://books.google.com/ngrams/json?content=",
    paste0(words_vec, collapse ="%2C"),
    "&year_start=1800&year_end=2019&corpus=26&smoothing=0&direct_url=t1%3B%2C",
    paste0(words_vec, collapse ="%3B%2Cc0%3B.t1%3B%2C"),
    "%3B%2Cc0"
  )
}

words <- read.csv("moby_dick_test.csv")

words_url <- get_google_ngram_url(words$word)

words_ngram_data <- rjson::fromJSON(file = words_url)
  
data.frame(
  word = words_ngram_data[[1]]$ngram,
  time = ymd("1800-01-01") + years(1:220),
  val = as.numeric(words_ngram_data[[1]]$timeseries)
) %>% 
  ggplot(aes(x= time, y = val, color = word)) +
  geom_line()

