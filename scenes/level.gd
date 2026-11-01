extends Node2D

signal level_won(moves)

const TILE := 32
const HALF := Vector2(16, 16)
const N := 1
const E := 2
const S := 4
const W := 8
const DIRS := [N, E, S, W]
const STEP := {N: Vector2i(0, -1), E: Vector2i(1, 0), S: Vector2i(0, 1), W: Vector2i(-1, 0)}
const OPPOSITE := {N: S, E: W, S: N, W: E}
# Her parçanın dönmemiş haldeki bağlantıları
const SHAPES := {"T": N, "G": N, "K": N, "H": N, "I": N | S, "L": N | E, "Y": N | E | S}
const CABLES := ["I", "L", "Y"]

const SKY_DIRTY := Color(0.33, 0.33, 0.36)
const SKY_CLEAN := Color(0.45, 0.75, 0.95)

# Kablo renkleri: beyaz çizilen kablo bu renklere boyanır
const CABLE_OFF := Color(0.55, 0.6, 0.7)
const CABLE_ON := Color(1.0, 0.82, 0.3)
const CABLE_DIRTY := Color(0.45, 0.33, 0.28)
const OUTLINE := Color(0.25, 0.15, 0.19)

const FLOWER_CHANCE := 0.15  # çimlerin ne kadarı çiçekli olsun

# Görseller: dosya yoksa oyun geçici şekillerle çizer
const TEX_PATHS := {
	"ground_grass": "res://art/ground_grass.png",
	"ground_flower": "res://art/ground_flower.png",
	"ground_dirt": "res://art/ground_dirt.png",
	"I": "res://art/cable_I.png",
	"L": "res://art/cable_L.png",
	"Y": "res://art/cable_Y.png",
	"turbine_base": "res://art/turbine_base.png",
	"turbine_blades": "res://art/turbine_blades.png",
	"house_off": "res://art/house_off.png",
	"house_on": "res://art/house_on.png",
	"solar": "res://art/solar.png",
	"coal": "res://art/coal.png",
	"engineer_girl": "res://art/engineer_girl.png",
	"engineer_boy": "res://art/engineer_boy.png",
	"tree": "res://art/tree.png",
	"tree_dead": "res://art/tree_dead.png",
	"smoke": "res://art/smoke.png",
	"sea_1": "res://art/sea_1.png",
	"sea_2": "res://art/sea_2.png",
	"star_on": "res://art/star_on.png",
	"star_off": "res://art/star_off.png",
	"cat": "res://art/cat.png",
	"lock": "res://art/lock.png",
}

const SAVE_PATH := "user://save.cfg"

# Emeği geçenler: kendi adını ve (eklersen) müziğin kaynağını buraya yaz
const DEVELOPERS := ["Aslı Yağmur Ozan", "Fatma İnci Arıcı"]
const MUSIC_CREDIT := "Ana sayfa ve bölüm müzikleri Google Gemini ile yapay zekâ kullanılarak üretildi."
const MAX_HINTS := 2
const DARK := Color(0.25, 0.15, 0.19)
const PAPER := Color(0.99, 0.95, 0.86)
# COP31 ülkeleri: şimdilik sadece Türkiye oynanabilir
const COUNTRIES := [
	{"name": "Türkiye", "open": true},
	{"name": "Avustralya", "open": false},
	{"name": "Brezilya", "open": false},
	{"name": "Fiji", "open": false},
]
const CAT_LINES := [
	"Miyav! Şu kabloyu senin için çevirdim.",
	"Bilge kedi der ki: enerji en kısa yolu sever.",
	"Patilerimle düzelttim. Gerisi sende, mühendis!",
	"Acele etme. Önce kaynaktan başlayıp yolu takip et.",
]

const LAND_MARGIN := 2      # ızgara ile deniz arasındaki kara genişliği (kare)
const TREE_CHANCE := 0.25   # ızgara dışındaki karaların ne kadarında ağaç olsun

# Öğretici: elle tasarlanmış, çözülmüş haliyle yazıldı
const TUTORIAL := [
	"T1 I1 L2 .",
	". . H0 .",
]

# 0 = öğretici, sonrası rastgele üretilen bölümler
# cfg: w/h = ızgara boyutu, sources = kaynaklar (T türbin, G güneş), houses = ev sayısı, coal = kömür santrali
const LEVEL_INFO := [
	{"place": "Öğretici", "sea": [],
	 "note": "Harika! Kabloları çevirmeyi öğrendin, artık sahaya çıkma zamanı.",
	 "fact": "Rüzgâr türbinleri ve güneş panelleri elektriği yakıt yakmadan üretir."},
	{"place": "Çeşme", "sea": ["W"],
	 "cfg": {"w": 5, "h": 4, "sources": ["T"], "houses": 2, "coal": 0},
	 "note": "İlk görev Çeşme'de. Rüzgâr burada hiç eksik olmaz, evlerin ışıkları yandı!",
	 "fact": "Türkiye'de ticari elektrik üretebilen ilk rüzgâr türbini 1984'te Çeşme'de kuruldu."},
	{"place": "Bozcaada", "sea": ["N", "E", "S", "W"],
	 "cfg": {"w": 5, "h": 5, "sources": ["T"], "houses": 3, "coal": 0},
	 "note": "Bozcaada'da rüzgâr hiç durmuyor. Adadaki evlerin ışıkları yandı.",
	 "fact": "Bozcaada'nın batı ucunda 2000 yılından beri 17 türbinli bir rüzgâr santrali çalışıyor."},
	{"place": "Karapınar", "sea": [],
	 "cfg": {"w": 6, "h": 5, "sources": ["G", "G"], "houses": 3, "coal": 0},
	 "note": "Konya ovasında güneş çok cömert. Paneller bütün gün çalışıyor.",
	 "fact": "Türkiye'nin en büyük güneş santrali Karapınar'da, yaklaşık 20 milyon metrekarelik bir alanda."},
	{"place": "Sinop", "sea": ["N"],
	 "cfg": {"w": 6, "h": 5, "sources": ["T", "G"], "houses": 4, "coal": 0},
	 "note": "Sinop'ta rüzgâr ve güneş aynı ekipte. Biri dinlenirken öteki çalışıyor.",
	 "fact": "Sinop'taki rüzgâr türbinlerinin altına güneş panelleri kurularak hibrit santraller oluşturuldu."},
	{"place": "Zonguldak", "sea": ["N"],
	 "cfg": {"w": 6, "h": 5, "sources": ["T", "G"], "houses": 3, "coal": 2},
	 "note": "Zonguldak yüzyılı aşkın süre ülkeye enerji taşıdı. Madencilerin emeğine saygıyla, şimdi sıra temiz enerjide.",
	 "fact": "Zonguldak'ta taşkömürü 1829'da Uzun Mehmet tarafından bulundu. Bölge, Türkiye'nin tek taşkömürü havzası."},
	{"place": "İzmir", "sea": ["W"],
	 "cfg": {"w": 7, "h": 6, "sources": ["T", "T"], "houses": 5, "coal": 0},
	 "note": "İzmir'in rüzgârı bütün mahalleye yetti. Türbinler hiç durmuyor!",
	 "fact": "İzmir, Türkiye'de rüzgâr enerjisi kurulu gücü en yüksek şehir."},
	{"place": "Antalya", "sea": ["S"],
	 "cfg": {"w": 7, "h": 6, "sources": ["T", "G"], "houses": 5, "coal": 1},
	 "note": "Antalya'da bütün kasaba temiz enerjiyle parlıyor. Dünya bize bakıyor!",
	 "fact": "BM İklim Değişikliği Konferansı COP31, 9-20 Kasım 2026'da Antalya'da yapılıyor."},
]

var level_index := 0
var grid := {}      # Vector2i -> {"type", "rot", "turns", "angle"}
var grid_size := Vector2i.ZERO
var powered := {}   # temiz enerji alan kareler
var dirty := {}     # kömüre bağlı kareler
var moves := 0
var won := false
var tex := {}
var blade_angle := 0.0
var health := 0.0   # 0 = tamamen gri, 1 = tamamen yeşil
var waiting_card := false
var shown_health := 0.0   # pus için yumuşak geçişli sağlık
var smoke_on := false   # kömür bir eve bağlıyken duman yoğunlaşır
var noise := FastNoiseLite.new()   # doğal görünen çim öbekleri ve kıyılar için

