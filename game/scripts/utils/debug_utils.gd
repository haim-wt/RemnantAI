## Debug drawing and logging utilities.
## Only active in debug builds.
class_name DebugUtils
extends RefCounted

# -----------------------------------------------------------------------------
# Debug State
# -----------------------------------------------------------------------------

static var _debug_enabled: bool = OS.is_debug_build()
static var _draw_node: Node3D
static var _immediate_mesh: ImmediateMesh
static var _mesh_instance: MeshInstance3D
static var _material: StandardMaterial3D

# -----------------------------------------------------------------------------
# Initialization
# -----------------------------------------------------------------------------

## Call this once from a persistent node to enable 3D debug drawing
static func initialize(parent: Node3D) -> void:
	if not _debug_enabled:
		return

	_draw_node = parent

	_immediate_mesh = ImmediateMesh.new()

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _immediate_mesh
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.vertex_color_use_as_albedo = true
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	_mesh_instance.material_override = _material

	parent.add_child(_mesh_instance)


## Clear all debug drawings (call at start of frame)
static func clear() -> void:
	if not _debug_enabled or not _immediate_mesh:
		return
	_immediate_mesh.clear_surfaces()

# -----------------------------------------------------------------------------
# 3D Drawing
# -----------------------------------------------------------------------------

## Draw a line in 3D space
static func draw_line_3d(from: Vector3, to: Vector3, color: Color = Color.WHITE) -> void:
	if not _debug_enabled or not _immediate_mesh:
		return

	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_immediate_mesh.surface_set_color(color)
	_immediate_mesh.surface_add_vertex(from)
	_immediate_mesh.surface_add_vertex(to)
	_immediate_mesh.surface_end()


## Draw a point in 3D space
static func draw_point_3d(position: Vector3, size: float = 0.1, color: Color = Color.WHITE) -> void:
	if not _debug_enabled or not _immediate_mesh:
		return

	# Draw as small cross
	var half := size * 0.5
	draw_line_3d(position - Vector3(half, 0, 0), position + Vector3(half, 0, 0), color)
	draw_line_3d(position - Vector3(0, half, 0), position + Vector3(0, half, 0), color)
	draw_line_3d(position - Vector3(0, 0, half), position + Vector3(0, 0, half), color)


## Draw a vector from a point
static func draw_vector_3d(
	origin: Vector3,
	direction: Vector3,
	color: Color = Color.GREEN,
	arrow_size: float = 0.1
) -> void:
	if not _debug_enabled or not _immediate_mesh:
		return

	var end := origin + direction
	draw_line_3d(origin, end, color)

	# Arrow head
	if direction.length() > 0.01:
		var right := direction.cross(Vector3.UP).normalized() * arrow_size
		if right.is_zero_approx():
			right = direction.cross(Vector3.RIGHT).normalized() * arrow_size
		var back := -direction.normalized() * arrow_size

		draw_line_3d(end, end + back + right, color)
		draw_line_3d(end, end + back - right, color)


## Draw a sphere wireframe
static func draw_sphere_3d(
	center: Vector3,
	radius: float,
	color: Color = Color.WHITE,
	segments: int = 16
) -> void:
	if not _debug_enabled or not _immediate_mesh:
		return

	# Draw three circles for each axis
	for i in segments:
		var angle1 := float(i) / segments * TAU
		var angle2 := float(i + 1) / segments * TAU

		# XY plane
		var p1 := center + Vector3(cos(angle1), sin(angle1), 0) * radius
		var p2 := center + Vector3(cos(angle2), sin(angle2), 0) * radius
		draw_line_3d(p1, p2, color)

		# XZ plane
		p1 = center + Vector3(cos(angle1), 0, sin(angle1)) * radius
		p2 = center + Vector3(cos(angle2), 0, sin(angle2)) * radius
		draw_line_3d(p1, p2, color)

		# YZ plane
		p1 = center + Vector3(0, cos(angle1), sin(angle1)) * radius
		p2 = center + Vector3(0, cos(angle2), sin(angle2)) * radius
		draw_line_3d(p1, p2, color)


## Draw an axis-aligned bounding box
static func draw_aabb_3d(aabb: AABB, color: Color = Color.WHITE) -> void:
	if not _debug_enabled or not _immediate_mesh:
		return

	var corners: Array[Vector3] = [
		aabb.position,
		aabb.position + Vector3(aabb.size.x, 0, 0),
		aabb.position + Vector3(aabb.size.x, 0, aabb.size.z),
		aabb.position + Vector3(0, 0, aabb.size.z),
		aabb.position + Vector3(0, aabb.size.y, 0),
		aabb.position + Vector3(aabb.size.x, aabb.size.y, 0),
		aabb.position + aabb.size,
		aabb.position + Vector3(0, aabb.size.y, aabb.size.z),
	]

	# Bottom face
	draw_line_3d(corners[0], corners[1], color)
	draw_line_3d(corners[1], corners[2], color)
	draw_line_3d(corners[2], corners[3], color)
	draw_line_3d(corners[3], corners[0], color)

	# Top face
	draw_line_3d(corners[4], corners[5], color)
	draw_line_3d(corners[5], corners[6], color)
	draw_line_3d(corners[6], corners[7], color)
	draw_line_3d(corners[7], corners[4], color)

	# Vertical edges
	draw_line_3d(corners[0], corners[4], color)
	draw_line_3d(corners[1], corners[5], color)
	draw_line_3d(corners[2], corners[6], color)
	draw_line_3d(corners[3], corners[7], color)

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------

## Log with timestamp
static func log_info(message: String) -> void:
	if _debug_enabled:
		print("[%s] %s" % [Time.get_time_string_from_system(), message])


## Log warning
static func log_warn(message: String) -> void:
	if _debug_enabled:
		push_warning("[%s] %s" % [Time.get_time_string_from_system(), message])


## Log error
static func log_error(message: String) -> void:
	push_error("[%s] %s" % [Time.get_time_string_from_system(), message])


## Log physics state
static func log_physics_state(body: RigidBody3D) -> void:
	if not _debug_enabled:
		return

	print("=== Physics State: %s ===" % body.name)
	print("  Position: %s" % body.global_position)
	print("  Velocity: %s (%.2f m/s)" % [body.linear_velocity, body.linear_velocity.length()])
	print("  Angular:  %s" % body.angular_velocity)
	print("  Mass:     %.2f kg" % body.mass)
