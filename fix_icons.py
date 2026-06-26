import json
import os
import subprocess

with open('ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json', 'r') as f:
    data = json.load(f)

for img in data['images']:
    if 'filename' in img and 'expected-size' in img:
        size = img['expected-size']
        filename = img['filename']
        print(f"Generating {filename} ({size}x{size}) as PNG")
        subprocess.run(['sips', '-s', 'format', 'png', '-z', size, size, 'ios_icon.jpg', '--out', f'ios/Runner/Assets.xcassets/AppIcon.appiconset/{filename}'])

