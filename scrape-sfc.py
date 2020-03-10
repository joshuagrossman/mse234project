import bs4
from requests_html import HTMLSession
import time
import random
import json
import jsonlines
import pdb
from datetime import timedelta, date

LATER_PAGE_BASE_URL = "http://nl.newsbank.com/nl-search/we/Archives?p_action=list&p_topdoc="

START_DATE = date(2010, 1, 1)

def make_search_url(month, day, year):
    date_string = str(month) + "/" + str(day) + "/" + str(year)
    return "http://nl.newsbank.com/nl-search/we/Archives?p_product=SFCB&p_theme=sfcb&p_action=search&p_maxdocs=200&s_dispstring=date(" + date_string + "%20to%20" + date_string + ")&p_field_date-0=YMD_date&p_params_date-0=date:B,E&p_text_date-0=" + date_string + "%20to%20" + date_string + ")&xcal_numdocs=50&p_perpage=25&p_sort=YMD_date:D&xcal_useweights=no"

def get_next_url(page_counter):
    return LATER_PAGE_BASE_URL + str(1 + 25*page_counter)

article_writer = jsonlines.open("data/sf-article-by-date.jsonl", "w")
no_response_writer = open("data/sf-article-no-response.txt", "w")

session = HTMLSession()

search_date = START_DATE
todays_date = date.today()
    
while search_date < todays_date:
    search_month = search_date.month
    search_day = search_date.day
    search_year = search_date.year
    date_key = str(search_month).zfill(2) + str(search_day).zfill(2) + str(search_year)
    article_dict = {date_key: []}
    
    search_url = make_search_url(search_month, search_day, search_year)
    response = session.get(search_url)
    time.sleep(1)
    
    if response.status_code != 200:
        print(date_key + " : " + "Failure")
        no_response_writer.write(date_key + "\n")
        continue
    
    article_counter = 0
    search_page_counter = 0
    exists_more_results = True
    while(exists_more_results):
        if (search_page_counter > 0):
            search_url = get_next_url(search_page_counter)
            response = session.get(search_url)
            time.sleep(1)
        soup = bs4.BeautifulSoup(response.content)
        
        try:
            articles = soup.find('ul').find_all('li')
        except:
            exists_more_results = False
            continue
        
        if articles == []:
            exists_more_results = False
            continue
            
        for article in articles:
            title = article.find_all("span", {"class": "nBbol"})[1].text
            author_page_wc = article.find_all("span", {"class": "nB12"})[1].text
            article_metadata = (title, author_page_wc)
            article_dict[date_key].append(article_metadata)
            article_counter += 1
            
        search_page_counter += 1
    article_writer.write(json.dumps(article_dict))
    print(date_key + " : " + str(article_counter) + " articles")
    search_date += timedelta(days=1)