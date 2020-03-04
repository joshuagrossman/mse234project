import jsonlines
import json

ny_times_data = jsonlines.open("data/ny-times-data.jsonl", "r")

for month_dict in ny_times_data:
    print(month_dict['response']['docs'][0].get('byline'))
    
# month_dict['response']['docs'][0]['byline']['person'][0]['firstname']
# month_dict['response']['docs'][0]['byline']['person'][0]['lastname']
# month_dict['response']['docs'][0]['word_count']
# month_dict['response']['docs'][0]['news_desk']
# month_dict['response']['docs'][0]['section_name']
# month_dict['response']['docs'][0]['print_page']
# month_dict['response']['docs'][0]['print_section']
# month_dict['response']['docs'][0]['document_type']
# month_dict['response']['docs'][0]['type_of_material']