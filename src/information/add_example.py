import json

import sys

sys.path.append("src")
from configs.config import type

with open(f"src/information/{type}/ppl_dev.json", "r") as f:
    # ppls = json.load(f)
    ppls = json.load(f)

try:
    with open(f"src/information/{type}/example.json", "r") as f:
        examples = json.load(f)
except FileNotFoundError:
    pass

for i in range(len(ppls)):
    ppls[i]["example"] = examples[i]

with open(f"src/information/{type}/ppl_dev.json", "w") as f:
    json.dump(ppls, f, indent=4, ensure_ascii=False)
