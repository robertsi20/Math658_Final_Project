actual <- paste0("https://books.google.com/ngrams/json?content=hello%2Cmy%2Cname%2Cis%2Cbob&year_start=1800&year_end=2019&corpus=26&smoothing=0&direct_url=t1%3B%2Chello%3B%2Cc0%3B.t1%3B%2Cmy%3B%2Cc0%3B.t1%3B%2Cname%3B%2Cc0%3B.t1%3B%2Cis%3B%2Cc0%3B.t1%3B%2Cbob%3B%2Cc0")



words <- c("hello","my","name","is","bob")
test <- paste0(
  "https://books.google.com/ngrams/json?content=",
  paste0(words, collapse ="%2C"),
  "&year_start=1800&year_end=2019&corpus=26&smoothing=0&direct_url=t1%3B%2C",
  paste0(words, collapse ="%3B%2Cc0%3B.t1%3B%2C"),
  "%3B%2Cc0"
)


identical(actual,test)


actual2 <- paste0("https://books.google.com/ngrams/json?content=what%2Cis%2Cyour%2Cname&year_start=1800&year_end=2019&corpus=26&smoothing=0&direct_url=t1%3B%2Cwhat%3B%2Cc0%3B.t1%3B%2Cis%3B%2Cc0%3B.t1%3B%2Cyour%3B%2Cc0%3B.t1%3B%2Cname%3B%2Cc0")
words2 <- c("what","is","your","name")
test2 <- paste0(
  "https://books.google.com/ngrams/json?content=",
  paste0(words2, collapse ="%2C"),
  "&year_start=1800&year_end=2019&corpus=26&smoothing=0&direct_url=t1%3B%2C",
  paste0(words2, collapse ="%3B%2Cc0%3B.t1%3B%2C"),
  "%3B%2Cc0"
)
