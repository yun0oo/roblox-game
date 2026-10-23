"""Bake licensed, pre-existing marine scenery for the portable Roblox renderer.
Run: blender -b -t 2 --python tools/build_environment.py
Credits and upstream/mirror hashes: assets/manifest.json and assets/CREDITS.md.
"""
from pathlib import Path
import bpy, bmesh, json, math, struct
from mathutils import Vector, Matrix
ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/source'
OUTPUT = ROOT / 'assets/generated'

def import_gltf(filename):
    """Resolve each pack's own palette without altering archived source bytes."""
    source = SOURCE / filename
    if filename.startswith('Kenney_modern_'):
        manifest = json.loads((ROOT / 'assets/manifest.json').read_text())
        pack = next(row['pack'] for row in manifest['sources'] if row['file'] == filename)
        raw = source.read_bytes(); length, kind = struct.unpack_from('<II', raw, 12)
        model = json.loads(raw[20:20 + length])
        for image in model.get('images', []):
            if image.get('uri') == 'Textures/colormap.png':
                image['uri'] = str(SOURCE / ('Kenney_' + pack + '_colormap.png'))
        encoded = json.dumps(model, separators=(',', ':')).encode()
        encoded += b' ' * ((-len(encoded)) % 4)
        payload = struct.pack('<II', len(encoded), kind) + encoded + raw[20 + length:]
        cache = ROOT / 'build/import-cache'; cache.mkdir(parents=True, exist_ok=True)
        source = cache / filename
        source.write_bytes(struct.pack('<4sII', b'glTF', 2, len(payload) + 12) + payload)
    bpy.ops.import_scene.gltf(filepath=str(source))
ITEMS = [
    ('reef_tubes', 'PolyPizza_Coral.glb', 'tubes', 3500, 1000, 520),
    ('reef_fan', 'PolyPizza_EnviroCoral.glb', None, 6000, 1400, 360),
    ('reef_branch', 'PolyPizza_OrangeCoral.glb', None, 2800, 500, 160),
    ('reef_kelp', 'PolyPizza_Seaweed.glb', None, 1000, 400, 140),
    ('reef_meadow', 'PolyPizza_SeaweedThree.glb', None, 1500, 700, 220),
    ('reef_anemone', 'PolyPizza_Anemone.glb', None, 2800, 1400, 400),
    ('reef_lilac', 'PolyPizza_WhiteAnemone.glb', None, 1600, 280, 100),
    ('reef_boulder_a', 'Aquarium_CoralStoneA.js', 'rock', 1200, 260, 80),
    ('reef_boulder_b', 'Aquarium_CoralStoneB.js', 'rock', 1200, 260, 80),
    ('reef_shelf', 'Aquarium_RockB.js', 'rock', 1600, 320, 100),
    ('reef_arch', 'Aquarium_Arch.js', None, 2200, 600, 220),
    ('reef_columns', 'Aquarium_RuinColumn.js', None, 2200, 600, 220),
    ('reef_wreck', 'Aquarium_SunknShip.js', None, 3000, 900, 320),
    ('reef_chest', 'Aquarium_TreasureChest.js', None, 1000, 240, 80),
]

def clear():
    for obj in list(bpy.data.objects): bpy.data.objects.remove(obj, do_unlink=True)