# Giriş ve bitiş: uzaktan vadi haritası
var mode := "start"   # start, intro, play, ending
var total_moves := 0
var overview_layer: CanvasLayer
var overview: Node2D
var ov_noise := FastNoiseLite.new()
var ov_features := {}   # Vector2i -> "H" ev, "K" kömür, "T"/"G" bitişte kurulacak kaynak, "tree"
var ov_health := 0.0
var story_panel: PanelContainer
var story_label: Label
var story_hint: Label
var replay_btn: Button
var story_pages: Array = []
var story_page := 0
var margins := {}   # her yönde ızgara ile deniz arasındaki kara genişliği
var started := false
var player_name := ""
var engineer_key := "engineer_girl"
var time := 0.0
var start_screen: Control
var girl_btn: TextureButton
var boy_btn: TextureButton
var name_edit: LineEdit
var card: PanelContainer
var card_stars: HBoxContainer
var card_result: Label
var paused := false
var hints_left := MAX_HINTS
var hints_used := 0
var par := 0              # bölümü bitirmek için gereken en az hamle
var best_stars := {}      # bölüm -> en iyi yıldız
var music_on := true
var music: AudioStreamPlayer
var music_tracks := {}      # "menu" / "level" -> ses dosyası
var music_current := ""
var intro_seen := false
var title_screen: Control
var countries_screen: Control
var countries_star_label: Label
var reset_btn: Button
var reset_armed := false
var levels_screen: Control
var levels_grid: GridContainer
var levels_header: Label
var hud: HBoxContainer
var hint_btn: Button
var pause_screen: Control
var music_btn: Button
var cat_bubble: PanelContainer
var cat_label: Label
var cat_tween: Tween
var cat_jump: Tween
var cat_icon: TextureRect
var offer_row: HBoxContainer
var hint_offered := false   # bölüm başına kedi bir kez teklif eder
var start_grid := {}        # bölümün karışık başlangıç hali (baştan başlatmak için)
var credits_screen: Control
var credits_box: VBoxContainer
var credits_back: Button
var credits_tween: Tween
var credits_return := "levels"
var card_title: Label
var card_note: Label
var card_fact: Label

@onready var moves_label: Label = $UI/MovesLabel
@onready var message_label: Label = $UI/MessageLabel
@onready var sky: ColorRect = get_node_or_null("BG/Sky")  # yoksa oyun yine çalışır

func _ready() -> void:
	for key in TEX_PATHS:
		if ResourceLoader.exists(TEX_PATHS[key]):
			tex[key] = load(TEX_PATHS[key])
		else:
			print("Görsel bulunamadı: ", TEX_PATHS[key])
	if sky:
		sky.color = SKY_DIRTY
	message_label.position = Vector2(0, 245)
	message_label.size = Vector2(480, 20)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	noise.frequency = 0.18
	load_save()
	build_card()
	build_overview()
	build_story_panel()
	build_start_screen()
	build_title_screen()
	build_countries_screen()
	build_levels_screen()
	build_hud()
	build_cat_bubble()
	build_pause_screen()
	build_credits_screen()
	setup_music()
	load_level(level_index)
	set_mode("title")

func _process(delta: float) -> void:
	blade_angle += delta * 3.0
	time += delta
	shown_health = lerpf(shown_health, health, delta * 3.0)
	if overview_layer.visible:
		overview.queue_redraw()
	queue_redraw()

func load_level(i: int) -> void:
	noise.seed = randi()
	moves = 0
	won = false
	var solved := {}
	if i == 0:
		solved = parse_layout(TUTORIAL)
		grid_size = Vector2i.ZERO
		for p in solved:
			grid_size = Vector2i(maxi(grid_size.x, p.x + 1), maxi(grid_size.y, p.y + 1))
	else:
		var cfg: Dictionary = LEVEL_INFO[i]["cfg"]
		solved = generate_level(cfg)
		grid_size = Vector2i(cfg["w"], cfg["h"])
	# Kabloları karıştır; karışık hali yanlışlıkla çözülmüş olmasın
	for tries in range(20):
		grid.clear()
		for p in solved:
			var t: String = solved[p][0]
			var r: int = solved[p][1]
			if t in CABLES:
				r = randi() % 4
			var sol := rot_mask(SHAPES[t], solved[p][1])
			grid[p] = {"type": t, "rot": r, "turns": r, "angle": r * PI / 2, "sol": sol, "locked": false}
		if not is_solved():
			break
	hints_left = MAX_HINTS
	hints_used = 0
	hint_offered = false
	hide_cat()
	par = 0
	for p in grid:
		var cell: Dictionary = grid[p]
		if cell["type"] in CABLES:
			for k in range(4):
				if rot_mask(SHAPES[cell["type"]], (cell["rot"] + k) % 4) == cell["sol"]:
					par += k
					break
	start_grid = grid.duplicate(true)
	update_hud()
	update_ui()
	position = (Vector2(480, 270) - Vector2(grid_size) * TILE) / 2
	# Deniz ekranda görünsün diye kara şeridi boş alana göre daralır
	var space := {"W": position.x, "E": 480.0 - position.x - grid_size.x * TILE,
		"N": position.y, "S": 270.0 - position.y - grid_size.y * TILE}
	for k in space:
		margins[k] = clampi(floori(space[k] / TILE) - 1, 0, LAND_MARGIN)
	if i == 0:
		message_label.text = "Kablolara tıklayıp çevir, enerjiyi eve ulaştır!"
		message_label.visible = true
	else:
		message_label.visible = false
	update_power()

# "T1 I1 ." gibi yazılmış bir yerleşimi okur: kare -> [tür, çözüm dönüşü]
func parse_layout(rows: Array) -> Dictionary:
	var out := {}
	for y in range(rows.size()):
		var cells: PackedStringArray = rows[y].split(" ", false)
		for x in range(cells.size()):
			var c: String = cells[x]
			if c != ".":
				out[Vector2i(x, y)] = [c.substr(0, 1), c.substr(1, 1).to_int()]
	return out

# ---------- Rastgele bölüm üretici: her zaman çözülebilir ----------
func rot_mask(m: int, r: int) -> int:
	for i in range(r):
		m = ((m << 1) | (m >> 3)) & 15
	return m

func bit_count(m: int) -> int:
	return (m & 1) + ((m >> 1) & 1) + ((m >> 2) & 1) + ((m >> 3) & 1)

# Bağlantı yönlerinden parça türünü ve dönüşünü bulur
func piece_for(mask: int, special: String) -> Array:
	var t := special
	if t == "":
		if bit_count(mask) == 3:
			t = "Y"
		elif mask == (N | S) or mask == (E | W):
			t = "I"
		else:
			t = "L"
	for r in range(4):
		if rot_mask(SHAPES[t], r) == mask:
			return [t, r]
	return [t, 0]

func generate_level(cfg: Dictionary) -> Dictionary:
	var w: int = cfg["w"]
	var h: int = cfg["h"]
	var sources: Array = cfg["sources"]
	var houses: int = cfg["houses"]
	for attempt in range(500):
		# 1) Kaynak ve evleri rastgele karelere koy
		var cells: Array[Vector2i] = []
		for y in range(h):
			for x in range(w):
				cells.append(Vector2i(x, y))
		cells.shuffle()
		var spec := {}
		for k in range(sources.size() + houses):
			spec[cells[k]] = sources[k] if k < sources.size() else "H"
		# 2) İlk kaynaktan başlayıp rastgele bir ağaç gibi bütün ızgaraya yayıl
		var start: Vector2i = cells[0]
		var conn := {start: 0}
		var frontier: Array = []
		for d in DIRS:
			frontier.append([start, d])
		while not frontier.is_empty():
			var idx := randi() % frontier.size()
			var e: Array = frontier[idx]
			frontier.remove_at(idx)
			var a: Vector2i = e[0]
			var d: int = e[1]
			var cap := 1 if spec.has(a) else 3
			if bit_count(conn[a]) >= cap:
				continue
			var b: Vector2i = a + STEP[d]
			if b.x < 0 or b.y < 0 or b.x >= w or b.y >= h or conn.has(b):
				continue
			conn[a] = conn[a] | d
			conn[b] = OPPOSITE[d]
			if not spec.has(b):
				for dd in DIRS:
					frontier.append([b, dd])
		var ok := true
		for c in spec:
			if not conn.has(c):
				ok = false
		if not ok:
			continue
		# 3) Hiçbir eve gitmeyen kablo dallarını buda
		var changed := true
		while changed:
			changed = false
			for c in conn.keys():
				if spec.has(c) or not conn.has(c):
					continue
				if bit_count(conn[c]) <= 1:
					for d in DIRS:
						if (conn[c] & d) != 0:
							var nb: Vector2i = c + STEP[d]
							conn[nb] = conn[nb] & ~OPPOSITE[d]
					conn.erase(c)
					changed = true
		for c in spec:
			if bit_count(conn[c]) != 1:
				ok = false
		var cable_count := conn.size() - spec.size()
		if not ok or cable_count < houses * 2:
			continue
		var result := {}
		for c in conn:
			result[c] = piece_for(conn[c], spec.get(c, ""))
		# 4) Kömür santralleri: bir kablonun yanına, ona bakacak şekilde (tuzak)
		for k in range(cfg["coal"]):
			var opts: Array = []
			for c in cells:
				if result.has(c):
					continue
				for d in DIRS:
					var nb: Vector2i = c + STEP[d]
					if result.has(nb) and result[nb][0] in CABLES:
						opts.append([c, d])
			if opts.is_empty():
				ok = false
				break
			var pick: Array = opts.pick_random()
			result[pick[0]] = piece_for(pick[1], "K")
		if ok:
			return result
	push_error("Bölüm üretilemedi, öğretici yükleniyor")
	return parse_layout(TUTORIAL)

