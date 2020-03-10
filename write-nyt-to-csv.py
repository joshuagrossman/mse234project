import jsonlines
import json
import csv
import pdb

ny_times_data = jsonlines.open("data/ny-times-data.jsonl", "r")
nyt_csv = open("data/nyt.csv", "w")

FIELDNAMES = ['first_names', 'last_names','word_count','news_desk',
              'section_name', 'print_page', 'print_section',
              'document_type', 'type_of_material', 'pub_date']
csv_writer = csv.writer(nyt_csv)
csv_writer.writerow(FIELDNAMES)
csv_writer = csv.DictWriter(nyt_csv, fieldnames = FIELDNAMES)

month_number = 0

for month_dict in ny_times_data:
    print("Month number " + str(month_number))
    month_number += 1
    for article in month_dict['response']['docs']:
    
        article_dict = {}

        byline = article.get('byline')
        author_info = []
        if isinstance(byline, dict):
            author_info = byline.get('person')
        first_names = []
        last_names = []
        if isinstance(author_info, list):
            for author in author_info:
                first_names.append(str(author.get('firstname')).lower())
                last_names.append(str(author.get('lastname')).lower())
        article_dict['first_names'] = "|".join(first_names)
        article_dict['last_names'] = "|".join(last_names)

        article_dict['word_count'] = article.get('word_count')
        article_dict['news_desk'] = article.get('news_desk')
        article_dict['section_name'] = article.get('section_name')
        article_dict['print_page'] = article.get('print_page')
        article_dict['print_section'] = article.get('print_section')
        article_dict['document_type'] = article.get('document_type')
        article_dict['type_of_material'] = article.get('type_of_material')
        article_dict['pub_date'] = article.get('pub_date')

        csv_writer.writerow(article_dict)