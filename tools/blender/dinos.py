"""Builds the realistic dino base shapes in Blender (run inside Blender, see docs/MODELLE.md).

Units are studs. The pivot (origin) is the center of the Roblox figure, the feet stand 3 studs
below it, the front is +Y in Blender (the FBX export turns it into -Z in Roblox). Every shape is
split into four meshes that the game tints separately: Body (skin), Accent (claws, teeth, horns),
Eyes (amber) and Dark (slit pupils, mouth line). Budget per dino: at most 12 parts and 3000 triangles in total.
"""

import bpy
import math
import mathutils

COLLECTION = "Dinos"
# Flat shading gives the faceted low-poly look; False would give smooth surfaces.
FLAT = True
FLOOR = -3.0

# Preview colors only; the game colors the meshes (MeshPart.Color) per dino.
# Skin color of the film raptor (olive tan); the game tints the neutral pattern with its own colors.
SKIN = (0.6, 0.56, 0.34)

PREVIEW_COLORS = {
    "Body": (1.0, 1.0, 1.0, 1.0),
    "Accent": (0.88, 0.82, 0.66, 1.0),
    "Eyes": (0.95, 0.62, 0.08, 1.0),
    "Dark": (0.02, 0.02, 0.02, 1.0),
}

SEGMENTS = 10
RINGS = 6


def collection():
    existing = bpy.data.collections.get(COLLECTION)
    if existing is not None:
        return existing
    created = bpy.data.collections.new(COLLECTION)
    bpy.context.scene.collection.children.link(created)
    return created


def _finish(obj, name):
    obj.name = name
    for user in list(obj.users_collection):
        user.objects.unlink(obj)
    collection().objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    for polygon in obj.data.polygons:
        polygon.use_smooth = not FLAT
    return obj


def sphere(name, location, scale, segments=SEGMENTS, rings=RINGS):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1.0, location=location)
    obj = bpy.context.active_object
    obj.scale = scale
    return _finish(obj, name)


def cone(name, location, radius_base, radius_tip, depth, rotation=(0.0, 0.0, 0.0), vertices=8):
    """Axis along +Z (base at the bottom) before the rotation."""
    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices, radius1=radius_base, radius2=radius_tip, depth=depth, location=location, rotation=rotation
    )
    return _finish(bpy.context.active_object, name)


def cylinder(name, location, radius, depth, vertices=8):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    return _finish(bpy.context.active_object, name)


def join(objects, name):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    merged = bpy.context.active_object
    merged.name = name
    merged.data.name = name
    # The origin stays on the figure center (0, 0, 0).
    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    return merged


def material(obj, kind):
    mat = bpy.data.materials.get("Preview" + kind)
    if mat is None:
        mat = bpy.data.materials.new("Preview" + kind)
        mat.use_nodes = True
    mat.diffuse_color = PREVIEW_COLORS[kind]
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf is not None:
        bsdf.inputs["Base Color"].default_value = PREVIEW_COLORS[kind]
        bsdf.inputs["Roughness"].default_value = 0.7
        if kind == "Body" and mat.node_tree.nodes.get("PatternColor") is None:
            node = mat.node_tree.nodes.new("ShaderNodeVertexColor")
            node.name = "PatternColor"
            node.layer_name = "Pattern"
            mat.node_tree.links.new(node.outputs["Color"], bsdf.inputs["Base Color"])
    obj.data.materials.clear()
    obj.data.materials.append(mat)


