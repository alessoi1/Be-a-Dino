"""Prepares a Tripo model (one mesh, FBX) for the game (run inside Blender, for example through the
MCP connection: exec(open(path).read())): turns it so that the head looks to +Y, scales it to the
length of the other dinos, reduces the triangles, splits it into Body, Tail and the legs (two legs
for a two-legged dino, four for a four-legged one), adds the neutral skin pattern as vertex colors,
builds eyes and pupils from the head and exports one FBX file for the Studio import.

Game coordinates before the export (see tools/blender/loft.py): +Y is the front (the export turns
the model by 180 degrees), Z is up, the feet stand at z = -3, the middle of the length is at y = -0.8.
"""

import math

import bmesh
import bpy
from mathutils import Matrix, Vector

LENGTH = 9.46
TARGET_TRIANGLES = 1200
FOOT_Z = -3.0
# Flat faces on the ground larger than this are a base plate (studs squared); planar dissolve angle.
SLAB_AREA = 0.6
DISSOLVE_ANGLE = 5
# A face longer than this and thinner than the ratio (area / length squared) is a sliver.
SLIVER_LENGTH = 0.9
SLIVER_RATIO = 0.05
# A leg is the column around its foot: at most this far to the sides and to the front and back.
LEG_HALF_WIDTH = 0.85
LEG_HALF_LENGTH = 1.6


def _verts(obj):
    return [v.co for v in obj.data.vertices]


def prepare(name, target=TARGET_TRIANGLES, flip=False, slivers_off=True):
    """Imports nothing: expects the object `<name>_src` (already applied). Aligns, scales and
    reduces it in place and returns the object (renamed `<name>_all`)."""
    obj = bpy.data.objects[name + "_src"]
    obj.name = name + "_all"
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    mesh = obj.data
    # Yaw: the main direction of the vertices on the ground plane (power iteration on the 2x2
    # covariance) becomes the Y axis.
    points = _verts(obj)
    cx = sum(p.x for p in points) / len(points)
    cy = sum(p.y for p in points) / len(points)
    sxx = sum((p.x - cx) ** 2 for p in points)
    syy = sum((p.y - cy) ** 2 for p in points)
    sxy = sum((p.x - cx) * (p.y - cy) for p in points)
    angle = 0.5 * math.atan2(2 * sxy, sxx - syy)  # direction of the main axis
    mesh.transform(Matrix.Rotation(math.pi / 2 - angle, 4, "Z"))
    # Which end is the head? The head end has more detail (more vertices near the tip) than the tail.
    points = _verts(obj)
    low = min(p.y for p in points)
    high = max(p.y for p in points)
    length = high - low
    near_high = sum(1 for p in points if p.y > high - 0.18 * length)
    near_low = sum(1 for p in points if p.y < low + 0.18 * length)
    head_plus = near_high >= near_low
    if flip:
        head_plus = not head_plus
    if not head_plus:
        mesh.transform(Matrix.Rotation(math.pi, 4, "Z"))
    points = _verts(obj)
    low = min(p.y for p in points)
    high = max(p.y for p in points)
    zmin = min(p.z for p in points)
    factor = LENGTH / (high - low)
    mesh.transform(Matrix.Translation((-sum(p.x for p in points) / len(points), 0, 0)))
    mesh.transform(Matrix.Diagonal((factor, factor, factor, 1)))
    mesh.transform(Matrix.Translation((0, 0, 0)))
    points = _verts(obj)
    zmin = min(p.z for p in points)
    low = min(p.y for p in points)
    high = max(p.y for p in points)
    mesh.transform(Matrix.Translation((0, -(low + high) / 2 - 0.8, FOOT_Z - zmin)))
    # Clean up: consistent normals (a flipped face is invisible from one side in Roblox) and no flat
    # slab on the ground under the feet (Tripo sometimes adds a base plate).
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ground = min(v.co.z for v in bm.verts)
    slab = [f for f in bm.faces if abs(f.normal.z) > 0.9 and max(v.co.z for v in f.verts) < ground + 0.2 and f.calc_area() > SLAB_AREA]
    if slab:
        bmesh.ops.delete(bm, geom=slab, context="FACES")
        loose = [v for v in bm.verts if not v.link_faces]
        bmesh.ops.delete(bm, geom=loose, context="VERTS")
    bm.to_mesh(mesh)
    bm.free()
    print("prepare:", name, "slab faces removed:", len(slab))
    # Reduce: first dissolve flat areas (the blocky Tripo shapes keep their form), then collapse.
    mesh.calc_loop_triangles()
    before = len(mesh.loop_triangles)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.dissolve_limit(bm, angle_limit=math.radians(DISSOLVE_ANGLE), verts=bm.verts, edges=bm.edges)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    mesh.calc_loop_triangles()
    if len(mesh.loop_triangles) > target:
        modifier = obj.modifiers.new("Decimate", "DECIMATE")
        modifier.ratio = target / len(mesh.loop_triangles)
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    # Thin long slivers (a collapsed tooth, a stray bar) are removed.
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    slivers = []
    for face in bm.faces:
        longest = max(e.calc_length() for e in face.edges)
        if not slivers_off and longest > SLIVER_LENGTH and face.calc_area() < SLIVER_RATIO * longest * longest:
            slivers.append(face)
    if slivers:
        bmesh.ops.delete(bm, geom=slivers, context="FACES")
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(obj.data)
    bm.free()
    print("prepare:", name, "slivers removed:", len(slivers))
    for polygon in obj.data.polygons:
        polygon.use_smooth = False
    obj.data.calc_loop_triangles()
    return obj, before


