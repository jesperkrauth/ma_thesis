## Load libraries
library(tidyverse)
library(readr)
library(lubridate)
library(zoo)
library(tokenizers)
library(ggplot2)
library(scales)

## Figure 2: Star Power Distribution
star_power <- read_csv('../../gen/data-preparation/output/star_power.csv')
figure2 <- ggplot(star_power, aes(x=star_power/1000000)) + 
  geom_histogram(colour="black", fill="orange2") + 
  theme_bw() + 
  labs(x = "Star Power (in millions)", y = "Count")
figure2
ggsave("../../gen/analysis/output/figure2.png", figure2)

## In-text citation: Check whether top 3 star power movies also make most box office in the end
complete <- read_csv('../../gen/data-preparation/output/complete.csv')
temp <- complete %>% group_by(movie_id) %>% select(foreign_total_gross, domestic_total_gross) %>% distinct()


# Table 4: Descriptive Statistics
lmdata <- complete %>% select(t, movie_id, gross_box_office, lag_cum_tweets, lag_pos_neg_ratio, pre_release_volume, pre_pos_neg_ratio, lag_cumadspend, day_of_release, genre, star_power, production_budget_monetary, metascore, week_number, day_of_release, star_power)
lmdata <- lmdata %>% rename(production_budget = production_budget_monetary)
options(scipen=999)
summary(lmdata$gross_box_office)
sd(lmdata$gross_box_office)
summary(lmdata$lag_cum_tweets)
sd(lmdata$lag_cum_tweets)
summary(lmdata$lag_pos_neg_ratio)
sd(lmdata$lag_pos_neg_ratio)
summary(lmdata$pre_release_volume)
sd(lmdata$pre_release_volume)
summary(lmdata$pre_pos_neg_ratio)
sd(lmdata$pre_pos_neg_ratio)
summary(lmdata$lag_cumadspend)
sd(lmdata$lag_cumadspend)
temp <- lmdata %>% select(movie_id, star_power) %>% distinct()
summary(temp$star_power)
sd(temp$star_power)
temp <- lmdata %>% select(movie_id, production_budget) %>% distinct()
summary(temp$production_budget)
sd(temp$production_budget, na.rm = TRUE)
temp <- lmdata %>% select(movie_id, metascore) %>% distinct()
summary(temp$metascore)
sd(temp$metascore, na.rm = TRUE)


# FIGURES 3&4 WITH BOTH AVG. GROSS BOX OFFICE & AVG. 
figuredata <- complete %>% select(box_office, day_of_release, totaltweets, daily_pos_neg_ratio)
meanboxoffice <- figuredata %>% group_by(day_of_release) %>% summarize(mean_box_office = mean(box_office))
meanwomvolume <- figuredata %>% group_by(day_of_release) %>% summarize(mean_wom_volume = mean(totaltweets))
meanwomvalence <- figuredata %>% group_by(day_of_release) %>% summarize(mean_wom_valence = mean(daily_pos_neg_ratio))
figuredata2 <- meanboxoffice %>% left_join(meanwomvolume, by = "day_of_release")
figuredata2 <- figuredata2 %>% left_join(meanwomvalence, by = "day_of_release")

figuredata3 <- figuredata2 %>% filter(day_of_release <= 21)
figuredata3 <- figuredata3 %>% mutate(lag_mean_wom_volume = lag(mean_wom_volume))
figuredata3 <- figuredata3 %>% mutate(lag_mean_wom_valence = lag(mean_wom_valence))

figure3 <- ggplot(figuredata3, aes(x = day_of_release)) + 
  geom_line(aes(y = lag_mean_wom_volume, color = "Daily lagged average Tweet volume")) + 
  geom_line(aes(y = mean_box_office/500, color = "Daily average box office")) + 
  scale_y_continuous(
    name = "WOM Volume (Number of Tweets)",
    sec.axis = sec_axis(~.*500, name = "Box Office (USD)")
  ) +
  labs(x = "Days in Cinema") + 
  scale_color_manual(values = c("orange2", "gray30")) + 
  theme_bw()
figure3
ggsave("../../gen/analysis/output/figure3.png", figure3)  

figure4 <- ggplot(figuredata3, aes(x = day_of_release)) + 
  geom_line(aes(y = lag_mean_wom_valence, color = "Daily lagged average positive-negative ratio")) + 
  geom_line(aes(y = mean_box_office/500000, color = "Daily average box office")) + 
  scale_y_continuous(
    name = "WOM Valence (Positive-Negative Ratio)",
    sec.axis = sec_axis(~.*500000, name = "Box Office (USD)")
  ) +
  labs(x = "Days in Cinema") + 
  scale_color_manual(values = c("orange2", "gray30")) + 
  theme_bw()
figure4
ggsave("../../gen/analysis/output/figure4.png", figure4)  


