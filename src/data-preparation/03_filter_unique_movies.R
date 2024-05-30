library(readr)
library(tidyverse)

movieinfoperactor <- read_csv('../../gen/data-preparation/output/imdbmovieinfoperactor.csv')
movieinfoperactor <- movieinfoperactor %>% select(movie_name, movie_url)
unique_movies <- movieinfoperactor %>% distinct()

write_csv(unique_movies, '../../gen/data-preparation/output/unique_movies.csv')
