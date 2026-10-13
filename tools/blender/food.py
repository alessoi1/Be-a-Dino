"""Builds the food pieces (berry, leaf, seed, fruit, melon, mushroom, meat, fish, egg) in the same
faceted low-poly style as the dinos and props.

Run inside Blender (nothing else is needed, this file is self-contained):
    ns = {}
    exec(open("tools/blender/food.py").read(), ns)
    ns["build_food"]()                       # builds the nine pieces, returns the triangle counts
    ns["food_lineup"]("some/path.png")       # renders them in one row
    ns["export_food"]("assets/blender/food.fbx")
Units are studs. Every piece is about 1 stud in its longest side and centered on the origin (the game
scales it by the size of the food kind). The pieces are painted with their final colors (vertex
colors); the part in the game stays white so the colors show as painted. Z is up in Blender.
"""

import bpy
import bmesh
import math
import mathutils
import random

PREFIX = "food_"
# Longest side of every piece before the game scales it (studs).
TARGET_SIZE = 1.0


def _paint(obj, color_of, seed, jitter=0.06):
    """Paints every face with `color_of(polygon)` (display values 0 to 255) and a small brightness
    change, so the flat faces do not look dull."""
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


def _apply(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def _flat(obj):
    """Flat shading, so the facets show."""
    for polygon in obj.data.polygons:
        polygon.use_smooth = False


def _ico(name, location, scale, color, seed, rough=0.0, color_of=None, rotation=(0.0, 0.0, 0.0)):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=1.0, location=location, rotation=rotation)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    _apply(obj)
    if rough:
        rng = random.Random(seed)
        for vertex in obj.data.vertices:
            vertex.co.x += rng.uniform(-rough, rough)
            vertex.co.y += rng.uniform(-rough, rough)
            vertex.co.z += rng.uniform(-rough, rough)
    _flat(obj)
    _paint(obj, color_of or (lambda polygon: color), seed)
    return obj


def _cylinder(name, location, radius, depth, color, seed, rotation=(0.0, 0.0, 0.0), vertices=6, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location, rotation=rotation)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    _apply(obj)
    _flat(obj)
    _paint(obj, lambda polygon: color, seed)
    return obj


def _cone(name, location, radius, depth, color, seed, rotation=(0.0, 0.0, 0.0), vertices=4, scale=(1, 1, 1), tip=0.0):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius, radius2=tip, depth=depth, location=location, rotation=rotation)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    _apply(obj)
    _flat(obj)
    _paint(obj, lambda polygon: color, seed)
    return obj


def _finish(name, pieces):
    """Joins the pieces, centers the result on the origin and scales it to `TARGET_SIZE`."""
    bpy.ops.object.select_all(action="DESELECT")
    for piece in pieces:
        piece.select_set(True)
    bpy.context.view_layer.objects.active = pieces[0]
    if len(pieces) > 1:
        bpy.ops.object.join()
    obj = bpy.context.active_object
    obj.name = PREFIX + name
    obj.data.name = PREFIX + name
    low = mathutils.Vector([min(v.co[i] for v in obj.data.vertices) for i in range(3)])
    high = mathutils.Vector([max(v.co[i] for v in obj.data.vertices) for i in range(3)])
    middle = (low + high) / 2
    longest = max(high - low)
    for vertex in obj.data.vertices:
        vertex.co = (vertex.co - middle) * (TARGET_SIZE / longest)
    obj.location = (0, 0, 0)
    obj.rotation_euler = (0, 0, 0)
    obj.scale = (1, 1, 1)
    obj.data.update()
    return obj


def triangles(obj):
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


# ---------------------------------------------------------------- the pieces


def build_berry():
    return _finish(
        "Berry",
        [
            _ico("body", (0, 0, 0), (0.5, 0.5, 0.46), (206, 64, 112), 1, 0.02),
            _cone("cap", (0, 0, 0.42), 0.26, 0.14, (70, 150, 70), 2, vertices=5, tip=0.05),
            _cylinder("stem", (0, 0, 0.56), 0.035, 0.2, (96, 140, 60), 3, vertices=4),
        ],
    )


def build_leaf():
    """A flat, pointed leaf with a vein."""
    angle = math.radians(90)
    return _finish(
        "Leaf",
        [
            _cone("blade", (0, 0, 0), 0.26, 1.0, (110, 214, 84), 11, rotation=(0, angle, 0), vertices=4, scale=(0.16, 1.0, 1.0)),
            _cylinder("vein", (0, 0, 0.03), 0.02, 0.95, (60, 130, 50), 12, rotation=(0, angle, 0), vertices=4),
            _cone("stalk", (-0.54, 0, 0), 0.03, 0.18, (60, 130, 50), 13, rotation=(0, -angle, 0), vertices=4, tip=0.02),
        ],
    )


def build_seed():
    return _finish(
        "Seed",
        [
            _ico("body", (0, 0, 0), (0.3, 0.3, 0.5), (226, 190, 96), 21, 0.02),
            _ico("cap", (0, 0, 0.36), (0.22, 0.22, 0.2), (168, 128, 60), 22),
        ],
    )


def build_fruit():
    return _finish(
        "Fruit",
        [
            _ico("body", (0, 0, 0), (0.5, 0.5, 0.47), (255, 160, 40), 31, 0.02),
            _cylinder("stem", (0, 0, 0.5), 0.04, 0.22, (110, 80, 52), 32, vertices=4),
            _cone("leaf", (0.14, 0, 0.55), 0.1, 0.3, (84, 170, 70), 33, rotation=(0, math.radians(70), 0), vertices=4, scale=(1, 1, 0.3)),
        ],
    )


