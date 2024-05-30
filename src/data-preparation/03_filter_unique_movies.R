# Load libraries
library(readr)
library(tidyverse)

# Filter unique movies
movieinfoperactor <- read_csv('../../gen/data-preparation/output/imdbmovieinfoperactor.csv')
movieinfoperactor <- movieinfoperactor %>% select(movie_name, movie_url)
unique_movies <- movieinfoperactor %>% distinct()

# Save unique movies
write_csv(unique_movies, '../../gen/data-preparation/output/unique_movies.csv')