func mask_of(cell: Dictionary) -> int:
	var m: int = SHAPES[cell["type"]]
	for i in range(cell["rot"]):
		m = ((m << 1) | (m >> 3)) & 15
	return m

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if mode == "play":
			toggle_pause()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if mode == "title":
			set_mode("select")
			return
		if mode == "intro" or mode == "ending":
			advance_story()
			return
		if mode == "credits":
			skip_credits()
			return
		if mode != "play" or paused:
			return
		if waiting_card:
			next_level()
			return
		if won:
			return
		var p := Vector2i((get_local_mouse_position() / TILE).floor())
		if grid.has(p) and grid[p]["type"] in CABLES and not grid[p]["locked"]:
			rotate_cell(grid[p])
			moves += 1
			update_ui()
			update_power()
			maybe_offer_hint()

# Mantıkta anında, görüntüde hafif sekmeyle döner
func rotate_cell(cell: Dictionary) -> void:
	cell["turns"] += 1
	cell["rot"] = cell["turns"] % 4
	if cell.has("tween") and cell["tween"]:
		cell["tween"].kill()
	var tw := create_tween()
	tw.tween_method(func(a: float): cell["angle"] = a, cell["angle"], cell["turns"] * PI / 2, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	cell["tween"] = tw

# Verilen kaynak türlerinden enerjiyi yayar, ulaştığı kareleri döndürür
func flood(sources: Array) -> Dictionary:
	var seen := {}
	var queue: Array[Vector2i] = []
	for p in grid:
		if grid[p]["type"] in sources:
			seen[p] = true
			queue.append(p)
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		var m := mask_of(grid[p])
		for d in DIRS:
			if (m & d) == 0:
				continue
			var n: Vector2i = p + STEP[d]
			if grid.has(n) and not seen.has(n) and (mask_of(grid[n]) & OPPOSITE[d]) != 0:
				seen[n] = true
				queue.append(n)
	return seen

func update_power() -> void:
	powered = flood(["T", "G"])
	dirty = flood(["K"])
	smoke_on = false
	for p in dirty:
		if grid[p]["type"] != "K":
			smoke_on = true
	update_health()
	if won or not houses_done():
		return
	won = true
	level_won.emit(moves)
	print("Bölüm bitti! Hamle: ", moves)
	var stars := calc_stars()
	if stars > best_stars.get(level_index, 0):
		best_stars[level_index] = stars
		save_game()
	message_label.text = "Kasaba temiz enerjiyle aydınlandı!"
	message_label.visible = true
	await get_tree().create_timer(1.0).timeout
	if mode == "play" and won:
		show_card(stars)

# Yıldızlar: hedef hamle sayısını geçmezsen 3, iki katını geçmezsen 2, yoksa 1.
# İlk ipucu bedava, sonraki her ipucu bir yıldız götürür (en az 1 yıldız).
func three_star_limit() -> int:
	return par + ceili(par * 0.5)

func two_star_limit() -> int:
	return par * 2 + 2

func calc_stars() -> int:
	var st := 1
	if moves <= three_star_limit():
		st = 3
	elif moves <= two_star_limit():
		st = 2
	st -= maxi(0, hints_used - 1)
	return clampi(st, 1, 3)

func show_card(stars: int = 3) -> void:
	set_stars(card_stars, stars)
	var r := "Hamle: %d   (3 yıldız için en fazla %d)" % [moves, three_star_limit()]
	if hints_used > 0:
		r += "   İpucu: %d (ilki bedava)" % hints_used
	card_result.text = r
	var info: Dictionary = LEVEL_INFO[level_index]
	if level_index == 0:
		card_title.text = "Eğitim tamamlandı!"
	else:
		card_title.text = "%d. Durak: %s" % [level_index, info["place"]]
	card_note.text = "%s: \"%s\"" % [eng_title(), info["note"]]
	card_fact.text = "Biliyor muydun? %s" % info["fact"]
	message_label.visible = false
	card.visible = true
	card.modulate.a = 0.0
	create_tween().tween_property(card, "modulate:a", 1.0, 0.3)
	waiting_card = true

func next_level() -> void:
	waiting_card = false
	card.visible = false
	total_moves += moves
	if level_index == LEVEL_INFO.size() - 1:
		start_ending()
		return
	level_index += 1
	if level_index >= LEVEL_INFO.size():
		level_index = 1
	load_level(level_index)

# Bölüm sonu kartını koddan kurar (sahneye elle bir şey eklemek gerekmez)
func build_card() -> void:
	card = PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.99, 0.95, 0.86)
	style.border_color = Color(0.25, 0.15, 0.19)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", style)
	card.position = Vector2(60, 50)
	card.custom_minimum_size = Vector2(360, 0)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	card_title = make_label(14, Color(0.25, 0.15, 0.19))
	card_note = make_label(10, Color(0.3, 0.2, 0.2))
	card_fact = make_label(10, Color(0.15, 0.35, 0.6))
	var hint := make_label(9, Color(0.5, 0.45, 0.45))
	hint.text = "Devam etmek için tıkla"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_stars = make_stars_row(20)
	card_result = make_label(9, Color(0.45, 0.4, 0.4))
	card_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(card_title)
	box.add_child(card_stars)
	box.add_child(card_result)
	for l in [card_note, card_fact, hint]:
		box.add_child(l)
	$UI.add_child(card)
	card.visible = false

