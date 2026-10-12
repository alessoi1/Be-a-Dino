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

# Skin color of every shape in the preview (the same as the first color of its family in
# src/shared/Config/DinoLooks.luau, divided by 255).
SKINS = {
    "runner": (0.6, 0.56, 0.34),
    "biped": (0.62, 0.30, 0.24),
    "duckbill": (0.30, 0.58, 0.54),
    "armored": (0.52, 0.50, 0.46),
    "horned": (0.80, 0.55, 0.32),
    "longneck": (0.44, 0.52, 0.64),
}

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


# Which shapes get dark stripes across the back (the heavy ones keep a plain skin).
STRIPED = {"runner": True, "biped": True, "duckbill": True, "armored": False, "horned": False, "longneck": False}


def paint_shape(prefix, neutral=False):
    for suffix, stripes in PAINTED.items():
        obj = bpy.data.objects.get(prefix + "_" + suffix)
        if obj is not None:
            paint_faces(obj, SKINS.get(prefix, SKIN), neutral=neutral, stripes=stripes and STRIPED.get(prefix, True))


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


# ---------------------------------------------------------------------------------------------
# The other body shapes. Same rules as the runner: Blender coordinates (front +Y, up +Z), the
# feet stand at z = -3, every shape has Body, Tail, the legs, Accent, Eyes and Dark.
# ---------------------------------------------------------------------------------------------

PAINTED.update({"LegFL": False, "LegFR": False, "LegBL": False, "LegBR": False})

SHAPE_JOINTS = {"runner": RUNNER_JOINTS}


def join_or_rename(objects, name):
    if len(objects) == 1:
        objects[0].name = name
        objects[0].data.name = name
        return objects[0]
    return join(objects, name)


def assemble(prefix, body_parts, tail_points, tail_extra, legs, accent, dark, eye, joints):
    """Joins the pieces of a shape into its meshes, paints them and gives them materials. `legs` maps
    the mesh name (LegL, LegFR ...) to its pieces."""
    body_obj = join_or_rename(body_parts, prefix + "_Body")
    tail_obj = join_or_rename([tube("tail", tail_points, sides=6)] + tail_extra, prefix + "_Tail")
    leg_objs = [join_or_rename(pieces, prefix + "_" + suffix) for suffix, pieces in legs.items()]
    accent_obj = join_or_rename(accent, prefix + "_Accent")
    eyes_obj, slits = eyes(prefix, *eye)
    dark_obj = join_or_rename(dark + slits, prefix + "_Dark")
    paint_shape(prefix)
    result = [body_obj, tail_obj] + leg_objs + [accent_obj, eyes_obj, dark_obj]
    kinds = ["Body", "Body"] + ["Body"] * len(leg_objs) + ["Accent", "Eyes", "Dark"]
    for obj, kind in zip(result, kinds):
        material(obj, kind)
    SHAPE_JOINTS[prefix] = joints
    return result


def pillar(x, y, hip_z, width, depth, sides=6):
    """A thick leg of the four-legged dinos: hip, knee, ankle and a flat foot pointing forward."""
    middle = (hip_z - 2.7) / 2
    path = [
        (x, y, hip_z, width, depth),
        (x, y + 0.05, middle, width * 0.85, depth * 0.85),
        (x, y, -2.7, width * 0.8, 0.25),
        (x, y + 0.1, -2.9, width * 0.85, 0.1),
        (x, y + 0.6, -2.92, width * 0.7, 0.08),
    ]
    pieces = [tube("leg", path, sides=sides)]
    for spread in (-0.45, 0.0, 0.45):
        pieces.append(
            cone(
                "claw",
                (x + spread * width, y + 0.82, -2.93),
                0.07,
                0.0,
                0.25,
                rotation=(math.radians(-90), 0, 0),
                vertices=4,
            )
        )
    return pieces


def quad_legs(front_y, back_y, x, hip_z, width, depth):
    """The four legs: front and back, left and right."""
    return {
        "LegFL": pillar(-x, front_y, hip_z, width, depth),
        "LegFR": pillar(x, front_y, hip_z, width, depth),
        "LegBL": pillar(-x, back_y, hip_z, width, depth),
        "LegBR": pillar(x, back_y, hip_z, width, depth),
    }


def quad_joints(front_y, back_y, x, hip_z, tail_y, tail_z):
    return {
        "Tail": (0, tail_y, tail_z),
        "LegFL": (-x, front_y, hip_z),
        "LegFR": (x, front_y, hip_z),
        "LegBL": (-x, back_y, hip_z),
        "LegBR": (x, back_y, hip_z),
    }


