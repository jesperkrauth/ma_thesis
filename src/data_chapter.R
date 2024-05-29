######################
### DATA CHAPTER #####
######################

## LIBRARIES
library(tidyverse)
library(readr)
library(lubridate)
library(zoo)
library(tokenizers)



### In-text citation: first and last dates in both datasets (book ratings) ###
# Goodreads
goodreads_dates <- read_rds('../../gen/data-preparation/output/goodreads_final.rds')
goodreads_dates %>% arrange(date) %>% head()
goodreads_dates %>% arrange(desc(date)) %>% head()
goodreads_dates %>% group_by(acquisition) %>% summarize(n=n())
# Amazon
amazon_dates <- read_rds('../../gen/data-preparation/output/amazon_final.rds')
amazon_dates %>% arrange(date) %>% head()
amazon_dates %>% arrange(desc(date)) %>% head()
amazon_dates %>% group_by(acquisition) %>% summarize(n=n())

# In-text citation: total number of observations in DiD dataset:
diff_in_diff <- read_rds('../../gen/data-preparation/output/final_diff_in_diff_data.rds')



### TABLE 2 ###
# For Goodreads, before acquisition:
summary(diff_in_diff %>% filter(amazon_dummy == 0 & acquisition == 0))
diff_in_diff %>% filter(amazon_dummy == 0 & acquisition == 0) %>% count()
temp <- diff_in_diff %>% filter(amazon_dummy == 0 & acquisition == 0) %>% select(rating)
mean(temp$rating)
sd(temp$rating)

# For Goodreads, after acquisition:
summary(diff_in_diff %>% filter(amazon_dummy == 0 & acquisition == 1))
diff_in_diff %>% filter(amazon_dummy == 0 & acquisition == 1) %>% count()
temp <- diff_in_diff %>% filter(amazon_dummy == 0 & acquisition == 1) %>% select(rating)
mean(temp$rating)
sd(temp$rating)

# For Amazon, before acquisition:
summary(diff_in_diff %>% filter(amazon_dummy == 1 & acquisition == 0))
diff_in_diff %>% filter(amazon_dummy == 1 & acquisition == 0) %>% count()
temp <- diff_in_diff %>% filter(amazon_dummy == 1 & acquisition == 0) %>% select(rating)
mean(temp$rating)
sd(temp$rating)

# For Amazon, after acquisition:
summary(diff_in_diff %>% filter(amazon_dummy == 1 & acquisition == 1))
diff_in_diff %>% filter(amazon_dummy == 1 & acquisition == 1) %>% count()
temp <- diff_in_diff %>% filter(amazon_dummy == 1 & acquisition == 1) %>% select(rating)
mean(temp$rating)
sd(temp$rating)



### FIGURE 2 ###
# Create dataset with column for average Goodreads and average Amazon ratings over time
temp <- diff_in_diff %>% filter(amazon_dummy == 0) %>% group_by(t) %>% summarize(mean_goodreads = mean(rating), n_obs = n()) %>% filter(n_obs>100)
temp2 <- diff_in_diff %>% filter(amazon_dummy == 1) %>% group_by(t) %>% summarize(mean_amazon = mean(rating), n_obs = n()) %>% filter(n_obs>100)
plot_data <- temp %>% left_join(temp2, by = "t") # Goodreads has less observations, so only use values for t present in both
lineplot_avg_rating <- ggplot(plot_data, (aes(x = t))) + 
  geom_line(aes(y = mean_goodreads), color = "red") +
  geom_line(aes(y = mean_amazon), color = "blue") + 
  geom_vline(xintercept = 205.5, linetype = "longdash") + 
  ylab("Mean Rating") + 
  xlab("Number of months since 31 May 1996") + 
  #  ggtitle("Average book rating on Amazon and Goodreads") +
  theme_bw() + 
  annotate("text", x=175, y=4.3, label="Amazon", size = 5.5, color = "blue") + 
  annotate("text", x=164, y = 3.88, label = "Goodreads", size = 5.5, color = "red") + 
  annotate("text", x = 222, y = 4.12, label = "Acquisition", size = 5) +
  theme(plot.title = element_text(hjust = 0.5))
