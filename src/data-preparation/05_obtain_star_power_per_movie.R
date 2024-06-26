# Load libraries
library(readr)
library(tidyverse)
library(quantmod)

# Read files
imdbmovieinfoperactor <- read_csv('../../gen/data-preparation/output/imdbmovieinfoperactor.csv') %>% select(-...1)
imdbboxofficepermovie <- read_csv('../../gen/data-preparation/output/imdbboxofficepermovie.csv') %>% select(-...1)

# Join datasets
star_power <- imdbmovieinfoperactor %>% left_join(imdbboxofficepermovie, by = c("movie_name", "movie_url"))
star_power <- star_power %>% distinct() # Remove duplicates
star_power <- star_power %>% select(-gross_worldwide)
star_power <- star_power %>% na.omit() # Remove NAs
star_power <- star_power %>% select(actor_name, movie_name, year, gross_domestic)

# Convert production budget numbers
convert_monetary <- function(money_string) {
  # Remove non-numeric characters
  cleaned_string <- gsub("[^0-9.]", "", money_string)
  # Convert string to numeric
  numeric_value <- as.numeric(cleaned_string)
  
  # Check if "million" or "billion" is mentioned, and adjust accordingly
  if (grepl("million", tolower(money_string))) {
    numeric_value <- numeric_value * 10^6
  } else if (grepl("billion", tolower(money_string))) {
    numeric_value <- numeric_value * 10^9
  } else if (grepl("trillion", tolower(money_string))) {
    numeric_value <- numeric_value * 10^12
  }
  
  return(numeric_value)
}

# Convert to monetary
star_power$gross_domestic <- sapply(star_power$gross_domestic, convert_monetary)

# Get CPI values
symbol <- "CPIAUCNS"
getSymbols(symbol, src = "FRED")
head(CPIAUCNS)
yearly_cpi <- apply.yearly(CPIAUCNS, mean)
cpi_values <- c(`2010` = 218.056, `2011` = 224.939, `2012` = 229.594, `2013` = 233.049)
yearly_cpi$CPIAUCNS
years <- as.numeric(format(index(yearly_cpi), "%Y"))
cpi_values <- setNames(coredata(yearly_cpi), as.character(years))

# Convert prices to 2014 USD
convert_to_2014_usd <- function(gross_domestic, year) {
  # Define CPI values for each year as a named vector

  # Calculate inflation factor relative to 2013
  inflation_factor <- cpi_values[as.character(year)] / cpi_values["2014"]
  
  # Convert prices to 2013 USD
  prices_2014_usd <- gross_domestic / inflation_factor
  
  return(prices_2014_usd)
}

# Convert monetary sums to 2014 USD
star_power$gross_domestic_2014 <- round(convert_to_2014_usd(star_power$gross_domestic, star_power$year),0)
options(scipen=999)

# Discount 2014 values w/ 0.8 discount factor as 'decay'
discount_box_office <- function(gross_domestic_2014, year, base_year = 2014, discount_rate = 0.8) {
  discount_factor <- discount_rate ^ (base_year - year)
  discounted_value <- gross_domestic_2014 * discount_factor
  return(discounted_value)
}
star_power$discounted_box_office <- with(star_power, discount_box_office(gross_domestic_2014, year))
star_power$discounted_box_office <- round(star_power$discounted_box_office)


# Compute WCIAR star power per actor
wciar_actor <- star_power %>% group_by(actor_name) %>% summarize(sum(discounted_box_office))

# Save WCIAR values
write_csv(wciar_actor, '../../gen/data-preparation/output/wciar_actor.csv')

# Compute star power per movie
actors_per_movie <- read_csv('../../gen/data-preparation/output/imdbactorspermovie.csv') %>% select(-...1)
actors_per_movie <- actors_per_movie %>% left_join(wciar_actor, by = c("actor" = "actor_name"))

# Rename column
actors_per_movie <- actors_per_movie %>% rename('wciar_actor' = 'sum(discounted_box_office)')

# Remove NAs
actors_per_movie <- na.omit(actors_per_movie)

# Compute star power per movie
star_power <- actors_per_movie %>% group_by(movie_id) %>% summarize(star_power = sum(wciar_actor))

# Save star power per movie dataset
write_csv(star_power, '../../gen/data-preparation/output/star_power.csv')

