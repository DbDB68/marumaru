"""Generate the editable courtyard blockout from the owner's September layout.

Coordinates follow the drawing; buildings without labels are scenery for now.
Run from any directory with Python. No external image dependencies.
"""
from pathlib import Path
import math

ROOT = Path(__file__).resolve().parents[1]
parts = ['''[gd_scene load_steps=5 format=3]
[ext_resource type="Script" path="res://scripts/room.gd" id="room"]
[ext_resource type="PackedScene" path="res://scenes/player.tscn" id="player"]
[ext_resource type="PackedScene" path="res://scenes/door.tscn" id="door"]
[ext_resource type="PackedScene" path="res://scenes/dialog_box.tscn" id="dialog"]
[node name="Courtyard" type="Node2D"]
script = ExtResource("room")
room_id = "courtyard"
room_size = Vector2(1280, 1120)
''']
counter = 0


def node(kind, props, parent='.', name=None):
    global counter
    counter += 1
    name = name or f'{kind}{counter}'
    parts.append(f'[node name="{name}" type="{kind}" parent="{parent}"]\n{props}\n')
    return name


def color(hex_value):
    return 'Color(%s, 1)' % ', '.join(str(int(hex_value[i:i+2], 16)/255) for i in (0, 2, 4))


def points(coords):
    return 'PackedVector2Array(%s)' % ', '.join(str(round(v, 2)) for xy in coords for v in xy)


def poly(coords, tint, z=-5):
    node('Polygon2D', f'polygon = {points(coords)}\ncolor = {color(tint)}\nz_index = {z}')


def solid(coords):
    body = node('StaticBody2D', '')
    node('CollisionPolygon2D', f'polygon = {points(coords)}', body)


def rect(x, y, w, h, tint, collision=False):
    p = [(x,y),(x+w,y),(x+w,y+h),(x,y+h)]
    poly(p,tint)
    if collision:
        solid(p)


def line(coords, tint, width, z=-8):
    node('Line2D', f'points = {points(coords)}\nwidth = {width}\ndefault_color = {color(tint)}\njoint_mode = 2\nbegin_cap_mode = 2\nend_cap_mode = 2\nz_index = {z}')


def label(x,y,text):
    node('Label', f'offset_left = {x-55}.0\noffset_top = {y}.0\noffset_right = {x+55}.0\ntext = "{text}"\nhorizontal_alignment = 1\ntheme_override_font_sizes/font_size = 14\ntheme_override_colors/font_color = {color("443e39")}')


def building(x,y,w,h,title=''):
    rect(x+5,y+7,w,h,'a9aa85')
    rect(x,y,w,h,'a67f58',True)
    rect(x+5,y+5,w-10,h-10,'dfc59b')
    rect(x-5,y-8,w+10,22,'626b69')
    line([(x,y+3),(x+w,y+3)],'8b9590',3,-4)
    if title:
        label(x+w/2,y+h/2-8,title)


poly([(0,0),(1280,0),(1280,1120),(0,1120)],'c3c99c',-10)
# Sparse, deterministic ground marks keep the blockout legible.
for i in range(330):
    x,y = (i*173+29)%1250+15,(i*317+41)%1090+15
    rect(x,y,3,2,'b6bf91')
for x,y,w,h in [(0,0,1280,12),(0,1108,1280,12),(0,0,12,1120),(1268,0,12,1120)]:
    rect(x,y,w,h,'818974',True)

paths = [
    [(710,300),(770,300),(800,340),(855,350),(900,290)],
    [(610,440),(610,550),(640,625),(700,645),(755,625),(785,560),(850,495),(900,465),(945,485),(970,535),(1040,540),(1115,510),(1170,455),(1180,360),(1140,270),(1060,235),(975,220),(925,260),(900,290)],
    [(755,625),(785,715),(830,760),(890,765),(970,705),(1050,710),(1117,710),(1117,615),(1150,560),(1115,510)],
    [(975,220),(935,185),(930,135),(930,60)],
    [(1060,235),(1100,175),(1170,130),(1180,90)],
    [(1050,675),(1050,830)],
    [(700,645),(550,645),(420,730),(245,820)],
    [(550,645),(460,530),(340,440),(180,440),(180,275)],
]
for p in paths:
    line(p,'bca67c',30)
    line(p,'ecd8ab',24,-7)

# Footprints retain the drawing's north entrance, west wings and east garden.
for b in [(555,25,210,125,''),(570,160,130,195,'主屋'),(425,385,210,80,'缘侧'),
          (325,270,145,90,'厨房'),(155,500,245,80,'手合场'),(155,580,65,160,''),
          (330,580,70,160,''),(90,340,75,105,''),(215,325,90,70,''),
          (205,25,260,32,''),(890,25,85,30,''),(1000,25,85,30,''),
          (230,855,160,50,''),(470,755,80,45,''),(840,270,90,45,''),
          (1030,840,45,48,'')]:
    building(*b)
rect(170,115,300,130,'98ac79')
for y in range(126,240,18):
    line([(180,y),(460,y)],'788e62',5,-4)
