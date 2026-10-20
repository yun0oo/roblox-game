"""Bake portable, colored mesh data. Run: blender -b -t 2 --python tools/build_art.py.

Sources: Microsoft Barramundi Fish and Kenney Blaster Kit, both CC0.
Derived marine monsters, egg shell and other animal silhouettes are original.
The checked-in output runs without importing assets or enabling Studio APIs.
"""
from pathlib import Path
import bpy
import math
import json
import sys
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/source'
OUTPUT = ROOT / 'assets/generated'
OUTPUT.mkdir(parents=True, exist_ok=True)

def clear():
    for obj in list(bpy.data.objects): bpy.data.objects.remove(obj, do_unlink=True)

def material(name, color):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    return m

skin = material('Marine pearl', (.21, .66, .83))
belly = material('Ivory underside', (.94, .96, .9))
fin = material('Deep turquoise fins', (.09, .32, .59))
gold = material('Ancient gold', (1, .73, .13))
eye = material('Obsidian eyes', (.008, .015, .025))
glow = material('Bioluminescent tissue', (.35, .95, .84))
white = material('Cartoon eye whites', (1, 1, 1))

def sphere(name, location, scale, mat, segments=16, rings=8):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=location)
    o = bpy.context.object; o.name=name; o.scale=scale; o.data.materials.append(mat)
    return o

def tube(name, points, radii, mat, sides=8):
    preserve = name in {"Curled tentacle", "Serpent neck", "Jointed leg", "Serpentine body", "Coiled body", "Whip tail"}
    if preserve: sides = min(sides, 6)
    vertices=[]; faces=[]
    for i, p in enumerate(points):
        p=Vector(p)
        tangent=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)])
        tangent.normalize(); normal=tangent.cross(Vector((0,0,1)))
        if normal.length < .01: normal=tangent.cross(Vector((0,1,0)))
        normal.normalize(); other=tangent.cross(normal).normalized()
        for j in range(sides):
            a=j*math.tau/sides
            vertices.append(p+radii[i]*(math.cos(a)*normal+math.sin(a)*other))
    for i in range(len(points)-1):
        for j in range(sides):
            a=i*sides+j;b=i*sides+(j+1)%sides;c=b+sides;d=a+sides
            faces.append((a,b,c,d))
    faces.extend((tuple(reversed(range(sides))),tuple((len(points)-1)*sides+j for j in range(sides))))
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(vertices,[],faces);mesh.materials.append(mat)
    o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o)
    if preserve: o['KeepSurface'] = True
    return o

def sail(name, points, mat):
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(points,[],[tuple(range(len(points)))]);mesh.materials.append(mat)
    obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
    obj['KeepSurface']=True
    # Tiny thickness gives fins a real silhouette from both sides.
    mod=obj.modifiers.new('Fin thickness','SOLIDIFY');mod.thickness=.035
    return obj

def import_fish():
    bpy.ops.import_scene.gltf(filepath=str(SOURCE/'BarramundiFish.glb'))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    for o in meshes:
        # glTF uses +Y up; Blender's importer converts that to +Z.
        bpy.context.view_layer.update()
        transform=o.matrix_world.copy()
        if o.dimensions.x > o.dimensions.y: transform=Matrix.Rotation(math.pi/2,4,'Z')@transform
        # Rotate in WORLD space: the imported armature has its own glTF basis.
        transform=Matrix.Rotation(math.pi,4,'Z')@transform
        coords=[transform@v.co for v in o.data.vertices]
        center=Vector(tuple((min(v[i] for v in coords)+max(v[i] for v in coords))/2 for i in range(3)))
        factor=6/(max(v.y for v in coords)-min(v.y for v in coords))
        for modifier in list(o.modifiers):
            if modifier.type=='ARMATURE': o.modifiers.remove(modifier)
        o.parent=None;o.matrix_world=Matrix.Identity(4)
        for vertex,coord in zip(o.data.vertices,coords): vertex.co=(coord-center)*factor
    return meshes