def teeth_row(count, start_y, end_y, reach, z, size, side, accent):
    for index in range(count):
        y = start_y + (end_y - start_y) * index / max(1, count - 1)
        accent.append(
            cone("tooth", (side * reach(y), y, z), 0.06, 0.0, size, rotation=(math.radians(180), 0, 0), vertices=3)
        )


def dark_details(dark, side, nostril, mouth):
    dark.append(sphere("nostril", (side * nostril[0], nostril[1], nostril[2]), (0.04, 0.08, 0.035), 4, 3))
    dark.append(tube("mouth", [(side * m[0], m[1], m[2], 0.025, 0.025) for m in mouth], sides=3))


def build_biped(prefix="biped"):
    """Big two-legged hunter (T-Rex and the other heavy meat eaters): a huge head with strong jaws,
    thick legs, tiny arms and a heavy tail."""
    remove_shape(prefix)
    spine = [
        (0, 4.6, -0.1, 0.12, 0.14),
        (0, 4.1, -0.05, 0.3, 0.34),
        (0, 3.2, 0.1, 0.55, 0.62),
        (0, 2.5, 0.35, 0.62, 0.78),
        (0, 1.9, 0.2, 0.55, 0.7),
        (0, 1.3, -0.1, 0.55, 0.65),
        (0, 0.6, -0.5, 0.85, 0.95),
        (0, -0.4, -0.7, 1.1, 1.15),
        (0, -1.4, -0.75, 1.0, 1.05),
        (0, -2.4, -0.8, 0.8, 0.85),
    ]
    tail = [(0, -2.2, -0.8, 0.8, 0.85), (0, -4.0, -1.0, 0.5, 0.55), (0, -5.8, -1.2, 0.25, 0.25), (0, -7.4, -1.4, 0.05, 0.05)]
    body = [tube("spine", spine, sides=6)]
    body.append(tube("jaw", [(0, 4.3, -0.4, 0.2, 0.12), (0, 3.4, -0.5, 0.45, 0.22), (0, 2.6, -0.45, 0.55, 0.28)], sides=6))
    legs, accent, dark = {}, [], []
    for side, suffix in ((-1, "LegL"), (1, "LegR")):
        x = side * 0.8
        leg = [
            (x, -1.4, -1.0, 0.7, 0.8),
            (x, -1.0, -1.7, 0.6, 0.7),
            (x, -0.4, -2.1, 0.45, 0.5),
            (x, -1.0, -2.6, 0.35, 0.4),
            (x, -1.0, -2.88, 0.4, 0.14),
        ]
        pieces = [tube("leg", leg, sides=6)]
        for spread in (-0.28, 0.0, 0.28):
            pieces.append(tube("toe", [(x, -1.0, -2.9, 0.13, 0.1), (x + spread, 0.1, -2.94, 0.07, 0.06)], sides=4))
            pieces.append(
                cone("claw", (x + spread, 0.4, -2.94), 0.08, 0.0, 0.45, rotation=(math.radians(-90), 0, 0), vertices=4)
            )
        legs[suffix] = pieces
        body.append(tube("arm", [(side * 0.9, 1.0, -1.3, 0.14, 0.16), (side * 0.95, 1.4, -1.6, 0.1, 0.1)], sides=4))
        for spread in (-0.05, 0.05):
            accent.append(
                cone("handclaw", (side * 0.95 + spread, 1.6, -1.65), 0.04, 0.0, 0.3, rotation=(math.radians(-90), 0, 0), vertices=3)
            )
        teeth_row(6, 4.0, 2.9, lambda y: 0.3 + (4.1 - y) * 0.18, -0.46, 0.26, side, accent)
        dark_details(dark, side, (0.1, 4.62, 0.0), [(0.25, 4.3, -0.28), (0.45, 3.4, -0.25), (0.6, 2.6, -0.2)])
    for y in (0.4, -0.5, -1.4):
        accent.append(cone("spike", (0, y, spine_top(spine, y) + 0.05), 0.14, 0.0, 0.3, vertices=4))
    joints = {"Tail": (0, -2.2, -0.8), "LegL": (-0.8, -1.4, -1.0), "LegR": (0.8, -1.4, -1.0)}
    return assemble(prefix, body, tail, [], legs, accent, dark, (0.58, 3.0, 0.62, 0.2), joints)


