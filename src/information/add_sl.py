import json
import sys

sys.path.append("src")
from configs.config import type

with open(f"src/information/{type}/ppl_dev.json", "r") as f:
    ppls = json.load(f)

with open(f"src/information/{type}/schema.json", "r") as f:
    datas = json.load(f)

for i in range(len(ppls)):
    data = datas[i]
    ppls[i]["tables"] = data["tables"]
    ppls[i]["columns"] = data["columns"]

with open(f"src/information/{type}/ppl_dev.json", "w") as f:
    json.dump(ppls, f, indent=4, ensure_ascii=False)
