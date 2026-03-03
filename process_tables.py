import json
import sys

with open('tables_dump.json', 'r') as f:
    content = f.read()

start = content.find('[')
end = content.rfind(']') + 1
data = json.loads(content[start:end])

with open('supabase/migrations/full_snapshot_FINAL.sql', 'a') as f:
    for row in data:
        f.write(row['?column?'] + "\n")