func make_label(font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(340, 0)
	return l

func houses_done() -> bool:
	for p in grid:
		if grid[p]["type"] == "H" and (not powered.has(p) or dirty.has(p)):
			return false
	return true

# Karıştırılmış hal yanlışlıkla çözülmüş mü?
func is_solved() -> bool:
	powered = flood(["T", "G"])
	dirty = flood(["K"])
	return houses_done()

# Temiz enerjiyle yanan ev oranı: gökyüzü ve zemin buna göre iyileşir
func update_health() -> void:
	var houses := 0
	var clean := 0
	for p in grid:
		if grid[p]["type"] == "H":
			houses += 1
			if powered.has(p) and not dirty.has(p):
				clean += 1
	health = float(clean) / maxi(houses, 1)
	if sky:
		create_tween().tween_property(sky, "color", SKY_DIRTY.lerp(SKY_CLEAN, health), 0.5)

func update_ui() -> void:
	var target := "Hamle: %d / %d" % [moves, three_star_limit()]
	if level_index == 0:
		moves_label.text = "Öğretici   " + target
	else:
		moves_label.text = "%s   Bölüm %d / %d   %s" % [LEVEL_INFO[level_index]["place"], level_index, LEVEL_INFO.size() - 1, target]

# Her kare için sabit bir rastgele sayı (0-1): çizim her karede aynı kalsın diye
func cell_rand(p: Vector2i, salt: int) -> float:
	return float(absi(hash([p.x, p.y, level_index, salt])) % 10000) / 10000.0

func cable_color(p: Vector2i) -> Color:
	if dirty.has(p):
		return CABLE_DIRTY
	if powered.has(p):
		return CABLE_ON
	return CABLE_OFF

# Görseli karenin ortasına, kare boyutuna büyüterek ve döndürerek çizer
func draw_sprite(key: String, center: Vector2, angle: float = 0.0, col: Color = Color.WHITE, size_mult: float = 1.0) -> bool:
	if not tex.has(key):
		return false
	var t: Texture2D = tex[key]
	var s := TILE / float(t.get_width()) * size_mult
	draw_set_transform(center, angle, Vector2(s, s))
	draw_texture(t, -t.get_size() / 2, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true

# Gürültüden 0-1 arası değer: komşu kareler benzer değer alır, öbekler oluşur
func n01(p: Vector2i, offset: float) -> float:
	return clampf((noise.get_noise_2d(p.x + offset, p.y) + 1.0) * 0.5, 0.0, 1.0)

func green_at(p: Vector2i) -> bool:
	return health >= 1.0 or n01(p, 0.0) < health

func ground_key(p: Vector2i) -> String:
	# Her karenin bir "yeşerme eşiği" var: sağlık bu eşiği geçince çime döner
	if green_at(p):
		return "ground_flower" if cell_rand(p, 2) < FLOWER_CHANCE else "ground_grass"
	return "ground_dirt"

# ---------- Dünya: zemin, ağaçlar, deniz ----------
func is_sea(p: Vector2i) -> bool:
	if in_grid(p) or near_engineer(p):
		return false
	var sides: Array = LEVEL_INFO[level_index]["sea"]
	if sides.is_empty():
		return false
	# Kıyıya göre işaretli uzaklık: eksi = karanın içi, artı = denizin içi
	var dx := -INF
	var dy := -INF
	if "W" in sides:
		dx = maxf(dx, -p.x - margins["W"])
	if "E" in sides:
		dx = maxf(dx, p.x - (grid_size.x - 1) - margins["E"])
	if "N" in sides:
		dy = maxf(dy, -p.y - margins["N"])
	if "S" in sides:
		dy = maxf(dy, p.y - (grid_size.y - 1) - margins["S"])
	var depth := maxf(dx, dy)
	if dx > 0.0 and dy > 0.0:
		depth = Vector2(dx, dy).length()   # köşeler yuvarlak olsun
	# Gürültü kıyı çizgisini girintili çıkıntılı yapar
	return depth + (n01(p, 100.0) - 0.5) * 3.0 > 0.5

func near_engineer(p: Vector2i) -> bool:
	return p.x >= -2 and p.x < 0 and p.y >= grid_size.y - 2 and p.y <= grid_size.y

func in_grid(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < grid_size.x and p.y < grid_size.y

func draw_world() -> void:
	# Ekranın tamamını kaplayan kareleri dolaş
	var x0 := floori(-position.x / TILE) - 1
	var y0 := floori(-position.y / TILE) - 1
	var x1 := ceili((480.0 - position.x) / TILE) + 1
	var y1 := ceili((270.0 - position.y) / TILE) + 1
	var sea_key := "sea_1" if int(time * 2.0) % 2 == 0 else "sea_2"
	var trees: Array = []
	for y in range(y0, y1):
		for x in range(x0, x1):
			var p := Vector2i(x, y)
			var gc := Vector2(p) * TILE + HALF
			if is_sea(p):
				if not draw_sprite(sea_key, gc):
					draw_rect(Rect2(gc - HALF, Vector2(TILE, TILE)), Color(0.0, 0.6, 0.86))
				draw_foam(p, gc)
				continue
			if not draw_sprite(ground_key(p), gc) and not draw_sprite("ground_grass", gc):
				draw_rect(Rect2(gc - HALF, Vector2(TILE, TILE)), Color(0.15, 0.2, 0.15))
			if not in_grid(p) and not near_engineer(p) and cell_rand(p, 3) < TREE_CHANCE:
				trees.append(p)
	# Ağaçlar zeminden sonra çizilir ki sallanırken komşu kare üstlerini kesmesin
	for p in trees:
		draw_tree(p)

# Denizin karaya değdiği kenarlara ince köpük çizgisi
func draw_foam(p: Vector2i, gc: Vector2) -> void:
	var foam := Color(0.85, 0.96, 1.0, 0.85)
	var tl := gc - HALF
	if not is_sea(p + Vector2i(0, -1)):
		draw_rect(Rect2(tl, Vector2(TILE, 2)), foam)
	if not is_sea(p + Vector2i(0, 1)):
		draw_rect(Rect2(tl + Vector2(0, TILE - 2), Vector2(TILE, 2)), foam)
	if not is_sea(p + Vector2i(-1, 0)):
		draw_rect(Rect2(tl, Vector2(2, TILE)), foam)
	if not is_sea(p + Vector2i(1, 0)):
		draw_rect(Rect2(tl + Vector2(TILE - 2, 0), Vector2(2, TILE)), foam)

# Ağaç kökünün etrafında rüzgârda hafifçe sallanır
func draw_tree(p: Vector2i) -> void:
	var gc := Vector2(p) * TILE + HALF
	var alive := green_at(p)
	var sway := sin(time * 1.6 + cell_rand(p, 4) * TAU) * (0.06 if alive else 0.02)
	var root := gc + Vector2(0, 14)
	var center := root + (gc - root).rotated(sway)
	draw_sprite("tree" if alive else "tree_dead", center, sway)

# Kömür santrali bölüm boyunca tüter, bir eve bağlıyken duman yoğunlaşır
func draw_smoke(c: Vector2) -> void:
	var chimney := c + Vector2(-9, -14)
	var count := 4 if smoke_on else 2
	for i in range(count):
		var ph := fmod(time * 0.5 + float(i) / count, 1.0)
		var pos := chimney + Vector2(sin(ph * 6.0 + i) * 3.0, -ph * 26.0)
		var col := Color(1, 1, 1, (1.0 - ph) * (1.0 if smoke_on else 0.6))
		draw_sprite("smoke", pos, 0.0, col, 0.3 + ph * 0.4)

# Kirlilik pusu: temiz enerji arttıkça açılır
func draw_haze() -> void:
	var a := 0.4 * (1.0 - shown_health)
	if a > 0.01:
		draw_rect(Rect2(-position, Vector2(480, 270)), Color(0.28, 0.27, 0.3, a))

func _draw() -> void:
	draw_world()
	# Parçalar
	for p in grid:
		var cell: Dictionary = grid[p]
		var c := Vector2(p) * TILE + HALF
		var col := cable_color(p)
		var t: String = cell["type"]
		if t in CABLES:
			if cell["locked"]:
				# Bilge kedinin çevirdiği kablo hafifçe parlar
				var glow := Color(1.0, 0.85, 0.4, 0.45 + 0.25 * sin(time * 4.0))
				draw_rect(Rect2(c - HALF + Vector2(2, 2), Vector2(TILE - 4, TILE - 4)), glow, false, 2.0)
			if not draw_sprite(t, c, cell["angle"], col):
				var m := mask_of(cell)
				for d in DIRS:
					if (m & d) != 0:
						draw_line(c, c + Vector2(STEP[d]) * TILE / 2, col, 4)
			continue
		# Kaynak ve evlerin bağlantı ucu (bina dönmez, uç döner)
		var tip := c + Vector2(STEP[mask_of(cell)]) * TILE / 2
		draw_line(c, tip, OUTLINE, 8)
		draw_line(c, tip, col, 4)
		match t:
			"T":
				if draw_sprite("turbine_base", c):
					draw_sprite("turbine_blades", c, blade_angle)
				else:
					draw_circle(c, 9, Color.SKY_BLUE)
			"G":
				if not draw_sprite("solar", c):
					draw_circle(c, 9, Color.SKY_BLUE)
			"K":
				if not draw_sprite("coal", c):
					draw_circle(c, 9, Color.DIM_GRAY)
				if not won:
					draw_smoke(c)
			"H":
				var on: bool = powered.has(p) and not dirty.has(p)
				if not draw_sprite("house_on" if on else "house_off", c):
					draw_rect(Rect2(c - Vector2(8, 8), Vector2(16, 16)), Color.YELLOW if on else Color.SADDLE_BROWN)
	draw_haze()
	draw_engineer()

# Mühendis ızgaranın solunda bekler, bölüm bitince zıplar
func draw_engineer() -> void:
	if not started or not tex.has(engineer_key):
		return
	var base := Vector2(-48, grid_size.y * TILE - 26)
	var bob := sin(time * 3.0) * 1.5
	if won:
		bob = -absf(sin(time * 9.0)) * 10.0
	draw_sprite(engineer_key, base + Vector2(0, bob), 0.0, Color.WHITE, 1.5)
	draw_string(moves_label.get_theme_font("font"), base + Vector2(-40, 36), player_name if player_name != "" else "Mühendis",
		HORIZONTAL_ALIGNMENT_CENTER, 80, 8, Color.WHITE)

# ---------- Başlangıç ekranı: mühendis seçimi ve isim ----------
func build_start_screen() -> void:
	start_screen = Control.new()
	start_screen.position = Vector2.ZERO
	start_screen.size = Vector2(480, 270)
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.11, 0.17, 0.6)
	bg.size = Vector2(480, 270)
	start_screen.add_child(bg)
	var center := CenterContainer.new()
	center.size = Vector2(480, 270)
	start_screen.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	center.add_child(box)

	var title := make_label(18, Color(1.0, 0.82, 0.3))
	title.text = "Mühendisini seç"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub := make_label(10, Color(0.85, 0.88, 0.95))
	sub.text = "Vadiye temiz enerji getirecek mühendis kim olsun?"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	girl_btn = make_engineer_button("engineer_girl")
	boy_btn = make_engineer_button("engineer_boy")
	row.add_child(girl_btn)
	row.add_child(boy_btn)

	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Adını yaz"
	name_edit.max_length = 12
	name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_edit.add_theme_font_size_override("font_size", 10)
	name_edit.custom_minimum_size = Vector2(140, 0)
	name_edit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	name_edit.text_submitted.connect(func(_t: String): start_game())
	box.add_child(name_edit)

	var start_btn := Button.new()
	start_btn.text = "Başla"
	style_button(start_btn, 12)
	start_btn.custom_minimum_size = Vector2(100, 0)
	start_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_btn.pressed.connect(start_game)
	box.add_child(start_btn)

	$UI.add_child(start_screen)
	select_engineer("engineer_girl")

func make_engineer_button(key: String) -> TextureButton:
	var b := TextureButton.new()
	if tex.has(key):
		b.texture_normal = tex[key]
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = Vector2(64, 64)
	b.pressed.connect(func(): select_engineer(key))
	return b

func select_engineer(key: String) -> void:
	engineer_key = key
	# Seçili olan parlak, diğeri soluk görünür
	girl_btn.modulate = Color.WHITE if key == "engineer_girl" else Color(0.45, 0.45, 0.5)
	boy_btn.modulate = Color.WHITE if key == "engineer_boy" else Color(0.45, 0.45, 0.5)

func start_game() -> void:
	if mode != "select":
		return
	var n := name_edit.text.strip_edges()
	if n != "":
		player_name = n
	if intro_seen:
		set_mode("countries")
	else:
		start_intro()

# ---------- Giriş ve bitiş: uzaktan vadi ----------
const OV_W := 30   # harita 16 piksellik karelerle ekranı kaplar
const OV_H := 17
const OV_VILLAGES := [Vector2i(7, 3), Vector2i(13, 5), Vector2i(20, 3), Vector2i(25, 7),
	Vector2i(9, 10), Vector2i(16, 11), Vector2i(23, 12)]
const OV_COAL := [Vector2i(11, 8), Vector2i(19, 8), Vector2i(27, 3)]

func build_overview() -> void:
	overview_layer = CanvasLayer.new()
	overview_layer.layer = 1
	add_child(overview_layer)
	$UI.layer = 2
	overview = Node2D.new()
	overview_layer.add_child(overview)
	overview.draw.connect(_draw_overview)
	overview_layer.visible = false
	# Harita her oyunda aynı: giriş ve bitiş aynı vadiyi gösterir
	ov_noise.seed = 2026
	ov_noise.frequency = 0.15
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for k in range(OV_VILLAGES.size()):
		var v: Vector2i = OV_VILLAGES[k]
		ov_features[v] = "H"
		ov_features[v + Vector2i(1, 1)] = "H"
		ov_features[v + Vector2i(-1, 1)] = "T" if k % 2 == 0 else "G"
	for c in OV_COAL:
		ov_features[c] = "K"
	var placed := 0
	while placed < 45:
		var p := Vector2i(rng.randi_range(0, OV_W - 1), rng.randi_range(0, OV_H - 1))
		if ov_features.has(p) or ov_sea(p):
			continue
		ov_features[p] = "tree"
		placed += 1

func ov_n01(p: Vector2i, offset: float) -> float:
	return clampf((ov_noise.get_noise_2d(p.x + offset, p.y) + 1.0) * 0.5, 0.0, 1.0)

# Batıda Ege, güneyde Akdeniz gibi girintili kıyılar
func ov_sea(p: Vector2i) -> bool:
	var j := (ov_n01(p, 50.0) - 0.5) * 4.0
	return p.x + j < 3.0 or p.y - j > 14.5

func ov_sprite(key: String, center: Vector2, angle: float = 0.0, col: Color = Color.WHITE, size: float = 1.0) -> void:
	if not tex.has(key):
		return
	var t: Texture2D = tex[key]
	var sc := 16.0 / t.get_width() * size
	overview.draw_set_transform(center, angle, Vector2(sc, sc))
	overview.draw_texture(t, -t.get_size() / 2, col)
	overview.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_overview() -> void:
	var sea_key := "sea_1" if int(time * 2.0) % 2 == 0 else "sea_2"
	var foam := Color(0.85, 0.96, 1.0, 0.85)
	for y in range(OV_H):
		for x in range(OV_W):
			var p := Vector2i(x, y)
			var c := Vector2(p) * 16 + Vector2(8, 8)
			if ov_sea(p):
				ov_sprite(sea_key, c)
				var tl := c - Vector2(8, 8)
				if y > 0 and not ov_sea(p + Vector2i(0, -1)):
					overview.draw_rect(Rect2(tl, Vector2(16, 1)), foam)
				if x < OV_W - 1 and not ov_sea(p + Vector2i(1, 0)):
					overview.draw_rect(Rect2(tl + Vector2(15, 0), Vector2(1, 16)), foam)
				continue
			var green := ov_health >= 1.0 or ov_n01(p, 0.0) < ov_health
			var g := "ground_dirt"
			if green:
				g = "ground_flower" if cell_rand(p, 9) < FLOWER_CHANCE else "ground_grass"
			ov_sprite(g, c)
	for p in ov_features:
		var c := Vector2(p) * 16 + Vector2(8, 8)
		var f: String = ov_features[p]
		var healed := ov_health >= 0.95
		match f:
			"tree":
				var alive := ov_health >= 1.0 or ov_n01(p, 0.0) < ov_health
				var sway := sin(time * 1.6 + cell_rand(p, 4) * TAU) * (0.06 if alive else 0.02)
				var root := c + Vector2(0, 7)
				ov_sprite("tree" if alive else "tree_dead", root + (c - root).rotated(sway), sway)
			"H":
				ov_sprite("house_on" if healed else "house_off", c)
			"K":
				if healed:
					ov_sprite("turbine_base", c)
					ov_sprite("turbine_blades", c, blade_angle)
				else:
					ov_sprite("coal", c)
					for i in range(3):
						var ph := fmod(time * 0.5 + i / 3.0, 1.0)
						var sp := c + Vector2(-4.5, -7) + Vector2(sin(ph * 6.0 + i) * 2.0, -ph * 14.0)
						ov_sprite("smoke", sp, 0.0, Color(1, 1, 1, 1.0 - ph), 0.5 + ph * 0.5)
			"T":
				if healed:
					ov_sprite("turbine_base", c)
					ov_sprite("turbine_blades", c, blade_angle)
			"G":
				if healed:
					ov_sprite("solar", c)
	# Kirlilik pusu
	var a := 0.45 * (1.0 - ov_health)
	if a > 0.01:
		overview.draw_rect(Rect2(Vector2.ZERO, Vector2(480, 270)), Color(0.28, 0.27, 0.3, a))
	# Maskotlar: başlıkta ikisi birden, hikâyede seçilen mühendis
	var bob := sin(time * 3.0) * 1.5
	if mode == "title":
		ov_sprite("engineer_girl", Vector2(204, 178 + bob), 0.0, Color.WHITE, 3.0)
		ov_sprite("engineer_boy", Vector2(276, 178 - bob), 0.0, Color.WHITE, 3.0)
		# Bilge kedi mühendislerin arasında, ara sıra zıplar
		var hop := -absf(sin(time * 2.2)) * 6.0 if fmod(time, 4.0) < 1.4 else 0.0
		ov_sprite("cat", Vector2(240, 192 + hop), 0.0, Color.WHITE, 2.0)
	elif mode == "intro" or mode == "ending":
		if mode == "ending" and ov_health >= 0.95:
			bob = -absf(sin(time * 9.0)) * 10.0
		ov_sprite(engineer_key, Vector2(44, 168 + bob), 0.0, Color.WHITE, 3.0)

# Kamera uzaktan bakıyormuş gibi yavaşça geri çekilir
func zoom_out_overview() -> void:
	overview.scale = Vector2(1.35, 1.35)
	overview.position = Vector2(240, 135) - Vector2(240, 135) * 1.35
	var tw := create_tween().set_parallel()
	tw.tween_property(overview, "scale", Vector2.ONE, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(overview, "position", Vector2.ZERO, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func build_story_panel() -> void:
	story_panel = PanelContainer.new()
	story_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.99, 0.95, 0.86, 0.95)
	style.border_color = Color(0.25, 0.15, 0.19)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	story_panel.add_theme_stylebox_override("panel", style)
	story_panel.position = Vector2(92, 196)
	story_panel.custom_minimum_size = Vector2(376, 0)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	story_panel.add_child(box)
	story_label = make_label(11, Color(0.25, 0.15, 0.19))
	story_label.custom_minimum_size = Vector2(360, 0)
	story_hint = make_label(8, Color(0.5, 0.45, 0.45))
	story_hint.custom_minimum_size = Vector2(360, 0)
	story_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	story_hint.text = "Devam etmek için tıkla"
	replay_btn = Button.new()
	replay_btn.text = "Bölümlere Dön"
	style_button(replay_btn, 11)
	replay_btn.add_theme_font_size_override("font_size", 11)
	replay_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	replay_btn.pressed.connect(replay)
	box.add_child(story_label)
	box.add_child(story_hint)
	box.add_child(replay_btn)
	$UI.add_child(story_panel)
	story_panel.visible = false

# Kutu yazı uzunluğuna göre büyür; alt kenardan taşmasın
func fit_story_panel() -> void:
	story_panel.reset_size()
	story_panel.position.y = 264.0 - story_panel.size.y

func show_story(pages: Array) -> void:
	story_pages = pages
	story_page = 0
	story_label.text = story_pages[0]
	story_hint.visible = true
	replay_btn.visible = false
	fit_story_panel.call_deferred()
	story_panel.visible = true
	story_panel.modulate.a = 0.0
	create_tween().tween_property(story_panel, "modulate:a", 1.0, 0.5)

func advance_story() -> void:
	if story_page >= story_pages.size() - 1:
		if mode == "intro":
			finish_intro()
		elif mode == "ending":
			show_credits("levels")
		return
	story_page += 1
	story_label.text = story_pages[story_page]
	fit_story_panel.call_deferred()

func start_intro() -> void:
	set_mode("intro")
	# Başlıktaki yeşil vadi gözümüzün önünde kurur
	ov_health = 1.0
	zoom_out_overview()
	var tw := create_tween()
	tw.tween_property(self, "ov_health", 0.0, 3.0)
	show_story([
		"Bir zamanlar yemyeşil olan vadide ışıklar birer birer söndü.",
		"Kömür santrallerinin dumanı gökyüzünü kararttı. Topraklar kurudu, ağaçlar yapraklarını döktü.",
		"%s, vadinin umudu sensin! Rüzgârı ve güneşi kasabalara ulaştır, vadiyi yeniden canlandır." % eng_title(),
	])

func finish_intro() -> void:
	intro_seen = true
	save_game()
	set_mode("countries")

func start_ending() -> void:
	set_mode("ending")
	ov_health = 0.0
	zoom_out_overview()
	# Vadi gözümüzün önünde iyileşir
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(self, "ov_health", 1.0, 3.5)
	tw.tween_callback(show_ending_story)

func show_ending_story() -> void:
	if mode != "ending":
		return
	show_story([
		"Başardın, %s!" % eng_title(),
		"Rüzgâr ve güneş bütün vadiyi aydınlatıyor. Topraklar yeşerdi, ağaçlar yeniden canlandı.",
		"Vadi yeniden nefes alıyor. Toplam hamle: %d. Teşekkürler, %s!" % [total_moves, eng_title()],
	])

func replay() -> void:
	total_moves = 0
	set_mode("levels")

# ---------- Ekran yönetimi ----------
func set_mode(m: String) -> void:
	mode = m
	started = m == "play"
	paused = false
	title_screen.visible = m == "title"
	start_screen.visible = m == "select"
	countries_screen.visible = m == "countries"
	levels_screen.visible = m == "levels"
	credits_screen.visible = m == "credits"
	hud.visible = m == "play"
	moves_label.visible = m == "play"
	pause_screen.visible = false
	hide_cat()
	if m != "play":
		message_label.visible = false
		card.visible = false
		waiting_card = false
	if m != "intro" and m != "ending":
		story_panel.visible = false
	overview_layer.visible = m != "play"
	overview.modulate.a = 1.0
	if m == "title" or m == "select":
		ov_health = 1.0
		overview.scale = Vector2.ONE
		overview.position = Vector2.ZERO
	elif m == "countries" or m == "levels":
		ov_health = float(total_stars()) / 21.0   # vadi ilerledikçe yeşerir
		overview.scale = Vector2.ONE
		overview.position = Vector2.ZERO
	if m == "select":
		name_edit.grab_focus.call_deferred()
	play_music("level" if m == "play" else "menu")
	if m == "countries":
		countries_star_label.text = "%d / 21" % total_stars()
	if m == "levels":
		refresh_levels()

func play_level(i: int) -> void:
	level_index = i
	total_moves = 0
	card.visible = false
	waiting_card = false
	set_mode("play")
	load_level(i)

# İsim yazılmadıysa sadece "Mühendis" der
func eng_title() -> String:
	return "Mühendis" if player_name == "" else "Mühendis " + player_name

func total_stars() -> int:
	var t := 0
	for i in range(1, LEVEL_INFO.size()):
		t += best_stars.get(i, 0)
	return t

func is_unlocked(i: int) -> bool:
	return i == 0 or best_stars.has(i - 1)

# ---------- Kayıt ----------
func load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for i in range(LEVEL_INFO.size()):
		var v: int = cfg.get_value("stars", str(i), 0)
		if v > 0:
			best_stars[i] = v
	music_on = cfg.get_value("settings", "music", true)
	intro_seen = cfg.get_value("settings", "intro_seen", false)

# Yanlışlıkla basılmasın diye iki kez basmak gerekir
func ask_reset() -> void:
	if not reset_armed:
		reset_armed = true
		reset_btn.text = "Emin misin? Tekrar bas"
		await get_tree().create_timer(3.0).timeout
		reset_armed = false
		reset_btn.text = "İlerlemeyi Sıfırla"
		return
	reset_armed = false
	reset_btn.text = "İlerlemeyi Sıfırla"
	best_stars.clear()
	intro_seen = false
	total_moves = 0
	save_game()
	set_mode("countries")

func save_game() -> void:
	var cfg := ConfigFile.new()
	for i in best_stars:
		cfg.set_value("stars", str(i), best_stars[i])
	cfg.set_value("settings", "music", music_on)
	cfg.set_value("settings", "intro_seen", intro_seen)
	cfg.save(SAVE_PATH)

# ---------- Arayüz yardımcıları ----------
func style_button(b: Button, font_size: int = 11) -> void:
	b.add_theme_font_size_override("font_size", font_size)
	var colors := {"normal": PAPER, "hover": Color(1.0, 0.88, 0.6), "pressed": Color(0.99, 0.75, 0.4),
		"disabled": Color(0.62, 0.62, 0.68)}
	for st in colors:
		var sb := StyleBoxFlat.new()
		sb.bg_color = colors[st]
		sb.border_color = DARK
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(4)
		sb.set_content_margin_all(4)
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, DARK)
	b.add_theme_color_override("font_disabled_color", Color(0.35, 0.33, 0.38))

func make_button(text: String, font_size: int, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	style_button(b, font_size)
	b.pressed.connect(callback)
	return b

# Ekran genişliğinde, ortalanmış, kenarlıklı yazı
func make_text(text: String, font_size: int, col: Color, y: float) -> Label:
	var l := Label.new()
	l.text = text
	l.position = Vector2(0, y)
	l.size = Vector2(480, font_size + 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", DARK)
	l.add_theme_constant_override("outline_size", maxi(4, font_size / 4))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func make_icon(key: String, px: int) -> TextureRect:
	var r := TextureRect.new()
	if tex.has(key):
		r.texture = tex[key]
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(px, px)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

func make_stars_row(px: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 2)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k in range(3):
		row.add_child(make_icon("star_off", px))
	return row

func set_stars(row: HBoxContainer, n: int) -> void:
	for k in range(3):
		var r: TextureRect = row.get_child(k)
		var key := "star_on" if k < n else "star_off"
		if tex.has(key):
			r.texture = tex[key]

func full_screen_control() -> Control:
	var c := Control.new()
	c.position = Vector2.ZERO
	c.size = Vector2(480, 270)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

# ---------- Başlık ekranı ----------
func build_title_screen() -> void:
	title_screen = full_screen_control()
	title_screen.add_child(make_text("Rüzgâr Yolu", 40, Color(1.0, 0.82, 0.3), 36))
	title_screen.add_child(make_text("Temiz enerjiyle vadiyi kurtar", 12, Color.WHITE, 88))
	var hint := make_text("Başlamak için tıkla", 11, Color.WHITE, 236)
	title_screen.add_child(hint)
	var tw := create_tween().set_loops()
	tw.tween_property(hint, "modulate:a", 0.3, 0.8)
	tw.tween_property(hint, "modulate:a", 1.0, 0.8)
	$UI.add_child(title_screen)

# ---------- Ülke seçimi ----------
func build_countries_screen() -> void:
	countries_screen = full_screen_control()
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.11, 0.17, 0.35)
	dim.size = Vector2(480, 270)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	countries_screen.add_child(dim)
	countries_screen.add_child(make_text("Bir ülke seç", 20, Color(1.0, 0.82, 0.3), 16))
	countries_screen.add_child(make_text("COP31'e katılan ülkeleri temiz enerjiyle buluştur", 10, Color.WHITE, 44))
	var row := HBoxContainer.new()
	row.position = Vector2(16, 84)
	row.size = Vector2(448, 110)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	countries_screen.add_child(row)
	for c in COUNTRIES:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		var b := make_button(c["name"], 12, func(): set_mode("levels"))
		b.custom_minimum_size = Vector2(100, 64)
		b.disabled = not c["open"]
		col.add_child(b)
		var info := HBoxContainer.new()
		info.alignment = BoxContainer.ALIGNMENT_CENTER
		info.add_theme_constant_override("separation", 3)
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_color_override("font_outline_color", DARK)
		lbl.add_theme_constant_override("outline_size", 4)
		if c["open"]:
			info.add_child(make_icon("star_on", 12))
			countries_star_label = lbl
		else:
			info.add_child(make_icon("lock", 12))
			lbl.text = "Yakında"
		info.add_child(lbl)
		col.add_child(info)
		row.add_child(col)
	var back := make_button("Ana Sayfa", 10, func(): set_mode("title"))
	back.position = Vector2(10, 236)
	countries_screen.add_child(back)
	var cred := make_button("Emeği Geçenler", 10, func(): show_credits("countries"))
	cred.position = Vector2(176, 236)
	countries_screen.add_child(cred)
	reset_btn = make_button("İlerlemeyi Sıfırla", 10, ask_reset)
	reset_btn.position = Vector2(318, 236)
	reset_btn.custom_minimum_size = Vector2(152, 0)
	countries_screen.add_child(reset_btn)
	$UI.add_child(countries_screen)

# ---------- Bölüm seçimi ----------
func build_levels_screen() -> void:
	levels_screen = full_screen_control()
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.11, 0.17, 0.35)
	dim.size = Vector2(480, 270)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	levels_screen.add_child(dim)
	levels_header = make_text("Türkiye", 20, Color(1.0, 0.82, 0.3), 12)
	levels_screen.add_child(levels_header)
	levels_grid = GridContainer.new()
	levels_grid.columns = 4
	levels_grid.position = Vector2(36, 52)
	levels_grid.add_theme_constant_override("h_separation", 12)
	levels_grid.add_theme_constant_override("v_separation", 10)
	levels_screen.add_child(levels_grid)
	var back := make_button("Geri", 10, func(): set_mode("countries"))
	back.position = Vector2(10, 236)
	levels_screen.add_child(back)
	$UI.add_child(levels_screen)

func refresh_levels() -> void:
	levels_header.text = "Türkiye   %d / 21" % total_stars()
	for ch in levels_grid.get_children():
		levels_grid.remove_child(ch)
		ch.queue_free()
	for i in range(LEVEL_INFO.size()):
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 3)
		var label := "Öğretici" if i == 0 else "%d\n%s" % [i, LEVEL_INFO[i]["place"]]
		var idx := i
		var b := make_button(label, 10, func(): play_level(idx))
		b.custom_minimum_size = Vector2(90, 54)
		b.disabled = not is_unlocked(i)
		col.add_child(b)
		if is_unlocked(i):
			var row := make_stars_row(14)
			set_stars(row, best_stars.get(i, 0))
			col.add_child(row)
		else:
			var lock_row := HBoxContainer.new()
			lock_row.alignment = BoxContainer.ALIGNMENT_CENTER
			lock_row.add_child(make_icon("lock", 14))
			col.add_child(lock_row)
		levels_grid.add_child(col)

# ---------- Oyun içi: ipucu ve duraklatma butonları ----------
func build_hud() -> void:
	hud = HBoxContainer.new()
	hud.position = Vector2(352, 4)
	hud.size = Vector2(124, 20)
	hud.alignment = BoxContainer.ALIGNMENT_END
	hud.add_theme_constant_override("separation", 4)
	hint_btn = make_button("İpucu (2)", 9, use_hint)
	var pause_btn := make_button("II", 9, toggle_pause)
	pause_btn.custom_minimum_size = Vector2(22, 0)
	hud.add_child(hint_btn)
	hud.add_child(pause_btn)
	$UI.add_child(hud)

func update_hud() -> void:
	if hint_btn:
		hint_btn.text = "İpucu (%d)" % hints_left
		hint_btn.disabled = hints_left <= 0

# Bilge kedi: yanlış duran bir kabloyu doğru yöne çevirip kilitler
func use_hint() -> void:
	if mode != "play" or paused or won or waiting_card or hints_left <= 0:
		return
	var wrong: Array = []
	for p in grid:
		var cell: Dictionary = grid[p]
		if cell["type"] in CABLES and not cell["locked"] and mask_of(cell) != cell["sol"]:
			wrong.append(p)
	if wrong.is_empty():
		show_cat("Her şey yolunda görünüyor. Enerji akmıyorsa başka bir yolu dene!")
		return
	var cell: Dictionary = grid[wrong.pick_random()]
	for k in range(4):
		if mask_of(cell) == cell["sol"]:
			break
		rotate_cell(cell)
	cell["locked"] = true
	hints_left -= 1
	hints_used += 1
	update_hud()
	show_cat(CAT_LINES.pick_random())
	update_power()

func build_cat_bubble() -> void:
	cat_bubble = PanelContainer.new()
	cat_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = DARK
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(4)
	cat_bubble.add_theme_stylebox_override("panel", style)
	cat_bubble.position = Vector2(236, 214)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cat_bubble.add_child(row)
	# Kedi bir kutunun içinde: zıplarken yazılar kaymasın
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(40, 40)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cat_icon = make_icon("cat", 40)
	cat_icon.size = Vector2(40, 40)
	holder.add_child(cat_icon)
	row.add_child(holder)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)
	cat_label = Label.new()
	cat_label.add_theme_font_size_override("font_size", 9)
	cat_label.add_theme_color_override("font_color", DARK)
	cat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cat_label.custom_minimum_size = Vector2(180, 0)
	col.add_child(cat_label)
	offer_row = HBoxContainer.new()
	offer_row.add_theme_constant_override("separation", 6)
	offer_row.add_child(make_button("Evet", 9, accept_hint_offer))
	offer_row.add_child(make_button("Hayır", 9, hide_cat))
	col.add_child(offer_row)
	$UI.add_child(cat_bubble)
	cat_bubble.visible = false