lineplot_avg_rating
dir.create('../../gen')
dir.create('../../gen/analysis')
dir.create('../../gen/analysis/output')
ggsave("../../gen/analysis/output/lineplot_avg_rating.png", lineplot_avg_rating)



# In-text citation: first and last dates in both datasets (sentiment analysis)
vader_sample2 <- read_rds('../../gen/data-preparation/output/vader_sample2.rds')
# Goodreads
vader_sample2 %>% filter(Label == 'Goodreads') %>% arrange(timestamp) %>% head()
vader_sample2 %>% filter(Label == 'Goodreads') %>% arrange(desc(timestamp)) %>% head()
# Amazon
vader_sample2 %>% filter(Label == 'Amazon') %>% arrange(timestamp) %>% head()
vader_sample2 %>% filter(Label == 'Amazon') %>% arrange(desc(timestamp)) %>% head()



### TABLE 4 ###
text_sample_final <- read_rds('../../gen/data-preparation/output/text_sample_final.rds')
text_sample_final$length <- count_words(text_sample_final$reviewText)

# Goodreads, before merger
summary(text_sample_final %>% filter(Label == "Goodreads" & after == 0)) 
text_sample_final %>% filter(Label == "Goodreads" & after == 0) %>% count()
temp <- text_sample_final %>% filter(Label == "Goodreads" & after == 0) %>% select(length)
sd(temp$length)

# Goodreads, after merger
summary(text_sample_final %>% filter(Label == "Goodreads" & after == 1)) 
text_sample_final %>% filter(Label == "Goodreads" & after == 1) %>% count()
temp <- text_sample_final %>% filter(Label == "Goodreads" & after == 1) %>% select(length)
sd(temp$length)

# Amazon, before merger
summary(text_sample_final %>% filter(Label == "Amazon" & after == 0)) 
text_sample_final %>% filter(Label == "Amazon" & after == 0) %>% count()
temp <- text_sample_final %>% filter(Label == "Amazon" & after == 0) %>% select(length)
sd(temp$length)

# Amazon, after merger
summary(text_sample_final %>% filter(Label == "Amazon" & after == 1)) 
text_sample_final %>% filter(Label == "Amazon" & after == 1) %>% count()
temp <- text_sample_final %>% filter(Label == "Amazon" & after == 1) %>% select(length)
sd(temp$length)



### FIGURE 3 ###
# Add t to dataset
first_date <- as.Date('1998-01-02')
text_sample_final$t <- (as.yearmon(text_sample_final$timestamp) - as.yearmon(first_date))*12
text_sample_final$t <- round(text_sample_final$t, 0)

# Create dataset with column for average Goodreads and average Amazon lengths
temp <- text_sample_final %>% filter(Label == "Goodreads") %>% group_by(t) %>% summarize(mean_length_goodreads = mean(length), n_obs = n()) %>% filter(n_obs>100)
temp2 <- text_sample_final %>% filter(Label == "Amazon") %>% group_by(t) %>% summarize(mean_length_amazon = mean(length), n_obs = n()) %>% filter(n_obs>100)
plot_data <- temp %>% left_join(temp2, by = "t") # Goodreads has less observations, so only use values for t present in both

text_sample_final %>% filter(timestamp == "2013-07-01") # t = 186

lineplot_avg_review_length <- ggplot(plot_data, (aes(x = t))) + 
  geom_line(aes(y = mean_length_goodreads), color = "red") +
  geom_line(aes(y = mean_length_amazon), color = "blue") + 
  geom_vline(xintercept = 186, linetype = "longdash") + 
  ylab("Mean Review Length") + 
  xlab("Number of months since 2 January 1998") + 
  #  ggtitle("Average book rating on Amazon and Goodreads") +
  theme_bw() + 
  annotate("text", x=220, y=35, label="Amazon", size = 5.5, color = "blue") + 
  annotate("text", x=220, y = 155, label = "Goodreads", size = 5.5, color = "red") + 
  annotate("text", x = 170, y = 35, label = "Acquisition", size = 5) +
  theme(plot.title = element_text(hjust = 0.5))
lineplot_avg_review_length
ggsave("../../gen/analysis/output/lineplot_avg_review_length.png", lineplot_avg_review_length)

