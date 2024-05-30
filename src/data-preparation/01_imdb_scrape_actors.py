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
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


# Get start time
start_time = time.time()

# Define driver
driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()))

# Open IMDb
url = 'https://www.imdb.com'
driver.get(url)
time.sleep(5)
driver.maximize_window()

# Decline cookie popup
driver.find_element(By.CLASS_NAME, 'ecppKW').click()
time.sleep(1)

# Change language from English to French and back (so movie titles don't get auto translated based on IP)
# Click on language button
driver.find_elements(By.CSS_SELECTOR, "[aria-label='Toggle language selector']")[0].click()
time.sleep(1)

# Click on French one
driver.find_elements(By.CSS_SELECTOR, "[aria-label='Français (Canada)']")[1].click()
time.sleep(5)

# Click on language button
driver.find_elements(By.CSS_SELECTOR, "[aria-label='Basculer vers le sélecteur de langue']")[0].click()
time.sleep(1)

# Click on English one
driver.find_elements(By.CSS_SELECTOR, "[aria-label='English (United States)']")[1].click()

# Counter for print statements
moviecounter = 0

# Get row count of CSV file for print statements
file = open('../../data/movielist.csv')
rowcount = len(file.readlines())-1

# Open movielist.csv
with open('../../data/movielist.csv', mode = "r", encoding='utf-8-sig') as csv_file:
    csv_reader = csv.DictReader(csv_file)
    
    # Iterate through each movie
    for row in csv_reader:
        driver.get(row['url'])
        
        # Wait until cast data is loaded
        WebDriverWait(driver, 20).until(EC.presence_of_element_located((By.CLASS_NAME, 'hNfYaW')))
        time.sleep(1)
        print(f"Opening IMDb page for movie with ID {row['movie_id']}")
        
        # Get page source
        soup = BeautifulSoup(driver.page_source)
        
        # Find list of actors
        actorslist = soup.find_all(class_ = 'sc-bfec09a1-1 gCQkeh')
        
        # Save each actor in JSON
        for actor in actorslist:
            data = {'movie_id': row['movie_id'],
                    'movie_title': soup.find(class_ = 'hero__primary-text').get_text(),
                    'actor': actor.get_text(),
                   'actor_url': 'https://www.imdb.com' + actor['href'].split("?")[0]}
            f = open('../../gen/data-preparation/output/imdbactorspermovie.json', 'a', encoding = 'utf-8')
            f.write(json.dumps(data))
            f.write('\n')
            f.close()
        moviecounter += 1
        print(f"Wrote data for movie {moviecounter} of {rowcount}: {data['movie_title']}")
        end_time = time.time()
        print(f"Time elapsed: {datetime.timedelta(seconds=int(end_time-start_time))}")

# Convert final JSON file to CSV
df = pd.read_json('../../gen/data-preparation/output/imdbactorspermovie.json', lines = True)
df.to_csv('../../gen/data-preparation/output/imdbactorspermovie.csv')
print('Saved data to imdbactorspermovie.csv')
end_time = time.time()
print(f"Total duration: {datetime.timedelta(seconds=int(end_time-start_time))}")