def build_duckbill(prefix="duckbill"):
    """Plant eater with a flat beak and a crest (Parasaurolophus, Edmontosaurus ...): a long body
    on strong hind legs and slimmer front legs."""
    remove_shape(prefix)
    spine = [
        (0, 4.0, -0.2, 0.28, 0.1),
        (0, 3.5, -0.15, 0.34, 0.14),
        (0, 2.9, 0.0, 0.36, 0.3),
        (0, 2.4, 0.3, 0.4, 0.45),
        (0, 1.8, 0.1, 0.35, 0.4),
        (0, 1.2, -0.2, 0.4, 0.5),
        (0, 0.5, -0.6, 0.8, 0.85),
        (0, -0.6, -0.7, 1.0, 1.0),
        (0, -1.8, -0.75, 0.9, 0.95),
    ]
    tail = [(0, -1.6, -0.75, 0.9, 0.95), (0, -3.2, -0.9, 0.55, 0.6), (0, -4.8, -1.0, 0.3, 0.3), (0, -6.2, -1.05, 0.05, 0.05)]
    body = [tube("spine", spine, sides=6)]
    legs = quad_legs(0.6, -1.2, 0.8, -0.95, 0.5, 0.55)
    accent, dark = [], []
    accent.append(tube("crest", [(0, 2.9, 0.5, 0.07, 0.05), (0, 2.3, 1.0, 0.09, 0.18), (0, 1.6, 1.1, 0.07, 0.1)], sides=4))
    for side in (-1, 1):
        dark_details(dark, side, (0.12, 4.0, -0.1), [(0.2, 3.6, -0.2), (0.3, 3.0, -0.1), (0.38, 2.5, 0.0)])
    for y in (0.6, -0.2, -1.0):
        accent.append(cone("spike", (0, y, spine_top(spine, y) + 0.03), 0.1, 0.0, 0.22, vertices=4))
    joints = quad_joints(0.6, -1.2, 0.8, -0.95, -1.6, -0.75)
    return assemble(prefix, body, tail, [], legs, accent, dark, (0.4, 2.7, 0.35, 0.17), joints)


def build_armored(prefix="armored"):
    """Low, wide armored dino (Ankylosaurus, Stegosaurus ...): small head, plates and spikes on the
    back and sides, short strong legs and a tail with a club."""
    remove_shape(prefix)
    spine = [
        (0, 3.4, -1.3, 0.18, 0.14),
        (0, 3.0, -1.25, 0.4, 0.3),
        (0, 2.4, -1.2, 0.55, 0.45),
        (0, 1.8, -1.2, 0.6, 0.5),
        (0, 1.0, -1.0, 1.3, 0.95),
        (0, -0.5, -0.85, 1.6, 1.15),
        (0, -1.8, -0.9, 1.5, 1.1),
        (0, -2.8, -1.05, 1.1, 0.9),
    ]
    tail = [(0, -2.6, -1.05, 1.0, 0.8), (0, -4.2, -1.3, 0.6, 0.45), (0, -5.6, -1.5, 0.4, 0.3)]
    club = [sphere("club", (0, -6.2, -1.5), (0.8, 0.8, 0.6), 6, 4)]
    body = [tube("spine", spine, sides=6)]
    legs = quad_legs(0.8, -1.8, 1.1, -1.5, 0.5, 0.55)
    accent, dark = [], []
    for index, y in enumerate((1.0, 0.1, -0.8, -1.7, -2.5)):
        top = spine_top(spine, y)
        for side in (-1, 1):
            accent.append(cone("plate", (side * 0.7, y, top - 0.1), 0.3, 0.0, 0.75, vertices=5))
        accent.append(cone("plate", (0, y - 0.3, top - 0.05), 0.25, 0.0, 0.6, vertices=5))
    for y in (0.6, -0.6, -1.8):
        for side in (-1, 1):
            accent.append(cone("sidespike", (side * 1.55, y, -0.9), 0.2, 0.0, 0.7, rotation=(0, math.radians(side * 90), 0), vertices=4))
    for side in (-1, 1):
        dark_details(dark, side, (0.07, 3.4, -1.25), [(0.15, 3.1, -1.3), (0.3, 2.7, -1.25), (0.4, 2.4, -1.2)])
    joints = quad_joints(0.8, -1.8, 1.1, -1.5, -2.6, -1.05)
    return assemble(prefix, body, tail, club, legs, accent, dark, (0.5, 2.7, -1.0, 0.14), joints)


