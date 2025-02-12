import requests
import jsonlines
import time

API_KEY = "REDACTED"

with jsonlines.open("data/ny-times-data.jsonl", "w") as writer:
    for year in range(2010, 2021, 1):
        for month in range(1, 13, 1):
            response = requests.get("https://api.nytimes.com/svc/archive/v1/" + str(year) + "/" + str(month) + ".json?api-key=" + API_KEY)
            if response.status_code == 200:
                print(str(year) + "-" + str(month))
                response_as_json = response.json()
                writer.write(response_as_json)
            time.sleep(6)