def source_material_color(obj, poly):
    mat=obj.data.materials[poly.material_index] if obj.data.materials else None
    if not mat: return (.45,.65,.7)
    if mat.use_nodes:
        bsdf=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
        if bsdf:
            socket=bsdf.inputs['Base Color']
            if socket.is_linked:
                image=next((n.image for n in mat.node_tree.nodes if n.type=='TEX_IMAGE' and n.image),None)
                uv=obj.data.uv_layers.active
                if image and uv and image.size[0] and image.size[1]:
                    # glTF palettes and fish texture are baked into face colors.
                    coords=[uv.data[i].uv for i in poly.loop_indices]
                    u=sum(c.x for c in coords)/len(coords);v=sum(c.y for c in coords)/len(coords)
                    w,h=image.size; x=int((u%1)*(w-1));y=int((v%1)*(h-1))
                    offset=(y*w+x)*4
                    return tuple(image.pixels[offset:offset+3])
            return tuple(socket.default_value[:3])
    return tuple(mat.diffuse_color[:3])

def bake(key, kind, target=650, lod_target=150):
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    # Apply modifiers and world transforms, including imported glTF parent rigs.
    for o in meshes:
        bpy.context.view_layer.objects.active=o;o.select_set(True)
        for mod in list(o.modifiers):
            if mod.type=='ARMATURE': o.modifiers.remove(mod)
            else: bpy.ops.object.modifier_apply(modifier=mod.name)
        transform=o.matrix_world.copy();o.parent=None;o.matrix_world=transform
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
        o.select_set(False)
    vertices=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
    lo=Vector(tuple(min(v[i] for v in vertices) for i in range(3)))
    hi=Vector(tuple(max(v[i] for v in vertices) for i in range(3)))
    center=(lo+hi)/2
    # Marine bodies face -Z in Roblox, after mapping Blender +Y to Roblox -Z.
    factor=(1.25/(hi.z-lo.z)) if key=='egg' else ((4.5 if kind=='weapon' else 6)/(hi.y-lo.y))
    for o in meshes:
        for v in o.data.vertices: v.co=(v.co-center)*factor
    results={}
    for level,budget in [('Full',target),('Lod',lod_target)]:
        vertices=[];faces=[];colors=[]
        total=sum(len(o.data.polygons) for o in meshes)
        for original in meshes:
            o=original.copy();o.data=original.data.copy();bpy.context.collection.objects.link(o)
            bpy.context.view_layer.objects.active=o
            mod=o.modifiers.new('Bounded art budget','DECIMATE');mod.ratio=1 if original.get('KeepSurface') else min(1,budget/max(total*2,1))
            bpy.ops.object.modifier_apply(modifier=mod.name)
            mod=o.modifiers.new('Triangles','TRIANGULATE');bpy.ops.object.modifier_apply(modifier=mod.name)
            offset=len(vertices)
            vertices.extend([[round(v.co.x,5),round(v.co.z,5),round(-v.co.y,5)] for v in o.data.vertices])
            for poly in o.data.polygons:
                faces.append([offset+i+1 for i in poly.vertices])
                c=source_material_color(o,poly)
                colors.append([round(max(0,min(1,x))*255) for x in c])
            bpy.data.objects.remove(o,do_unlink=True)
        bounds=[max(v[i] for v in vertices)-min(v[i] for v in vertices) for i in range(3)]
        results[level]={'Vertices':vertices,'Faces':faces,'Colors':colors,'Bounds':bounds}
    results['Kind']=kind
    (OUTPUT/(key+'.json')).write_text(json.dumps(results,separators=(',',':')))
    print('BAKED',key,len(results['Full']['Faces']),len(results['Lod']['Faces']),flush=True)

