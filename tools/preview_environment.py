"""Review the exact baked scenery meshes offline (not a Roblox screenshot).
blender -b -t 2 --python tools/preview_environment.py -- --scene
Use --full for optional native-mesh data; default is the portable near LOD.
"""
from pathlib import Path
import bpy, json, math, sys
from mathutils import Vector
ROOT = Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
materials = {}
level = 'Full' if '--full' in sys.argv else 'Lod'
def sculpture(key, location, scale=1, angle=0):
    data=json.loads((ROOT/'assets/generated'/(key+'.json')).read_text())[level]
    mesh=bpy.data.meshes.new(key)
    mesh.from_pydata([(v[0]*scale,-v[2]*scale,v[1]*scale) for v in data['Vertices']],[],[[i-1 for i in f] for f in data['Faces']])
    obj=bpy.data.objects.new(key,mesh);bpy.context.collection.objects.link(obj)
    obj.location=location;obj.rotation_euler.z=angle
    indices={}
    for poly,rgb in zip(mesh.polygons,data['Colors']):
        rgb=tuple(round(v/8)*8 for v in rgb)
        if rgb not in materials:
            mat=bpy.data.materials.new(str(rgb));mat.use_nodes=True
            def linear(v): return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
            mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=tuple(linear(min(v,255)/255) for v in rgb)+(1,)
            mat.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.6
            materials[rgb]=mat
        if rgb not in indices: indices[rgb]=len(mesh.materials);mesh.materials.append(materials[rgb])
        poly.material_index=indices[rgb]
    return obj
if '--scene' in sys.argv:
    import random
    rng=random.Random(41871)
    for x in range(-2,3):
        for y in range(-1,3):
            if x==0 and y<2: continue
            p=(x*19+rng.uniform(-3,3), y*19+rng.uniform(-3,3))
            sculpture('reef_boulder_a' if x%2 else 'reef_boulder_b',(p[0],p[1],4),2.6)
            sculpture(['reef_fan','reef_tubes','reef_anemone','reef_branch'][(x+y)%4],(p[0]+5,p[1]+4,8),2.4, rng.uniform(0,6))
            sculpture('reef_meadow',(p[0]-5,p[1]-3,5),2.4,rng.uniform(0,6))
            sculpture('reef_kelp',(p[0]+8,p[1]-7,5),2.3,rng.uniform(0,6))
    sculpture('reef_arch',(6,42,10),6)
    sculpture('reef_wreck',(-30,48,4),6,.3)
    target=Vector((0,10,6));cam_pos=(48,-69,35);ortho=112
else:
    keys=['reef_fan','reef_tubes','reef_branch','reef_meadow','reef_anemone','reef_lilac','reef_kelp','reef_boulder_a','reef_boulder_b','reef_arch','reef_columns','reef_wreck']
    for i,key in enumerate(keys):
        sculpture(key,((i%4-1.5)*12,(1-i//4)*14,3),1.25)
        bpy.ops.object.text_add(location=((i%4-1.5)*12-4,(1-i//4)*14-4.5,.03));obj=bpy.context.object;obj.data.body=key.replace('reef_','');obj.data.size=.8
    target=Vector((0,0,2));cam_pos=(24,-47,44);ortho=66
bpy.ops.mesh.primitive_plane_add(size=500);plane=bpy.context.object
mat=bpy.data.materials.new('Sand');mat.use_nodes=True;mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.67,.52,.3,1);plane.data.materials.append(mat)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=False
scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.23,.58,.72,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.6
for loc,power in [((5,-20,55),16000),((-35,24,30),10000)]:
    bpy.ops.object.light_add(type='AREA',location=loc);bpy.context.object.data.energy=power;bpy.context.object.data.size=40
bpy.ops.object.camera_add(location=cam_pos);camera=bpy.context.object;camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=ortho;scene.camera=camera
scene.render.resolution_x=1500;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
out=ROOT/'build'/('reef-scene-preview.png' if '--scene' in sys.argv else 'reef-models-preview.png');out.parent.mkdir(exist_ok=True)
scene.render.filepath=str(out);bpy.ops.render.render(write_still=True)
