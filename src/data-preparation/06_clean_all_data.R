### Load libraries for data cleaning ###
library(tidyverse) # read csv
library(janitor)  # clean names

# Load data
folder_path <- "../../data/twitter_stats/chicago/hourly-0.05/counts"
csv_files <- list.files(folder_path, full.names = TRUE)
all_datasets <- list()
crosswalk <- read_csv("../../data/crosswalk/chicago_mojo.csv")
charac2014 <- read_csv("../../data/mojo/charac/movie-charac-wide-2014.csv")
charac2015 <- read_csv("../../data/mojo/charac/movie-charac-wide-2015.csv")
characcomplete <- rbind(charac2014, charac2015)

# Function to transform dates in boxofficedata datasets
transform_date <- function(date_str) {
  # Remove any extra spaces
  date_str <- gsub("\\s+", " ", date_str)
  # Remove spaces between month and dot
  date_str <- gsub("(\\b\\w{3}) \\. ", "\\1. ", date_str)
  # Replace abbreviated month names with full names
  date_str <- gsub("Jan\\.", "January", date_str)
  date_str <- gsub("Feb\\.", "February", date_str)
  date_str <- gsub("Mar\\.", "March", date_str)
  date_str <- gsub("Apr\\.", "April", date_str)
  date_str <- gsub("May", "May", date_str)
  date_str <- gsub("Jun\\.", "June", date_str)
  date_str <- gsub("Jul\\.", "July", date_str)
  date_str <- gsub("Aug\\.", "August", date_str)
  date_str <- gsub("Sep\\.", "September", date_str)
  date_str <- gsub("Oct\\.", "October", date_str)
  date_str <- gsub("Nov\\.", "November", date_str)
  date_str <- gsub("Dec\\.", "December", date_str)
  # Convert to Date object
  date <- as.Date(date_str, format = "%B %d, %Y")
  # Format Date object to desired format
  formatted_date <- format(date, "%Y-%m-%d")
  return(formatted_date)
}

# Fix faulty column value in some datasets where movie column has value "movie"
datasets_to_modify <- list(
  dataset1 = list(filename = "../../data/twitter_stats/chicago/hourly-0.05/counts/DeerChappie.csv", column_name = "movie_name", specific_value = "chappie"),
  dataset2 = list(filename = "../../data/twitter_stats/chicago/hourly-0.05/counts/DeerCrimsonPeak.csv", column_name = "movie_name", specific_value = "crimsonpeak"),
  dataset3 = list(filename = "../../data/twitter_stats/chicago/hourly-0.05/counts/DeerGoodDinosaur.csv", column_name = "movie_name", specific_value = "gooddinosaur"),
  dataset4 = list(filename = "../../data/twitter_stats/chicago/hourly-0.05/counts/DeerLastWitchHunter.csv", column_name = "movie_name", specific_value = "lastwitchhunter"),
  dataset5 = list(filename = "../../data/twitter_stats/chicago/hourly-0.05/counts/DeerPeanutsMovie.csv", column_name = "movie_name", specific_value = "peanutsmovie"),
  dataset6 = list(filename = "../../data/twitter_stats/chicago/hourly-0.05/counts/DeerRickyAndTheFlash.csv", column_name = "movie_name", specific_value = "rickyandtheflash")
)


