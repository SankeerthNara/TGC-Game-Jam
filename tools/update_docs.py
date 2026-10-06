"""
Updates docs/AI_USAGE.md and CREDITS.md with the prompt logs and generator details.
"""

new_ai_usage_row = '| 2026-10-05 | Antigravity | The Editions High-Fidelity Character Sprites & Master Sheets (AI Image Generation Model): Replaced childish flat-polygon sprites with mature, high-fidelity painted comic and true pixel art characters. Master turnaround sheets (pulp_hero_sheet, narrator_friendly_sheet, narrator_villain_sheet); 2K painted comic hero animation frames (hero_idle, hero_run1, hero_run2, hero_jump, hero_attack, hero_dash, hero_hurt; 512x512 PNG RGBA, right-facing, bottom-grounded, 8-heads-tall athletic proportions, torn crimson cape, glowing white eyes, light blade); 2K Narrator final boss & Masked Villain (narrator_boss, masked_villain; 768x768 PNG RGBA, purple tailcoat with gold trim, giant quill dripping black ink); 2K comms dialogue portraits (hero, narrator_friendly, narrator_evil; 512x512 PNG); 720p true pixel art brawler hero frames (px_hero, px_hero_run1, px_hero_run2, px_hero_punch, px_hero_kick, px_hero_roll, px_hero_hurt; 64x64 PNG RGBA, 58px tall, <=24 colors, hard alpha); 720p pixel portraits (px_narrator_friendly, px_narrator_evil; 96x96 PNG); quality validation previews (preview_2k.png, preview_720.png). | `new-game-project/assets/editions/sprites/*`, `new-game-project/assets/editions/portraits/*`, `new-game-project/assets/editions/reference/*` |'

