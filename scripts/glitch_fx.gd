class_name GlitchFx
extends CanvasLayer

const CODIGO := """
shader_type canvas_item;
uniform sampler2D pantalla : hint_screen_texture, filter_nearest;
uniform float fuerza : hint_range(0.0, 1.0) = 0.0;
float rnd(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = SCREEN_UV;
	float banda = floor(uv.y * 24.0);
	float t = floor(TIME * 12.0);
	uv.x += (rnd(vec2(banda, t)) - 0.5) * 0.15 * fuerza * step(0.7, rnd(vec2(banda + 3.0, t)));
	float sep = 0.01 * fuerza;
	COLOR = vec4(texture(pantalla, uv + vec2(sep, 0.0)).r, texture(pantalla, uv).g, texture(pantalla, uv - vec2(sep, 0.0)).b, 1.0);
}
"""
var _mat: ShaderMaterial
var _f := 0.0

static func activar(arbol: SceneTree) -> GlitchFx:
	var g := arbol.root.get_node_or_null("GlitchFx") as GlitchFx
	if g == null:
		g = GlitchFx.new()
		g.name = "GlitchFx"
		arbol.root.add_child(g)
	return g

func _ready() -> void:
	layer = 100
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = CODIGO
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	rect.material = _mat
	add_child(rect)

func fuerza(v: float, seg: float = 0.0) -> void:
	if seg <= 0.0:
		_poner(v)
	else:
		create_tween().tween_method(_poner, _f, v, seg)

func _poner(v: float) -> void:
	_f = v
	_mat.set_shader_parameter("fuerza", v)
