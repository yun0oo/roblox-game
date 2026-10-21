"""Offline review of the actual Ship.Build / Visuals.Harpoon geometry.
Run: blender -b -t 2 --python tools/preview_ship.py
Uses engine doubles for instantiation, then Blender for rendering. This is not
Roblox Studio, and does not validate native materials, physics or performance.
"""
from pathlib import Path
import bpy, json, math, subprocess, tempfile, os
from mathutils import Matrix, Vector
ROOT = Path(__file__).resolve().parents[1]
# The startup doubles deliberately omit rendering math. Supply transforms/colours
# only for this geometry export; normal tests continue to use their own doubles.
H = r'''
local Engine = require("./support/Engine")
local e = Engine.new()
local game, workspace, script = e.Game, e.Workspace, e.Script
local Instance, Vector3, Enum = e.Instance, e.Vector3, e.Enum
local function ident() return {1,0,0,0,1,0,0,0,1} end
local function transform(m,v) return Vector3.new(m[1]*v.X+m[2]*v.Y+m[3]*v.Z,m[4]*v.X+m[5]*v.Y+m[6]*v.Z,m[7]*v.X+m[8]*v.Y+m[9]*v.Z) end
local mt, CFrame = {}, {}
function CFrame.new(x,y,z) return setmetatable({Position=type(x)=="table" and x or Vector3.new(x,y,z),M=ident()},mt) end
function mt.__mul(a,b)
    local r = CFrame.new(a.Position+transform(a.M,b.Position)); r.M = {}
    for i=0,2 do for j=0,2 do local n=0;for k=0,2 do n+=a.M[i*3+k+1]*b.M[k*3+j+1] end;r.M[i*3+j+1]=n end end
    return r
end
function CFrame.Angles(x,y,z)
    local sx,cx,sy,cy,sz,cz=math.sin(x),math.cos(x),math.sin(y),math.cos(y),math.sin(z),math.cos(z)
    local a,b,c=CFrame.new(),CFrame.new(),CFrame.new()
    a.M={1,0,0,0,cx,-sx,0,sx,cx}; b.M={cy,0,sy,0,1,0,-sy,0,cy};c.M={cz,-sz,0,sz,cz,0,0,0,1}
    return a*b*c
end
function CFrame.lookAt(pos,target)
    local back=(pos-target).Unit;local right=Vector3.new(0,1,0):Cross(back)
    if right.Magnitude<.001 then right=Vector3.new(1,0,0) else right=right.Unit end
    local up=back:Cross(right);local f=CFrame.new(pos);f.M={right.X,up.X,back.X,right.Y,up.Y,back.Y,right.Z,up.Z,back.Z};return f
end
local Color3 = {}
local cm = {};cm.__index=cm
function Color3.new(r,g,b) return setmetatable({r=r,g=g,b=b},cm) end
function Color3.fromRGB(r,g,b) return Color3.new(r/255,g/255,b/255) end
function cm:Lerp(b,t) return Color3.new(self.r+(b.r-self.r)*t,self.g+(b.g-self.g)*t,self.b+(b.b-self.b)*t) end
local UDim2 = {fromOffset=function() return {} end,fromScale=function() return {} end}
local UDim,Vector2,ColorSequence,NumberSequence,NumberRange={new=function()return {} end},{new=function()return {} end},{new=function()return {} end},{new=function()return {} end},{new=function()return {} end}
local factories,loaded={},{}
local function require(ref) if not loaded[ref.Name] then loaded[ref.Name]=factories[ref.Name]() end;return loaded[ref.Name] end
--[[ MODULES ]]
local config,visuals=require(e.ReplicatedStorage.Modules.Config),require(e.ReplicatedStorage.Modules.Visuals)
local world={}
for _,name in ipairs({"Map","Bases","NPCs"}) do world[name]=Instance.new("Folder");world[name].Parent=workspace end
require(script.Parent.Ship).Build(world,config,visuals)
local gun=Instance.new("Tool");visuals.Harpoon(gun,1)
local function vector(v) return {v.X,v.Y,v.Z} end
local function dump(parent,origin)
    local rows={}
    for _,p in ipairs(parent:GetDescendants()) do
        if p.ClassName~="Part" and p.ClassName~="WedgePart" then continue end
        local art=p:GetAttribute("ArtAsset")
        if not art and (p.Transparency or 0)>=.94 then continue end
        local row={Name=p.Name,Position=vector(p.Position-origin),Matrix=p.CFrame.M,Size=vector(p.Size),Shape=p.Shape or "Block",Color={p.Color.r,p.Color.g,p.Color.b},Alpha=p.Transparency or 0,Material=p.Material,Art=art}
        local scale=p:GetAttribute("ArtScale");if scale then row.Scale=type(scale)=="number" and {scale,scale,scale} or vector(scale) end
        local off=p:GetAttribute("ArtOffset");if off then row.Offset=vector(off) end
        local mesh=p:FindFirstChildOfClass("SpecialMesh");if mesh then row.Shape=mesh.MeshType end
        table.insert(rows,row)
    end
    return rows
end
local function json(v)
    local t=type(v)
    if t=="string" then return '"'..v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n')..'"' end
    if t=="number" or t=="boolean" then return tostring(v) end
    local parts={}
    if #v>0 then for _,x in ipairs(v) do table.insert(parts,json(x)) end;return '['..table.concat(parts,',')..']' end
    for k,x in pairs(v) do table.insert(parts,json(k)..':'..json(x)) end;return '{'..table.concat(parts,',')..'}'
end
local base=world.Bases[1]
print(json({Base=dump(base.Model,base.Center-Vector3.new(0,9.4,0)),Harpoon=dump(gun,Vector3.zero)}))
'''
sources=[]
for directory in ('shared','server'):
    for p in sorted((ROOT/'src'/directory).glob('*.luau')):
        if p.name.endswith('.server.luau'): continue
        sources.append('factories["'+p.stem+'"] = function()\n'+p.read_text()+'\nend\n')
