import os

path = 'D:/Infinium/wt-claude/new-game-project/export_presets.cfg'
if os.path.exists(path):
    with open(path, 'r', encoding='utf-8') as f:
        text = f.read()
    old_val = 'include_filter="data/*.json, data/levels/*.json"'
    new_val = 'include_filter="data/*.json, data/levels/*.json, assets/audio/vo/*.json"'
    if old_val in text:
        text = text.replace(old_val, new_val)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(text)
        print('Updated export_presets.cfg')
    else:
        print('Already updated or pattern not found')
