"""Builds low-poly dino parts from cross sections (run inside Blender, for example through the MCP
connection: exec(open(path).read())). A part is a "loft": a tube along a list of stations, each
station has a position and the half width and half height of its cross section. Used to model a
dino after a reference picture (see docs/MODELLE.md, section "Modelle nach Bild").

Coordinates are the game coordinates before the export: +Y is the front (the export turns the
model by 180 degrees), Z is up, the feet stand at z = -3 and the middle of the figure is the origin.
"""

import math

import bmesh
import bpy
from mathutils import Matrix, Vector

SIDES = 6
PART_SUFFIXES = ("Body", "Tail", "LegL", "LegR", "Eyes", "Dark")
EXPORT_SCALE = 0.01


def _frame(direction, up):
    side = direction.cross(Vector(up))
    if side.length < 1e-6:
        side = direction.cross(Vector((1, 0, 0)))
    side.normalize()
    normal = side.cross(direction)
    normal.normalize()
    return side, normal


def loft_bmesh(bm, stations, sides=SIDES, up=(0, 0, 1), cap_start=True, cap_end=True):
    """Adds a tube to `bm`. stations: list of (x, y, z, half_width, half_height). A station with a
    half width and height of 0 ends in a point."""
    rings = []
    count = len(stations)
    for index, (x, y, z, rw, rh) in enumerate(stations):
        center = Vector((x, y, z))
        before = Vector(stations[max(index - 1, 0)][:3])
        after = Vector(stations[min(index + 1, count - 1)][:3])
        direction = after - before
        if direction.length < 1e-6:
            direction = Vector((0, 1, 0))
        direction.normalize()
        side, normal = _frame(direction, up)
        ring = []
        for k in range(sides):
            angle = 2 * math.pi * k / sides
            point = center + side * (rw * math.cos(angle)) + normal * (rh * math.sin(angle))
            ring.append(bm.verts.new(point))
        rings.append(ring)
    for index in range(count - 1):
        for k in range(sides):
            a, b = rings[index][k], rings[index][(k + 1) % sides]
            c, d = rings[index + 1][(k + 1) % sides], rings[index + 1][k]
            try:
                bm.faces.new((a, b, c, d))
            except ValueError:
                pass
    if cap_start:
        try:
            bm.faces.new(rings[0])
        except ValueError:
            pass
    if cap_end:
        try:
            bm.faces.new(list(reversed(rings[-1])))
        except ValueError:
            pass
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)


def sphere_bmesh(bm, center, scale, u_segments=6, v_segments=4):
    bmesh.ops.create_uvsphere(
        bm,
        u_segments=u_segments,
        v_segments=v_segments,
        radius=1.0,
        matrix=Matrix.Translation(center) @ Matrix.Diagonal((scale[0], scale[1], scale[2], 1)),
    )


def cone_bmesh(bm, base, tip, radius, sides=3):
    """A claw or horn from `base` to `tip`."""
    base, tip = Vector(base), Vector(tip)
    loft_bmesh(bm, [(*base, radius, radius), (*tip, 0.0, 0.0)], sides=sides, up=(0, 0, 1), cap_start=True, cap_end=False)


def make_object(name, bm, material=None):
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    for polygon in mesh.polygons:
        polygon.use_smooth = False
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    if material is not None:
        mesh.materials.append(material)
    return obj


def paint(obj):
    """Neutral grey values: a lighter belly, a darker back (the game multiplies them with the
    color of the dino)."""
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


def clear(prefix):
    for obj in list(bpy.data.objects):
        if obj.name.startswith(prefix + "_"):
            bpy.data.objects.remove(obj, do_unlink=True)


def bounds(obj):
    vertices = [v.co for v in obj.data.vertices]
    low = [min(v[i] for v in vertices) for i in range(3)]
    high = [max(v[i] for v in vertices) for i in range(3)]
    center = [(a + b) / 2 for a, b in zip(low, high)]
    size = [b - a for a, b in zip(low, high)]
    return low, high, center, size


