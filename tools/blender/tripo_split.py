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
# A leg is the column around its foot: at most this far to the sides and to the front and back.
LEG_HALF_WIDTH = 0.85
LEG_HALF_LENGTH = 1.6


def _verts(obj):
    return [v.co for v in obj.data.vertices]


def prepare(name, target=TARGET_TRIANGLES, flip=False):
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
    # Reduce.
    mesh.calc_loop_triangles()
    before = len(mesh.loop_triangles)
    if before > target:
        modifier = obj.modifiers.new("Decimate", "DECIMATE")
        modifier.ratio = target / before
        bpy.ops.object.modifier_apply(modifier=modifier.name)
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


def _paint(obj):
    mesh = obj.data
    if "Pattern" in mesh.color_attributes:
        mesh.color_attributes.remove(mesh.color_attributes["Pattern"])
    attribute = mesh.color_attributes.new(name="Pattern", type="BYTE_COLOR", domain="CORNER")
    for polygon in mesh.polygons:
        value = 1.0 if polygon.normal.z < -0.25 else 0.82
        linear = value ** 2.2
        for loop_index in polygon.loop_indices:
            attribute.data[loop_index].color = (linear, linear, linear, 1.0)
    mesh.color_attributes.active_color = attribute
    mesh.color_attributes.render_color_index = mesh.color_attributes.find("Pattern")


def _sphere(bm, center, scale):
    bmesh.ops.create_uvsphere(bm, u_segments=6, v_segments=4, radius=1.0,
                              matrix=Matrix.Translation(center) @ Matrix.Diagonal((scale[0], scale[1], scale[2], 1)))


def add_face(name, objects, half_cap=0.7, drop=0.4):
    """Eyes and pupils on the head (the front end of the body): the eye sits `drop` below the
    top of the head, as wide as the head is there (at most `half_cap`)."""
    low = name.lower()
    points = _verts(objects["Body"])
    ymax = max(p.y for p in points)
    zone = [p for p in points if ymax - 1.3 <= p.y <= ymax - 0.5]
    top = max(p.z for p in zone)
    ez = top - drop
    near = sorted(abs(p.x) for p in zone if abs(p.z - ez) < 0.5)
    half = min(near[int(len(near) * 0.9)] if near else 0.35, half_cap)
    ey = ymax - 0.9
    eyes, dark = bmesh.new(), bmesh.new()
    for side in (-1, 1):
        _sphere(eyes, (side * half * 0.92, ey, ez), (0.10, 0.17, 0.17))
        _sphere(dark, (side * (half * 0.92 + 0.08), ey + 0.04, ez), (0.045, 0.09, 0.09))
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
    for part, obj in objects.items():
        if part not in ("Eyes", "Dark"):
            _paint(obj)
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
