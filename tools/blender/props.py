"""Builds the jungle props (trees, rocks, plants) in the same faceted low-poly style as the dinos.

Run inside Blender after dinos.py, in the same namespace (it uses the helpers of that file):
    ns = {}
    exec(open("tools/blender/dinos.py").read(), ns)
    exec(open("tools/blender/props.py").read(), ns)
    ns["build_props"]()
Units are studs. The origin is the middle of the base, the foot of a prop stands at z = 0. Unlike the
dinos the props are painted with their final colors (vertex colors, nothing is tinted in the game
except a small random brightness per prop).
"""

import random


def _paint_solid(obj, color_of, seed, jitter=0.07):
    """Paints every face with `color_of(polygon)` (display values 0 to 255) and a small random
    brightness change, so the flat faces do not look dull."""
    mesh = obj.data
    if "Pattern" in mesh.color_attributes:
        mesh.color_attributes.remove(mesh.color_attributes["Pattern"])
    attribute = mesh.color_attributes.new(name="Pattern", type="BYTE_COLOR", domain="CORNER")
    rng = random.Random(seed)
    for polygon in mesh.polygons:
        red, green, blue = color_of(polygon)
        factor = 1 + rng.uniform(-jitter, jitter)
        linear = tuple(min(1.0, max(0.0, channel / 255 * factor)) ** 2.2 for channel in (red, green, blue)) + (1.0,)
        for loop_index in polygon.loop_indices:
            attribute.data[loop_index].color = linear
    mesh.color_attributes.active_color = attribute
    mesh.color_attributes.render_color_index = mesh.color_attributes.find("Pattern")


def _rough(obj, amount, seed):
    """Moves the corners a little, so a rock does not look like a perfect ball."""
    rng = random.Random(seed)
    for vertex in obj.data.vertices:
        vertex.co.x += rng.uniform(-amount, amount)
        vertex.co.y += rng.uniform(-amount, amount)
        vertex.co.z += rng.uniform(-amount, amount) * 0.6


def _ico(name, location, scale, color, seed, rough=0.0, color_of=None):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=1.0, location=location)
    obj = bpy.context.active_object
    obj.scale = scale
    _finish(obj, name)
    if rough:
        _rough(obj, rough, seed)
    _paint_solid(obj, color_of or (lambda polygon: color), seed)
    return obj


def _tube_painted(name, points, color, seed, sides=6):
    obj = tube(name, points, sides=sides)
    _paint_solid(obj, lambda polygon: color, seed)
    return obj


def _cone_painted(name, location, radius, depth, rotation, color, seed, vertices=4):
    obj = cone(name, location, radius, 0.0, depth, rotation=rotation, vertices=vertices)
    _paint_solid(obj, lambda polygon: color, seed)
    return obj


def _sit_on_ground(obj, sink=0.0):
    """Moves the mesh so its lowest point is at z = -sink."""
    low = min(vertex.co.z for vertex in obj.data.vertices)
    obj.data.transform(mathutils.Matrix.Translation((0, 0, -low - sink)))


def _finish_prop(name, pieces, sink=0.0):
    obj = join_or_rename(pieces, "prop_" + name)
    _sit_on_ground(obj, sink)
    material(obj, "Body")
    return obj


def build_tree():
    pieces = [
        _tube_painted("trunk", [(0, 0, 0, 0.55, 0.55), (0.15, 0, 3.5, 0.42, 0.42), (0.3, 0, 7.6, 0.3, 0.3)], (98, 72, 52), 11),
        _ico("crown1", (0.3, 0, 8.4), (3.3, 3.3, 2.1), (52, 108, 50), 12, 0.25),
        _ico("crown2", (-0.5, 0.3, 10.4), (2.6, 2.6, 1.8), (66, 126, 54), 13, 0.2),
        _ico("crown3", (0.2, -0.2, 12.2), (1.7, 1.7, 1.4), (84, 144, 60), 14, 0.15),
    ]
    return _finish_prop("Tree", pieces)


def build_palm():
    """A cycad: a short trunk with a crown of long leaves."""
    pieces = [_tube_painted("trunk", [(0, 0, 0, 0.5, 0.5), (0.3, 0, 3.0, 0.4, 0.4), (0.6, 0, 6.2, 0.33, 0.33)], (110, 84, 58), 21)]
    rng = random.Random(22)
    tilt = math.radians(66)
    for index in range(9):
        angle = math.radians(index * 40 + rng.uniform(-8, 8))
        depth = rng.uniform(3.8, 4.8)
        direction = (math.sin(tilt) * math.sin(angle), -math.sin(tilt) * math.cos(angle), math.cos(tilt))
        base = (0.6, 0, 6.2)
        center = tuple(base[axis] + direction[axis] * depth / 2 for axis in range(3))
        green = (70 + rng.randint(0, 25), 140 + rng.randint(0, 20), 58)
        pieces.append(_cone_painted("leaf", center, 0.85, depth, (tilt, 0, angle), green, 30 + index, vertices=4))
    return _finish_prop("Palm", pieces)