def _slice_stats(points, top, size):
    inside = [p for p in points if p.y > top - size]
    return min(p.z for p in inside), max(p.z for p in inside)


def split(name, mode=None, zcut_frac=None):
    """Splits `<name>_all` into `<lower>_Body`, `_Tail` and the legs (`_LegL`, `_LegR` for a two-legged
    dino; `_LegFL`, `_LegFR`, `_LegBL`, `_LegBR` for a four-legged one). `mode` is "biped" or "quad"
    (detected from the feet when left out). Returns the mode and the objects."""
    low = name.lower()
    source = bpy.data.objects[name + "_all"]
    points = _verts(source)
    zmin = min(p.z for p in points)
    zmax = max(p.z for p in points)
    height = zmax - zmin
    ymin = min(p.y for p in points)
    ymax = max(p.y for p in points)
    feet = [p for p in points if p.z < zmin + 0.1 * height]
    foot_ys = sorted(p.y for p in feet)
    if mode is None:
        mode = "quad" if (foot_ys[-1] - foot_ys[0]) > 0.22 * (ymax - ymin) else "biped"
    if zcut_frac is None:
        zcut_frac = 0.34 if mode == "biped" else 0.30
    zcut = zmin + zcut_frac * height
    # The feet decide where the legs are: one column per foot (its middle on the ground plane).
    if mode == "quad":
        gaps = [(foot_ys[i + 1] - foot_ys[i], i) for i in range(len(foot_ys) - 1)]
        _, split_at = max(gaps)
        limit_y = foot_ys[split_at]
        columns_def = [("LegFL", True, -1), ("LegFR", True, 1), ("LegBL", False, -1), ("LegBR", False, 1)]
        back_ys = [p.y for p in feet if p.y <= limit_y]
        y_back = sum(back_ys) / len(back_ys)
        y_tail = y_back - 2.2
    else:
        limit_y = None
        columns_def = [("LegL", None, -1), ("LegR", None, 1)]
        y_foot = sum(p.y for p in feet) / len(feet)
        y_tail = y_foot - 2.0
    columns = []
    for part, front, side in columns_def:
        group_points = [
            p for p in feet
            if (p.x < 0) == (side < 0) and (front is None or (p.y > limit_y) == front)
        ]
        if group_points:
            columns.append((part, sum(p.x for p in group_points) / len(group_points), sum(p.y for p in group_points) / len(group_points)))
    bm = bmesh.new()
    bm.from_mesh(source.data)
    if mode == "biped" and len(columns) == 2:
        # Nothing stands between the two feet on the ground (Tripo sometimes leaves a bar there).
        mid_x = (columns[0][1] + columns[1][1]) / 2
        half_gap = abs(columns[1][1] - columns[0][1]) / 2
        bar = [
            f for f in bm.faces
            if abs(f.calc_center_median().x - mid_x) < half_gap - 0.5
            and f.calc_center_median().z < zmin + 0.45
            and abs(f.calc_center_median().y - y_foot) < 1.8
        ]
        if bar:
            bmesh.ops.delete(bm, geom=bar, context="FACES")
            bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
        print("split:", name, "faces removed between the feet:", len(bar))

    def group(face):
        c = face.calc_center_median()
        best = None
        best_distance = None
        if c.z < zcut:
            for part, fx, fy in columns:
                dx, dy = abs(c.x - fx), abs(c.y - fy)
                if dx < LEG_HALF_WIDTH and dy < LEG_HALF_LENGTH:
                    distance = dx * dx + dy * dy
                    if best is None or distance < best_distance:
                        best, best_distance = part, distance
        if best is not None:
            return best
        if c.y < y_tail:
            return "Tail"
        return "Body"

    names = ["Body", "Tail", "LegL", "LegR"] if mode == "biped" else ["Body", "Tail", "LegFL", "LegFR", "LegBL", "LegBR"]
    objects = {}
    for part in names:
        copy = bm.copy()
        bmesh.ops.delete(copy, geom=[f for f in copy.faces if group(f) != part], context="FACES")
        bmesh.ops.delete(copy, geom=[v for v in copy.verts if not v.link_faces], context="VERTS")
        if not copy.faces:
            # No face reached this foot (the leg stays part of the body): the part is left out.
            copy.free()
            print("split: no faces for", f"{low}_{part}")
            continue
        mesh = bpy.data.meshes.new(f"{low}_{part}")
        copy.to_mesh(mesh)
        copy.free()
        for polygon in mesh.polygons:
            polygon.use_smooth = False
        obj = bpy.data.objects.new(f"{low}_{part}", mesh)
        bpy.context.scene.collection.objects.link(obj)
        objects[part] = obj
    bm.free()
    source.hide_set(True)
    source.hide_render = True
    return mode, objects


