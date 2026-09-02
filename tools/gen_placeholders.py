# 占位素材生成器：小狐狸主角 sprite sheet + 木地板 tile
# 以后换正式素材时直接替换 assets/sprites/ 下的 png 即可（保持尺寸一致）
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets" / "sprites"
OUT.mkdir(parents=True, exist_ok=True)

# ---------- 主角：2 帧 × 4 方向，单帧 16x24 ----------
FW, FH = 16, 24
ROWS = ["down", "up", "left", "right"]  # 行顺序，tscn 里按这个取

BODY = (222, 148, 60, 255)      # 狐狸橘
BODY_D = (190, 118, 40, 255)    # 暗面
CREAM = (250, 238, 210, 255)    # 肚皮/脸
DARK = (60, 40, 30, 255)        # 眼睛/鼻尖
SCARF = (180, 50, 50, 255)      # 红围巾，占位也要有点性格


def draw_frame(facing: str, step: int) -> Image.Image:
    img = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    bob = 1 if step == 1 else 0  # 第二步身体下沉 1px
    top = 2 + bob
    # 耳朵
    d.polygon([(3, top + 4), (5, top), (7, top + 4)], fill=BODY)
    d.polygon([(9, top + 4), (11, top), (13, top + 4)], fill=BODY)
    d.point([(5, top + 2), (11, top + 2)], fill=CREAM)
    # 头
    d.rectangle([3, top + 4, 12, top + 11], fill=BODY)
    # 身体
    d.rectangle([4, top + 12, 11, top + 18], fill=BODY)
    d.rectangle([4, top + 12, 11, top + 13], fill=SCARF)  # 围巾
    # 腿（走路交替）
    if step == 0:
        d.rectangle([5, top + 19, 6, top + 21], fill=BODY_D)
        d.rectangle([9, top + 19, 10, top + 20], fill=BODY_D)
    else:
        d.rectangle([5, top + 19, 6, top + 20], fill=BODY_D)
        d.rectangle([9, top + 19, 10, top + 21], fill=BODY_D)
    # 尾巴（侧后方一撮）
    if facing == "left":
        d.rectangle([12, top + 13, 14, top + 16], fill=BODY)
        d.point([(14, top + 13)], fill=CREAM)
    elif facing == "right":
        d.rectangle([1, top + 13, 3, top + 16], fill=BODY)
        d.point([(1, top + 13)], fill=CREAM)
    else:
        d.rectangle([12, top + 14, 13, top + 16], fill=BODY_D)
    # 脸
    if facing == "down":
        d.rectangle([5, top + 7, 10, top + 10], fill=CREAM)
        d.point([(5, top + 8), (10, top + 8)], fill=DARK)      # 眼
        d.point([(7, top + 10), (8, top + 10)], fill=DARK)     # 鼻
    elif facing == "up":
        d.rectangle([3, top + 4, 12, top + 6], fill=BODY_D)    # 后脑勺暗面
    elif facing == "left":
        d.rectangle([4, top + 7, 8, top + 10], fill=CREAM)
        d.point([(5, top + 8)], fill=DARK)
        d.point([(4, top + 10)], fill=DARK)
    else:  # right
        d.rectangle([7, top + 7, 11, top + 10], fill=CREAM)
        d.point([(10, top + 8)], fill=DARK)
        d.point([(11, top + 10)], fill=DARK)
    return img


sheet = Image.new("RGBA", (FW * 2, FH * 4), (0, 0, 0, 0))
for r, facing in enumerate(ROWS):
    for c in range(2):
        sheet.paste(draw_frame(facing, c), (c * FW, r * FH))
sheet.save(OUT / "player.png")

# ---------- 压切长谷部（占位）：黑短发、深紫衣装配金扣 ----------
HAIR = (42, 38, 52, 255)
HAIR_D = (30, 27, 40, 255)
SKIN = (246, 224, 200, 255)
CLOTH = (56, 50, 82, 255)      # 深紫上衣
CLOTH_D = (44, 39, 66, 255)
GOLD = (205, 172, 92, 255)
PANTS = (36, 33, 48, 255)


def draw_hasebe(facing: str, step: int) -> Image.Image:
    img = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    bob = 1 if step == 1 else 0
    top = 1 + bob
    # 头发（盖头顶+两侧）
    d.rectangle([3, top, 12, top + 5], fill=HAIR)
    d.rectangle([3, top + 5, 4, top + 9], fill=HAIR)
    d.rectangle([11, top + 5, 12, top + 9], fill=HAIR)
    # 脸
    d.rectangle([5, top + 6, 10, top + 10], fill=SKIN)
    # 身体
    d.rectangle([4, top + 12, 11, top + 18], fill=CLOTH)
    d.line([(7, top + 12), (7, top + 18)], fill=GOLD)  # 前襟金线
    d.point([(8, top + 14), (8, top + 16)], fill=GOLD)  # 金扣
    # 腿（交替迈步）
    if step == 0:
        d.rectangle([5, top + 19, 6, top + 21], fill=PANTS)
        d.rectangle([9, top + 19, 10, top + 20], fill=PANTS)
    else:
        d.rectangle([5, top + 19, 6, top + 20], fill=PANTS)
        d.rectangle([9, top + 19, 10, top + 21], fill=PANTS)
    if facing == "down":
        d.rectangle([5, top + 3, 10, top + 5], fill=HAIR)  # 刘海
        d.point([(5, top + 8), (10, top + 8)], fill=DARK)
    elif facing == "up":
        d.rectangle([3, top, 12, top + 10], fill=HAIR)
        d.rectangle([3, top + 7, 12, top + 9], fill=HAIR_D)  # 后发暗面
        d.rectangle([5, top + 10, 10, top + 10], fill=SKIN)  # 后颈
    elif facing == "left":
        d.rectangle([5, top + 3, 10, top + 4], fill=HAIR)
        d.point([(5, top + 8)], fill=DARK)
        d.line([(7, top + 12), (7, top + 18)], fill=CLOTH_D)
    else:  # right
        d.rectangle([5, top + 3, 10, top + 4], fill=HAIR)
        d.point([(10, top + 8)], fill=DARK)
        d.line([(8, top + 12), (8, top + 18)], fill=CLOTH_D)
    return img