if '--licensed-only' not in sys.argv:
    clear();import_fish()
    for side in (-1,1):
        sclera=sphere('Expressive eye',(side*.52,2,.32),(.28,.35,.29),white,8,4)
        sclera['KeepSurface']=True
        sphere('Pupil',(side*.61,2.22,.35),(.19,.2,.19),eye,8,4)
        sphere('Eye sparkle',(side*.64,2.36,.45),(.06,.06,.06),white,8,4)
    bake('fish','fish',1100,260)
    clear();bpy.ops.import_scene.gltf(filepath=str(SOURCE/'KenneyBlaster.glb'));bake('harpoon','weapon',900,280)

    # Anatomical silhouettes are generated in Blender, then shipped as mesh data.
    for key in ('shark','ray','turtle','whale','eel','jelly','octopus','seahorse','crab','kraken','leviathan','dragon','scylla','charybdis'):
        clear()
        if key in ('leviathan','dragon','shark'):
            # A real CC0 fish mesh supplies the marine anatomy of these derivatives.
            for o in import_fish():
                o.scale*=1.1 if key!='shark' else 1
            sail('Dorsal fin',[(0,-.6,.8),(0,-1.4,2),(0,1,.65)],fin)
            if key!='shark':
                for i in range(7):
                    y=-2+i*.8
                    tube('Dorsal horn',[(0,y,.8),(0,y+.15,1.7),(0,y+.45,2)], [.2,.13,.01],gold,6)
                for side in (-1,1):
                    sail('Wing fin',[(side*.5,-.8,.2),(side*3,-1.8,.6),(side*2,1.4,-.2),(side*.5,1.8,0)],fin)
                    tube('Jaw horn',[(side*.6,1.4,0),(side*.9,2.3,-.4),(side*.7,2.8,0)],[.16,.1,.01],belly,6)
        elif key in ('kraken','octopus','scylla','jelly'):
            sphere('Mantle',(0,0,.6),(1.1,1.2,1.5 if key!='jelly' else .6),skin)
            for i in range(8):
                a=i*math.tau/8
                points=[(math.cos(a)*r,math.sin(a)*r,-h) for r,h in ((.7,.1),(1.3,.6),(2.1,1.2),(2.8,1.1),(3.1,.4),(2.8,.1))]
                tube('Curled tentacle',points,[.25,.26,.2,.13,.08,.015],fin)
                if key!='jelly':
                    for r,h in ((1.4,.5),(2,.9),(2.5,.9)):
                        sphere('Sucker',(math.cos(a)*r,math.sin(a)*r,-h),(.12,.12,.07),belly,8,4)
            if key=='scylla':
                for x in (-1,0,1):
                    tube('Serpent neck',[(x*.5,.5,.5),(x,1.2,1.5),(x*1.5,2,1.7)],[.28,.2,.14],skin)
                    sphere('Serpent head',(x*1.5,2.2,1.7),(.35,.6,.3),belly)
        elif key=='ray':
            sphere('Ray body',(0,0,0),(.7,1.3,.3),skin)
            for side in (-1,1): sail('Ray wing',[(0,1,.2),(side*3,-.1,0),(side*1.4,-1.3,-.1),(0,-1,0)],fin)
            tube('Whip tail',[(0,-.8,0),(0,-2,0),(.3,-3,-.1)],[.15,.08,.005],fin)
        elif key=='turtle':
            sphere('Shell',(0,0,0),(1.3,1.7,.65),fin)
            sphere('Head',(0,1.8,.05),(.4,.65,.35),skin)
            for x in (-1,1):
                for y in (-1,1): sphere('Flipper',(x*1.2,y*.8,-.1),(.9,.35,.12),skin)
            for i in range(5): sphere('Shell scute',(math.sin(i)*.65,math.cos(i)*.85,.5),(.42,.5,.14),gold)
        elif key=='whale':
            sphere('Whale',(0,0,0),(1,2.6,.9),skin,20,10)
            sphere('Chin',(0,1.1,-.35),(.8,1.3,.5),belly)
            for side in (-1,1):
                sail('Flipper',[(side*.5,1,0),(side*2.2,-.6,-.3),(side*.7,-.8,0)],fin)
                sail('Fluke',[(0,-2.2,0),(side*1.8,-3,.1),(side*.5,-3.2,0)],fin)
        elif key=='eel':
            tube('Serpentine body',[(math.sin(i*.6)*.4,-3+i*.7,math.cos(i*.4)*.1) for i in range(10)], [.05,.12,.22,.28,.32,.35,.36,.36,.3,.2],skin,12)
        elif key=='seahorse':
            tube('Coiled body',[(0,-.5,-1),(0,-1,-1.5),(0,-1.5,-1.2),(0,-1.2,-.7),(0,-.5,-.4),(0,0,.4),(0,.3,1.3),(0,1,1.6)], [.04,.08,.1,.15,.24,.35,.28,.2],skin,10)
            sphere('Horse head',(0,1.2,1.5),(.27,.6,.35),skin)
        elif key=='crab':
            sphere('Carapace',(0,0,0),(1.3,1,.45),skin)
            for side in (-1,1):
                for i in range(4):
                    tube('Jointed leg',[(side*.8,i*.4-.6,0),(side*1.8,i*.65-1,-.3),(side*2.1,i*.8-1.2,-.6)],[.12,.08,.02],fin,6)
                sphere('Claw',(side*1.5,1.2,.1),(.55,.7,.35),skin)
        else:
            sphere('Armored leviathan',(0,0,0),(1.8,2.4,1.5),fin)
            sphere('Vortex maw',(0,2,.1),(1.3,.35,1.2),eye)
            for i in range(12):
                a=i*math.tau/12
                tube('Ivory tooth',[(math.cos(a)*1.1,2.2,math.sin(a)),(math.cos(a)*.7,2.5,math.sin(a)*.65)],[.14,.005],belly,5)
        if key in ('leviathan','dragon','kraken'):
            # Large contrasting facial features survive the portable gameplay mesh.
            front = 1.2 if key == 'kraken' else 2.4
            sphere('Dark open jaws',(0,front,.05),(.53,.17,.37),eye,12,6)
            for side in (-1,1):
                tube('Heroic ivory fang',[(side*.35,front+.1,.27),(side*.27,front+.22,-.18)],[.13,.005],belly,6)
                tube('Crown horn',[(side*.7,.3,1),(side*.85,.4,1.8),(side*.65,.65,2.2)],[.21,.13,.005],gold,7)
            if key == 'dragon':
                for side in (-1,1):
                    tube('Wing gold ridge',[(side*.5,-.8,.2),(side*3,-1.8,.6),(side*2,1.4,-.2)],[.09,.07,.025],gold,6)
        # Toy-like, expressive eyes: separate white, pupil and highlight geometry.
        ex,ey,ez = (.9,1.4,.45) if key=='whale' else (.65,1,.5)
        if key=='turtle': ex,ey,ez=.35,2,.2
        if key=='charybdis': ex,ey,ez=1.05,2.25,.95
        for side in (-1,1):
            sclera=sphere('Eye white',(side*ex,ey,ez),(.32,.36,.33),white,8,4)
            sclera['KeepSurface']=True
            sphere('Eye',(side*(ex+.03),ey+.23,ez),(.25,.25,.25),eye,10,5)
            sphere('Eye glint',(side*(ex+.1),ey+.4,ez+.1),(.08,.08,.08),white,8,4)
        if key=='scylla':
            for x in (-1,0,1):
                for side in (-1,1):
                    sphere('Serpent eye',(x*1.5+side*.24,2.52,1.84),(.1,.13,.1),eye,8,4)
        bake(key,'creature' if key in ('kraken','leviathan','dragon','scylla','charybdis') else 'fish',1100 if key in ('kraken','scylla') else 850,360 if key in ('kraken','leviathan','dragon','scylla','charybdis') else 220)

    clear()
    points=[];radii=[]
    for i in range(25):
        t=i/24;angle=math.pi*t
        points.append((0,0,(t-.5)*1.25))
        radii.append(max(.003,.48*math.sin(angle)*(1-.26*(t-.5))))
    eggmat=material('Pearlescent shell',(.97,.98,1))
    tube('Ovoid shell',points,radii,eggmat,32)
    bake('egg','egg',1200,320)