def game_geometry(obj):
    """Size and offset as the game needs them (x, y, z in figure coordinates: x stays, y is Blender
    z, z is minus Blender y)."""
    _, _, center, size = bounds(obj)
    obj.data.calc_loop_triangles()
    return {
        "size": [round(size[0], 4), round(size[2], 4), round(size[1], 4)],
        "off": [round(center[0], 4), round(center[2], 4), round(-center[1], 4)],
        "tris": len(obj.data.loop_triangles),
    }


def export(prefix, path):
    """Exports <prefix>_Body, _Tail, _LegL, _LegR, _Eyes and _Dark as one FBX file (turned by 180
    degrees around the vertical axis, like tools/blender/dinos.py)."""
    objects = [bpy.data.objects[f"{prefix}_{suffix}"] for suffix in PART_SUFFIXES if f"{prefix}_{suffix}" in bpy.data.objects]
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.hide_set(False)
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    turn = Matrix.Rotation(math.pi, 4, "Z")
    for obj in objects:
        obj.data.transform(turn)
    try:
        bpy.ops.export_scene.fbx(
            filepath=path,
            use_selection=True,
            object_types={"MESH"},
            apply_scale_options="FBX_SCALE_NONE",
            axis_forward="-Z",
            axis_up="Y",
            global_scale=EXPORT_SCALE,
            use_mesh_modifiers=True,
            mesh_smooth_type="FACE",
            colors_type="SRGB",
            add_leaf_bones=False,
            bake_anim=False,
        )
    finally:
        for obj in objects:
            obj.data.transform(turn)
    return {obj.name: game_geometry(obj) for obj in objects}


def preview(prefix, path, zoom=11):
    """Renders a side view and a three-quarter view next to each other."""
    import numpy as np

    objects = [o for o in bpy.data.objects if o.type == "MESH" and o.name.startswith(prefix + "_")]
    for obj in bpy.data.objects:
        if obj.type == "MESH":
            obj.hide_render = obj not in objects
    palette = {"Body": (0.78, 0.78, 0.78), "Tail": (0.85, 0.45, 0.35), "LegL": (0.3, 0.55, 0.9), "LegR": (0.3, 0.8, 0.4), "Eyes": (0.95, 0.62, 0.08), "Dark": (0.02, 0.02, 0.02)}
    for obj in objects:
        suffix = obj.name.split("_", 1)[1]
        material = bpy.data.materials.get("pv_" + suffix) or bpy.data.materials.new("pv_" + suffix)
        material.use_nodes = True
        material.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*palette.get(suffix, (0.7, 0.7, 0.7)), 1)
        obj.data.materials.clear()
        obj.data.materials.append(material)
    scene = bpy.context.scene
    camera = bpy.data.objects["Camera"]
    light = bpy.data.objects["Light"]
    light.hide_render = False
    light.data.energy = 3000
    light.location = (14, 10, 18)
    scene.render.resolution_x, scene.render.resolution_y = 640, 480
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = zoom
    images = []
    views = [((30, 0, 0.5), (0, 0, 0)), ((zoom * 1.0, zoom * 1.3, zoom * 0.55), (0, 0, 0))]
    for index, (location, target) in enumerate(views):
        camera.data.type = "ORTHO" if index == 0 else "PERSP"
        camera.data.lens = 55
        camera.location = location
        camera.rotation_euler = (Vector(target) - Vector(location)).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = path + f".v{index}.png"
        bpy.ops.render.render(write_still=True)
        image = bpy.data.images.load(scene.render.filepath)
        images.append(np.array(image.pixels[:]).reshape(480, 640, 4))
        bpy.data.images.remove(image)
    merged = np.concatenate(images, axis=1)
    out = bpy.data.images.new("preview_merged", 1280, 480)
    out.pixels = merged.flatten().tolist()
    out.filepath_raw = path
    out.file_format = "PNG"
    out.save()
    bpy.data.images.remove(out)


# ---------------------------------------------------------------------------------------------
# A two-legged dino from a spec read off a side picture. All points are picture pixels (px, py) with
# the head on the left; `spec["s"]` turns pixels into studs, `spec["ground"]` is the pixel row of the
# feet. Half widths and heights are in studs.


def _point(spec, px, py):
    """(y, z) in game coordinates: the head ends up at +Y. With spec["direct"] the points are
    (y, height above the ground) in studs instead of picture pixels."""
    if spec.get("direct"):
        return px, py - 3.0
    return (spec["x0"] - px) * spec["s"], (spec["ground"] - py) * spec["s"] - 3.0


