"""Offline art review, not a Roblox Studio screenshot. Run with Blender."""
from pathlib import Path
import bpy, json, math, sys
LOD = "--lod" in sys.argv
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
palette={}
for key,location,scale in [('fish',(-9,3,0),1),('harpoon',(0,3,0),1),('egg',(9,3,0),3.5),('leviathan',(-9,-6,0),1),('kraken',(0,-6,0),1),('scylla',(9,-6,0),1)]:
    data=json.loads((ROOT/'assets/generated'/(key+'.json')).read_text())['Lod' if LOD else 'Full']
    mesh=bpy.data.meshes.new(key)
    mesh.from_pydata([(v[0]*scale,-v[2]*scale,v[1]*scale+3) for v in data['Vertices']],[],[[i-1 for i in f] for f in data['Faces']])
    obj=bpy.data.objects.new(key,mesh);bpy.context.collection.objects.link(obj);obj.location=location
    indices={}
    for poly,rgb in zip(mesh.polygons,data['Colors']):
        if key == "harpoon" and rgb[0] > rgb[1] * 1.15 and rgb[1] > rgb[2] * 1.1: rgb = (36, 165, 207)
        rgb=tuple(round(c/16)*16 for c in rgb)
        if rgb not in palette:
            m=bpy.data.materials.new(str(rgb));m.diffuse_color=tuple(c/255 for c in rgb)+(1,);m.use_nodes=True
            m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=m.diffuse_color
            m.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.34
            palette[rgb]=m
        if rgb not in indices:indices[rgb]=len(mesh.materials);mesh.materials.append(palette[rgb])
        poly.material_index=indices[rgb]
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.5));plane=bpy.context.object
m=bpy.data.materials.new('Deep navy');m.diffuse_color=(.025,.06,.085,1);plane.data.materials.append(m)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=False
scene.render.resolution_x=1440;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.world.color=(.18,.18,.18)
for location,power,size in [((0,5,18),2400,12),((-14,4,10),1400,10),((12,-8,9),1800,9)]:
    bpy.ops.object.light_add(type='AREA',location=location);bpy.context.object.data.energy=power;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=size
bpy.ops.object.camera_add(location=(18,-26,28));camera=bpy.context.object
camera.rotation_euler=(Vector((0,-1,2))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.type='ORTHO';camera.data.ortho_scale=33;scene.camera=camera
output=ROOT/'build'/('art-preview-lod.png' if LOD else 'art-preview.png');output.parent.mkdir(exist_ok=True)
scene.render.filepath=str(output);bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'build/art-preview.blend'));bpy.ops.render.render(write_still=True)
