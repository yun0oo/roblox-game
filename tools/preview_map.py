"""Review six actual map constructors with Blender, outside Roblox Studio.
Run: blender -b -t 2 --python tools/preview_map.py
The image depicts real near-LOD geometry and landmark positions. Random garden
jitter uses a simulated deterministic RNG; native lighting, UI, particles,
physics and performance are not represented or validated.
"""
from pathlib import Path
import ast, bpy, json, math, os, subprocess, tempfile
from mathutils import Matrix, Vector
ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / 'build'; BUILD.mkdir(exist_ok=True)
# Read only constants from the existing geometry exporter; do not import its
# module, which intentionally runs its own separate rendering workflow.
tree = ast.parse((ROOT / 'tools/preview_ship.py').read_text())
H = next(ast.literal_eval(n.value) for n in tree.body if isinstance(n, ast.Assign) and any(isinstance(t, ast.Name) and t.id == 'H' for t in n.targets))
a = H.index('local world={}'); b = H.index('local function vector(v)', a)
H = H[:a] + '''local task = e.Task
local Random = { new = function(seed)
    local n = seed or 17
    return { NextNumber = function(_, low, high)
        n = (n * 16807) % 2147483647
        return (low or 0) + n / 2147483647 * ((high or 1) - (low or 0))
    end, NextInteger = function(_, low, high)
        n = (n * 16807) % 2147483647; return low + n % (high-low+1)
    end }
end }
local world
task.spawn(function() world = require(script.Parent.World).Build(config, visuals) end)
e:Drain()
''' + H[b:]
a = H.index('local base=world.Bases[1]')
H = H[:a] + '''local floors = {}
local reef = require(e.ReplicatedStorage.Modules.Reef)
for i, floor in ipairs(config.Floors) do
    local parent = world.Floors:GetChildren()[i]
    local site = reef.Landmarks[i]
    local origin = Vector3.new(site.Position[1], floor.Bottom, site.Position[2])
    local rows = dump(parent, origin)
    -- Append only this level's utility station, not other depth layers.
    local station = world.NPCs:FindFirstChild("Station oxygène " .. i)
    if station then for _, row in ipairs(dump(station, origin)) do table.insert(rows,row) end end
    table.insert(floors,{Name=floor.Name,Rows=rows})
end
print(json(floors))
'''
a=H.index('local task = e.Task'); b=H.index('local world\n',a)
helpers=H[a:b]; H=H[:a]+H[b:]; H=H.replace('--[[ MODULES ]]',helpers+'\n--[[ MODULES ]]')
sources=[]
for directory in ('shared','server'):
    for p in sorted((ROOT/'src'/directory).glob('*.luau')):
        if p.name.endswith('.server.luau'):continue
        sources.append('factories["'+p.stem+'"] = function()\n'+p.read_text()+'\nend\n')
env=dict(os.environ);env['PATH']=str(ROOT/'.tools/bin')+os.pathsep+env.get('PATH','')
with tempfile.NamedTemporaryFile(mode='w', suffix='.luau', prefix='.runtime-map-', dir=ROOT/'tests', delete=False) as f:
    f.write(H.replace('--[[ MODULES ]]','\n'.join(sources))); path=Path(f.name)
try: data=json.loads(subprocess.check_output(['luau', str(path)],cwd=ROOT,env=env,text=True))
finally:path.unlink()
(BUILD/'map-geometry.json').write_text(json.dumps(data))
B=Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
materials={}; meshes={}
def material(rgb,alpha=0,kind='SmoothPlastic'):
    key=(tuple(round(float(c),3) for c in rgb),round(alpha,2),kind)
    if key not in materials:
        mat=bpy.data.materials.new(str(key));mat.use_nodes=True
        node=mat.node_tree.nodes['Principled BSDF']
        def linear(c):return c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4
        node.inputs['Base Color'].default_value=tuple(linear(c) for c in rgb)+(1,)
        node.inputs['Roughness'].default_value=.32 if kind=='Metal' else .61
        node.inputs['Metallic'].default_value=.5 if kind=='Metal' else 0
        if alpha>.4:node.inputs['Transmission Weight'].default_value=.9;node.inputs['Roughness'].default_value=.06;node.inputs['IOR'].default_value=1.15
        if kind=='Neon':node.inputs['Emission Color'].default_value=tuple(rgb)+(1,);node.inputs['Emission Strength'].default_value=.7
        materials[key]=mat
    return materials[key]
def frame(row):
    m=row['Matrix'];p=row['Position'];return Matrix(((m[0],m[1],m[2],p[0]),(m[3],m[4],m[5],p[1]),(m[6],m[7],m[8],p[2]),(0,0,0,1)))
