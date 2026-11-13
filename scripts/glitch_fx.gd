class_name GlitchFx
extends CanvasLayer

const CODIGO := """
shader_type canvas_item;
uniform sampler2D pantalla : hint_screen_texture, filter_nearest;
uniform float fuerza : hint_range(0.0, 1.0) = 0.0;
float rnd(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = SCREEN_UV;
	// corta la pantalla en 12 franjas
	float banda = floor(uv.y * 24.0);
	// 12 veces por segundo
	float t = floor(TIME * 12.0);
	// + fuerza, + franjas se mueven
	float umbral = 1.0 - 0.45 * fuerza;
	float mueve = step(umbral, rnd(vec2(banda + 3.0, t)));
	// mover franjas a izquierda o derecha.
	uv.x += (rnd(vec2(banda, t)) - 0.5) * 0.12 * fuerza * mueve;
	// algo cromatico, mueve el rojo un poco a la derecha y el azul un poco a la izquierda.
	float sep = 0.008 * fuerza;
	COLOR = vec4(texture(pantalla, uv + vec2(sep, 0.0)).r, texture(pantalla, uv).g, texture(pantalla, uv - vec2(sep, 0.0)).b, 1.0);
}
"""

var _mat: ShaderMaterial
var _rect: ColorRect
var _f := 0.0
var _tween: Tween

# modo ráfagas
var _modo_rafagas := false
var _en_rafaga := false
var _t_sig := 0.0
var _base_f := 0.0
var _pico_f := 0.0

static func activar(arbol: SceneTree) -> GlitchFx:
	var g := arbol.root.get_node_or_null("GlitchFx") as GlitchFx
	if g == null:
		g = GlitchFx.new()
		g.name = "GlitchFx"
		arbol.root.add_child(g)
	return g

func _ready() -> void:
	layer = 100
	_rect = ColorRect.new()
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = CODIGO
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	_rect.material = _mat
	add_child(_rect)
	_poner(0.0)

func _process(delta: float) -> void:
	if not _modo_rafagas:
		return
	_t_sig -= delta
	if _t_sig > 0.0:
		return
	if _en_rafaga:
		_en_rafaga = false
		_poner(_base_f)
		_t_sig = randf_range(0.6, 1.8)   # calma entre ráfagas
	else:
		_en_rafaga = true
		_poner(_pico_f)
		_t_sig = randf_range(0.06, 0.16)  # la ráfaga dura una fracción de segundo

# Fuerza fija. Con seg > 0 hace una transición suave desde el valor actual.
func fuerza(v: float, seg: float = 0.0) -> void:
	_modo_rafagas = false
	_matar_tween()
	if seg <= 0.0:
		_poner(v)
	else:
		_tween = create_tween()
		_tween.tween_method(_poner, _f, v, seg)

func pulso(pico: float = 0.4, seg: float = 0.2) -> void:
	_modo_rafagas = false
	_matar_tween()
	_poner(pico)
	_tween = create_tween()
	_tween.tween_method(_poner, pico, 0.0, seg).set_ease(Tween.EASE_OUT)

# Intermitente: fuerza "base" casi todo el tiempo, y ráfagas cortas a "pico".
# Se puede volver a llamar para subir la intensidad sin cortar el efecto.
func rafagas(base: float, pico: float) -> void:
	_matar_tween()
	_base_f = base
	_pico_f = pico
	if not _modo_rafagas:
		_modo_rafagas = true
		_en_rafaga = false
		_t_sig = randf_range(0.4, 1.0)
		_poner(base)

func parar_rafagas() -> void:
	_modo_rafagas = false
	_en_rafaga = false
	_poner(0.0)

func _matar_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

func _poner(v: float) -> void:
	_f = v
	_mat.set_shader_parameter("fuerza", v)
	_rect.visible = v > 0.001
