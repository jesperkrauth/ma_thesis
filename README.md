# Thesis MSc Marketing Analytics (MA): how online WOM volume and valence affect movie box office performance
This repository contains the code used in the analysis part of my master's thesis for the MSc Marketing Analytics at Tilburg University.

## Repository overview

```
- src
  - analysis
  - data-preparation
- README.md
```

## Dependencies

- Python. [Installation guide](https://tilburgsciencehub.com/topics/computer-setup/software-installation/python/python/).
- R. [Installation guide](https://tilburgsciencehub.com/topics/computer-setup/software-installation/rstudio/r/).

- For Python, make sure you have installed the following libraries:
```
- bs4
- csv
- datetime
- json
- pandas
- selenium
- time
- webdriver_manager
```

- For R, make sure you have installed the following packages:
```
library(car)
library(fixest)
library(janitor)
library(readr)
library(tidyverse)
```

## Running the code
### Step-by-step
To generate the outputs used in the thesis, follow these instructions:
1. Obtain the datasets used in this thesis. Datasets were provided by the supervisor of this thesis.
2. Run ``src/data-preparation/01_imdb_scrape_actors.py`` to scrape a list of actors from IMDb for each relevant movie in the analysis.
3. Run ``src/data-preparation/02_imdb_scrape_movie_info_per_actor.py`` to scrape a list for each movie before 2014 each actor identified in ``src/data-preparation/01_imdb_scrape_actors.py`` played in.
4. Run ``src/data-preparation/03_filter_unique_movies.R`` to filter the list scraped in the step before for unique movies.
5. Run ``src/data-preparation/04_imdb_scrape_box_office_per_movie.py`` to scrape a list of box office data for each unique movie identified in the prior step.
6. Run ``src/data-preparation/05_obtain_star_power_per_movie.R`` to obtain the dataset with information on star power per relevant movie.
7. Run ``src/data-preparation/06_clean_all_data.R`` to obtain the final dataset used in the analysis.
8. Run ``src/analysis/data_chapter.R`` to obtain all graphs and figures used in the ``Data`` chapter.
9. Run ``src/analysis/results_chapter.R`` to obtain all graphs and figures used in the ``Results`` chapter.


## Authors
- [Jesper Krauth](https://github.com/jesperkrauth),         e-mail: j.krauth@tilburguniversity.edu 