for (file in csv_files) {
  # Load the dataset
  movie <- read.csv(file)
  
  # Clean DF
  movie <- movie %>% clean_names()
  
  # Fix faulty column names for some datasets
  for (dataset_info in datasets_to_modify) {
    if (file == dataset_info$filename) {
      # Modify the value of a specific column for each row
      movie[[dataset_info$column_name]] <- dataset_info$specific_value
    }
  }
  
  # Drop duplicates
  movie <- distinct(movie)
  
  # Make copy to compute positive-negative ratio
  movie3 <- movie
  
  # Summarize total tweets per time
  movie2 <- movie %>% group_by(date) %>% summarize(totaltweets=sum(n_tweets))
  
  # Drop time from dates
  movie2$date <- format(as.Date(movie2$date), "%Y-%m-%d")
  
  # Get Tweet volume per day
  movie2 <- movie2 %>% group_by(date) %>% summarize(totaltweets=sum(totaltweets))
  
  # Add column with cumulative tweet count
  movie2 <- movie2 %>% mutate(cumtweets = cumsum(totaltweets))
  
  # Add name of movie to each row
  twitter_id = tolower(movie$movie_name[1])
  movie2['twitter_id'] = twitter_id
  
  # TRY TO GET MOJO DATA
  # Find corresponding mojo_id for twitter_id
  mojo_id <- crosswalk$mojo_id[which(crosswalk == twitter_id)[1]]
  
  # Test if mojo_id is in 2014 or 2015 data 
  movie_in_2014 <- mojo_id %in% charac2014$movie_id
  movie_in_2015 <- mojo_id %in% charac2015$movie_id
  
  # Get release date for a movie
  if(movie_in_2014 == TRUE){
    release_date <- charac2014$release_date[which(charac2014$movie_id == mojo_id)]
  } else {
    release_date <- charac2015$release_date[which(charac2015$movie_id == mojo_id)]
  }

  # Drop UTC from release date
  release_date <- format(release_date, "%Y-%m-%d")
  
  # Add pre-release data in a separate dataset 
  pre_release <- movie2 %>% filter(date < release_date)
  
  # Compute positive-negative ratio
  movie3 <- movie3 %>% filter(vader_classifier != "1")
  movie3$date <- format(as.Date(movie3$date), "%Y-%m-%d")
  movie4 <- movie3 # make copy to later compute pre-release pos-neg ratio
  movie3 <- movie3 %>% filter(date >= release_date)
  movie3 <- movie3 %>% group_by(date, vader_classifier, movie_name) %>% summarize(totalday = sum(n_tweets))
  movie3 <- movie3 %>% group_by(vader_classifier) %>% mutate(cumtweets = cumsum(totalday))
  movie3 <- movie3 %>% group_by(date) %>% mutate(pos_neg_ratio = cumtweets[2]/cumtweets[1])
  movie3 <- movie3 %>% group_by(date) %>% mutate(daily_pos_neg_ratio = totalday[2]/totalday[1])
  movie3 <- movie3 %>% select(date, pos_neg_ratio, daily_pos_neg_ratio)
  movie3 <- movie3 %>% distinct()
  movie2 <- movie2 %>% left_join(movie3, by = "date")
  
  # Compute pre-release pos-neg ratio
  movie4 <- movie4 %>% filter(date < release_date)
  movie4 <- movie4 %>% group_by(date, vader_classifier, movie_name) %>% summarize(totalday = sum(n_tweets))
  movie4 <- movie4 %>% group_by(vader_classifier) %>% mutate(cumtweets = cumsum(totalday))
  movie4 <- movie4 %>% group_by(vader_classifier) %>% summarize(sumcumtweets = sum(cumtweets))
  movie2$pre_pos_neg_ratio <- movie4$sumcumtweets[2]/movie4$sumcumtweets[1]
  
  # Drop pre-release data from dataset
  movie2 <- movie2 %>% filter(date >= release_date)
  
  # Add pre-release volume to dataset
  movie2$pre_release_volume <- sum(pre_release$totaltweets)
  
  # Add t for release day:
  movie2 <- movie2 %>% rownames_to_column("t")
  
  # ADD BOX OFFICE DATA FOR MOVIE FOR YEARS AVAILABLE
  release_year <- as.numeric(format(as.Date(release_date), "%Y"))
  years <- seq(release_year, 2015)
  boxofficedata <- NULL
  for (year in years) {
    # Construct the filepath
    filepath <- paste("../../data/mojo/boxoffice/daily/", year, "/boxOffice-daily-", mojo_id, ".csv", sep = "")
    
    # Check if the file exists
    if (file.exists(filepath)) {
      # Load the CSV file
      data <- read.csv(filepath)
      
      # Merge data with previously loaded data
      if (is.null(boxofficedata)) {
        boxofficedata <- data
      } else {
        boxofficedata <- rbind(boxofficedata, data)
      }
    }
  }
  
  if (is.null(boxofficedata)) {
    next
  }
  
  # ADD BOX OFFICE DATA TO MOVIE2 DATASET
  # Change date
  boxofficedata$date <- sapply(boxofficedata$date, transform_date)

  # Cut movie2 off by last date available in boxofficedata
  last_boxoffice <- max(boxofficedata$date)
  movie2 <- movie2 %>% filter(movie2$date<=last_boxoffice)
  
  # Merge movie2 and boxofficedata
  movie2 <- movie2 %>% left_join(boxofficedata, by = "date")
  
  # Add column with cumulative tweet count
  movie2 <- movie2 %>% mutate(cumtweets = cumsum(totaltweets))
  
  # Add a lag tweet column (i.e., all cum tweet counts shifted one time period up, so tweets at t-1 correspond to box office cum at t)
  movie2 <- movie2 %>% mutate(lag_cum_tweets = lag(cumtweets))
  
  # Add a lag pos-neg ratio column
  movie2 <- movie2 %>% mutate(lag_pos_neg_ratio = lag(pos_neg_ratio))
  
  # Store the dataset in the list
  all_datasets[[file]] <- movie2
}