label(320,160,'田地')

# Pond and creek are solid, with deliberate gaps under both wooden bridges.
pond=[(724,460),(755,440),(786,450),(800,485),(793,515),(808,540),(794,584),(769,601),(732,580),(718,540),(725,510),(710,485)]
poly(pond,'80aeb8')
# Cut a diagonal corridor through the pond collider, matching the deck width.
def clip_bank(vertices, threshold, keep_less):
    result = []
    for a, b in zip(vertices, vertices[1:] + vertices[:1]):
        va, vb = sum(a) - threshold, sum(b) - threshold
        inside_a = va <= 0 if keep_less else va >= 0
        inside_b = vb <= 0 if keep_less else vb >= 0
        if inside_a:
            result.append(a)
        if inside_a != inside_b:
            t = va / (va - vb)
            result.append((a[0] + t*(b[0]-a[0]), a[1] + t*(b[1]-a[1])))
    return result

solid(clip_bank(pond, 1320, True))
solid(clip_bank(pond, 1380, False))
creek=[(795,585),(805,620),(820,655),(850,666),(885,649),(922,650),(958,665),(995,658),(1030,644),(1094,659),(1135,670),(1175,665),(1270,665)]
line(creek,'80aeb8',18,-4)
for a,b in zip(creek,creek[1:]):
    # The eastern crossing sits at x=1120; split the water collider there.
    segments=[(a,b)]
    if a[0] == 1094:
        segments=[(a,(1104,662)),((1130,669),b)]
    for start,end in segments:
        dx,dy=end[0]-start[0],end[1]-start[1]
        length=math.hypot(dx,dy)
        nx,ny=-dy/length*9,dx/length*9
        solid([(start[0]+nx,start[1]+ny),(end[0]+nx,end[1]+ny),(end[0]-nx,end[1]-ny),(start[0]-nx,start[1]-ny)])
rect(1103,647,28,39,'c59c6d')
for y in range(650,684,6):
    line([(1103,y),(1131,y)],'876d52',2,-3)
# Diagonal bridge extends onto dry land at both ends.
line([(745,605),(840,510)],'ad805d',46,-3)
line([(745,605),(840,510)],'e2bd89',42,-2)
for step in range(0, 96, 8):
    x, y = 745 + step, 605 - step
    line([(x-13,y-13),(x+13,y+13)],'987453',2,-1)

for x,y,r,cherry in [(1030,330,40,True),(1010,400,42,True),(1075,410,20,True),
    (920,550,22,True),(970,590,18,True),(1050,605,23,True),
    (1180,210,45,False),(1200,650,35,False),(850,730,40,False),
    (620,820,42,False),(1170,900,58,False),(1020,990,50,False),
    (100,950,60,False),(290,995,48,False),(80,480,40,False)]:
    rect(x-5,y-4,10,16,'82745a',True)
    canopy=[(x+math.cos(i*math.tau/12)*r,y-23+math.sin(i*math.tau/12)*r*.8) for i in range(12)]
    poly(canopy,'dca5ae' if cherry else '91a779',1)

node('Node2D','','.', 'Spawns')
destinations=[('Main',710,300,'FromCourtyard','主屋'),('Kitchen',480,325,'FromMain','厨房'),
              ('Engawa',645,435,'FromMain','缘侧'),('Dojo',410,540,'FromEngawa','手合场'),
              ('Field',320,255,'FromCourtyard','田地')]
for room,x,y,target,title in destinations:
    parts.append(f'''[node name="DoorTo{room}" parent="." instance=ExtResource("door")]
position = Vector2({x}, {y})
target_room = "res://scenes/{room.lower()}.tscn"
target_spawn = "{target}"
''')
    sx,sy=(x+44,y) if room in ('Main','Kitchen','Engawa','Dojo') else (x,y+44)
    node('Marker2D',f'position = Vector2({sx}, {sy})','Spawns',f'From{room}')
    rect(x-18,y-10,36,20,'f3dea5')
    label(sx,sy+18,title+' ↑' if sx==x else title+' ←')
parts.append('''[node name="Player" parent="." instance=ExtResource("player")]
position = Vector2(689, 435)
[node name="DialogBox" parent="." instance=ExtResource("dialog")]
[node name="HUD" type="CanvasLayer" parent="."]
[node name="HintBackground" type="ColorRect" parent="HUD"]
offset_top = 332.0
offset_right = 640.0
offset_bottom = 360.0
color = Color(0.93, 0.90, 0.80, 0.95)
mouse_filter = 2
[node name="Hint" type="Label" parent="HUD"]
offset_left = 8.0
offset_top = 334.0
theme_override_font_sizes/font_size = 12
theme_override_colors/font_color = Color(0.22, 0.25, 0.19, 1)
text = "庭院 · WASD 移动 / Z 搭话 / 踩门进屋 · 草地也能走"
''')
(ROOT/'scenes/courtyard.tscn').write_text('\n'.join(parts),encoding='utf-8')