def _smooth(edge0, edge1, value):
    t = min(max((value - edge0) / (edge1 - edge0), 0.0), 1.0)
    return t * t * (3 - 2 * t)


def _paint(obj, zlow, zhigh):
    """Neutral grey values as a natural gradient (the game multiplies them with the color of the
    dino): a dark back, a lighter belly and a little variation from face to face. The back is the
    top of the whole dino, so the gradient runs through all parts alike."""
    mesh = obj.data
    if "Pattern" in mesh.color_attributes:
        mesh.color_attributes.remove(mesh.color_attributes["Pattern"])
    attribute = mesh.color_attributes.new(name="Pattern", type="BYTE_COLOR", domain="CORNER")
    span = max(zhigh - zlow, 1e-3)
    for polygon in mesh.polygons:
        # A little different brightness per face keeps the faceted look alive.
        noise = ((polygon.index * 2654435761) % 1000) / 1000.0 * 0.08 - 0.04
        for loop_index in polygon.loop_indices:
            z = mesh.vertices[mesh.loops[loop_index].vertex_index].co.z
            t = (z - zlow) / span
            value = 1.0 - 0.42 * _smooth(0.2, 0.95, t)
            if polygon.normal.z < -0.25:
                value = min(1.0, value + 0.12)
            value = min(max(value + noise, 0.0), 1.0)
            linear = value ** 2.2
            attribute.data[loop_index].color = (linear, linear, linear, 1.0)
    mesh.color_attributes.active_color = attribute
    mesh.color_attributes.render_color_index = mesh.color_attributes.find("Pattern")


def _sphere(bm, center, scale):
    bmesh.ops.create_uvsphere(bm, u_segments=6, v_segments=4, radius=1.0,
                              matrix=Matrix.Translation(center) @ Matrix.Diagonal((scale[0], scale[1], scale[2], 1)))


