import jsonlines
import json
import csv
import pdb

sfc_data_1 = jsonlines.open("data/sf-article-by-date-01012010-to-06262014.jsonl", "r")
sfc_data_2 = jsonlines.open("data/sf-article-by-date-06272014-forward.jsonl", "r")
sfc_csv = open("data/sfc.csv", "w")

FIELDNAMES = ['pub_date', 'title', 'metadata']
csv_writer = csv.writer(sfc_csv)
csv_writer.writerow(FIELDNAMES)
csv_writer = csv.DictWriter(sfc_csv, fieldnames = FIELDNAMES)

for data in [sfc_data_1, sfc_data_2]:
    for day_dict_json in data:
        day_dict = json.loads(day_dict_json)
        # should only be one date... but unpacking safely
        for date, articles in day_dict.items():
            for article in articles:
                article_dict = {}
                article_dict['pub_date'] = date
                article_dict['title'] = article[0].replace("\xa0","|")
                article_dict['metadata'] = article[1].replace("\xa0","|")
                csv_writer.writerow(article_dict)

                