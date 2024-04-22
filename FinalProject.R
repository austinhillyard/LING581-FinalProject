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



setwd("../LING581")

reddit = read_csv("dataTest.csv")
setwd("../LING440")

reddit$content = gsub("\\[SEP\\]|\\[CLS\\]", "", reddit$content)

reddit_corpus = corpus(reddit, text_field = 3)


# Word cloud of whole corpus

whole_corpus_tokenized = reddit_corpus %>% tokens(remove_punct = T) %>% 
  tokens_remove(pattern = stopwords("english")) %>% 
  dfm()

png("wordclouds/wholecorpus.png", width = 1800, height = 1200, units = "px")

textplot_wordcloud(whole_corpus_tokenized)
title("Whole corpus", adj = 0, line = -1.5, cex.main = 4)

# Save to image file


dev.off()

# Loop through subreddits and export a wordcloud plot for each one.

for (curr_subreddit in as.list(unique(reddit$subreddit))) {

  subreddit_tokenized = reddit_corpus %>% corpus_subset(subreddit == curr_subreddit) %>% tokens(remove_punct = T) %>% 
    tokens_remove(pattern = stopwords("english")) %>% 
    dfm()
  
  filePath = glue("wordclouds/{curr_subreddit}.png")
  png(filePath, width = 1800, height = 1200, units = "px")
  
  textplot_wordcloud(subreddit_tokenized)
  title(curr_subreddit, adj = 0, line = -1.5, cex.main = 4)
  
  dev.off()

}

# Loop through subreddits and plot a keyness plot for each.


tokenized_corpus = reddit_corpus %>%
  tokens(remove_punct = T) %>% 
  tokens_remove(pattern = stopwords("english")) %>% 
  tokens_group(groups = subreddit)

for (this_subreddit in as.list(unique(reddit$subreddit))) {
  
  print(this_subreddit)
  
  filePath = glue("keynessPlot/{this_subreddit}.png")
  
  tstat_keyness = textstat_keyness(tokenized_corpus, target = this_subreddit)
  plot = textplot_keyness(tstat_keyness)
  
  ggsave(filePath, plot = plot, width = 2400, height = 1800, units = "px")
  
}

# Compute average length of posts, and separately average length of comments, and see if there is a statistical difference between them.

reddit_length = reddit %>% mutate(tokenized_text = tokenizers::tokenize_words(content)) %>% mutate(num_words = sapply(tokenized_text, length))

# Split up dataframes by type after calculating length.

comment_length = reddit_length %>% filter(type == "Comment")

post_length = reddit_length %>% filter(type == "Post")

# Plot comment length

comment_length %>% ggplot(aes(x = subreddit, y = num_words))+
  geom_boxplot(aes(fill = subreddit), outlier.shape = NA)+
  stat_summary(fun.y = mean, shape = 4)+
  labs(title = "Mean comment length by subreddit")+
  scale_y_continuous(limits = quantile(comment_length$num_words, c(0.1, 0.9)))+
  ylab("Number of words in comments")+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90), legend.position = "none")

# Plot post length

post_length %>% ggplot(aes(x = subreddit, y = num_words))+
  geom_boxplot(aes(fill = subreddit),outlier.shape = NA)+
  stat_summary(fun.y = mean, shape = 4)+
  labs(title = "Mean Post length by subreddit")+
  scale_y_continuous(limits = quantile(comment_length$num_words, c(0.1, 0.9)))+
  ylab("Number of words in Post")+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90), legend.position = "none")
  
# Anova analysis on comment length,

result = aov(num_words~subreddit, data = comment_length)
t1 = TukeyHSD(result, ordered = T)

plot(result, 1)

# Filter out results to statistical significance

result_table = t1$subreddit %>% as_tibble(rownames = "comparitors")

print(result_table %>% filter(`p adj` < .05), n=127)

# Anova analysis on post length

result = aov(num_words~subreddit, data = post_length)
t1 = TukeyHSD(result, ordered = T)

plot(result, 2)

result_table = t1$subreddit %>% as_tibble(rownames = "comparitors")

print(result_table %>% filter(`p adj` < .05))


# Get the most common trigam in each subreddit

# Tibble for results
trigrams = tibble(subreddit = character(), trigram = character())


for (curr_subreddit in as.list(unique(reddit$subreddit))) {
  # Get a dataframe of trigrams for the specific subreddit
  trigram_tokens = tokenized_corpus[curr_subreddit] %>% 
    tokens_ngrams(n = 3) %>% 
    dfm()
  
  # Count the frequency of each trigram
  trigram_freq <- colSums(trigram_tokens)
  
  # Identify the most common trigram
  most_common_trigram <- names(sort(trigram_freq, decreasing = TRUE)[1])
  new_row = tibble(subreddit = curr_subreddit, trigram = most_common_trigram)
  trigrams = add_row(trigrams, new_row)
  
}

print(trigrams, n = 22)

leveneTest(num_words~subreddit, data = post_length)
leveneTest(num_words~subreddit, data = comment_length)

# Transform comment length using logarithm to normalize data

clean_comment = remove_outliers(comment_length, "num_words")

log_comment = clean_comment

# Really small value because some values are zero before logarithm
epsilon = 1e-6
log_comment$num_wordsPositive = log_comment$num_words + epsilon
log_comment$num_words = log(log_comment$num_wordsPositive)

# Remove outliers

# Levenetest
leveneTest(num_words~subreddit, data = log_comment)

result = aov(num_words~subreddit, data = log_comment)
plot(result, 2)

t1 = TukeyHSD(result, ordered = T)

plot(result, 2)

result_table = t1$subreddit %>% as_tibble(rownames = "comparitors")

print(result_table %>% filter(`p adj` < .05))