def triangles(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def remove_shape(prefix):
    for obj in list(bpy.data.objects):
        if obj.name.startswith(prefix + "_"):
            bpy.data.objects.remove(obj, do_unlink=True)


def smooth(points, step):
    """Smooth path (Catmull-Rom) through the points with a new point about every `step` studs;
    all values (position and the two half sizes) are interpolated."""
    count = len(points)
    result = [tuple(points[0])]
    for index in range(count - 1):
        p0 = points[max(index - 1, 0)]
        p1, p2 = points[index], points[index + 1]
        p3 = points[min(index + 2, count - 1)]
        pieces = max(1, math.ceil(math.dist(p1[:3], p2[:3]) / step))
        for piece in range(1, pieces + 1):
            t = piece / pieces
            t2, t3 = t * t, t * t * t
            result.append(
                tuple(
                    0.5 * (2 * b + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t2 + (-a + 3 * b - 3 * c + d) * t3)
                    for a, b, c, d in zip(p0, p1, p2, p3)
                )
            )
    return result


def tube(name, points, sides=8, caps=True):
    """A smooth tube through `points`: each point is (x, y, z, width, height), the half sizes of
    the elliptical cross section (width across the body, height up and down)."""
    positions = [mathutils.Vector(p[:3]) for p in points]
    vertices = []
    for index, point in enumerate(points):
        before = positions[max(index - 1, 0)]
        after = positions[min(index + 1, len(points) - 1)]
        tangent = (after - before).normalized()
        reference = mathutils.Vector((1, 0, 0))
        if abs(tangent.dot(reference)) > 0.9:
            reference = mathutils.Vector((0, 1, 0))
        side = (reference - tangent * reference.dot(tangent)).normalized()
        up = tangent.cross(side).normalized()
        for corner in range(sides):
            angle = 2 * math.pi * corner / sides
            vertices.append(positions[index] + side * math.cos(angle) * point[3] + up * math.sin(angle) * point[4])
    faces = []
    for ring in range(len(points) - 1):
        for corner in range(sides):
            a = ring * sides + corner
            b = ring * sides + (corner + 1) % sides
            faces.append((a, b, b + sides, a + sides))
    if caps:
        faces.append(tuple(reversed(range(sides))))
        last = (len(points) - 1) * sides
        faces.append(tuple(range(last, last + sides)))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([tuple(v) for v in vertices], [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    collection().objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    for polygon in mesh.polygons:
        polygon.use_smooth = not FLAT
    return obj


def eyes(prefix, x, y, z, radius):
    """A pair of amber eyes with slit pupils on the sides of the head."""
    whites = [
        sphere("e%d" % i, (side * x, y, z), (radius * 0.8, radius, radius), 6, 4) for i, side in enumerate((-1, 1))
    ]
    slits = [
        sphere(
            "p%d" % i,
            (side * (x + radius * 0.62), y + radius * 0.15, z),
            (radius * 0.12, radius * 0.28, radius * 0.8),
            6,
            4,
        )
        for i, side in enumerate((-1, 1))
    ]
    return join(whites, prefix + "_Eyes"), slits


def spine_top(spine, y):
    """Height of the top of the spine tube at position `y` (linear between the points)."""
    for first, second in zip(spine, spine[1:]):
        low, high = sorted((first[1], second[1]))
        if low <= y <= high and first[1] != second[1]:
            t = (y - first[1]) / (second[1] - first[1])
            return (first[2] + (second[2] - first[2]) * t) + (first[4] + (second[4] - first[4]) * t)
    return spine[0][2]


def paint_faces(obj, tint, neutral=False, stripes=True):
    """Paints the skin pattern face by face (flat colors, matching the faceted look): a lighter
    belly, a darker back and, on the body and tail, dark stripes across the back. `neutral` paints
    grey values only (what the export keeps; the game multiplies them with the color of the dino),
    otherwise the values are tinted for the preview."""
    mesh = obj.data
    if "Pattern" in mesh.color_attributes:
        mesh.color_attributes.remove(mesh.color_attributes["Pattern"])
    attribute = mesh.color_attributes.new(name="Pattern", type="BYTE_COLOR", domain="CORNER")
    stripe_from, stripe_to, period, duty = 1.1, -4.2, 1.1, 0.5
    for polygon in mesh.polygons:
        value = 0.82
        if polygon.normal.z < -0.25:
            value = 1.0
        elif stripes and polygon.normal.z > 0.1 and stripe_to < polygon.center.y < stripe_from and polygon.center.z > -1.5:
            phase = ((stripe_from - polygon.center.y) / period) % 1.0
            if phase < duty:
                value = 0.45
        color = (value, value, value) if neutral else (value * tint[0], value * tint[1], value * tint[2])
        # The numbers above are display values (sRGB); Blender stores linear colors.
        linear = (color[0] ** 2.2, color[1] ** 2.2, color[2] ** 2.2, 1.0)
        for loop_index in polygon.loop_indices:
            attribute.data[loop_index].color = linear
    mesh.color_attributes.active_color = attribute
    mesh.color_attributes.render_color_index = mesh.color_attributes.find("Pattern")


# The meshes that carry the skin pattern, and whether they get stripes.
PAINTED = {"Body": True, "Tail": True, "LegL": False, "LegR": False}


def paint_shape(prefix, neutral=False):
    for suffix, stripes in PAINTED.items():
        obj = bpy.data.objects.get(prefix + "_" + suffix)
        if obj is not None:
            paint_faces(obj, SKIN, neutral=neutral, stripes=stripes)


# Where the limbs turn, in Blender coordinates (the game turns them into figure coordinates:
# x stays, y becomes -z, z becomes y). The tail turns at its start, each leg at its hip.
RUNNER_JOINTS = {"Tail": (0, -1.6, -1.1), "LegL": (-0.66, -0.8, -1.1), "LegR": (0.66, -0.8, -1.1)}


def build_runner(prefix="runner"):
    """Two-legged raptor-like runner (Compy, Raptor and the other light dinos) in the faceted
    low-poly style. Moving parts are separate meshes (Tail, LegL, LegR) so the game can animate
    them; everything else is one Body mesh."""
    remove_shape(prefix)
    # Snout tip to hips: x, y, z, width, height.
    spine = [
        (0, 3.95, -0.15, 0.08, 0.08),
        (0, 3.5, -0.1, 0.22, 0.24),
        (0, 2.9, -0.05, 0.3, 0.34),
        (0, 2.5, 0.12, 0.44, 0.5),
        (0, 2.0, 0.08, 0.42, 0.46),
        (0, 1.45, -0.2, 0.36, 0.42),
        (0, 0.8, -0.65, 0.7, 0.75),
        (0, 0.0, -1.0, 0.85, 0.9),
        (0, -0.9, -1.05, 0.8, 0.84),
        (0, -1.8, -1.1, 0.55, 0.58),
    ]
    tail = [(0, -1.6, -1.1, 0.55, 0.58), (0, -3.0, -1.2, 0.35, 0.36), (0, -4.3, -1.25, 0.2, 0.2), (0, -5.5, -1.3, 0.04, 0.04)]
    body_parts = [tube("spine", spine, sides=6)]
    dark = []
    teeth = []
    jaw = [(0, 3.75, -0.27, 0.1, 0.07), (0, 3.0, -0.3, 0.2, 0.12), (0, 2.4, -0.28, 0.3, 0.16), (0, 2.1, -0.2, 0.3, 0.16)]
    body_parts.append(tube("jaw", jaw, sides=6))
    legs = {}
    for side, suffix in ((-1, "LegL"), (1, "LegR")):
        dark.append(sphere("nostril", (side * 0.07, 3.8, 0.04), (0.035, 0.07, 0.03), 4, 3))
        mouth = [(side * 0.17, 3.68, -0.19, 0.02, 0.02), (side * 0.27, 3.1, -0.17, 0.025, 0.025), (side * 0.4, 2.45, -0.12, 0.025, 0.025)]
        dark.append(tube("mouth", mouth, sides=3))
        for y in (3.55, 3.3, 3.05, 2.8, 2.55):
            reach = 0.16 + (3.65 - y) * 0.2
            teeth.append(cone("tooth", (side * reach, y, -0.26), 0.05, 0.0, 0.15, rotation=(math.radians(180), 0, 0), vertices=3))
        x = side * 0.66
        leg = [
            (x, -0.8, -1.1, 0.55, 0.62),
            (x, -0.5, -1.65, 0.46, 0.5),
            (x, 0.15, -2.0, 0.3, 0.34),
            (x, -0.25, -2.55, 0.2, 0.26),
            (x, -0.3, -2.88, 0.2, 0.12),
        ]
        pieces = [tube("leg", leg, sides=6)]
        for toe, spread in ((-1, -0.2), (0, 0.0), (1, 0.2)):
            tip = 0.85 if toe != 0 else 0.8
            path = [(x, -0.3, -2.9, 0.1, 0.09), (x + spread * 1.2, tip, -2.94, 0.05, 0.05)]
            pieces.append(tube("toe", path, sides=4))
            claw_length = 0.5 if toe == 0 else 0.28
            pieces.append(
                cone(
                    "claw",
                    (x + spread * 1.2, tip + claw_length / 2, -2.94 - (0.05 if toe == 0 else 0.0)),
                    0.06,
                    0.0,
                    claw_length,
                    rotation=(math.radians(-90 if toe != 0 else -110), 0, 0),
                    vertices=4,
                )
            )
        legs[suffix] = join(pieces, prefix + "_" + suffix)
        arm = [(side * 0.7, 0.65, -1.0, 0.2, 0.22), (side * 0.85, 0.95, -1.45, 0.14, 0.15), (side * 0.78, 1.5, -1.5, 0.1, 0.09)]
        body_parts.append(tube("arm", arm, sides=5))
        for spread in (-0.07, 0.0, 0.07):
            teeth.append(
                cone("handclaw", (side * 0.78 + spread, 1.62, -1.52), 0.045, 0.0, 0.32, rotation=(math.radians(-90), 0, 0), vertices=3)
            )
    # Small spikes along the back (the second color).
    for y in (1.0, 0.3, -0.4, -1.1, -1.8):
        teeth.append(cone("spike", (0, y, spine_top(spine, y) + 0.05), 0.13, 0.0, 0.34, vertices=4))
    body_obj = join(body_parts, prefix + "_Body")
    tail_obj = tube("tail", tail, sides=6)
    tail_obj.name = prefix + "_Tail"
    tail_obj.data.name = prefix + "_Tail"
    accent_obj = join(teeth, prefix + "_Accent")
    eyes_obj, slits = eyes(prefix, 0.4, 2.55, 0.3, 0.19)
    dark_obj = join(dark + slits, prefix + "_Dark")

    paint_shape(prefix)
    result = [body_obj, tail_obj, legs["LegL"], legs["LegR"], accent_obj, eyes_obj, dark_obj]
    kinds = ("Body", "Body", "Body", "Body", "Accent", "Eyes", "Dark")
    for obj, kind in zip(result, kinds):
        material(obj, kind)
    return result


SHAPES = {"runner": build_runner}


def build(shape):
    objects = SHAPES[shape]()
    return {obj.name: triangles(obj) for obj in objects}


def preview(path, shape="runner", width=900, height=700, angle=35, distance=14.0, target=(0, 0.3, -1.3), height_z=3.5):
    """Renders the shape from the front right (Eevee) to `path`."""
    scene = bpy.context.scene
    keep = {}
    for obj in bpy.data.objects:
        keep[obj.name] = obj.hide_render
        obj.hide_render = not (obj.name.startswith(shape + "_") or obj.name in ("PreviewCam", "PreviewSun"))
    camera = bpy.data.objects.get("PreviewCam")
    if camera is None:
        camera = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
        scene.collection.objects.link(camera)
    sun = bpy.data.objects.get("PreviewSun")
    if sun is None:
        sun = bpy.data.objects.new("PreviewSun", bpy.data.lights.new("PreviewSun", "SUN"))
        scene.collection.objects.link(sun)
    sun.data.energy = 2.5
    sun.rotation_euler = (math.radians(50), 0, math.radians(35))
    rad = math.radians(angle)
    camera.location = (math.sin(rad) * distance, math.cos(rad) * distance, height_z)
    target = mathutils.Vector(target)
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 50
    scene.camera = camera
    scene.render.engine = "BLENDER_EEVEE"
    scene.view_settings.view_transform = "Standard"
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    scene.render.film_transparent = False
    scene.world.use_nodes = True
    background = scene.world.node_tree.nodes.get("Background")
    if background is not None:
        background.inputs["Color"].default_value = (0.55, 0.62, 0.55, 1.0)
        background.inputs["Strength"].default_value = 0.8
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    for name, hidden in keep.items():
        bpy.data.objects[name].hide_render = hidden
    return path


def export_fbx(shape, path):
    """Exports the meshes of a shape as one FBX file (for the Studio import). The skin pattern
    is saved as grey values, so the game can tint it with the color of each dino.

    The Roblox importer keeps the Blender direction (Blender +Y ends up as Roblox +Z), but the
    front of a Roblox figure is -Z. So the meshes are turned by 180 degrees around the vertical
    axis for the export and turned back afterwards."""
    paint_shape(shape, neutral=True)
    bpy.ops.object.select_all(action="DESELECT")
    meshes = [obj for obj in bpy.data.objects if obj.name.startswith(shape + "_")]
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    turn = mathutils.Matrix.Rotation(math.pi, 4, "Z")
    for obj in meshes:
        obj.data.transform(turn)
    try:
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
    finally:
        for obj in meshes:
            obj.data.transform(turn)
    paint_shape(shape)
    return sorted(obj.name for obj in meshes)


def dump_parts(shape, path):
    """Writes the geometry of a shape as JSON for the direct upload from Studio (see
    docs/MODELLE.md). Coordinates are Roblox figure coordinates in studs: x stays, y is Blender z,
    z is minus Blender y (so the front is -Z). Every triangle has its three corners and one grey
    value (the neutral skin pattern, 1 where the part has no pattern). Also gives the center of the
    bounding box of every part: that is where the part sits relative to the figure center."""
    import json

    paint_shape(shape, neutral=True)
    parts = {}
    for obj in bpy.data.objects:
        if not obj.name.startswith(shape + "_"):
            continue
        mesh = obj.data
        attribute = mesh.color_attributes.get("Pattern")
        triangles = []
        low = [math.inf] * 3
        high = [-math.inf] * 3
        for polygon in mesh.polygons:
            corners = [mesh.vertices[index].co for index in polygon.vertices]
            grey = 1.0
            if attribute is not None:
                linear = attribute.data[polygon.loop_indices[0]].color[0]
                grey = round(linear ** (1 / 2.2), 3)
            converted = [(round(c.x, 4), round(c.z, 4), round(-c.y, 4)) for c in corners]
            for axis in range(3):
                for corner in converted:
                    low[axis] = min(low[axis], corner[axis])
                    high[axis] = max(high[axis], corner[axis])
            # Triangle fan; the winding follows Blender (counter clockwise seen from outside).
            for index in range(1, len(converted) - 1):
                triangles.append([converted[0], converted[index], converted[index + 1], grey])
        center = [round((low[axis] + high[axis]) / 2, 4) for axis in range(3)]
        size = [round(high[axis] - low[axis], 4) for axis in range(3)]
        parts[obj.name[len(shape) + 1 :]] = {"center": center, "size": size, "triangles": triangles}
    paint_shape(shape)
    with open(path, "w", encoding="utf-8") as handle:
        json.dump({"shape": shape, "parts": parts}, handle, separators=(",", ":"))
    return {name: (len(part["triangles"]), part["center"], part["size"]) for name, part in parts.items()}