# Merge everything into one dataset
merged_data <- do.call(rbind, all_datasets)

# Fix row names
rownames(merged_data) <- 1:nrow(merged_data)

# Add 0 for NA values in lag columns
merged_data$lag_cum_tweets[is.na(merged_data$lag_cum_tweets)] <- 0
merged_data$lag_pos_neg_ratio[is.na(merged_data$lag_pos_neg_ratio)] <- 0

# Remove NAs, clean names
complete <- na.omit(merged_data)
complete <- complete %>% clean_names()

# Add all character data to complete dataset
complete <- complete %>% left_join(characcomplete, by = "movie_id")

# Merge star_power with complete
star_power <- read_csv('../../gen/data-preparation/output/star_power.csv')
complete <- complete %>% left_join(star_power, by = "movie_id")

## Add metacritic scores
crosswalk <- read_csv('../../data/crosswalk/mojo_meta.csv')
metascores2014 <- read_csv('../../data/metacritic/metaScores/2014-metaScores.csv') %>% select(-title)
metascores2015 <- read_csv('../../data/metacritic/metaScores/2015-metaScores.csv') %>% select(-title)
metascores_extra <- read_csv('../../data/other/metascore_extra.csv')
metascores <- rbind(metascores2014, metascores2015)
metascores <- rename(metascores, metascore = metaScore)
metascores <- rename(metascores, n_reviews = nReviews)
metascores <- metascores %>% left_join(crosswalk, by = c("movieID" = "meta_id")) %>% select(-movieID)
metascores <- rbind(metascores, metascores_extra)
complete <- complete %>% left_join(metascores, by = c("movie_id" = "mojo_id"))

## Add production budgets
# Note: there is no crosswalk dataset available to properly merge these
# Hence, I added the mojo_id for each movie to the production_budgets.csv dataset myself by hand
# If you're trying to run this code yourself, it will probably throw an error because your dataset won't have this column
# Will include this modified CSV in my final generated data I will hand in
production_budgets <- read_csv('../../data/the_numbers/production_budgets.csv')
production_budgets <- production_budgets %>% clean_names()
production_budgets <- production_budgets %>% na.omit() %>% select(production_budget, mojo_id)

complete <- complete %>% left_join(production_budgets, by = c("movie_id" = "mojo_id"))
complete <- complete %>% select(-production_budget.x)
complete <- rename(complete, production_budget = production_budget.y)

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

complete$production_budget_monetary <- sapply(complete$production_budget, convert_monetary)


## Add sequel/series info
sequels <- read_csv('../../data/other/sequels.csv')
complete <- complete %>% left_join(sequels, by = "movie_id")

## Add advertisement data for movies
nationaltv2014 <- read_csv('../../data/nielsen-ads/CSV/movies_nationaltv_2014.csv')
nationaltv2015 <- read_csv('../../data/nielsen-ads/CSV/movies_nationaltv_2015.csv')
nationaltv_total <- rbind(nationaltv2014, nationaltv2015)