hsheet = Image.new("RGBA", (FW * 2, FH * 4), (0, 0, 0, 0))
for r, facing in enumerate(ROWS):
    for c in range(2):
        hsheet.paste(draw_hasebe(facing, c), (c * FW, r * FH))
hsheet.save(OUT / "hasebe.png")

# ---------- 木地板：16x16 可平铺 ----------
T = 16
floor = Image.new("RGBA", (T, T))
d = ImageDraw.Draw(floor)
WOOD = [(166, 124, 82, 255), (156, 115, 74, 255), (171, 129, 87, 255), (150, 110, 70, 255)]
GAP = (110, 80, 52, 255)
for y in range(T):
    plank = (y // 4) % 4
    for x in range(T):
        shade = ((x * 7 + y * 13) % 5) - 2  # 轻微噪点
        c = WOOD[plank]
        floor.putpixel((x, y), (c[0] + shade, c[1] + shade, c[2] + shade, 255))
for y in range(0, T, 4):
    d.line([(0, y), (T - 1, y)], fill=GAP)
for i, y in enumerate(range(0, T, 4)):  # 错缝
    xoff = 8 if i % 2 else 0
    d.point([(xoff, y + 1), (xoff, y + 2), (xoff, y + 3)], fill=GAP)
floor.save(OUT / "floor.png")

# ---------- 草地：16x16 可平铺 ----------
grass = Image.new("RGBA", (T, T))
d = ImageDraw.Draw(grass)
GRASS = [(110, 152, 78, 255), (102, 144, 72, 255), (118, 158, 84, 255)]
for y in range(T):
    for x in range(T):
        c = GRASS[(x * 5 + y * 11) % 3]
        shade = ((x * 13 + y * 7) % 7) - 3
        grass.putpixel((x, y), (c[0] + shade, c[1] + shade, c[2] + shade, 255))
# 草叶尖：深色小点随机撒
for i in range(14):
    x, y = (i * 37 + 5) % T, (i * 53 + 9) % T
    grass.putpixel((x, y), (80, 118, 56, 255))
    if (x, y + 1)[1] < T:
        grass.putpixel((x, y + 1), (96, 136, 66, 255))
grass.save(OUT / "grass.png")

# ---------- 樱花树：48x64，树冠粉色+树干 ----------
TW, TH = 48, 64
tree = Image.new("RGBA", (TW, TH), (0, 0, 0, 0))
d = ImageDraw.Draw(tree)
TRUNK = (96, 66, 44, 255)
TRUNK_D = (76, 52, 34, 255)
BLOOM = [(238, 178, 196, 255), (244, 196, 210, 255), (228, 160, 182, 255)]
# 树干
d.rectangle([21, 40, 26, 61], fill=TRUNK)
d.line([(22, 40), (22, 61)], fill=TRUNK_D)
d.polygon([(16, 62), (32, 62), (28, 56), (20, 56)], fill=TRUNK_D)  # 根部
# 树冠：几团圆
blobs = [(24, 22, 16), (12, 30, 10), (36, 30, 10), (18, 14, 9), (30, 14, 9)]
for cx, cy, r in blobs:
    c = BLOOM[(cx + cy) % 3]
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=c)
# 花瓣高光点
for i in range(20):
    x, y = (i * 29 + 7) % TW, (i * 17 + 3) % 40
    if tree.getpixel((x, y))[3] > 0:
        tree.putpixel((x, y), (252, 224, 234, 255))
tree.save(OUT / "tree.png")

# ---------- 铺盖（被褥）：32x20，横放 ----------
futon = Image.new("RGBA", (32, 20), (0, 0, 0, 0))
d = ImageDraw.Draw(futon)
SHEET = (240, 240, 232, 255)     # 床单
BLANKET = (64, 90, 120, 255)     # 被子（绀色）
BLANKET_D = (52, 74, 100, 255)
PILLOW = (250, 248, 240, 255)
PILLOW_D = (224, 220, 208, 255)
d.rectangle([0, 2, 31, 17], fill=SHEET)          # 床单
d.rectangle([2, 4, 9, 15], fill=PILLOW)          # 枕头
d.line([(2, 15), (9, 15)], fill=PILLOW_D)
d.rectangle([11, 3, 31, 16], fill=BLANKET)       # 被子
d.line([(11, 3), (11, 16)], fill=BLANKET_D)
d.line([(14, 4), (14, 15)], fill=BLANKET_D)      # 被子褶
d.line([(20, 4), (20, 15)], fill=BLANKET_D)
d.line([(26, 4), (26, 15)], fill=BLANKET_D)
futon.save(OUT / "futon.png")

print("done: assets/sprites/player.png, hasebe.png, floor.png, grass.png, tree.png, futon.png")
