import sys

with open('lib/ui/pages/today_page.dart', 'r') as f:
    lines = f.readlines()

new_lines = []
weather_lines = []
in_weather = False

for line in lines:
    if line.startswith('class _CognitiveWeatherWidget'):
        in_weather = True
    
    if in_weather:
        weather_lines.append(line)
        if line.startswith('}'):
            in_weather = False
    else:
        if line.strip() == 'final paint = Paint()':
            new_lines.append(line)
        else:
            new_lines.append(line)

new_lines.extend(weather_lines)

with open('lib/ui/pages/today_page.dart', 'w') as f:
    f.writelines(new_lines)