def _stations(spec, rows, x=0.0):
    out = []
    for px, py, rw, rh in rows:
        y, z = _point(spec, px, py)
        out.append((x, y, z, rw, rh))
    return out


def _add_foot(bm, spec, side_x, foot_rows, claws):
    loft_bmesh(bm, _stations(spec, foot_rows, side_x), sides=5, up=(0, 0, 1))
    tip_px, tip_py, _, _ = foot_rows[-1]
    for spread in claws:
        base_y, base_z = _point(spec, tip_px, tip_py)
        if spec.get("direct"):
            tip_y, tip_z = _point(spec, tip_px + 0.35, tip_py - 0.05)
        else:
            tip_y, tip_z = _point(spec, tip_px - 30, tip_py + 6)
        cone_bmesh(bm, (side_x + spread, base_y, base_z), (side_x + spread * 1.4, tip_y, tip_z), 0.07)


def build_biped(prefix, spec, material=None):
    clear(prefix)
    # Body: torso, neck and head as one tube, plus the arms.
    body = bmesh.new()
    loft_bmesh(body, _stations(spec, spec["body"]), sides=spec.get("sides", SIDES))
    for side in (-1, 1):
        ax = side * spec["arm_x"]
        loft_bmesh(body, _stations(spec, spec["arm"], ax), sides=4, up=(0, 1, 0))
        hand_y, hand_z = _point(spec, spec["arm"][-1][0], spec["arm"][-1][1])
        claw = spec.get("claw_len", 0.2)
        for spread in (-0.05, 0.05):
            cone_bmesh(body, (ax + spread, hand_y, hand_z), (ax + spread * 1.5, hand_y + claw, hand_z - claw * 0.6), spec.get("claw_r", 0.04))
    for extra in spec.get("extras", []):
        if extra[0] == "sphere":
            _, (ex, ey, eh), scale = extra
            sphere_bmesh(body, (ex, ey, eh - 3.0), scale)
        else:
            _, (bx, by, bh), (tx, ty, th), radius = extra
            cone_bmesh(body, (bx, by, bh - 3.0), (tx, ty, th - 3.0), radius, sides=4)
    tail = bmesh.new()
    loft_bmesh(tail, _stations(spec, spec["tail"]), sides=spec.get("sides", SIDES))
    objects = {"Body": make_object(f"{prefix}_Body", body, material), "Tail": make_object(f"{prefix}_Tail", tail, material)}
    for name, side in (("LegL", -1), ("LegR", 1)):
        leg = bmesh.new()
        lx = side * spec["leg_x"]
        loft_bmesh(leg, _stations(spec, spec["leg"], lx), sides=5, up=(0, 1, 0))
        _add_foot(leg, spec, lx, spec["foot"], (-0.12, 0.0, 0.12))
        objects[name] = make_object(f"{prefix}_{name}", leg, material)
    # Face: eyes and pupils on both sides of the head.
    ey, ez = _point(spec, *spec["eye"])
    eyes, dark = bmesh.new(), bmesh.new()
    for side in (-1, 1):
        sphere_bmesh(eyes, (side * spec["head_half"] * 0.92, ey, ez), (0.10, 0.17, 0.17))
        sphere_bmesh(dark, (side * (spec["head_half"] * 0.92 + 0.08), ey + 0.04, ez), (0.045, 0.09, 0.09))
    objects["Eyes"] = make_object(f"{prefix}_Eyes", eyes)
    objects["Dark"] = make_object(f"{prefix}_Dark", dark)
    # Center on the figure: the middle of the length at y = -0.8 (like the other shapes).
    low = min(min(v.co.y for v in obj.data.vertices) for obj in objects.values())
    high = max(max(v.co.y for v in obj.data.vertices) for obj in objects.values())
    shift = -(low + high) / 2 - 0.8
    for obj in objects.values():
        obj.data.transform(Matrix.Translation((0, shift, 0)))
    for suffix in ("Body", "Tail", "LegL", "LegR"):
        paint(objects[suffix])
    total = 0
    for obj in objects.values():
        obj.data.calc_loop_triangles()
        total += len(obj.data.loop_triangles)
    # Joints in game coordinates (x stays, y is Blender z, z is minus Blender y).
    hip_y, hip_z = _point(spec, spec["leg"][0][0], spec["leg"][0][1])
    tail_y, tail_z = _point(spec, spec["tail"][1][0], spec["tail"][1][1])
    joints = {
        "hip": [spec["leg_x"], round(hip_z - 0.12, 3), round(-(hip_y + shift), 3)],
        "tail": [0, round(tail_z, 3), round(-(tail_y + shift), 3)],
    }
    return {"objects": objects, "tris": total, "joints": joints, "shift": shift}