prompts_doc = """

## Prompt Log: The Editions Character Art & Sprites (2026-10-05)

### Generator: Google Gemini Image Model (`gemini-3.1-flash-image`) via Antigravity `generate_image`

1. **Master Turnaround Sheet: The Pulp Hero (`pulp_hero_sheet.jpg`)**
   - *Prompt*: "Character master turnaround sheet, model sheet for the PULP HERO. Three full body poses on a clean neutral solid light background: front view, three-quarter view, and side profile view. Adult man, athletic and lean, heroic proportions, 8 heads tall, small head, long legs, broad shoulders, narrow waist. NOT chibi, NOT cute, NOT big-headed. Confident, dangerous, stunning, heroic posture. Navy-blue fitted superhero suit with subtle fabric folds and armour seams, high stiff collar, gold lightning emblem on the chest, dark gloves and boots, gold belt. Long torn crimson cape with ragged tattered edges. Black domino mask with glowing solid white eyes (no pupils), sharp masculine jaw, short swept black hair. Holding a glowing blade of pure white-gold light in his right hand. Art style: painted comic illustration with bold ink outlines, rich painterly shading, warm amber rim light on one side and cool teal shadows on the other, matching gothic cathedral library lighting."
   - *References*: `2k/hall_far.jpg`, `2k/arena_far.jpg`

2. **Master Turnaround Sheet: The Narrator / Friendly Guide (`narrator_friendly_sheet.jpg`)**
   - *Prompt*: "Character master turnaround sheet, model sheet for THE NARRATOR (opera-house ringmaster and secretly masked villain). Three full body poses on a clean neutral solid light background: front view, three-quarter view, and side profile view. Tall, gaunt, elegant adult man with long limbs, long slender fingers, dramatic theatrical posture. Costume: deep dark purple tailcoat with ornate gold filigree embroidery trim and long split tails, high stiff collar, crisp white cravat, gold chain pocket watch. Friendly ringmaster look: tall black silk top hat with a crimson velvet band and gold buckle, a gold monocle over his left eye, thin curled pencil moustache, a warm charismatic but slightly too-wide sinister smile. Weapon: holding a GIANT feathered quill pen in his hand that drips supernatural glowing black ink and absorbs ambient light. Art style: painted comic illustration with bold dark ink outlines, rich painterly shading, warm amber backlight on one side and cool teal shadows on the other. Consistent proportions across all views."
   - *References*: `2k/arena_far.jpg`, `2k/hall_far.jpg`

3. **Master Turnaround Sheet: The Masked Villain & Evil Reveal (`narrator_villain_sheet.jpg`)**
   - *Prompt*: "Character model turnaround sheet for THE MASKED VILLAIN and UNMASKED EVIL NARRATOR. The EXACT same man and costume from the reference image, but in his villainous reveal: Three full body poses on a clean neutral light background: 1) Left pose: Masked villain wearing a deep purple hooded tailcoat with gold trim, a stark porcelain white theatre mask with narrow slanted eye holes, dramatic menacing ringmaster posture, holding the giant feathered quill dripping black ink. 2) Center pose: Unmasked evil final boss version: the hood is down, showing his face with slicked black hair, cracked monocle, furious manic wide grin, tall and gaunt, conducting dark ink magic with the giant quill. 3) Right pose: Side profile of the masked hooded villain. High-end painted comic illustration style with bold ink outlines, rich chiaroscuro painterly shading, deep purple and teal shadows, warm amber backlight. Identical body proportions and tailcoat to reference image."
   - *References*: `narrator_friendly_sheet.jpg`, `2k/arena_dark.jpg`

4. **2K Hero Frames (`hero_idle`, `hero_run1`, `hero_run2`, `hero_jump`, `hero_attack`, `hero_dash`, `hero_hurt`)**
   - *Model*: `gemini-3.1-flash-image` with `pulp_hero_sheet.jpg` reference.
   - Poses:
     - `hero_idle.png`: Ready stance, blade low, cape moving softly, facing right.
     - `hero_run1.png`: Left leg forward sprint stride, cape flowing back.
     - `hero_run2.png`: Right leg forward driving stride, cape flowing back.
     - `hero_jump.png`: Mid-air leap, knees bent up, cape flaring upward.
     - `hero_attack.png`: Deep forward lunge, wide horizontal slash with luminous white-gold arc trail.
     - `hero_dash.png`: Low forward slipstream dash, cape horizontal behind.
     - `hero_hurt.png`: Recoil from impact, gritted teeth, cape twisted in mid-air.
   - *Post-Processing*: Background removal via flood-fill border masking, horizontal centering, feet grounded to bottom edge of 512x512 canvas.

5. **2K Narrator Frames (`narrator_boss`, `masked_villain`)**
   - `narrator_boss.png`: 768x768 PNG RGBA, unmasked final boss battle conductor pose, raising giant quill with glowing swirling ink tendrils, furious grin.
   - `masked_villain.png`: 768x768 PNG RGBA, hooded in purple with gold trim, porcelain white theatre mask with glowing violet eyes, claw gesture, giant quill.

6. **2K Dialogue Portraits (`hero`, `narrator_friendly`, `narrator_evil`)**
   - `hero.png`: 512x512 PNG RGBA, intense close-up, glowing white eyes, sharp jaw, high stiff collar.
   - `narrator_friendly.png`: 512x512 PNG RGBA, tall top hat, monocle, curled moustache, warm theatrical smile.
   - `narrator_evil.png`: 512x512 PNG RGBA, cracked monocle, slicked hair, manic furious wide grin.

7. **720p Pixel Art Sprites & Portraits**
   - Downscaled using bilinear filtering to target bounding box, grounded to bottom row (y=64), hard 1-bit alpha thresholding, quantized to at most 24 colors with median-cut algorithm.
"""

new_credits_row = '| The Editions High-Fidelity Character Sprites & Master Sheets | 2D Art | Antigravity AI Image Generator (`gemini-3.1-flash-image`) | AI-generated with Antigravity, logged in docs/AI_USAGE.md | CC0 1.0 Universal | `new-game-project/assets/editions/sprites/*`, `new-game-project/assets/editions/portraits/*`, `new-game-project/assets/editions/reference/*` |'

for base in ['D:/Infinium/wt-anti', 'd:/Infinium/TGC-Game-Jam']:
    ai_usage_path = f'{base}/docs/AI_USAGE.md'
    credits_path = f'{base}/CREDITS.md'
    
    # AI_USAGE
    content = open(ai_usage_path, encoding='utf-8').read()
    if 'The Editions High-Fidelity Character Sprites' not in content:
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
    if 'The Editions High-Fidelity Character Sprites' not in content:
        lines = content.splitlines()
        table_lines = [l for l in lines if l.startswith('|')]
        last_table_line = table_lines[-1] if table_lines else ''
        idx = content.rfind(last_table_line) + len(last_table_line)
        content = content[:idx] + '\n' + new_credits_row + content[idx:]
        with open(credits_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print('Updated', credits_path)