def add_face(name, objects, half_cap=0.7, drop=0.45, back=1.1, eye_z=None, right_extra=0.0):
    """Eyes and pupils on the head (the front end of the body). The eye sits `drop` studs below the
    top of the head and `back` studs behind the tip of the snout, centered on the head and as wide as
    the skull is there (at most `half_cap`)."""
    low = name.lower()
    points = _verts(objects["Body"])
    ymax = max(p.y for p in points)
    zone = [p for p in points if p.y > ymax - 2.0]
    zs = sorted(p.z for p in zone)
    top = zs[int(len(zs) * 0.95)]
    ez = eye_z if eye_z is not None else top - drop
    ey = ymax - back
    cx = sum(p.x for p in zone) / len(zone)
    near = sorted(abs(p.x - cx) for p in points if abs(p.y - ey) < 0.5 and abs(p.z - ez) < 0.45)
    half = min(near[int(len(near) * 0.8)] if near else 0.35, half_cap)
    eyes, dark = bmesh.new(), bmesh.new()
    for side in (-1, 1):
        # `right_extra` moves only the right eye (+X, seen from behind) outwards (a turned head).
        extra = right_extra if side > 0 else 0.0
        _sphere(eyes, (cx + side * (half * 0.92 + extra), ey, ez), (0.10, 0.17, 0.17))
        _sphere(dark, (cx + side * (half * 0.92 + extra + 0.08), ey + 0.04, ez), (0.045, 0.09, 0.09))
    for part, bm in (("Eyes", eyes), ("Dark", dark)):
        mesh = bpy.data.meshes.new(f"{low}_{part}")
        bm.to_mesh(mesh)
        bm.free()
        for polygon in mesh.polygons:
            polygon.use_smooth = False
        obj = bpy.data.objects.new(f"{low}_{part}", mesh)
        bpy.context.scene.collection.objects.link(obj)
        objects[part] = obj
    return objects


def remove_parts(name):
    """Deletes the parts of an earlier split (so a dino can be split again)."""
    low = name.lower() + "_"
    for obj in list(bpy.data.objects):
        if obj.name.startswith(low):
            bpy.data.objects.remove(obj, do_unlink=True)


def finish(name, objects):
    """Skin pattern on the skin parts; returns the geometry and the joints for Config/DinoMeshes."""
    skin = [obj for part, obj in objects.items() if part not in ("Eyes", "Dark")]
    zlow = min(v.co.z for obj in skin for v in obj.data.vertices)
    zhigh = max(v.co.z for obj in skin for v in obj.data.vertices)
    for obj in skin:
        _paint(obj, zlow, zhigh)
    geometry = {}
    total = 0
    for part, obj in objects.items():
        obj.data.calc_loop_triangles()
        total += len(obj.data.loop_triangles)
        pts = _verts(obj)
        lo = [min(p[i] for p in pts) for i in range(3)]
        hi = [max(p[i] for p in pts) for i in range(3)]
        c = [(a + b) / 2 for a, b in zip(lo, hi)]
        geometry[part] = {
            "size": [round(hi[0] - lo[0], 4), round(hi[2] - lo[2], 4), round(hi[1] - lo[1], 4)],
            "off": [round(c[0], 4), round(c[2], 4), round(-c[1], 4)],
            "top": round(hi[2], 3),
            "front": round(hi[1], 3),
            "tris": len(obj.data.loop_triangles),
        }
    joints = {}
    for part, g in geometry.items():
        if part.startswith("Leg"):
            joints[part] = [g["off"][0], round(g["top"] - 0.15, 3), g["off"][2]]
    tail = geometry.get("Tail")
    if tail is not None:
        tail_pts = [p for p in _verts(objects["Tail"]) if p.y > tail["front"] - 0.5]
        height = sum(p.z for p in tail_pts) / len(tail_pts)
        joints["Tail"] = [0, round(height, 3), round(-tail["front"] + 0.5, 3)]
    return {"geometry": geometry, "joints": joints, "tris": total}


def export(name, objects, path):
    """One FBX file with all parts, turned by 180 degrees (like tools/blender/loft.py)."""
    items = list(objects.values())
    bpy.ops.object.select_all(action="DESELECT")
    for obj in items:
        obj.hide_set(False)
        obj.select_set(True)
    bpy.context.view_layer.objects.active = items[0]
    turn = Matrix.Rotation(math.pi, 4, "Z")
    for obj in items:
        obj.data.transform(turn)
    try:
        bpy.ops.export_scene.fbx(
            filepath=path, use_selection=True, object_types={"MESH"}, apply_scale_options="FBX_SCALE_NONE",
            axis_forward="-Z", axis_up="Y", global_scale=0.01, use_mesh_modifiers=True, mesh_smooth_type="FACE",
            colors_type="SRGB", add_leaf_bones=False, bake_anim=False,
        )
    finally:
        for obj in items:
            obj.data.transform(turn)


TARGETS = {"Edmonto": 3000, "Stego": 2000, "Ankylo": 2000}
FLIP_AFTER = {"Ankylo": True}  # Tripo made it face the other way round.


