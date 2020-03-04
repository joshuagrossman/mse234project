import requests
import jsonlines
import time

API_KEY = "5H7nYNEhMUt3gVwkIwQYaRu7GW9s9xXz"

with jsonlines.open("data/ny-times-data.jsonl", "w") as writer:
    for year in range(2010, 2021, 1):
        for month in range(1, 13, 1):
            request = requests.get("https://api.nytimes.com/svc/archive/v1/" + str(year) + "/" + str(month) + ".json?api-key=" + API_KEY)
            if request.status_code == 200:
                print(str(year) + "-" + str(month))
                request_as_json = request.json()
                writer.write(request_as_json)
            time.sleep(6)
