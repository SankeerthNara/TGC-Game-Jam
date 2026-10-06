import os

def update_file(path, old_sub, new_sub):
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            c = f.read()
        if old_sub in c:
            c = c.replace(old_sub, new_sub)
            with open(path, 'w', encoding='utf-8') as f:
                f.write(c)
            print(f"Updated {path}")
        else:
            print(f"Pattern not found in {path}")

for base in ['D:/Infinium/wt-claude', 'D:/Infinium/TGC-Game-Jam']:
    # 1. main.gd
    p_main = os.path.join(base, 'new-game-project/scripts/core/main.gd')
    update_file(p_main, 'if event.keycode == KEY_P:', 'if event.keycode == KEY_ESCAPE:')
    update_file(p_main, '# P pauses anywhere you play (pausing only with P, not with ESC)', '# Esc pauses anywhere you play')
    update_file(p_main, 'var paused := false ## the whole game is frozen (P / Esc); the UI keeps running', 'var paused := false ## the whole game is frozen (Esc); the UI keeps running')

    # 2. ui/comic_ui.gd
    p_ui = os.path.join(base, 'new-game-project/ui/comic_ui.gd')
    update_file(p_ui, '_make_comic_button("PAUSE [P]")', '_make_comic_button("PAUSE [ESC]")')
    update_file(p_ui, '["P", "Pause / Resume game"]', '["ESC", "Pause / Resume game"]')

    # 3. scripts/editions/notice_card.gd
    p_notice = os.path.join(base, 'new-game-project/scripts/editions/notice_card.gd')
    update_file(p_notice, '["PAUSE", "P", "Pause / Resume game"]', '["PAUSE", "ESC", "Pause / Resume game"]')

    # 4. ui/main_menu.gd
    p_menu = os.path.join(base, 'new-game-project/ui/main_menu.gd')
    update_file(p_menu, '"5. [P] pauses. [M] shows the map in the first edition."', '"5. [ESC] pauses. [M] shows the map in the first edition."')

    # 5. scripts/tools/edge_test.gd
    p_edge = os.path.join(base, 'new-game-project/scripts/tools/edge_test.gd')
    update_file(p_edge, 'tap(KEY_P)', 'tap(KEY_ESCAPE)')
    update_file(p_edge, 'press(KEY_P, false)', 'press(KEY_ESCAPE, false)')

    # 6. scripts/tools/chaos_test.gd
    p_chaos = os.path.join(base, 'new-game-project/scripts/tools/chaos_test.gd')
    update_file(p_chaos, 'tap(KEY_P)', 'tap(KEY_ESCAPE)')
    update_file(p_chaos, 'press(KEY_P, false)', 'press(KEY_ESCAPE, false)')