def build_melon():
    def stripes(polygon):
        # Dark and light stripes around the melon, like a real one.
        sector = int((math.atan2(polygon.center.y, polygon.center.x) + math.pi) / (math.pi / 3))
        return (78, 142, 52) if sector % 2 == 0 else (150, 210, 90)

    return _finish("Melon", [_ico("body", (0, 0, 0), (0.5, 0.46, 0.44), None, 41, 0.025, stripes)])


def build_mushroom():
    def cap(polygon):
        # A few pale spots on the orange cap.
        return (240, 232, 214) if polygon.index in (3, 9, 15) else (214, 120, 60)

    return _finish(
        "Mushroom",
        [
            _cylinder("stem", (0, 0, -0.18), 0.16, 0.5, (236, 226, 206), 51, vertices=6),
            _ico("cap", (0, 0, 0.14), (0.5, 0.5, 0.3), None, 53, 0.015, cap),
        ],
    )


def build_meat():
    """A drumstick lying along x: the meat bulb and the bone with two knobs."""
    return _finish(
        "Meat",
        [
            _ico("meat", (-0.18, 0, 0), (0.4, 0.34, 0.34), (204, 78, 70), 61, 0.03),
            _cylinder("bone", (0.34, 0, 0), 0.07, 0.4, (240, 232, 210), 62, rotation=(0, math.radians(90), 0), vertices=5),
            _ico("knob1", (0.55, 0.07, 0), (0.1, 0.1, 0.1), (240, 232, 210), 63),
            _ico("knob2", (0.55, -0.07, 0), (0.1, 0.1, 0.1), (240, 232, 210), 64),
        ],
    )


def build_fish():
    def skin(polygon):
        return (222, 232, 240) if polygon.normal.z < -0.35 else (92, 160, 222)

    angle = math.radians(90)
    return _finish(
        "Fish",
        [
            _ico("body", (0, 0, 0), (0.5, 0.17, 0.22), None, 71, 0.01, skin),
            _cone("tail", (-0.6, 0, 0), 0.24, 0.4, (240, 150, 60), 72, rotation=(0, -angle, 0), vertices=4, scale=(1, 0.3, 1), tip=0.05),
            _cone("fin", (0, 0, 0.24), 0.1, 0.22, (240, 150, 60), 73, vertices=3, scale=(1, 0.3, 1), tip=0.02),
            _ico("eye", (0.34, 0.13, 0.07), (0.05, 0.05, 0.05), (20, 20, 28), 74),
            _ico("eye2", (0.34, -0.13, 0.07), (0.05, 0.05, 0.05), (20, 20, 28), 75),
        ],
    )


def build_egg():
    rng = random.Random(82)

    def shell(polygon):
        return (150, 108, 72) if rng.random() < 0.12 else (244, 236, 210)

    return _finish("Egg", [_ico("shell", (0, 0, 0), (0.36, 0.36, 0.5), None, 81, 0.012, shell)])


BUILDERS = {
    "Berry": build_berry,
    "Leaf": build_leaf,
    "Seed": build_seed,
    "Fruit": build_fruit,
    "Melon": build_melon,
    "Mushroom": build_mushroom,
    "Meat": build_meat,
    "Fish": build_fish,
    "Egg": build_egg,
}


def build_food():
    """Builds every piece (and removes older ones of the same names); returns the triangle counts."""
    for obj in list(bpy.data.objects):
        if obj.name.startswith(PREFIX):
            bpy.data.objects.remove(obj, do_unlink=True)
    return {name: triangles(builder()) for name, builder in BUILDERS.items()}


def food_lineup(path, width=1800, height=420):
    """Renders all pieces in one row (a quick preview with the vertex colors)."""
    scene = bpy.context.scene
    names = list(BUILDERS)
    for index, name in enumerate(names):
        obj = bpy.data.objects[PREFIX + name]
        obj.location = ((index - (len(names) - 1) / 2) * 1.4, 0, 0)
    for obj in bpy.data.objects:
        if obj.name.startswith("FoodCam"):
            bpy.data.objects.remove(obj, do_unlink=True)
    camera_data = bpy.data.cameras.new("FoodCam")
    camera = bpy.data.objects.new("FoodCam", camera_data)
    scene.collection.objects.link(camera)
    camera.location = (0, -17.5, 4.0)
    camera.rotation_euler = (mathutils.Vector((0, 0, 0)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 50
    scene.camera = camera
    previous = {}
    for obj in bpy.data.objects:
        previous[obj.name] = obj.hide_render
        obj.hide_render = not (obj.name.startswith(PREFIX) or obj.name == "FoodCam")
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "VERTEX"
    scene.display.shading.show_cavity = False
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    scene.render.filepath = path
    scene.world.color = (0.55, 0.62, 0.7)
    bpy.ops.render.render(write_still=True)
    for obj in bpy.data.objects:
        if obj.name in previous:
            obj.hide_render = previous[obj.name]
        if obj.name.startswith(PREFIX):
            obj.location = (0, 0, 0)
    bpy.data.objects.remove(camera, do_unlink=True)
    return path


def export_food(path):
    """Exports all pieces as one FBX file (nothing is turned, the colors stay as painted)."""
    bpy.ops.object.select_all(action="DESELECT")
    meshes = [obj for obj in bpy.data.objects if obj.name.startswith(PREFIX)]
    for obj in meshes:
        obj.location = (0, 0, 0)
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