def build_fern():
    pieces = []
    rng = random.Random(41)
    tilt = math.radians(58)
    for index in range(9):
        angle = math.radians(index * 40 + rng.uniform(-10, 10))
        depth = rng.uniform(2.0, 2.8)
        direction = (math.sin(tilt) * math.sin(angle), -math.sin(tilt) * math.cos(angle), math.cos(tilt))
        center = tuple(direction[axis] * depth / 2 for axis in range(3))
        green = (78 + rng.randint(0, 20), 150 + rng.randint(0, 25), 62)
        pieces.append(_cone_painted("frond", center, 0.5, depth, (tilt, 0, angle), green, 50 + index, vertices=3))
    return _finish_prop("Fern", pieces)


def build_bush():
    pieces = [
        _ico("b1", (0, 0, 0.9), (1.5, 1.4, 1.0), (58, 100, 52), 61, 0.15),
        _ico("b2", (0.9, 0.3, 0.7), (1.0, 1.0, 0.8), (70, 116, 56), 62, 0.12),
        _ico("b3", (-0.8, -0.3, 0.6), (0.9, 0.9, 0.7), (50, 90, 48), 63, 0.12),
    ]
    for index, spot in enumerate(((0.4, 0.5, 1.7), (-0.5, 0.2, 1.55), (0.9, -0.2, 1.2))):
        pieces.append(_ico("flower", spot, (0.22, 0.22, 0.22), (238, 196, 72), 70 + index))
    return _finish_prop("Bush", pieces)


def build_rock():
    pieces = [_ico("rock", (0, 0, 0.5), (1.1, 0.95, 0.65), (126, 121, 112), 81, 0.18)]
    return _finish_prop("Rock", pieces, sink=0.1)


def build_rock_big():
    def mossy(polygon):
        return (84, 112, 62) if polygon.normal.z > 0.55 else (104, 99, 92)

    pieces = [
        _ico("big1", (0, 0, 1.8), (3.0, 2.6, 2.0), None, 91, 0.45, mossy),
        _ico("big2", (2.3, 0.8, 1.0), (1.8, 1.6, 1.2), None, 92, 0.3, mossy),
        _ico("big3", (-1.8, -1.2, 0.9), (1.4, 1.3, 1.0), None, 93, 0.25, mossy),
    ]
    return _finish_prop("RockBig", pieces, sink=0.3)


def build_log():
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=6, radius=0.7, depth=7.5, location=(0, 0, 0.7), rotation=(math.radians(90), 0, 0)
    )
    log = bpy.context.active_object
    _finish(log, "log")
    _paint_solid(log, lambda polygon: (172, 142, 100) if abs(polygon.normal.y) > 0.9 else (100, 72, 50), 101)
    stub = _cone_painted("stub", (0.5, 1.0, 1.3), 0.25, 1.2, (0, math.radians(50), 0), (100, 72, 50), 102, vertices=4)
    return _finish_prop("Log", [log, stub])


PROP_BUILDERS = {
    "Tree": build_tree,
    "Palm": build_palm,
    "Fern": build_fern,
    "Bush": build_bush,
    "Rock": build_rock,
    "RockBig": build_rock_big,
    "Log": build_log,
}


def build_props():
    """Builds every prop and returns the triangle count of each."""
    for obj in list(bpy.data.objects):
        if obj.name.startswith("prop_"):
            bpy.data.objects.remove(obj, do_unlink=True)
    return {name: triangles(builder()) for name, builder in PROP_BUILDERS.items()}


def props_lineup(path, width=1800, height=520):
    """Renders all props in one row, seen from the side."""
    scene = bpy.context.scene
    names = list(PROP_BUILDERS)
    for index, name in enumerate(names):
        obj = bpy.data.objects["prop_" + name]
        obj.location = ((index - (len(names) - 1) / 2) * 11.0, 0, 0)
    for obj in bpy.data.objects:
        obj.hide_render = not (obj.name.startswith("prop_") or obj.name in ("PreviewCam", "PreviewSun"))
    camera = bpy.data.objects["PreviewCam"]
    camera.location = (0, -85, 12)
    camera.rotation_euler = (mathutils.Vector((0, 0, 5)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 34
    scene.camera = camera
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    for obj in bpy.data.objects:
        if obj.name.startswith("prop_"):
            obj.location = (0, 0, 0)
    return path


def export_props(path):
    """Exports all props as one FBX file (like export_fbx of the dinos, but nothing is turned and
    the colors stay as painted)."""
    bpy.ops.object.select_all(action="DESELECT")
    meshes = [obj for obj in bpy.data.objects if obj.name.startswith("prop_")]
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.export_scene.fbx(
        filepath=path,
        use_selection=True,
        object_types={"MESH"},
        apply_scale_options="FBX_SCALE_NONE",
        axis_forward="-Z",
        axis_up="Y",
        global_scale=0.01,
        use_mesh_modifiers=True,
        mesh_smooth_type="FACE",
        colors_type="SRGB",
        add_leaf_bones=False,
        bake_anim=False,
    )
    return sorted(obj.name for obj in meshes)