def import_raw(name, folder):
    """Imports `<folder>/<name>.fbx` as `<name>_src` with the transforms applied."""
    before = set(bpy.data.objects.keys())
    bpy.ops.import_scene.fbx(filepath=f"{folder}/{name}.fbx")
    new = [bpy.data.objects[k] for k in set(bpy.data.objects.keys()) - before if bpy.data.objects[k].type == "MESH"]
    obj = new[0]
    obj.name = name + "_src"
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def remove_head_bars(name, min_height=0.6, max_area=0.2, zone=0.9):
    """Deletes thin upright plates at the very front of the head (a bar across an open mouth)."""
    obj = bpy.data.objects[name + "_all"]
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    ymax = max(v.co.y for v in bm.verts)
    bars = []
    for face in bm.faces:
        center = face.calc_center_median()
        heights = [v.co.z for v in face.verts]
        if center.y > ymax - zone and max(heights) - min(heights) > min_height and face.calc_area() < max_area:
            bars.append(face)
    if bars:
        bmesh.ops.delete(bm, geom=bars, context="FACES")
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(obj.data)
    bm.free()
    print("remove_head_bars:", name, len(bars))


def process(name, zcut_frac=None, slivers=False, bars=False, **face):
    """Everything for one dino after `import_raw`: prepare, split, face, skin pattern. Returns the
    result of `finish` plus the mode."""
    remove_parts(name)
    obj, _ = prepare(name, target=TARGETS.get(name, TARGET_TRIANGLES), slivers_off=not slivers)
    if FLIP_AFTER.get(name):
        obj.data.transform(Matrix.Rotation(math.pi, 4, "Z"))
        obj.data.transform(Matrix.Translation((0, -1.6, 0)))
    if bars:
        remove_head_bars(name)
    mode, objects = split(name, zcut_frac=zcut_frac)
    add_face(name, objects, **face)
    info = finish(name, objects)
    info["mode"] = mode
    return info, objects


def head_sheet(names, path, size=4.5):
    """Renders the head of each dino from the side and from the front-left into one picture, with
    the eyes in place (to check them)."""
    import numpy as np

    scene = bpy.context.scene
    camera = bpy.data.objects["Camera"]
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = size
    scene.render.resolution_x, scene.render.resolution_y = 480, 360
    palette = {"Eyes": (0.95, 0.62, 0.08), "Dark": (0.02, 0.02, 0.02)}
    for key, color in palette.items():
        mat = bpy.data.materials.get("pc_" + key) or bpy.data.materials.new("pc_" + key)
        mat.use_nodes = True
        mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*color, 1)
    grey = bpy.data.materials.get("pc_Body") or bpy.data.materials.new("pc_Body")
    grey.use_nodes = True
    grey.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.75, 0.75, 0.75, 1)
    tiles = []
    for name in names:
        low = name.lower()
        for obj in bpy.data.objects:
            if obj.type == "MESH":
                obj.hide_render = True
        parts = [o for o in bpy.data.objects if o.name.startswith(low + "_") and o.type == "MESH"]
        for obj in parts:
            obj.hide_render = False
            suffix = obj.name.split("_", 1)[1]
            obj.data.materials.clear()
            obj.data.materials.append(bpy.data.materials.get("pc_" + suffix) or grey)
        body = bpy.data.objects[low + "_Body"]
        pts = [v.co for v in body.data.vertices]
        ymax = max(p.y for p in pts)
        zs = sorted(p.z for p in pts if p.y > ymax - 2.0)
        center = Vector((0, ymax - 1.0, zs[int(len(zs) * 0.7)]))
        for location in (Vector((30, 0, 0)), Vector((20, 14, 6))):
            camera.location = center + location
            camera.rotation_euler = (center - camera.location).to_track_quat("-Z", "Y").to_euler()
            scene.render.filepath = path + ".tmp.png"
            bpy.ops.render.render(write_still=True)
            image = bpy.data.images.load(scene.render.filepath)
            tiles.append(np.array(image.pixels[:]).reshape(360, 480, 4))
            bpy.data.images.remove(image)
    while len(tiles) % 4:
        tiles.append(np.zeros_like(tiles[0]))
    rows = [np.concatenate(tiles[i:i + 4], axis=1) for i in range(0, len(tiles), 4)]
    sheet = np.concatenate(rows[::-1], axis=0)
    out = bpy.data.images.new("head_sheet", 1920, 360 * len(rows))
    out.pixels = sheet.flatten().tolist()
    out.filepath_raw = path
    out.file_format = "PNG"
    out.save()
    bpy.data.images.remove(out)