env=dict(os.environ);env['PATH']=str(ROOT/'.tools/bin')+os.pathsep+env.get('PATH','')
with tempfile.NamedTemporaryFile(mode='w',suffix='.luau',prefix='.runtime-preview-',dir=ROOT/'tests',delete=False) as f:
    f.write(H.replace('--[[ MODULES ]]','\n'.join(sources)));path=Path(f.name)
try: data=json.loads(subprocess.check_output(['luau',str(path)],cwd=ROOT,env=env,text=True))
finally: path.unlink()
(ROOT/'build/ship-geometry.json').write_text(json.dumps(data))
B=Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
materials={}
def material(rgb,alpha=0,kind='SmoothPlastic'):
    key=(tuple(round(c,3) for c in rgb),round(alpha,2),kind)
    if key not in materials:
        m=bpy.data.materials.new(str(key));m.use_nodes=True;n=m.node_tree.nodes['Principled BSDF']
        def linear(c):return c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4
        n.inputs['Base Color'].default_value=tuple(linear(c) for c in rgb)+(1,)
        n.inputs['Roughness'].default_value=.25 if kind=='Metal' else .48
        n.inputs['Metallic'].default_value=.55 if kind=='Metal' else 0
        if alpha>.4:n.inputs['Transmission Weight'].default_value=.94;n.inputs['Roughness'].default_value=.04;n.inputs['IOR'].default_value=1.15
        if kind=='Neon':n.inputs['Emission Color'].default_value=tuple(rgb)+(1,);n.inputs['Emission Strength'].default_value=1.1
        materials[key]=m
    return materials[key]
def frame(row):
    m=row['Matrix'];p=row['Position'];return Matrix(((m[0],m[1],m[2],p[0]),(m[3],m[4],m[5],p[1]),(m[6],m[7],m[8],p[2]),(0,0,0,1)))
def sculpture(row):
    a=json.loads((ROOT/'assets/generated'/(row['Art']+'.json')).read_text())['Lod']
    mesh=bpy.data.meshes.new(row['Art']);mesh.from_pydata(a['Vertices'],[],[[i-1 for i in f] for f in a['Faces']]);o=bpy.data.objects.new(row['Art'],mesh);bpy.context.collection.objects.link(o)
    o.matrix_world=B@frame(row)@Matrix.Translation(Vector(row.get('Offset',(0,0,0))))@Matrix.Diagonal((*row['Scale'],1))
    indices={}
    for poly,rgb in zip(mesh.polygons,a['Colors']):
        k=tuple(rgb)
        if k not in indices:indices[k]=len(mesh.materials);mesh.materials.append(material([v/255 for v in rgb]))
        poly.material_index=indices[k]
def native(row):
    size=row['Size'];shape=row['Shape'];extra=Matrix.Identity(4)
    if shape=='Cylinder':
        bpy.ops.mesh.primitive_cylinder_add(vertices=20,radius=1,depth=1);scale=(size[2]/2,size[1]/2,size[0]);extra=Matrix.Rotation(math.pi/2,4,'Y')
    elif shape=='Ball':bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8);scale=tuple(v/2 for v in size)
    elif shape=='Pyramid':bpy.ops.mesh.primitive_cone_add(vertices=4,radius1=1,radius2=0,depth=1);scale=(size[0]/2,size[2]/2,size[1]);extra=Matrix.Rotation(-math.pi/2,4,'X')
    else:bpy.ops.mesh.primitive_cube_add(size=1);scale=size
    o=bpy.context.object;o.name=row['Name'];o.matrix_world=B@frame(row)@extra@Matrix.Diagonal((*scale,1));o.data.materials.append(material(row['Color'],row['Alpha'],row['Material']))
def render(kind,position,target,ortho,filename):
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    for row in data[kind]:
        if row.get('Art'):sculpture(row)
        else:native(row)
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=False
    scene.render.resolution_x=1440;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
    scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.35,.53,.65,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.6
    bpy.ops.mesh.primitive_plane_add(size=500,location=(0,0,-.1 if kind=='Base' else -1.8));bpy.context.object.data.materials.append(material((.08,.19,.27)))
    for p,power,size in [((20,-50,85),160000,65),((-50,20,45),80000,40)] if kind=='Base' else [((3,-4,9),900,7),((-6,2,5),600,5)]:
        bpy.ops.object.light_add(type='AREA',location=p);bpy.context.object.data.energy=power;bpy.context.object.data.size=size;bpy.context.object.rotation_euler=(Vector(target)-bpy.context.object.location).to_track_quat('-Z','Y').to_euler()
    bpy.ops.object.camera_add(location=position);cam=bpy.context.object;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=ortho;scene.camera=cam
    scene.render.filepath=str(ROOT/'build'/filename);bpy.ops.render.render(write_still=True)
render('Base',(78,-110,66),(0,0,16),125,'base-preview.png')
render('Harpoon',(7,-9,5),(0,1.8,.3),8,'harpoon-preview.png')
