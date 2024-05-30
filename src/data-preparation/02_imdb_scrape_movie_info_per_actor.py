# Import packages
from selenium import webdriver
from bs4 import BeautifulSoup
import time
import json
import datetime
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
import pandas as pd

# Get start time
start_time = time.time()

# Define Chrome driver
driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()))

# Open IMDB first to get rid of cookie notif once
url = 'https://www.imdb.com/'
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
actorcounter = 0

# Open actors per movie JSON
source_code = open('../../gen/data-preparation/output/imdbactorspermovie.json', 'r').readlines() # Open source code file
row_count = len(source_code) # Get rowcount for print statements
for source in source_code: # Iterate through each line
    obj = json.loads(source)
    driver.get(obj['actor_url'])
    actorcounter += 1
    moviecounter = 0
    failcount = 0
    
    # Wait until funnel icon is loaded
    WebDriverWait(driver, 20).until(EC.presence_of_element_located((By.CLASS_NAME, 'ipc-chip--on-base-accent2')))
    time.sleep(1)
    
    # Scroll to funnel icon
    element = driver.find_element(By.CLASS_NAME, 'ipc-chip--on-base-accent2')
    actions = ActionChains(driver)
    actions.move_to_element(element).perform()

    # Click funnel icon
    driver.find_element(By.CLASS_NAME, 'ipc-chip--on-base-accent2').click()
    time.sleep(1)

    # Click 'project type'
    driver.find_elements(By.CLASS_NAME, 'ipc-chip--on-baseAlt')[1].click()
    
    # Wait until actor/actress section has loaded
    while True:
        try:
            WebDriverWait(driver, 20).until(EC.any_of(
                EC.presence_of_element_located((By.CLASS_NAME, 'filmo-section-actor')),
                EC.presence_of_element_located((By.CLASS_NAME, 'filmo-section-actress'))))
        except:
            print(f"ERROR: No actor/actress button found for actor {actorcounter} of {row_count}: {obj['actor']}, attempting to fix")
            failcount = 1
            break
        break
        
    # Close popup
    driver.find_element(By.CLASS_NAME, 'ipc-promptable-base__close').click()
    time.sleep(1)
    
    # If no actor/actress button found initially, try to locate it further in the scroll list
    if failcount == 1:
        if driver.find_elements(By.CSS_SELECTOR, "[id='name-filmography-filter-actor']"): # Look for actor button
            try:
                driver.find_element(By.CSS_SELECTOR, "[id='name-filmography-filter-actor']").click() # Click actor button
            except:
                driver.find_element(By.CLASS_NAME, 'ipc-chip-list__arrow--right').click()
                time.sleep(1)
                driver.find_element(By.CSS_SELECTOR, "[id='name-filmography-filter-actor']").click() # Click actor button
            WebDriverWait(driver, 20).until(EC.any_of(
                EC.presence_of_element_located((By.CLASS_NAME, 'filmo-section-actor')),
                EC.presence_of_element_located((By.CLASS_NAME, 'filmo-section-actress'))))
            # SCROLL TO EXPAND/COLLAPSE BUTTON
            element = driver.find_element(By.CSS_SELECTOR, "[data-testid='nm-flmg-all-accordion-expander']")
            actions = ActionChains(driver)
            actions.move_to_element(element).perform()
            time.sleep(1)
            # CLICK EXPAND AND COLLAPSE TWO TIMES
            driver.find_element(By.CSS_SELECTOR, "[data-testid='nm-flmg-all-accordion-expander']").click()
            time.sleep(3)
            driver.find_element(By.CSS_SELECTOR, "[data-testid='nm-flmg-all-accordion-expander']").click()
        elif driver.find_elements(By.CSS_SELECTOR, "[id='name-filmography-filter-actress']"): # Look for actress button
            try:
                driver.find_element(By.CSS_SELECTOR, "[id='name-filmography-filter-actress']").click()
            except:
                driver.find_element(By.CLASS_NAME, 'ipc-chip-list__arrow--right').click()
                time.sleep(1)
                driver.find_element(By.CSS_SELECTOR, "[id='name-filmography-filter-actress']").click()
            WebDriverWait(driver, 20).until(EC.any_of(
                EC.presence_of_element_located((By.CLASS_NAME, 'filmo-section-actor')),
                EC.presence_of_element_located((By.CLASS_NAME, 'filmo-section-actress'))))
            # SCROLL TO EXPAND/COLLAPSE BUTTON
            element = driver.find_element(By.CSS_SELECTOR, "[data-testid='nm-flmg-all-accordion-expander']")
            actions = ActionChains(driver)
            actions.move_to_element(element).perform()
            time.sleep(1)
            # CLICK EXPAND AND COLLAPSE TWO TIMES
            driver.find_element(By.CSS_SELECTOR, "[data-testid='nm-flmg-all-accordion-expander']").click()
            time.sleep(3)
            driver.find_element(By.CSS_SELECTOR, "[data-testid='nm-flmg-all-accordion-expander']").click()
        else:
            print(f"ERROR: No movies found for actor {actorcounter} of {row_count}: {obj['actor']}")
            print(f"Moving on to the next one")
            end_time = time.time()
            print(f"Time elapsed: {datetime.timedelta(seconds=int(end_time-start_time))}")
            failcount += 1
    
    # If no actor/actress button in scroll list either, continue with next actor
    if failcount == 2:
        print(f"Confirmed aborting for actor {actorcounter} of {row_count}: {obj['actor']}")
        continue

    # Get page source
    soup = BeautifulSoup(driver.page_source)
    
    successtring = 0
    
    # Iterate until actor/actress button is listed first
    substring = "Actor"
    substring3 = "Actress"
    if len(soup.find_all(class_ = 'filmography-selected-chip-filter ipc-chip ipc-chip--active ipc-chip--on-base-accent2')) > 0:
        for i in range(len(soup.find_all(class_ = 'filmography-selected-chip-filter ipc-chip ipc-chip--active ipc-chip--on-base-accent2'))):
            substring2 = soup.find_all(class_ = 'filmography-selected-chip-filter ipc-chip ipc-chip--active ipc-chip--on-base-accent2')[i].find(class_ = 'ipc-chip__text').get_text()
            if substring in substring2:
                successtring = 1
                break
            if substring3 in substring2:
                successtring = 1
                break
            else:
                driver.find_elements(By.CLASS_NAME, 'ipc-chip--on-base-accent2')[1].click()
    else:
        print(f"Only one category available")
        if soup.find(class_ = 'filmo-section-actress'):
            if substring in soup.find(class_ = 'filmo-section-actress').get_text():
                successtring = 1
            if substring3 in soup.find(class_ = 'filmo-section-actress').get_text():
                successtring = 1
    
    time.sleep(2)
    
    # Abort if no actor/actress button at all
    if successtring < 1:
        print(f"Aborted for actor {actorcounter} of {row_count}: {obj['actor']}, as successtring < 1")
        print(f"Moving on to the next one")
        end_time = time.time()
        print(f"Time elapsed: {datetime.timedelta(seconds=int(end_time-start_time))}")
        continue
    
    # Get page source again
    soup = BeautifulSoup(driver.page_source)
    
    # Find which sublist in the actor list is 'movies'
    for i in range(len(soup.find_all(class_ = 'ipc-accordion__item ipc-accordion__item--collapsed accordion-item'))):
        if soup.find_all(class_ = 'ipc-accordion__item ipc-accordion__item--collapsed accordion-item')[i].find(class_ = 'ipc-accordion__item__header ipc-accordion__item__header--sticky').find(class_ = 'ipc-inline-list__item').get_text() == "Movie":
            moviecount = i
            break
    
    # Define cutoff year
    cutoff_year = '2014'
    
    # Scroll to movie button
    element = driver.find_elements(By.CLASS_NAME, 'ipc-accordion--pageSection')[moviecount]
    actions = ActionChains(driver)
    actions.move_to_element(element).perform()
    time.sleep(1)
    
    # Click on 'Movie'
    driver.find_elements(By.CLASS_NAME, 'ipc-accordion--pageSection')[moviecount].click()
    time.sleep(1)
        
    # Try to scroll to last element
    while True:
        try:
            element = driver.find_elements(By.CLASS_NAME, 'accordion-content')[moviecount].find_elements(By.CLASS_NAME, 'titleType-released-credit')[-1]
            actions = ActionChains(driver)
            actions.move_to_element(element).perform()
        except:
            continue
        break
    
    time.sleep(2)
    
    # Get page source again
    soup = BeautifulSoup(driver.page_source)
    
    # Define movie list
    movie_list = soup.find_all(class_ = 'ipc-accordion__item__content_inner accordion-content')[moviecount].find_all(class_ = 'ipc-metadata-list-summary-item')
    
    # Write data for movies < cutoff year
    for i in range(len(movie_list)):
        try:
            if movie_list[i].find(class_ = 'ipc-metadata-list-summary-item__li').get_text() < cutoff_year:
                data = {'actor_name': obj['actor'],
                       'movie_name': movie_list[i].find(class_ = 'ipc-metadata-list-summary-item__t').get_text(),
                       'year': movie_list[i].find(class_ = 'ipc-metadata-list-summary-item__li').get_text(),
                       'movie_url': 'https://imdb.com' + movie_list[i].find(class_ = 'ipc-lockup-overlay ipc-focusable')['href'].split("?")[0]}
                f = open('../../gen/data-preparation/output/imdbmovieinfoperactor.json', 'a', encoding = 'utf-8')
                f.write(json.dumps(data))
                f.write('\n')
                f.close()
                moviecounter +=1
        except:
            continue
    
    # Print statement for x>0 number of relevant movies found
    if moviecounter > 0:
        print(f"{moviecounter} relevant movies found for actor {actorcounter} of {row_count}: {obj['actor']}")
        print(f"Wrote data for actor {actorcounter} of {row_count}: {obj['actor']}")
        end_time = time.time()
        print(f"Time elapsed: {datetime.timedelta(seconds=int(end_time-start_time))}")
    
    # Print statement is 0 relevant movies found
    if moviecounter == 0:
        print(f"No movies earlier than 2014 found for actor {actorcounter} of {row_count}: {obj['actor']}")
        end_time = time.time()
        print(f"Time elapsed: {datetime.timedelta(seconds=int(end_time-start_time))}")

# Convert final JSON to CSV
df = pd.read_json('../../gen/data-preparation/output/imdbmovieinfoperactor.json', lines = True)
df.to_csv('../../gen/data-preparation/output/imdbmovieinfoperactor.csv')
print('Saved data to imdbmovieinfoperactor.csv')
print(f"Total duration: {datetime.timedelta(seconds=int(end_time-start_time))}")