# Reuse the licensed Quaternius game-ready marine sculpts, preserving their
# distinct silhouettes, teeth and eyes instead of painting one generic fish.
def import_licensed(filename):
    bpy.ops.import_scene.gltf(filepath=str(SOURCE/filename))
    bpy.context.view_layer.update()
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and len(o.data.materials)>0]
    for o in list(bpy.context.scene.objects):
        if o.type=='MESH' and o not in meshes: bpy.data.objects.remove(o,do_unlink=True)
    for o in meshes:
        matrix=o.matrix_world.copy()
        for mod in list(o.modifiers): o.modifiers.remove(mod)
        o.parent=None;o.matrix_world=Matrix.Identity(4)
        for v in o.data.vertices: v.co=matrix@v.co
    points=[v.co for o in meshes for v in o.data.vertices]
    # Quaternius models have the tail along +Y after Blender's glTF conversion.
    # Eyes give an independent forward check for the cute-fish pack.
    center=Vector(tuple((min(v[i] for v in points)+max(v[i] for v in points))/2 for i in range(3)))
    eye_points=[]
    for o in meshes:
        for poly in o.data.polygons:
            mat=o.data.materials[poly.material_index] if len(o.data.materials) > poly.material_index else None
            if mat and 'eye' in mat.name.lower(): eye_points.extend(o.data.vertices[i].co for i in poly.vertices)
    flip=(sum(v.y for v in eye_points)/len(eye_points)<center.y) if eye_points else True
    rotate=Matrix.Rotation(math.pi if flip else 0,4,'Z')
    for o in meshes:
        for v in o.data.vertices: v.co=rotate@(v.co-center)
        # Split by material to protect eyes/teeth when reducing geometry.
        bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
        bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.separate(type='MATERIAL');bpy.ops.object.mode_set(mode='OBJECT')
    body_colors={
        'Clownfish':((1,.35,.035),(1,1,1),(.035,.04,.05)),
        'ButterflyFish':((1,.82,.12),(1,1,.91),(.05,.055,.07)),
        'Puffer':((1,.78,.24),(1,.94,.7),(.36,.24,.1)),
        'Sunfish':((.45,.68,.88),(.88,.96,1),(.2,.35,.52)),
        'Swordfish':((.14,.42,.8),(.87,.96,1),(.04,.1,.23)),
        'GoblinShark':((.2,.36,.53),(.53,.74,.84),(.04,.075,.13)),
        'Anglerfish':((.26,.11,.47),(.54,.3,.78),(.055,.025,.12)),
        'Piranha':((.96,.2,.27),(1,.8,.66),(.16,.035,.06)),
        'CoralGrouper':((.96,.43,.3),(1,.84,.64),(.28,.12,.14)),
        'BlueTang':((.055,.4,.95),(1,.84,.12),(.025,.07,.17)),
        'Lionfish':((.94,.31,.24),(1,.94,.84),(.27,.08,.1)),
        'Shark':((.24,.46,.66),(.9,.97,1),(.045,.09,.17)),
        'Whale':((.17,.36,.64),(.78,.91,1),(.06,.13,.24)),
        'Manta_ray':((.2,.3,.49),(.86,.95,.99),(.045,.075,.14)),
        'Dolphin':((.25,.6,.75),(.86,.96,1),(.08,.2,.29)),
    }
    species=filename.removeprefix('Quaternius_').removesuffix('.glb')
    main,light_color,dark=body_colors[species]
    for o in [o for o in bpy.context.scene.objects if o.type=='MESH']:
        for mat in o.data.materials:
            n=mat.name.lower()
            paint=(.01,.015,.025) if 'eye' in n else ((1,.97,.87) if 'teeth' in n else ((.35,1,1) if n.split('.')[0]=='light' else (dark if 'dark' in n else (light_color if 'light' in n or 'bottom' in n else main))))
            mat.use_nodes=False;mat.diffuse_color=(*paint,1)
        mats=[m.name.lower() for m in o.data.materials if m]
        if any('eye' in m or 'teeth' in m for m in mats): o['KeepSurface']=True
    print('LICENSED',filename,'forwardFlip',flip,flush=True)

