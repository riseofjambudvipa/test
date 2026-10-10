import os
import math
from PIL import Image, ImageDraw, ImageFont

script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(os.path.dirname(script_dir))
output_dir = os.path.join(project_root, "assets", "custom_stickers")
os.makedirs(output_dir, exist_ok=True)
size = (256, 256)

def create_red_arrow():
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Downward pointing arrow with smooth bevel effect
    # Shaft: 98 to 158 horizontal, 30 to 140 vertical
    # Head: triangle from (40, 130) to (216, 130) to (128, 226)
    
    # Shadow
    shadow_offset = 6
    draw.rounded_rectangle([98+shadow_offset, 30+shadow_offset, 158+shadow_offset, 140+shadow_offset], radius=8, fill=(0, 0, 0, 90))
    draw.polygon([(40+shadow_offset, 130+shadow_offset), (216+shadow_offset, 130+shadow_offset), (128+shadow_offset, 226+shadow_offset)], fill=(0, 0, 0, 90))

    # Outer border (white outline for contrast on any background)
    draw.rounded_rectangle([92, 24, 164, 146], radius=12, fill=(255, 255, 255, 255))
    draw.polygon([(30, 124), (226, 124), (128, 238)], fill=(255, 255, 255, 255))

    # Inner bright red body
    draw.rounded_rectangle([98, 30, 158, 140], radius=8, fill=(235, 35, 45, 255))
    draw.polygon([(40, 130), (216, 130), (128, 226)], fill=(235, 35, 45, 255))

    # Highlight streak
    draw.rounded_rectangle([104, 36, 124, 130], radius=4, fill=(255, 120, 120, 180))

    img.save(os.path.join(output_dir, "red_arrow_down.png"))

def create_verified_badge():
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Shadow
    draw.ellipse([26, 26, 236, 236], fill=(0, 0, 0, 80))
    
    # White outline
    draw.ellipse([20, 20, 230, 230], fill=(255, 255, 255, 255))
    
    # Blue circle
    draw.ellipse([26, 26, 224, 224], fill=(29, 155, 240, 255)) # Twitter/X verified blue
    
    # White checkmark (thick lines)
    # Check coords: start (75, 125) -> corner (110, 165) -> tip (180, 85)
    points = [
        (75, 125), (110, 165), (180, 85)
    ]
    draw.line([(75, 125), (110, 165)], fill=(255, 255, 255, 255), width=24)
    draw.line([(110, 165), (180, 85)], fill=(255, 255, 255, 255), width=24)
    # Smooth check joints
    draw.ellipse([75-12, 125-12, 75+12, 125+12], fill=(255, 255, 255, 255))
    draw.ellipse([110-12, 165-12, 110+12, 165+12], fill=(255, 255, 255, 255))
    draw.ellipse([180-12, 85-12, 180+12, 85+12], fill=(255, 255, 255, 255))

    img.save(os.path.join(output_dir, "verified_badge.png"))

def create_fire():
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Multi-layered stylized flame
    # Outer orange-red flame
    # Shadow
    draw.ellipse([46, 76, 216, 246], fill=(0, 0, 0, 70))

    # Outer border
    draw.polygon([(128, 14), (170, 70), (220, 130), (210, 190), (160, 242), (96, 242), (46, 190), (36, 130), (86, 70)], fill=(255, 255, 255, 255))
    
    # Outer red-orange flame
    draw.polygon([(128, 20), (166, 74), (214, 132), (204, 186), (156, 236), (100, 236), (52, 186), (42, 132), (90, 74)], fill=(255, 69, 0, 255))

    # Middle bright orange/amber flame
    draw.polygon([(128, 70), (160, 110), (186, 160), (160, 226), (96, 226), (70, 160), (96, 110)], fill=(255, 140, 0, 255))

    # Inner bright yellow core
    draw.polygon([(128, 120), (148, 150), (160, 190), (140, 220), (116, 220), (96, 190), (108, 150)], fill=(255, 235, 59, 255))

    # Innermost white hot spot
    draw.ellipse([114, 180, 142, 214], fill=(255, 255, 255, 230))

    img.save(os.path.join(output_dir, "fire_trending.png"))