def build_horned(prefix="horned"):
    """Horned dino with a frill (Triceratops and its relatives): a big head with three horns, a
    wide neck frill, a stocky body on four thick legs and a short tail."""
    remove_shape(prefix)
    spine = [
        (0, 4.3, -1.0, 0.15, 0.2),
        (0, 3.8, -0.9, 0.3, 0.35),
        (0, 3.0, -0.6, 0.5, 0.6),
        (0, 2.2, -0.3, 0.6, 0.7),
        (0, 1.2, -0.6, 0.9, 0.95),
        (0, 0.2, -0.8, 1.3, 1.2),
        (0, -1.2, -0.85, 1.35, 1.2),
        (0, -2.4, -1.0, 1.0, 0.95),
    ]
    tail = [(0, -2.2, -1.0, 0.9, 0.85), (0, -3.4, -1.25, 0.5, 0.5), (0, -4.5, -1.5, 0.05, 0.05)]
    body = [tube("spine", spine, sides=6), sphere("frill", (0, 1.9, -0.05), (1.6, 0.2, 1.4), 8, 5)]
    legs = quad_legs(0.4, -1.6, 1.0, -1.3, 0.55, 0.6)
    accent, dark = [], []
    for side in (-1, 1):
        accent.append(cone("browhorn", (side * 0.55, 3.55, -0.05), 0.17, 0.0, 1.7, rotation=(math.radians(-70), 0, 0), vertices=5))
        dark_details(dark, side, (0.09, 4.3, -0.85), [(0.2, 3.9, -1.0), (0.3, 3.4, -0.9), (0.4, 2.9, -0.8)])
    accent.append(cone("nosehorn", (0, 4.15, -0.55), 0.15, 0.0, 0.7, rotation=(math.radians(-25), 0, 0), vertices=5))
    for index in range(7):
        angle = math.radians(-70 + 140 * index / 6)
        accent.append(
            cone(
                "frillspike",
                (math.sin(angle) * 1.55, 1.9, math.cos(angle) * 1.35 - 0.05),
                0.14,
                0.0,
                0.4,
                rotation=(0, angle, 0),
                vertices=4,
            )
        )
    joints = quad_joints(0.4, -1.6, 1.0, -1.3, -2.2, -1.0)
    return assemble(prefix, body, tail, [], legs, accent, dark, (0.55, 3.0, 0.0, 0.14), joints)


def build_longneck(prefix="longneck"):
    """Giant long-necked plant eater (Diplodocus, Brachiosaurus ...): a huge body on four pillar legs,
    a long neck with a small head and a very long tail."""
    remove_shape(prefix)
    spine = [
        (0, 4.8, 2.9, 0.12, 0.12),
        (0, 4.4, 2.95, 0.2, 0.2),
        (0, 3.9, 3.0, 0.22, 0.22),
        (0, 3.4, 2.7, 0.2, 0.22),
        (0, 2.8, 2.0, 0.3, 0.32),
        (0, 2.1, 1.1, 0.45, 0.5),
        (0, 1.4, 0.2, 0.7, 0.75),
        (0, 0.4, -0.6, 1.1, 1.1),
        (0, -0.8, -0.8, 1.25, 1.2),
        (0, -2.0, -0.8, 1.1, 1.1),
    ]
    tail = [(0, -1.8, -0.8, 1.0, 0.95), (0, -3.6, -1.0, 0.6, 0.6), (0, -5.8, -1.3, 0.3, 0.3), (0, -8.0, -1.5, 0.04, 0.04)]
    body = [tube("spine", spine, sides=6)]
    legs = quad_legs(0.6, -1.6, 0.9, -1.2, 0.55, 0.6)
    accent, dark = [], []
    for y in (3.2, 2.7, 2.2, 1.7):
        accent.append(cone("neckspike", (0, y, spine_top(spine, y) + 0.04), 0.1, 0.0, 0.25, vertices=4))
    for y in (0.8, -0.2, -1.2, -2.2):
        accent.append(cone("spike", (0, y, spine_top(spine, y) + 0.04), 0.14, 0.0, 0.3, vertices=4))
    for side in (-1, 1):
        dark_details(dark, side, (0.06, 4.82, 2.93), [(0.12, 4.5, 2.88), (0.2, 4.1, 2.9), (0.24, 3.8, 2.95)])
    joints = quad_joints(0.6, -1.6, 0.9, -1.2, -1.8, -0.8)
    return assemble(prefix, body, tail, [], legs, accent, dark, (0.2, 4.15, 3.12, 0.12), joints)


SHAPES.update(
    {
        "biped": build_biped,
        "duckbill": build_duckbill,
        "armored": build_armored,
        "horned": build_horned,
        "longneck": build_longneck,
    }
)


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