def theropod(hh=3.4, tr=0.8, tw=0.6, tl=1.7, nk=1.2, nrise=1.2, nth=0.35, hl=1.5, hw=0.35, hhh=0.35,
             tail=4.5, lt=0.4, arm=1.2, at=0.1, hipf=0.4, extras=(), claw_len=0.25):
    """A spec for build_biped from a few measures (studs): hh hip height, tr/tw half height and width
    of the torso, tl half length of the torso, nk/nrise/nth neck length, rise and half thickness,
    hl/hw/hhh head length, half width and half height, tail length, lt leg thickness, arm length."""
    hc = hh + tr * 0.35
    hy = -tl * hipf
    sh = (tl, hc + tr * 0.2)
    ne = (tl + nk, hc + nrise)
    mid = ((sh[0] + ne[0]) / 2 - 0.05, (sh[1] + ne[1]) / 2 + 0.05)
    body = [
        (ne[0] + hl, ne[1] - hhh * 0.5, hw * 0.3, hhh * 0.3),
        (ne[0] + hl * 0.85, ne[1] - hhh * 0.4, hw * 0.6, hhh * 0.55),
        (ne[0] + hl * 0.45, ne[1] - hhh * 0.1, hw, hhh * 0.95),
        (ne[0], ne[1], hw * 0.9, hhh),
        (mid[0], mid[1], nth, nth * 1.1),
        (sh[0], hc + tr * 0.1, tw * 0.9, tr * 0.9),
        (0, hc, tw, tr),
        (-tl, hc, tw * 0.9, tr * 0.9),
        (-tl - 0.4, hc - 0.05, tw * 0.7, tr * 0.7),
    ]
    taillist = [
        (-tl + 0.1, hc, tw * 0.7, tr * 0.7),
        (-tl - tail * 0.25, hc - 0.1, tw * 0.55, tr * 0.55),
        (-tl - tail * 0.55, hc - 0.05, tw * 0.3, tr * 0.32),
        (-tl - tail * 0.8, hc + 0.1, tw * 0.14, tr * 0.15),
        (-tl - tail, hc + 0.2, 0.0, 0.0),
    ]
    leg = [
        (hy, hc - 0.1, lt, lt * 1.05),
        (hy + 0.6, hh * 0.55, lt * 0.75, lt * 0.75),
        (hy - 0.2, 0.32, lt * 0.5, lt * 0.5),
        (hy - 0.2, 0.2, lt * 0.5, lt * 0.4),
    ]
    foot = [(hy - 0.2, 0.22, lt * 0.55, 0.2), (hy + 0.5, 0.1, lt * 0.55, 0.13), (hy + 1.2, 0.04, lt * 0.25, 0.07)]
    arm_rows = [(tl * 0.8, hc - 0.1, at * 1.2, at * 1.2), (tl * 0.9, hc - 0.1 - arm * 0.5, at, at), (tl * 1.0 + 0.1, hc - 0.1 - arm, at * 0.8, at * 0.8)]
    return dict(
        direct=True, body=body, tail=taillist, leg=leg, foot=foot, arm=arm_rows,
        leg_x=tw * 0.85, arm_x=tw + 0.05, eye=(ne[0] + hl * 0.4, ne[1] + hhh * 0.35), head_half=hw,
        extras=list(extras), claw_len=claw_len,
    )


# ---------------------------------------------------------------------------------------------
# A more detailed two-legged hunter (T-Rex and its kin): round body, a skull with a separate lower
# jaw and teeth, brow bumps, thick bent legs with three toes and claws, tiny arms. Same measures as
# theropod() and the same parts as build_biped(). About 1,500 triangles.


