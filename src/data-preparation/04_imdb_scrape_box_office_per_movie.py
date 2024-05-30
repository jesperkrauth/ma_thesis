# Import packages
from selenium import webdriver
from bs4 import BeautifulSoup
import time
import json
import csv
import datetime
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager
import pandas as pd

# Get start time
start_time = time.time()

# Define Chrome driver
driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()))

# Open IMDB first to get rid of cookie notif once
url = 'https://www.imdb.com/'
driver.get(url)
time.sleep(3)
driver.maximize_window()

# Decline cookie popup
driver.find_element(By.CLASS_NAME, 'ecppKW').click()
time.sleep(1)

# Counter for print statements
moviecounter = 0

# Get row count of CSV file for print statements
file = open('../../gen/data-preparation/output/unique_movies.csv')
row_count = len(file.readlines())-1

# Read unique movies
with open('../../gen/data-preparation/output/unique_movies.csv', mode = "r", encoding='utf-8-sig') as csv_file:
    csv_reader = csv.DictReader(csv_file)
    
    # Iterate through each movie
    for row in csv_reader:
        driver.get(row['movie_url'])
        moviecounter += 1
        time.sleep(2)

        # Get page source
        soup = BeautifulSoup(driver.page_source)
    
        # Find boxoffice metadata section
        boxoffice_metadata = soup.find_all(class_ = 'ipc-metadata-list__item sc-1bec5ca1-2 bGsDqT')
        
        # If no box office metadata section
        if len(boxoffice_metadata) == 0:
            data = {'movie_name': row['movie_name'],
                    'movie_url': row['movie_url'],
                    'gross_domestic': '',
                    'gross_worldwide': ''}
            f = open('../../gen/data-preparation/output/imdbboxofficepermovie.json', 'a', encoding = 'utf-8')
            f.write(json.dumps(data))
            f.write('\n')
            f.close()
            print(f"No box office data found for movie {moviecounter} of {row_count}: {row['movie_name']}, continuing to next movie")
            end_time = time.time()
            print(f"Time elapsed: {datetime.timedelta(seconds=int(end_time-start_time))}")
            continue
        
        # Find domestic gross data
        for i in range(len(boxoffice_metadata)):
            if boxoffice_metadata[i].find(class_ = 'ipc-metadata-list-item__label').get_text() == "Gross US & Canada":
                gross_domestic = boxoffice_metadata[i].find(class_ = 'ipc-metadata-list-item__list-content-item').get_text()
                break
            else:
                gross_domestic = ''
        
        # Find worldwide gross data
        for i in range(len(boxoffice_metadata)):
            if boxoffice_metadata[i].find(class_ = 'ipc-metadata-list-item__label').get_text() == "Gross worldwide":
                gross_worldwide = boxoffice_metadata[i].find(class_ = 'ipc-metadata-list-item__list-content-item').get_text()
                break
            else:
                gross_worldwide = ''
        
        # Write data
        data = {'movie_name': row['movie_name'],
                'movie_url': row['movie_url'],
                'gross_domestic': gross_domestic,
                'gross_worldwide': gross_worldwide}
        f = open('../../gen/data-preparation/output/imdbboxofficepermovie.json', 'a', encoding = 'utf-8')
        f.write(json.dumps(data))
        f.write('\n')
        f.close()

        # Print statements for no box office at all, one of each, or both found
        if ((gross_domestic == '') and (gross_worldwide == '')):
            print(f"No box office data found for movie {moviecounter} of {row_count}: {row['movie_name']}")
            end_time = time.time()
            print(f"Time elapsed: {datetime.timedelta(seconds=int(end_time-start_time))}")
        if ((gross_domestic != '') and (gross_worldwide == '')):
            print(f"No gross worldwide data found for movie {moviecounter} of {row_count}: {row['movie_name']}")
            print(f"Saved domestic box office data for movie {moviecounter} of {row_count}: {row['movie_name']}")
            end_time = time.time()
            print(f"Time elapsed: {datetime.timedelta(seconds=int(end_time-start_time))}")
        if ((gross_domestic == '') and (gross_worldwide != '')):
            print(f"No gross domestic data found for movie {moviecounter} of {row_count}: {row['movie_name']}")
            print(f"Saved worldwide box office data for movie {moviecounter} of {row_count}: {row['movie_name']}")
            end_time = time.time()
            print(f"Time elapsed: {datetime.timedelta(seconds=int(end_time-start_time))}")
        if ((gross_domestic != '') and (gross_worldwide != '')):
            print(f"Saved box office data for movie {moviecounter} of {row_count}: {row['movie_name']}")
            end_time = time.time()
            print(f"Time elapsed: {datetime.timedelta(seconds=int(end_time-start_time))}")

# Convert final JSON to CSV
df = pd.read_json('../../gen/data-preparation/output/imdbboxofficepermovie.json', lines = True)
df.to_csv('../../gen/data-preparation/output/imdbboxofficepermovie.csv')
print('Saved data to imdbboxofficepermovie.csv')
print(f"Total duration: {datetime.timedelta(seconds=int(end_time-start_time))}")