# Note: I manually edited some columns in this crosswalk set, because some of the column names did not properly correspond
# If you run this code below without my adjusted file, you will get an error
# Will include this modified CSV in my final generated data I will hand in
crosswalk <- read_csv('../../data/crosswalk/mojo_nielsen.csv') %>% select(-mojo_title)

nationaltv_total <- nationaltv_total %>% clean_names()
nationaltv_total <- nationaltv_total %>% select(ad_date, ad_time, spend, duration, ad_code, brand_desc, tv_daypart_desc)
nationaltv_total <- nationaltv_total %>% distinct()
nationaltv_total$brand_desc <- gsub(" MOTION PICTURE", "", nationaltv_total$brand_desc)
nationaltv_total$brand_desc <- tolower(nationaltv_total$brand_desc)
nationaltv_total <- nationaltv_total %>% group_by(ad_date, brand_desc) %>% summarize(spend_nationaltv = sum(spend)) # compute spend per movie per day
nationaltv_total <- nationaltv_total %>% left_join(crosswalk, by = c("brand_desc" = "nielsen_title"))
nationaltv_total <- nationaltv_total %>% na.omit()

# Merge with complete
complete$date <- as.Date(complete$date)
complete <- complete %>% left_join(nationaltv_total, by = c("movie_id" = "movie_id", "date" = "ad_date"))

# Change ad spend NAs to 0
complete$spend_nationaltv[is.na(complete$spend_nationaltv)] <- 0

# Look at spot TV ads as well
spottv2014 <- read_csv('../../data/nielsen-ads/CSV/movies_spottv_2014.csv')
spottv2015 <- read_csv('../../data/nielsen-ads/CSV/movies_spottv_2015.csv')
spottv_total <- rbind(spottv2014, spottv2015)

spottv_total <- spottv_total %>% clean_names()
spottv_total <- spottv_total %>% select(ad_date, ad_time, brand_desc, spend)
spottv_total <- spottv_total %>% na.omit()
spottv_total <- spottv_total %>% distinct()
spottv_total$brand_desc <- gsub(" MOTION PICTURE", "", spottv_total$brand_desc)
spottv_total$brand_desc <- tolower(spottv_total$brand_desc)
spottv_total <- spottv_total %>% group_by(ad_date, brand_desc) %>% summarize(spend_spottv = sum(spend)) # compute spend per movie per day
spottv_total <- spottv_total %>% left_join(crosswalk, by = c("brand_desc" = "nielsen_title"))
spottv_total <- spottv_total %>% na.omit()

# Merge with complete
complete <- complete %>% left_join(spottv_total, by = c("movie_id" = "movie_id", "date" = "ad_date"))
complete <- complete %>% select(-brand_desc.x, -brand_desc.y)
# Change NAs to 0
complete$spend_spottv[is.na(complete$spend_spottv)] <- 0

# Compute cumulative ad spend
complete <- complete %>% group_by(movie_id) %>% mutate(cumadspend = cumsum(spend_nationaltv + spend_spottv))

# Create lag column
complete <- complete %>% mutate(lag_cumadspend = lag(cumadspend))
complete$lag_cumadspend[is.na(complete$lag_cumadspend)] <- 0

# Get week number
complete$week_number <- strftime(complete$date, format = "%V")
complete <- complete %>% ungroup()

# Add weeks since release
complete <- complete %>% mutate(weeks_since_release = (day_of_release %/% 7) + 1)

# Merge missing metascores
# Made this CSV myself, will include in final data I'll hand in
metascore_missing <- read_csv('../../data/metascore_missing.csv')
complete <- complete %>% left_join(metascore_missing, by = "movie_id", suffix = c("", ".new"))
complete <- complete %>% mutate(metascore = ifelse(is.na(metascore), metascore.new, metascore)) %>% select(-metascore.new)

# Add missing production budget value for strangemagic
complete$production_budget_monetary[complete$movie_id=='strangemagic'] <- 70000000

# Save CSV
write.csv(complete, '../../gen/data-preparation/output/complete.csv')

