import json

with open('./ProyectoFinal/Media/historias.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

for node in data:
    for choice in node.get('decisiones', []):
        req = choice.get('requisitos', {})
        cons = choice.get('consecuencias', {})
        
        # Make sure no negative requirements
        for k in ['disciplina_minima', 'inteligencia_practica_minima', 'confianza_minima', 'energia_minima']:
            if k in req and req[k] < 0:
                req[k] = 0

with open('./ProyectoFinal/Media/historias.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("JSON balanced")