def sculpture(row):
    key=row['Art']
    if key not in meshes:
        source=json.loads((ROOT/'assets/generated'/(key+'.json')).read_text());a=source['Lod']
        mesh=bpy.data.meshes.new(key);mesh.from_pydata(a['Vertices'],[],[[i-1 for i in f] for f in a['Faces']])
        slots={}
        for poly,rgb in zip(mesh.polygons,a['Colors']):
            rgb=tuple(round(v/8)*8 for v in rgb)
            if rgb not in slots:slots[rgb]=len(mesh.materials);mesh.materials.append(material([min(v,255)/255 for v in rgb],0,source.get('Material','SmoothPlastic')))
            poly.material_index=slots[rgb]
        meshes[key]=mesh
    o=bpy.data.objects.new(key,meshes[key]);bpy.context.collection.objects.link(o)
    o.matrix_world=B@frame(row)@Matrix.Diagonal((*row['Scale'],1))
def native(row):
    size=row['Size'];shape=row['Shape'];extra=Matrix.Identity(4)
    if shape=='Cylinder':
        bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=1,depth=1);scale=(size[2]/2,size[1]/2,size[0]);extra=Matrix.Rotation(math.pi/2,4,'Y')
    elif shape=='Ball':bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6);scale=tuple(v/2 for v in size)
    elif shape=='Pyramid':bpy.ops.mesh.primitive_cone_add(vertices=4,radius1=1,radius2=0,depth=1);scale=(size[0]/2,size[2]/2,size[1]);extra=Matrix.Rotation(-math.pi/2,4,'X')
    else:bpy.ops.mesh.primitive_cube_add(size=1);scale=size
    o=bpy.context.object;o.name=row['Name'];o.matrix_world=B@frame(row)@extra@Matrix.Diagonal((*scale,1));o.data.materials.append(material(row['Color'],row['Alpha'],row['Material']))

# Orthographic reviews frame each real landmark, with surrounding garden banks.
# Native seabed strips remain intact; no decorative floor is invented here.
for i,floor in enumerate(data):
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    for row in floor['Rows']:
        # Distant walls outside the review frame can occlude the camera; the
        # review is a landmark close-up, not the entire level seen from outside.
        if abs(row['Position'][0])>300 or abs(row['Position'][2])>300:continue
        if row.get('Art'):sculpture(row)
        else:native(row)
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=False
    scene.render.resolution_x=1000;scene.render.resolution_y=650;scene.render.resolution_percentage=100
    scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.17,.40,.57,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.6
    scene.view_settings.view_transform='AgX'
    target=Vector((0,0,25))
    for p,power,size in [((35,-120,200),500000,150),((-140,10,110),230000,120)]:
        bpy.ops.object.light_add(type='AREA',location=p);lamp=bpy.context.object;lamp.data.energy=power;lamp.data.size=size;lamp.rotation_euler=(target-lamp.location).to_track_quat('-Z','Y').to_euler()
    camera_x = 175 if i in (1, 3) else -175
    bpy.ops.object.camera_add(location=(camera_x,-230,130));cam=bpy.context.object
    cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=300 if i!=1 else 330;scene.camera=cam
    scene.render.filepath=str(BUILD/('map-view-'+str(i+1)+'.png'))
    print('RENDER MAP',i+1,floor['Name'],len(floor['Rows']),flush=True)
    bpy.ops.render.render(write_still=True)

# Put review labels on a separate flat contact sheet, not inside game geometry.
from PIL import Image, ImageDraw, ImageFont
width,height=2000,2140
canvas=Image.new('RGB',(width,height),(10,24,40));draw=ImageDraw.Draw(canvas)
font_path='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
font=ImageFont.truetype(font_path,25);small=ImageFont.truetype(font_path,18);title=ImageFont.truetype(font_path,31)
draw.text((28,18),'UNDERWATER EGG · SIX PANORAMAS',font=title,fill=(226,245,255))
draw.text((28,65),'GÉOMÉTRIES DU JEU · RENDU HORS ROBLOX / BLENDER',font=small,fill=(91,212,234))
for i,floor in enumerate(data):
    x=(i%2)*1000;y=110+(i//2)*660
    canvas.paste(Image.open(BUILD/('map-view-'+str(i+1)+'.png')).convert('RGB').resize((1000,620)),(x,y+38))
    draw.text((x+20,y+4),str(i+1).zfill(2)+' · '+floor['Name'].upper(),font=font,fill=(236,246,255))
draw.text((28,2100),'Lumière Blender · placements aléatoires simulés · interface, physique et performances Roblox non validées',font=small,fill=(185,205,221))
output=ROOT/'docs/previews/map.png';canvas.save(output,optimize=True)
print('REVIEW WRITTEN',output,flush=True)
