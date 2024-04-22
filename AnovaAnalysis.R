library(tidyverse)
library(quanteda)
library("quanteda.textplots")
library(quanteda.textstats)
library(readtext)
library(glue)
library(car)

remove_outliers <- function(data, variable, threshold = 1.5) {
  # Calculate the interquartile range (IQR)
  Q1 <- quantile(data[[variable]], 0.25)
  Q3 <- quantile(data[[variable]], 0.75)
  IQR <- Q3 - Q1
  
  # Define the lower and upper bounds for outliers
  lower_bound <- Q1 - threshold * IQR
  upper_bound <- Q3 + threshold * IQR
  
  # Identify outliers
  outliers <- data[[variable]] < lower_bound | data[[variable]] > upper_bound
  
  # Remove outliers from the dataset
  clean_data <- data[!outliers, ]
  
  return(clean_data)
}

print_goodPvalues = function(result, n = 10) {
  t1 = TukeyHSD(result, ordered = T)
  
  result_table = t1$subreddit %>% as_tibble(rownames = "comparitors")
  
  print(result_table %>% filter(`p adj` < .05), n = n)
}

# Read in comment and post length
comment_length = read_csv("comment_length")
post_length = read_csv("post_length")

# Remove outliers
clean_comment_length = remove_outliers(comment_length, "num_words")
clean_post_length = remove_outliers(post_length, "num_words")

# Confirm smaller range
range(comment_length$num_words)
range(clean_comment_length$num_words)

# Check heterorasticity
leveneTest(num_words~subreddit, data = clean_post_length)
leveneTest(num_words~subreddit, data = clean_comment_length)

# Transform data to logarithm
log_comment = clean_comment_length
log_post = clean_post_length

# Remove the values of 0.
log_comment = log_comment %>% filter(num_words > 0)

log_comment$num_words = log(log_comment$num_words)

range(log_comment$num_words)

log_post = log_post %>% filter(num_words > 0)

log_post$num_words = log(log_post$num_words)

range(log_post$num_words)

resultComment = aov(num_words~subreddit, data = log_comment)
plot(resultComment, 2)

resultPost = aov(num_words~subreddit, data = log_post)
plot(resultPost, 2)

print_goodPvalues(resultComment)

print_goodPvalues(resultPost, n = 78)