def load_aquarium(filename):
    raw = json.loads((SOURCE / filename).read_text())
    for index, part in enumerate(raw['models']):
        fields = part['fields']; data = fields['position']['data']; indices = fields['indices']['data']
        points = [(data[i], -data[i+2], data[i+1]) for i in range(0, len(data), 3)]
        mesh = bpy.data.meshes.new(filename)
        mesh.from_pydata(points, [], [indices[i:i+3] for i in range(0, len(indices), 3)])
        uv = fields['texCoord']['data']; layer = mesh.uv_layers.new()
        for poly in mesh.polygons:
            poly.use_smooth = True
            for loop in poly.loop_indices:
                vertex = mesh.loops[loop].vertex_index
                layer.data[loop].uv = uv[vertex*2:vertex*2+2]
        mat = bpy.data.materials.new(filename); mat.use_nodes = True
        node = mat.node_tree.nodes.new('ShaderNodeTexImage')
        node.image = bpy.data.images.load(str(SOURCE / ('Aquarium_' + part['textures']['diffuse'])), check_existing=True)
        mat.node_tree.links.new(node.outputs['Color'], mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
        mesh.materials.append(mat)
        obj = bpy.data.objects.new(filename + str(index), mesh); bpy.context.collection.objects.link(obj)
        # Add sampling points, preserving the original authored shape and UVs.
        bpy.context.view_layer.objects.active = obj
        sub = obj.modifiers.new('Texture colour samples', 'SUBSURF'); sub.subdivision_type = 'SIMPLE'; sub.levels = 2
        bpy.ops.object.modifier_apply(modifier=sub.name)

pixels = {}
def sample_color(obj, poly, mode):
    mat = obj.data.materials[poly.material_index] if obj.data.materials else None
    rgb = (.5, .65, .7)
    if mat:
        bsdf = next((n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None) if mat.use_nodes else None
        if bsdf:
            rgb = tuple(bsdf.inputs['Base Color'].default_value[:3])
            image = next((n.image for n in mat.node_tree.nodes if n.type == 'TEX_IMAGE' and n.image), None)
            uv = obj.data.uv_layers.active
            if image and uv:
                if image.name not in pixels: pixels[image.name] = list(image.pixels)
                coords = [uv.data[i].uv for i in poly.loop_indices]
                u = sum(v.x for v in coords)/len(coords); v = sum(v.y for v in coords)/len(coords)
                w, h = image.size; x = int((u % 1) * (w-1)); y = int((v % 1) * (h-1)); offset = (y*w+x)*4
                rgb = pixels[image.name][offset:offset+3]
        else: rgb = tuple(mat.diffuse_color[:3])
    if mode == 'tubes':
        # Preserve the sculpted mouths and colour differences of the original.
        lum = sum(rgb)/3
        rgb = (.035 + lum*.10, .32 + lum*.37, .45 + lum*.4)
    elif mode == 'rock':
        lum = sum(rgb)/3
        rgb = (.035 + lum*.04, .30 + lum*.15, .43 + lum*.15)
    def srgb(v): return 12.92*v if v <= .0031308 else 1.055*max(v, 0)**(1/2.4)-.055
    return [round(max(0, min(1, srgb(c)))*255) for c in rgb]

def bake(key, filename, mode, full, lod, far):
    clear()
    if filename.endswith('.glb'): import_gltf(filename)
    else: load_aquarium(filename)
    bpy.context.view_layer.update()
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    if mode == 'tubes':
        meshes = [o for o in meshes if o.name.lower().startswith('tube')]
        assert meshes, 'The source coral must contain the original tube sculptures'
    for obj in meshes:
        transform = obj.matrix_world.copy(); obj.parent = None; obj.matrix_world = Matrix.Identity(4)
        obj.data.transform(transform)
        # OBJ-derived GLBs often repeat each triangle's corner vertices. Weld
        # coincident points before decimation, otherwise whole disconnected
        # triangles disappear instead of the sculpt being simplified.
        bm = bmesh.new(); bm.from_mesh(obj.data)
        bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=0.0001)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        bm.to_mesh(obj.data); bm.free(); obj.data.update()
    verts = [v.co for o in meshes for v in o.data.vertices]
    lo = Vector(tuple(min(v[i] for v in verts) for i in range(3))); hi = Vector(tuple(max(v[i] for v in verts) for i in range(3)))
    factor = 6/max(hi-lo); center = (hi+lo)/2
    for o in meshes:
        for v in o.data.vertices: v.co = (v.co-center)*factor
    if key == 'reef_fan':
        # The original OBJ fan has overlapping non-manifold branch shells that
        # Blender cannot collapse. Rebuild the same sculpted volume before LOD.
        for obj in meshes:
            bpy.context.view_layer.objects.active = obj
            mod = obj.modifiers.new('Clean authored coral volume', 'REMESH')
            mod.mode = 'VOXEL'; mod.voxel_size = 0.018; mod.use_smooth_shade = True
            bpy.ops.object.modifier_apply(modifier=mod.name)
    source_triangles = sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in meshes)
    result = {'Kind': 'environment', 'Source': filename}
    for level, budget in [('Full', full), ('Lod', lod), ('Far', far)]:
        vertices = []; faces = []; colors = []; normals = []
        for original in meshes:
            obj = original.copy(); obj.data = original.data.copy(); bpy.context.collection.objects.link(obj)
            bpy.context.view_layer.objects.active = obj
            mod = obj.modifiers.new('Bounded authored scenery', 'DECIMATE'); mod.ratio = min(1, budget/max(source_triangles, 1))
            bpy.ops.object.modifier_apply(modifier=mod.name)
            mod = obj.modifiers.new('Triangles', 'TRIANGULATE'); bpy.ops.object.modifier_apply(modifier=mod.name)
            obj.data.update(); offset = len(vertices)
            vertices.extend([[round(v.co.x, 5), round(v.co.z, 5), round(-v.co.y, 5)] for v in obj.data.vertices])
            normals.extend([[round(v.normal.x, 5), round(v.normal.z, 5), round(-v.normal.y, 5)] for v in obj.data.vertices])
            for poly in obj.data.polygons:
                faces.append([offset+i+1 for i in poly.vertices]); colors.append(sample_color(obj, poly, mode))
            bpy.data.objects.remove(obj, do_unlink=True)
        used = set(i for face in faces for i in face); remap = {old:i+1 for i, old in enumerate(sorted(used))}
        vertices = [v for i, v in enumerate(vertices, 1) if i in used]; normals = [v for i, v in enumerate(normals, 1) if i in used]
        faces = [[remap[i] for i in face] for face in faces]
        low = [min(v[i] for v in vertices) for i in range(3)]
        high = [max(v[i] for v in vertices) for i in range(3)]
        bounds = [high[i]-low[i] for i in range(3)]
        midpoint = [(high[i]+low[i])/2 for i in range(3)]
        anchor = 0 if level == 'Full' else (bounds[1]-result['Full']['Bounds'][1])/2
        vertices = [[round(v[i]-midpoint[i]+(anchor if i == 1 else 0), 5) for i in range(3)] for v in vertices]
        result[level] = {'Vertices': vertices, 'Faces': faces, 'Colors': colors, 'Bounds': bounds, 'Normals': normals}
    (OUTPUT / (key+'.json')).write_text(json.dumps(result, separators=(',', ':')))
    print('BAKED', key, source_triangles, '->', *(len(result[k]['Faces']) for k in ('Full','Lod','Far')), flush=True)

def lua(v):
    if isinstance(v, dict): return '{'+','.join('['+json.dumps(k)+']='+lua(x) for k,x in v.items())+'}'
    if isinstance(v, list): return '{'+','.join(lua(x) for x in v)+'}'
    return json.dumps(v, separators=(',', ':'))
def write_catalog():
    assets = {p.stem:json.loads(p.read_text()) for p in sorted(OUTPUT.glob('*.json'))}
    (ROOT / 'src/shared/ArtData.luau').write_text('--!nonstrict\n-- Generated art; source credits: assets/CREDITS.md.\nreturn '+lua(assets)+'\n')

if __name__ == '__main__':
    for item in ITEMS: bake(*item)
    write_catalog()
    print('Environment art and shared catalog written.', flush=True)