def create_warning():
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Triangle warning badge
    # Shadow
    draw.polygon([(128+6, 20+6), (240+6, 226+6), (16+6, 226+6)], fill=(0, 0, 0, 80))

    # White thick outline for high contrast
    draw.polygon([(128, 14), (246, 232), (10, 232)], fill=(255, 255, 255, 255))

    # Bright yellow/amber triangle body
    draw.polygon([(128, 24), (238, 224), (18, 224)], fill=(255, 193, 7, 255))

    # Black inner border
    draw.line([(128, 40), (226, 216), (30, 216), (128, 40)], fill=(33, 33, 33, 255), width=8)

    # Exclamation mark
    # Bar: top (128, 85) to (128, 160)
    draw.line([(128, 85), (128, 155)], fill=(33, 33, 33, 255), width=18)
    draw.ellipse([128-9, 85-9, 128+9, 85+9], fill=(33, 33, 33, 255))
    draw.ellipse([128-9, 155-9, 128+9, 155+9], fill=(33, 33, 33, 255))

    # Dot
    draw.ellipse([128-11, 182-11, 128+11, 182+11], fill=(33, 33, 33, 255))

    img.save(os.path.join(output_dir, "warning_alert.png"))

def create_subscribe():
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Shadow
    draw.rounded_rectangle([16+5, 80+5, 240+5, 176+5], radius=48, fill=(0, 0, 0, 80))

    # White border
    draw.rounded_rectangle([10, 74, 246, 182], radius=54, fill=(255, 255, 255, 255))

    # Red pill button
    draw.rounded_rectangle([16, 80, 240, 176], radius=48, fill=(255, 0, 0, 255))

    # Play triangle icon on left
    draw.polygon([(46, 106), (46, 150), (84, 128)], fill=(255, 255, 255, 255))

    # White bold text "SUB" or bars
    # Draw stylized text blocks / clean letterforms
    # S
    draw.arc([100, 108, 122, 128], 90, 270, fill=(255, 255, 255, 255), width=6)
    draw.arc([100, 128, 122, 148], 270, 90, fill=(255, 255, 255, 255), width=6)
    draw.line([(111, 128), (111, 128)], fill=(255, 255, 255, 255), width=6)
    
    # U
    draw.line([(134, 108), (134, 136)], fill=(255, 255, 255, 255), width=6)
    draw.line([(156, 108), (156, 136)], fill=(255, 255, 255, 255), width=6)
    draw.arc([134, 124, 156, 148], 0, 180, fill=(255, 255, 255, 255), width=6)

    # B
    draw.line([(168, 108), (168, 148)], fill=(255, 255, 255, 255), width=6)
    draw.arc([168, 108, 192, 128], 270, 90, fill=(255, 255, 255, 255), width=6)
    draw.arc([168, 128, 192, 148], 270, 90, fill=(255, 255, 255, 255), width=6)

    # Bell icon on right
    # Bell body
    draw.polygon([(212, 116), (224, 136), (200, 136)], fill=(255, 255, 255, 255))
    draw.ellipse([207, 110, 217, 120], fill=(255, 255, 255, 255))
    draw.line([(197, 136), (227, 136)], fill=(255, 255, 255, 255), width=3)
    draw.ellipse([210, 138, 214, 142], fill=(255, 255, 255, 255))

    img.save(os.path.join(output_dir, "subscribe_button.png"))

