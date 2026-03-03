import json
import os

def fix_file(input_path, output_path):
    with open(input_path, 'r') as f:
        content = f.read()
    
    # Ищем JSON массив в тексте
    start = content.find('[')
    end = content.rfind(']') + 1
    if start == -1 or end == 0:
        print("JSON not found")
        return

    data = json.loads(content[start:end])
    
    with open(output_path, 'a') as f:
        f.write("\n-- 4. FUNCTIONS (CLEAN)\n")
        for row in data:
            # Берём значение первой колонки (может называться ?column? или pg_get_functiondef)
            sql = list(row.values())[0]
            f.write(sql)
            if not sql.strip().endswith(';'):
                f.write(';')
            f.write("\n\n")

# Получаем свежий дамп функций
os.system("mv /Users/dmitrit./.cursor/projects/Users-dmitrit-projectgt/agent-tools/adc90c8b-0003-45d5-9545-da0439019d23.txt functions_dump.json")
fix_file('functions_dump.json', 'supabase/migrations/full_snapshot_FINAL.sql')