marine=['Clownfish','ButterflyFish','Puffer','Sunfish','Swordfish','GoblinShark','Anglerfish','Piranha','CoralGrouper','BlueTang','Lionfish','Shark','Whale','Manta_ray','Dolphin']
for name in marine:
    clear();import_licensed('Quaternius_'+name+'.glb')
    bake('q_'+name.lower(),'licensed',2600,1400)
# The primordial guardian keeps a recognizable imported goblin-shark head and
# gains original fins, a golden crown and a long sea-dragon silhouette.
clear();import_licensed('Quaternius_GoblinShark.glb')
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
points=[v.co for o in meshes for v in o.data.vertices]
span=max(v.y for v in points)-min(v.y for v in points)
for o in meshes:
    for v in o.data.vertices: v.co*=6/span
for side in (-1,1):
    sail('Primordial wing',[(side*.4,-.8,.2),(side*2.6,-1.8,.8),(side*1.8,.8,0),(side*.4,1.1,0)],fin)
    tube('Royal horn',[(side*.45,.4,.6),(side*.6,.7,1.5),(side*.3,1,1.9)],[.18,.12,.005],gold,8)
bake('q_leviathan','licensed',2800,1400)

# Lua modules are generated from pure numeric data; no asset scripts are imported.
def lua(value):
    if isinstance(value,dict): return '{'+','.join(k+'='+lua(v) for k,v in value.items())+'}'
    if isinstance(value,list): return '{'+','.join(lua(x) for x in value)+'}'
    if isinstance(value,str): return json.dumps(value)
    return str(round(value,5)) if isinstance(value,float) else str(value)
assets={p.stem:json.loads(p.read_text()) for p in sorted(OUTPUT.glob('*.json'))}
(ROOT/'src/shared/ArtData.luau').write_text('--!nonstrict\n-- Generated by tools/build_art.py; source credits: assets/CREDITS.md.\nreturn '+lua(assets)+'\n')
print('ArtData written',flush=True)
