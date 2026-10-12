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
        polygon.use_smooth = True
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
        polygon.use_smooth = True
    return obj


def eyes(prefix, x, y, z, radius):
    """A pair of amber eyes with slit pupils on the sides of the head."""
    whites = [
        sphere("e%d" % i, (side * x, y, z), (radius * 0.8, radius, radius), 10, 7) for i, side in enumerate((-1, 1))
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


def paint_body(obj, tint, neutral=False, stripes=None):
    """Paints the skin pattern into the vertex colors: a lighter belly, darker back and dark
    stripes across the back and tail. `neutral` paints grey values only (what the export keeps;
    the game multiplies them with the color of the dino), otherwise the values are tinted."""
    mesh = obj.data
    if "Pattern" in mesh.color_attributes:
        mesh.color_attributes.remove(mesh.color_attributes["Pattern"])
    attribute = mesh.color_attributes.new(name="Pattern", type="BYTE_COLOR", domain="POINT")
    stripe_from, stripe_to, period, duty = stripes or (1.1, -4.2, 0.9, 0.5)
    for vertex in mesh.vertices:
        value = 0.82
        if vertex.normal.z < -0.25:
            value = 1.0
        elif vertex.normal.z > 0.1 and stripe_to < vertex.co.y < stripe_from and vertex.co.z > -1.5:
            phase = ((stripe_from - vertex.co.y) / period) % 1.0
            if phase < duty:
                value = 0.45
        color = (value, value, value, 1.0) if neutral else (value * tint[0], value * tint[1], value * tint[2], 1.0)
        # The numbers above are display values (sRGB); Blender stores linear colors.
        attribute.data[vertex.index].color = (color[0] ** 2.2, color[1] ** 2.2, color[2] ** 2.2, 1.0)
    mesh.color_attributes.active_color = attribute
    mesh.color_attributes.render_color_index = mesh.color_attributes.find("Pattern")


def build_runner(prefix="runner"):
    """Two-legged raptor-like runner (Compy, Raptor and the other light dinos): a long wedge
    head, a muscular S-shaped neck, a horizontal body with a stiff tail, strong bent legs with
    three toes (the second toe has the big sickle claw) and short arms with three claws."""
    remove_shape(prefix)
    # Snout tip to tail tip: x, y, z, width, height.
    spine = [
        (0, 3.95, -0.15, 0.07, 0.07),
        (0, 3.7, -0.1, 0.17, 0.18),
        (0, 3.1, -0.05, 0.25, 0.28),
        (0, 2.55, 0.12, 0.4, 0.46),
        (0, 2.1, 0.1, 0.4, 0.44),
        (0, 1.7, -0.1, 0.34, 0.4),
        (0, 1.25, -0.4, 0.45, 0.5),
        (0, 0.75, -0.7, 0.7, 0.76),
        (0, 0.0, -1.0, 0.82, 0.9),
        (0, -0.9, -1.05, 0.78, 0.82),
        (0, -1.8, -1.1, 0.55, 0.58),
        (0, -3.0, -1.2, 0.35, 0.36),
        (0, -4.3, -1.25, 0.2, 0.2),
        (0, -5.5, -1.3, 0.04, 0.04),
    ]
    parts = [tube("spine", smooth(spine, 0.4), sides=12)]
    dark = []
    teeth = []
    jaw = [(0, 3.75, -0.27, 0.1, 0.07), (0, 3.0, -0.3, 0.2, 0.12), (0, 2.4, -0.28, 0.3, 0.16), (0, 2.1, -0.2, 0.3, 0.16)]
    parts.append(tube("jaw", smooth(jaw, 0.4), sides=8))
    for side in (-1, 1):
        brow = [(side * 0.34, 2.75, 0.4, 0.07, 0.06), (side * 0.4, 2.45, 0.47, 0.09, 0.07), (side * 0.38, 2.15, 0.44, 0.07, 0.06)]
        parts.append(tube("brow", smooth(brow, 0.2), sides=5))
        cheek = [(side * 0.4, 2.85, -0.02, 0.05, 0.07), (side * 0.46, 2.5, -0.05, 0.1, 0.12), (side * 0.42, 2.15, -0.05, 0.07, 0.1)]
        parts.append(tube("cheek", smooth(cheek, 0.2), sides=5))
        dark.append(sphere("nostril", (side * 0.07, 3.8, 0.04), (0.035, 0.07, 0.03), 6, 4))
        mouth = [(side * 0.17, 3.68, -0.19, 0.02, 0.02), (side * 0.27, 3.1, -0.17, 0.025, 0.025), (side * 0.4, 2.45, -0.12, 0.025, 0.025)]
        dark.append(tube("mouth", smooth(mouth, 0.3), sides=4))
        for index, y in enumerate((3.6, 3.45, 3.3, 3.15, 3.0, 2.85, 2.7, 2.55)):
            reach = 0.16 + (3.65 - y) * 0.2
            size = 0.17 if index % 2 == 0 else 0.12
            teeth.append(cone("tooth", (side * reach, y, -0.26), 0.04, 0.0, size, rotation=(math.radians(180), 0, 0), vertices=4))
        for y in (3.5, 3.25, 3.0, 2.75):
            reach = 0.15 + (3.65 - y) * 0.2
            teeth.append(cone("tooth", (side * reach, y, -0.33), 0.035, 0.0, 0.11, vertices=4))
        # Legs: hip, knee (forward), ankle (back), then three toes with claws.
        x = side * 0.66
        leg = [
            (x, -0.8, -1.1, 0.55, 0.62),
            (x, -0.5, -1.65, 0.46, 0.5),
            (x, 0.15, -2.0, 0.3, 0.34),
            (x, -0.25, -2.55, 0.2, 0.26),
            (x, -0.3, -2.88, 0.2, 0.12),
        ]
        parts.append(tube("leg", smooth(leg, 0.4), sides=8))
        thigh = [(side * 0.78, -1.0, -1.0, 0.3, 0.38), (side * 0.82, -0.55, -1.45, 0.34, 0.4), (side * 0.7, -0.15, -1.85, 0.24, 0.26)]
        parts.append(tube("thigh", smooth(thigh, 0.4), sides=7))
        for toe, spread in ((-1, -0.2), (0, 0.0), (1, 0.2)):
            tip = 0.85 if toe != 0 else 0.8
            path = [(x, -0.3, -2.9, 0.1, 0.09), (x + spread * 0.7, 0.3, -2.92, 0.08, 0.075), (x + spread * 1.2, tip, -2.94, 0.05, 0.05)]
            parts.append(tube("toe", smooth(path, 0.4), sides=5))
            claw_length = 0.5 if toe == 0 else 0.28
            teeth.append(
                cone(
                    "claw",
                    (x + spread * 1.2, tip + claw_length / 2, -2.94 - (0.05 if toe == 0 else 0.0)),
                    0.055,
                    0.0,
                    claw_length,
                    rotation=(math.radians(-90 if toe != 0 else -110), 0, 0),
                    vertices=5,
                )
            )
        arm = [(side * 0.7, 0.65, -1.0, 0.2, 0.22), (side * 0.85, 0.95, -1.45, 0.14, 0.15), (side * 0.78, 1.5, -1.5, 0.1, 0.09)]
        parts.append(tube("arm", smooth(arm, 0.3), sides=6))
        for spread in (-0.07, 0.0, 0.07):
            teeth.append(
                cone("handclaw", (side * 0.78 + spread, 1.62, -1.52), 0.04, 0.0, 0.32, rotation=(math.radians(-90), 0, 0), vertices=5)
            )
    # Small scutes along the back (skin colored, they only break up the outline).
    for y in (1.0, 0.5, 0.0, -0.5, -1.0, -1.5, -2.1, -2.7, -3.3):
        parts.append(cone("scute", (0, y, spine_top(spine, y) + 0.02), 0.09, 0.0, 0.16, vertices=5))
    body_obj = join(parts, prefix + "_Body")
    accent_obj = join(teeth, prefix + "_Accent")
    eyes_obj, slits = eyes(prefix, 0.4, 2.55, 0.3, 0.17)
    dark_obj = join(dark + slits, prefix + "_Dark")

    paint_body(body_obj, SKIN)
    for obj, kind in ((body_obj, "Body"), (accent_obj, "Accent"), (eyes_obj, "Eyes"), (dark_obj, "Dark")):
        material(obj, kind)
    return [body_obj, accent_obj, eyes_obj, dark_obj]


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
    body = bpy.data.objects[shape + "_Body"]
    paint_body(body, SKIN, neutral=True)
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
    paint_body(body, SKIN)
    return [obj.name for obj in meshes]
