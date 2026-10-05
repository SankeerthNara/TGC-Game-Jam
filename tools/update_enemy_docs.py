"""
Update docs/AI_USAGE.md and CREDITS.md with 2K enemy assets, prompts, and attribution.
"""

new_ai_usage_row = '| 2026-10-05 | Antigravity | The Editions 2K Enemies & Boss Sprites (AI Image Generation Model): Replaced flat vector enemy sprites with high-fidelity painted comic characters matching the 2K gothic backgrounds. Master turnaround sheets (lancer_master_sheet, bat_master_sheet, brute_master_sheet, baron_master_sheet); 2K painted enemy sprites (enemy_lancer 512x512, enemy_bat 512x512, enemy_brute 768x768, enemy_baron 768x768; transparent PNG RGBA, right-facing, bottom-grounded, no trapped pocket areas); dialogue comms portraits (ink_baron 512x512, static_twins 512x512); validation check preview (preview_enemies.png). | `new-game-project/assets/editions/sprites/enemy_*`, `new-game-project/assets/editions/portraits/*`, `new-game-project/assets/editions/reference/*` |'

prompts_doc = """

### The Editions 2K Enemies, Bosses & Comms Portraits (2026-10-05)

**Generator**: Google Gemini Image Model (`gemini-3.1-flash-image`) via Antigravity `generate_image`

1. **Enemy Lancer (Opera Chorister Soldier) (`enemy_lancer.png` & `lancer_master_sheet.jpg`)**
   - *Master Sheet Prompt*: "Character master turnaround sheet for ENEMY LANCER (hooded opera chorister soldier). Three full body poses on a clean neutral solid light background: front view, three-quarter view, and side view. Tall, thin, sinister gothic chorister soldier. Completely faceless void under a deep dark hooded cowl with faint glowing teal eyes. Flowing tattered opera vestments and choir robes stained with black ink dripping at the edges, dark leather bracers and boots. Holding a long ornate gothic iron lance with an ink-tipped spearhead. Style: painted comic illustration with bold ink contours, rich painterly shading, warm amber rim lighting on one side and cool teal shadows on the other, matching the gothic library and opera cathedral aesthetic. Menacing, adult, non-cartoon. Proportions consistent across all views. Lance fully visible inside frame."
   - *Game Sprite Prompt*: "Full body 2D game sprite of ENEMY LANCER (hooded opera chorister soldier), facing RIGHT. Exactly matching the costume, face, and lance design from the reference image. Tall, thin, sinister chorister in deep forward-leaning ready thrust pose facing right. Faceless shadow under deep hooded cowl with faint glowing teal eyes, ink-dripping tattered choir robes, holding the ornate gothic iron lance with both hands pointing forward-right in a menacing combat thrust stance. Solid pure white background, no floor, no shadows, no text. Entire character and whole lance fully contained inside the canvas without any cropping. Bold ink outlines, rich painterly shading, warm amber and teal rim lights."

2. **Enemy Bat (Paper & Ink Origami Chimera) (`enemy_bat.png` & `bat_master_sheet.jpg`)**
   - *Master Sheet Prompt*: "Character turnaround sheet for ENEMY BAT (paper-and-ink origami chimera bat). Three views on clean neutral solid light background: front view with wings spread, three-quarter view, and side flight profile. A menacing monstrous gothic bat made entirely of torn parchment and antique manuscript paper pages, origami folded parchment wings with ink text fragments and ragged burnt edges dripping black liquid ink, sharp origami paper fangs, eerie glowing amber eyes, paper talon claws. Style: painted comic illustration with bold dark ink contours, rich painterly shading, warm amber and teal highlights, matching the gothic library atmosphere. Adult, dangerous, non-cute. Consistent design across all views. Wings fully inside frame."
   - *Game Sprite Prompt*: "Full 2D game sprite of ENEMY BAT in mid-air flight, facing RIGHT. Exactly matching the torn manuscript paper texture, folded origami anatomy, dripping black ink wingtips, and glowing amber eyes from the reference image. Menacing gothic origami bat flying horizontally towards the right, wide wings spread with tattered burnt edges dripping ink droplets, snarling paper fangs, talons extended. Solid pure white background, no floor, no shadows, no text. Whole creature including full wingspan completely contained inside canvas without any clipping. Painted comic illustration with bold dark ink contours and rich painterly lighting."

3. **Enemy Brute (Brass Furnace Golem) (`enemy_brute.png` & `brute_master_sheet.jpg`)**
   - *Master Sheet Prompt*: "Character master turnaround sheet for ENEMY BRUTE (hulking brass furnace golem). Three full body poses on clean neutral solid light background: front view, three-quarter view, and side view. A colossal, heavy steampunk gothic automaton golem. Heavy riveted brass and bronze armor plates, thick clockwork gears and hydraulic joints, glowing molten furnace fire burning behind an iron grill on its chest casting fiery orange light, massive heavy brass gauntlets and sledgehammer fists, hunched imposing menacing stance, glowing amber sensor optics. Style: painted comic illustration with bold ink contours, rich painterly shading, warm molten core lighting and teal metallic rim reflections, matching the opera cathedral arena aesthetic. Dangerous, adult, non-cartoon. Proportions consistent across all views."
   - *Game Sprite Prompt*: "Full body 2D game sprite of ENEMY BRUTE (hulking brass golem), facing RIGHT. Exactly matching the riveted brass plates, glowing fiery furnace chest grate, and heavy mechanical fists from the reference image. Imposing heavy forward combat stance facing right, right arm cocked back ready to deliver a crushing punch, left arm forward in guard. Fiery molten orange light glowing from the furnace chest grill, glowing optic eyes. Solid pure white background, no floor, no shadows, no text. Entire automaton fully inside canvas without any clipping. Bold ink contours, rich painterly metallic shading, warm fiery core lighting."

4. **Enemy Baron (The Ink Baron Boss) (`enemy_baron.png` & `baron_master_sheet.jpg`)**
   - *Master Sheet Prompt*: "Character master turnaround sheet for THE INK BARON (towering ringmaster made of living nightmare ink). Three full body poses on clean neutral solid light background: front view, three-quarter view, and side view. A towering, grotesque yet dapper ringmaster boss composed entirely of swirling viscous liquid black ink. Wears a battered tall black top hat perched crookedly, a sharp black cane with an ornate gold handle, a dark tailcoat whose long tails melt and drip into bubbling ink puddles on the ground. A wide, terrifying cheshire-like sharp-toothed white grin gleaming from a shadowy ink face, glowing yellow-amber eyes, claw-like dripping ink fingers. Style: painted comic illustration with bold ink contours, rich chiaroscuro shading, deep purple and teal specular reflections on the glossy liquid ink, warm amber rim lighting. Dangerous, adult, non-cartoon. Proportions consistent across all views. Cane and hat fully inside frame."
   - *Game Sprite Prompt*: "Full body 2D game sprite of ENEMY BARON (the Ink Baron boss), facing RIGHT. Exactly matching the living liquid ink body, dripping coat tails, battered top hat, gold-headed cane, and terrifying wide white grin from the reference image. Towering ringmaster boss standing in a sinister theatrical battle posture facing right, holding his cane firmly, left claw raised dripping ink, coat tails flowing and dripping bubbling black ink droplets at the bottom. Glowing amber eyes shining through shadowy ink face, sharp grinning teeth. Solid pure white background, no room, no floor shadow, no text. Whole figure from top of battered top hat to bottom of dripping ink hem fully inside canvas. Bold comic ink contours, rich chiaroscuro painterly shading, glossy purple-teal reflections."

5. **Comms Portraits: Ink Baron & Static Twins (`ink_baron.png` & `static_twins.png`)**
   - *Ink Baron*: Close-up head and shoulders comms dialogue portrait, battered crooked top hat dripping black ink, wide sharp-toothed grin, glowing yellow-amber eyes, living ink cowl.
   - *Static Twins*: Close-up comms dialogue portrait, two identical lanky brawlers shoulder-to-shoulder with vintage boxy CRT television heads, rabbit-ear antennas, screens flickering with television static forming ghostly grinning digital faces with glowing eyes, dark worn bomber jackets.
"""