def create_hundred():
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 100 in bright red with double underline (slanted creator style)
    # Shadow
    draw.rounded_rectangle([30+5, 195+5, 226+5, 203+5], radius=4, fill=(0, 0, 0, 70))
    draw.rounded_rectangle([30+5, 212+5, 226+5, 220+5], radius=4, fill=(0, 0, 0, 70))

    # White outlines for contrast
    # Underlines
    draw.rounded_rectangle([26, 191, 230, 207], radius=8, fill=(255, 255, 255, 255))
    draw.rounded_rectangle([26, 208, 230, 224], radius=8, fill=(255, 255, 255, 255))
    
    # Red lines
    draw.rounded_rectangle([30, 195, 226, 203], radius=4, fill=(229, 9, 20, 255))
    draw.rounded_rectangle([30, 212, 226, 220], radius=4, fill=(229, 9, 20, 255))

    # 1
    draw.line([(55, 55), (75, 45), (75, 175)], fill=(255, 255, 255, 255), width=24)
    draw.line([(55, 55), (75, 45), (75, 175)], fill=(229, 9, 20, 255), width=16)

    # First 0 (centered around x=125)
    draw.ellipse([95, 40, 155, 180], fill=(255, 255, 255, 255))
    draw.ellipse([99, 44, 151, 176], fill=(229, 9, 20, 255))
    draw.ellipse([113, 68, 137, 152], fill=(255, 255, 255, 255))
    draw.ellipse([117, 72, 133, 148], fill=(0, 0, 0, 0)) # transparent hole

    # Second 0 (centered around x=195)
    draw.ellipse([165, 40, 225, 180], fill=(255, 255, 255, 255))
    draw.ellipse([169, 44, 221, 176], fill=(229, 9, 20, 255))
    draw.ellipse([183, 68, 207, 152], fill=(255, 255, 255, 255))
    draw.ellipse([187, 72, 203, 148], fill=(0, 0, 0, 0)) # transparent hole

    img.save(os.path.join(output_dir, "hundred_points.png"))

def create_star_burst():
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 4-pointed sparkle star with golden gradient / outer white glow
    # Outer white glow
    for r in range(128, 14, -8):
        pass

    # Shadow
    draw.ellipse([128-40+5, 128-40+5, 128+40+5, 128+40+5], fill=(0, 0, 0, 60))

    # Outer 4-pointed star in white
    pts_white = [
        (128, 12), (146, 110), (244, 128), (146, 146),
        (128, 244), (110, 146), (12, 128), (110, 110)
    ]
    draw.polygon(pts_white, fill=(255, 255, 255, 255))

    # Inner golden star
    pts_gold = [
        (128, 22), (142, 114), (234, 128), (142, 142),
        (128, 234), (114, 142), (22, 128), (114, 114)
    ]
    draw.polygon(pts_gold, fill=(255, 215, 0, 255)) # Gold

    # Center white shine
    draw.ellipse([116, 116, 140, 140], fill=(255, 255, 255, 255))

    img.save(os.path.join(output_dir, "star_sparkle.png"))

def create_sound_wave():
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Neon cyan sound bars
    bars = [
        (40, 60),
        (70, 110),
        (100, 170),
        (128, 210),
        (156, 160),
        (186, 100),
        (216, 50),
    ]

    for x, h in bars:
        top = 128 - h // 2
        bottom = 128 + h // 2
        # Shadow
        draw.rounded_rectangle([x-8+4, top+4, x+8+4, bottom+4], radius=8, fill=(0, 0, 0, 60))
        # White border
        draw.rounded_rectangle([x-10, top-2, x+10, bottom+2], radius=10, fill=(255, 255, 255, 255))
        # Cyan fill
        draw.rounded_rectangle([x-7, top+1, x+7, bottom-1], radius=7, fill=(0, 229, 255, 255))

    img.save(os.path.join(output_dir, "sound_wave.png"))

if __name__ == "__main__":
    create_red_arrow()
    create_verified_badge()
    create_fire()
    create_warning()
    create_subscribe()
    create_hundred()
    create_star_burst()
    create_sound_wave()
    print("All 8 creator stickers generated successfully!")
