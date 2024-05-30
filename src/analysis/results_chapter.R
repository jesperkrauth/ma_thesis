### Load libraries for data cleaning ###
library(tidyverse)
library(car)
library(fixest)
options(scipen=99999)

# Read data
complete <- read_csv("../../gen/data-preparation/output/complete.csv")
lmdata <- complete %>% select(t, movie_id, gross_box_office, lag_cum_tweets, lag_pos_neg_ratio, pre_release_volume, pre_pos_neg_ratio, lag_cumadspend, day_of_release, genre, star_power, production_budget_monetary, metascore, week_number, day_of_release, star_power, weeks_since_release, domestic_total_gross)

# Add NA for lagged values equal to 0
lmdata$lag_cum_tweets[lmdata$lag_cum_tweets == 0] <- NA
lmdata$lag_pos_neg_ratio[lmdata$lag_pos_neg_ratio == 0] <- NA
lmdata$lag_cumadspend[lmdata$lag_cumadspend == 0] <- NA

# Change scale of some variables for clarity
lmdata$pre_release_volume <- lmdata$pre_release_volume/1000000
lmdata$lag_cumadspend <- lmdata$lag_cumadspend/1000000
lmdata$star_power <- lmdata$star_power/1000000000
lmdata$production_budget_monetary <- lmdata$production_budget_monetary/10000000

## RESULTS CHAPTER GRAPHS AND DATA
# REGRESSIONS
# MODEL 1: JUST THE MAIN VARIABLES OF INTEREST
lm1 <- lm(log(gross_box_office) ~ log(lag_cum_tweets) + log(lag_pos_neg_ratio), lmdata)
summary(lm1)
vif(lm1)

# MODEL 2: ADD CONTROL VARIABLES, BUT NO FIXED-EFFECTS
lm2 <- lm(log(gross_box_office) ~ log(lag_cum_tweets) + log(lag_pos_neg_ratio) + pre_release_volume + pre_pos_neg_ratio + lag_cumadspend + star_power + production_budget_monetary + metascore, lmdata)
summary(lm2)
vif(lm2)

# MODEL 3: CLUSTER STANDARD ERRORS + FIXED EFFECTS
lm3 <- feols(log(gross_box_office) ~ log(lag_cum_tweets) + log(lag_pos_neg_ratio) + pre_release_volume + pre_pos_neg_ratio + lag_cumadspend + star_power + production_budget_monetary + metascore | week_number + weeks_since_release,
             cluster = ~ movie_id,
             data = lmdata)
summary(lm3)


## Analysis split per genre
genre_split_data <- lmdata

# Group genres
genre_split_data$genre[genre_split_data$genre == "Comedy / Drama"] <- "Comedy" 
genre_split_data$genre[genre_split_data$genre == "Action"] <- "Action / Adventure" 
genre_split_data$genre[genre_split_data$genre == "Action Comedy"] <- "Comedy" 
genre_split_data$genre[genre_split_data$genre == "Horror Comedy"] <- "Comedy" 
genre_split_data$genre[genre_split_data$genre == "Music Drama"] <- "Drama" 
genre_split_data$genre[genre_split_data$genre == "Action Drama"] <- "Drama" 
genre_split_data$genre[genre_split_data$genre == "Action Thriller"] <- "Thriller" 
genre_split_data$genre[genre_split_data$genre == "Crime Drama"] <- "Drama" 
genre_split_data$genre[genre_split_data$genre == "Sports Drama"] <- "Drama" 
genre_split_data$genre[genre_split_data$genre == "Action Fantasy"] <- "Action / Adventure" 
genre_split_data$genre[genre_split_data$genre == "Adventure"] <- "Action / Adventure" 
genre_split_data$genre[genre_split_data$genre == "Family Comedy"] <- "Comedy" 
genre_split_data$genre[genre_split_data$genre == "Period Action"] <- "Action / Adventure" 
genre_split_data$genre[genre_split_data$genre == "Romantic Comedy"] <- "Comedy" 
genre_split_data$genre[genre_split_data$genre == "Western Comedy"] <- "Comedy" 

# Get datasets for regression
genre_split_data <- genre_split_data %>% filter(genre == "Comedy" | genre == "Drama" | genre == "Action / Adventure" | genre == "Thriller" | genre == "Animation" | genre == "Horror")
comedy <- genre_split_data %>% filter(genre == "Comedy")
drama <- genre_split_data %>% filter(genre == "Drama")
actionadventure <- genre_split_data %>% filter(genre == "Action / Adventure")
thriller <- genre_split_data %>% filter(genre == "Thriller")
animation <- genre_split_data %>% filter(genre == "Animation")
horror <- genre_split_data %>% filter(genre == "Horror")

# Regressions per genre
lm_comedy <- feols(log(gross_box_office) ~ log(lag_cum_tweets) + log(lag_pos_neg_ratio) + pre_release_volume + pre_pos_neg_ratio + lag_cumadspend + star_power + production_budget_monetary + metascore | week_number + weeks_since_release,
             cluster = ~ movie_id,
             data = comedy)
summary(lm_comedy)

lm_drama <- feols(log(gross_box_office) ~ log(lag_cum_tweets) + log(lag_pos_neg_ratio) + pre_release_volume + pre_pos_neg_ratio + lag_cumadspend + star_power + production_budget_monetary + metascore | week_number + weeks_since_release,
                   cluster = ~ movie_id,
                   data = drama)
summary(lm_drama)

lm_actionadventure <- feols(log(gross_box_office) ~ log(lag_cum_tweets) + log(lag_pos_neg_ratio) + pre_release_volume + pre_pos_neg_ratio + lag_cumadspend + star_power + production_budget_monetary + metascore | week_number + weeks_since_release,
                  cluster = ~ movie_id,
                  data = actionadventure)
summary(lm_actionadventure)

lm_thriller <- feols(log(gross_box_office) ~ log(lag_cum_tweets) + log(lag_pos_neg_ratio) + pre_release_volume + pre_pos_neg_ratio + lag_cumadspend + star_power + production_budget_monetary + metascore | week_number + weeks_since_release,
                            cluster = ~ movie_id,
                            data = thriller)
summary(lm_thriller)

lm_animation <- feols(log(gross_box_office) ~ log(lag_cum_tweets) + log(lag_pos_neg_ratio) + pre_release_volume + pre_pos_neg_ratio + lag_cumadspend + star_power + production_budget_monetary + metascore | week_number + weeks_since_release,
                     cluster = ~ movie_id,
                     data = animation)
summary(lm_animation)


lm_horror <- feols(log(gross_box_office) ~ log(lag_cum_tweets) + log(lag_pos_neg_ratio) + pre_release_volume + pre_pos_neg_ratio + lag_cumadspend + star_power + production_budget_monetary + metascore | week_number + weeks_since_release,
                      cluster = ~ movie_id,
                      data = horror)
summary(lm_horror)



## Figure 5 bar chart with average box office for all 6 genres
temp <- genre_split_data %>% group_by(movie_id, genre, domestic_total_gross) %>% count() %>% group_by(genre) %>% mutate(mean_box_office = mean(domestic_total_gross)) %>% select(genre, mean_box_office) %>% distinct()
figure5 <- ggplot(temp, aes(x = genre, y = mean_box_office/1000000)) + 
  geom_bar(stat = "identity", color = "black", fill = "orange2") + 
  labs(x = "Genre", y = "Mean Domestic Box Office (in millions USD)") + 
  theme_bw() + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
figure5
ggsave("../../gen/analysis/output/figure5.png", figure5)  