new_credits_row = '| The Editions 2K Enemies, Bosses & Comms Portraits | 2D Art | Antigravity AI Image Generator (`gemini-3.1-flash-image`) | AI-generated with Antigravity, logged in docs/AI_USAGE.md | CC0 1.0 Universal | `new-game-project/assets/editions/sprites/enemy_*`, `new-game-project/assets/editions/portraits/*`, `new-game-project/assets/editions/reference/*` |'

for base in ['D:/Infinium/wt-anti', 'd:/Infinium/TGC-Game-Jam']:
    ai_usage_path = f'{base}/docs/AI_USAGE.md'
    credits_path = f'{base}/CREDITS.md'
    
    # AI_USAGE
    content = open(ai_usage_path, encoding='utf-8').read()
    if 'The Editions 2K Enemies & Boss Sprites' not in content:
        lines = content.splitlines()
        table_lines = [l for l in lines if l.startswith('|')]
        last_table_line = table_lines[-1] if table_lines else ''
        idx = content.rfind(last_table_line) + len(last_table_line)
        content = content[:idx] + '\n' + new_ai_usage_row + content[idx:]
        content += prompts_doc
        with open(ai_usage_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print('Updated', ai_usage_path)
        
    # CREDITS
    content = open(credits_path, encoding='utf-8').read()
    if 'The Editions 2K Enemies, Bosses & Comms Portraits' not in content:
        lines = content.splitlines()
        table_lines = [l for l in lines if l.startswith('|')]
        last_table_line = table_lines[-1] if table_lines else ''
        idx = content.rfind(last_table_line) + len(last_table_line)
        content = content[:idx] + '\n' + new_credits_row + content[idx:]
        with open(credits_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print('Updated', credits_path)