# Kedi konuşur. offer = true ise Evet/Hayır sorar ve cevap gelene kadar zıplar.
func show_cat(text: String, offer: bool = false) -> void:
	hide_cat()
	cat_label.text = text
	offer_row.visible = offer
	cat_bubble.visible = true
	cat_bubble.modulate.a = 0.0
	fit_cat_bubble.call_deferred()
	cat_tween = create_tween()
	cat_tween.tween_property(cat_bubble, "modulate:a", 1.0, 0.25)
	if offer:
		cat_jump = create_tween().set_loops()
		cat_jump.tween_property(cat_icon, "position:y", -8.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		cat_jump.tween_property(cat_icon, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		cat_jump.tween_interval(0.35)
	else:
		cat_tween.tween_interval(3.5)
		cat_tween.tween_property(cat_bubble, "modulate:a", 0.0, 0.4)
		cat_tween.tween_callback(hide_cat)

func hide_cat() -> void:
	if cat_tween:
		cat_tween.kill()
	if cat_jump:
		cat_jump.kill()
	if cat_icon:
		cat_icon.position.y = 0.0
	if cat_bubble:
		cat_bubble.visible = false

# Kutu içeriğine göre büyür; alt kenardan taşmasın
func fit_cat_bubble() -> void:
	cat_bubble.reset_size()
	cat_bubble.position = Vector2(474.0 - cat_bubble.size.x, 266.0 - cat_bubble.size.y)

# Hamle sınırı geçilince kedi bir kez gelip ipucu önerir
func maybe_offer_hint() -> void:
	if hint_offered or won or hints_left <= 0 or moves <= three_star_limit():
		return
	hint_offered = true
	var cost := "İlki benden, bedava!" if hints_used == 0 else "Ama bu ipucu bir yıldız götürür."
	show_cat("Miyav! Biraz zorlandın gibi. İpucu ister misin? %s" % cost, true)

func accept_hint_offer() -> void:
	hide_cat()
	use_hint()

# ---------- Duraklatma ----------
func build_pause_screen() -> void:
	pause_screen = full_screen_control()
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.11, 0.17, 0.7)
	dim.size = Vector2(480, 270)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP   # arkadaki oyuna tıklanmasın
	pause_screen.add_child(dim)
	pause_screen.add_child(make_text("Duraklatıldı", 22, Color(1.0, 0.82, 0.3), 40))
	var box := VBoxContainer.new()
	box.position = Vector2(160, 80)
	box.size = Vector2(160, 160)
	box.add_theme_constant_override("separation", 8)
	pause_screen.add_child(box)
	box.add_child(make_button("Devam Et", 11, toggle_pause))
	box.add_child(make_button("Bölümü Baştan Başlat", 11, restart_level))
	box.add_child(make_button("Bölüm Seçimi", 11, func(): set_mode("levels")))
	box.add_child(make_button("Ana Sayfa", 11, func(): set_mode("title")))
	music_btn = make_button("Müzik: Açık", 11, toggle_music)
	box.add_child(music_btn)
	$UI.add_child(pause_screen)
	pause_screen.visible = false

# Aynı bulmacayı en baştaki karışık haliyle yeniden kurar
func restart_level() -> void:
	grid = start_grid.duplicate(true)
	moves = 0
	won = false
	hints_left = MAX_HINTS
	hints_used = 0
	hint_offered = false
	waiting_card = false
	card.visible = false
	hide_cat()
	paused = false
	pause_screen.visible = false
	if level_index == 0:
		message_label.text = "Kablolara tıklayıp çevir, enerjiyi eve ulaştır!"
		message_label.visible = true
	else:
		message_label.visible = false
	update_hud()
	update_ui()
	update_power()

func toggle_pause() -> void:
	if mode != "play":
		return
	paused = not paused
	pause_screen.visible = paused

# ---------- Müzik ----------
# audio/ klasörüne anasayfa.mp3 (menüler) ve bolum.mp3 (oyun) koyman yeterli. .ogg ve .wav da olur.
const MUSIC_FILES := {"menu": "anasayfa", "level": "bolum"}

func setup_music() -> void:
	music = AudioStreamPlayer.new()
	add_child(music)
	for key in MUSIC_FILES:
		for ext in [".ogg", ".mp3", ".wav"]:
			var path: String = "res://audio/" + MUSIC_FILES[key] + ext
			if ResourceLoader.exists(path):
				var st: AudioStream = load(path)
				if "loop" in st:
					st.loop = true
				music_tracks[key] = st
				break
		if not music_tracks.has(key):
			print("Müzik bulunamadı: audio/", MUSIC_FILES[key], " (.ogg/.mp3/.wav)")
	apply_music()

func start_track() -> void:
	music.stream = music_tracks[music_current]
	music.play()

# Ekran değişince doğru müziğe yumuşakça geçer
func play_music(key: String) -> void:
	if key == music_current or not music_tracks.has(key):
		return
	music_current = key
	var tw := create_tween()
	if music.playing:
		tw.tween_property(music, "volume_db", -40.0, 0.4)
	tw.tween_callback(start_track)
	tw.tween_property(music, "volume_db", 0.0, 0.6)

func toggle_music() -> void:
	music_on = not music_on
	apply_music()
	save_game()

func apply_music() -> void:
	AudioServer.set_bus_mute(0, not music_on)
	music_btn.text = "Müzik: Açık" if music_on else "Müzik: Kapalı"

# ---------- Emeği geçenler (jenerik) ----------
func build_credits_screen() -> void:
	credits_screen = full_screen_control()
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.11, 0.17, 0.72)
	dim.size = Vector2(480, 270)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credits_screen.add_child(dim)
	credits_box = VBoxContainer.new()
	credits_box.position = Vector2(30, 270)
	credits_box.custom_minimum_size = Vector2(420, 0)
	credits_box.add_theme_constant_override("separation", 6)
	credits_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credits_screen.add_child(credits_box)
	credits_back = make_button("Geri Dön", 10, func(): set_mode(credits_return))
	credits_back.position = Vector2(400, 238)
	credits_screen.add_child(credits_back)
	$UI.add_child(credits_screen)
	credits_screen.visible = false