def _add_toe(bm, base, tip, radius, claw=0.28):
    loft_bmesh(bm, [(*base, radius, radius * 0.9), (*tip, radius * 0.55, radius * 0.5)], sides=4, up=(0, 0, 1))
    cone_bmesh(bm, tip, (tip[0], tip[1] + 0.25, tip[2] - claw * 0.55), radius * 0.5, sides=3)


def build_hunter(prefix, hh=3.8, tr=1.3, tw=1.0, tl=2.2, nk=0.9, nrise=0.9, nth=1.05, hl=2.3, hw=0.8, hhh=0.8,
                 tail=4.6, lt=0.85, arm=0.7, at=0.1, material=None, teeth=True, pitch=0.0):
    """pitch: how much higher the chest is than the hips (studs)."""
    clear(prefix)
    hc = hh + tr * 0.35
    ney, neh = tl + nk, hc + pitch * 0.8 + nrise

    def z(h):
        return h - 3.0

    body = bmesh.new()
    chain = [
        (0, -tl - 0.3, z(hc - 0.05 - pitch * 0.5), tw * 0.7, tr * 0.75),
        (0, -tl, z(hc - pitch * 0.4), tw * 0.95, tr * 0.95),
        (0, 0.0, z(hc + 0.05), tw, tr),
        (0, tl * 0.8, z(hc + 0.1 + pitch * 0.5), tw * 0.95, tr * 0.95),
        (0, tl + 0.3, z(hc + 0.2 + pitch * 0.8), nth * 1.05, nth * 1.1),
        (0, tl + nk * 0.5, z(hc + pitch * 0.8 + nrise * 0.55), nth * 0.9, nth * 0.95),
        (0, ney, z(neh), hw * 0.95, hhh * 1.0),
        (0, ney + hl * 0.3, z(neh + hhh * 0.05), hw, hhh),
        (0, ney + hl * 0.6, z(neh - hhh * 0.08), hw * 0.74, hhh * 0.82),
        (0, ney + hl * 0.9, z(neh - hhh * 0.22), hw * 0.56, hhh * 0.6),
        (0, ney + hl, z(neh - hhh * 0.26), hw * 0.46, hhh * 0.48),
    ]
    loft_bmesh(body, [(x, y, zz, rw, rh) for x, y, zz, rw, rh in chain], sides=8)
    # Lower jaw, a little open from the skull.
    jaw = [
        (0, ney + hl * 0.12, z(neh - hhh * 0.95), hw * 0.74, hhh * 0.3),
        (0, ney + hl * 0.55, z(neh - hhh * 0.82), hw * 0.55, hhh * 0.25),
        (0, ney + hl * 0.92, z(neh - hhh * 0.66), hw * 0.4, hhh * 0.19),
        (0, ney + hl * 1.0, z(neh - hhh * 0.6), hw * 0.28, hhh * 0.13),
    ]
    loft_bmesh(body, jaw, sides=6)
    if teeth:
        for step in range(6):
            fraction = 0.42 + 0.1 * step
            half = hw * (0.72 - 0.22 * step / 5)
            for side in (-1, 1):
                edge = neh - hhh * (0.5 - 0.06 * step)
                cone_bmesh(body, (side * half, ney + hl * fraction, z(edge + 0.04)), (side * half, ney + hl * fraction + 0.03, z(edge - 0.3)), 0.07, sides=3)
                low = neh - hhh * (0.72 - 0.05 * step)
                cone_bmesh(body, (side * half * 0.8, ney + hl * (fraction + 0.04), z(low - 0.03)), (side * half * 0.8, ney + hl * (fraction + 0.04), z(low + 0.24)), 0.055, sides=3)
    # Brow bumps over the eyes.
    for side in (-1, 1):
        sphere_bmesh(body, (side * hw * 0.62, ney + hl * 0.3, z(neh + hhh * 0.72)), (0.24, 0.32, 0.15))
        sphere_bmesh(body, (side * hw * 0.2, ney + hl * 0.88, z(neh + hhh * 0.1)), (0.1, 0.12, 0.07))
    # Tiny arms with two claws.
    for side in (-1, 1):
        ax = side * tw * 0.88
        loft_bmesh(body, [(ax, tl * 0.72, z(hc - 0.2), at * 1.3, at * 1.3), (ax, tl * 0.82, z(hc - 0.2 - arm * 0.5), at * 1.1, at * 1.1), (ax, tl * 0.98, z(hc - 0.25 - arm), at * 0.9, at * 0.9)], sides=4, up=(0, 1, 0))
        for spread in (-0.06, 0.06):
            cone_bmesh(body, (ax + spread, tl * 0.98, z(hc - 0.25 - arm)), (ax + spread * 1.3, tl * 0.98 + 0.25, z(hc - 0.25 - arm - 0.2)), 0.045, sides=3)
    # Tail.
    tailbm = bmesh.new()
    loft_bmesh(
        tailbm,
        [
            (0, -tl + 0.2, z(hc), tw * 0.8, tr * 0.85),
            (0, -tl - tail * 0.2, z(hc - 0.05), tw * 0.68, tr * 0.72),
            (0, -tl - tail * 0.45, z(hc - 0.2), tw * 0.5, tr * 0.52),
            (0, -tl - tail * 0.7, z(hc - 0.35), tw * 0.3, tr * 0.3),
            (0, -tl - tail * 0.9, z(hc - 0.4), tw * 0.13, tr * 0.13),
            (0, -tl - tail, z(hc - 0.4), 0.0, 0.0),
        ],
        sides=8,
    )
    objects = {"Body": make_object(f"{prefix}_Body", body, material), "Tail": make_object(f"{prefix}_Tail", tailbm, material)}
    hy = -tl * 0.2
    for name, side in (("LegL", -1), ("LegR", 1)):
        leg = bmesh.new()
        lx = side * tw * 0.9
        loft_bmesh(
            leg,
            [
                (lx, hy, z(hc - 0.1), lt, lt * 1.15),
                (lx, hy + 0.55, z(hh * 0.72), lt * 0.85, lt * 0.9),
                (lx, hy + 0.75, z(hh * 0.5), lt * 0.62, lt * 0.62),
                (lx, hy + 0.1, z(hh * 0.28 + 0.2), lt * 0.42, lt * 0.42),
                (lx, hy - 0.15, z(0.5), lt * 0.36, lt * 0.34),
            ],
            sides=6,
            up=(0, 1, 0),
        )
        for offset, length in ((-lt * 0.4, 0.9), (0.0, 1.1), (lt * 0.4, 0.9)):
            _add_toe(leg, (lx + offset * 0.4, hy - 0.2, z(0.3)), (lx + offset, hy - 0.2 + length, z(0.07)), lt * 0.2)
        objects[name] = make_object(f"{prefix}_{name}", leg, material)
    # Eyes and pupils.
    eyes, dark = bmesh.new(), bmesh.new()
    for side in (-1, 1):
        sphere_bmesh(eyes, (side * hw * 0.88, ney + hl * 0.32, z(neh + hhh * 0.42)), (0.10, 0.17, 0.17))
        sphere_bmesh(dark, (side * (hw * 0.88 + 0.08), ney + hl * 0.32 + 0.04, z(neh + hhh * 0.42)), (0.045, 0.09, 0.09))
    objects["Eyes"] = make_object(f"{prefix}_Eyes", eyes)
    objects["Dark"] = make_object(f"{prefix}_Dark", dark)
    low = min(min(v.co.y for v in obj.data.vertices) for obj in objects.values())
    high = max(max(v.co.y for v in obj.data.vertices) for obj in objects.values())
    shift = -(low + high) / 2 - 0.8
    for obj in objects.values():
        obj.data.transform(Matrix.Translation((0, shift, 0)))
    for suffix in ("Body", "Tail", "LegL", "LegR"):
        paint(objects[suffix])
    total = 0
    for obj in objects.values():
        obj.data.calc_loop_triangles()
        total += len(obj.data.loop_triangles)
    joints = {
        "hip": [tw * 0.9, 0.0, round(-(hy + shift), 3)],
        "tail": [0, round(z(hc), 3), round(-(-tl + 0.2 - tail * 0.2 + shift), 3)],
    }
    joints["hip"][1] = round(z(hc - 0.1) - 0.12, 3)
    return {"objects": objects, "tris": total, "joints": joints, "shift": shift}