func credit_line(text: String, font_size: int, col: Color) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(420, 0)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", DARK)
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	credits_box.add_child(l)

func fill_credits() -> void:
	for ch in credits_box.get_children():
		credits_box.remove_child(ch)
		ch.queue_free()
	var gold := Color(1.0, 0.82, 0.3)
	var white := Color.WHITE
	var soft := Color(0.85, 0.88, 0.95)
	credit_line("Rüzgâr Yolu", 26, gold)
	credit_line("GameUP Türkiye Oyun Hackathonu · COP31 iklim teması", 10, soft)
	credit_line(" ", 6, white)
	credit_line("Emeği Geçenler", 16, gold)
	if not DEVELOPERS.is_empty():
		credit_line("Oyun tasarımı, pixel art ve geliştirme", 9, soft)
		for dev in DEVELOPERS:
			credit_line(dev, 13, white)
	credit_line("Yapay zekâ desteği", 9, soft)
	credit_line("Kodlama, bölüm üretici ve pixel art haritalarının tasarımında yapay zekâ asistanı Claude'dan (Anthropic) destek alındı.", 10, white)
	credit_line("Görsel tarz", 9, soft)
	credit_line("Pixel art'lar elle çizildi. Renk paleti ve tarzda Kenney'nin Tiny Town paketinden (kenney.nl, CC0) ilham alındı.", 10, white)
	credit_line("Yazı tipi", 9, soft)
	credit_line("Pixelify Sans (SIL Open Font License)", 10, white)
	credit_line("Oyun motoru", 9, soft)
	credit_line("Godot Engine (MIT lisansı)", 10, white)
	if MUSIC_CREDIT != "":
		credit_line("Müzik", 9, soft)
		credit_line(MUSIC_CREDIT, 10, white)
	credit_line("Bilgiler", 9, soft)
	credit_line("Bölüm sonu bilgileri kamuya açık kaynaklardan derlendi.", 10, white)
	credit_line(" ", 6, white)
	credit_line("Oynadığın için teşekkürler, %s!" % eng_title(), 14, gold)

# Yazılar sinema jeneriği gibi aşağıdan yukarı kayar
func show_credits(return_to: String) -> void:
	credits_return = return_to
	credits_back.text = "Bölümlere Dön" if return_to == "levels" else "Geri Dön"
	set_mode("credits")
	ov_health = 1.0
	fill_credits()
	credits_back.visible = false
	credits_box.position.y = 270.0
	start_credits_scroll.call_deferred()

func start_credits_scroll() -> void:
	credits_box.reset_size()
	var end_y := minf(20.0, 230.0 - credits_box.size.y)
	if credits_tween:
		credits_tween.kill()
	credits_tween = create_tween()
	credits_tween.tween_property(credits_box, "position:y", end_y, 14.0)
	credits_tween.tween_callback(func(): credits_back.visible = true)

# Tıklayınca jenerik sona atlar
func skip_credits() -> void:
	if credits_tween and credits_tween.is_running():
		credits_tween.custom_step(100.0)
