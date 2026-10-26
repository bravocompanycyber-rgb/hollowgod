extends Control
# A row of choice cards (gifts, bargains, shop, summaries). Pick with keys 1-5 or by clicking.
# Each option: {name, tag, tag_color, border, desc, foot, disabled}

signal picked(index)
signal closed

var options = []
var title_text = ""
var subtitle_text = ""
var extra_text = ""
var footer_text = ""
var allow_close = false
var skip = true

func _init():
    rect_size = Vector2(1280, 720)
    mouse_filter = Control.MOUSE_FILTER_STOP

func setup(title, subtitle, opts, can_close = false, extra = ""):
    title_text = title
    subtitle_text = subtitle
    options = opts
    allow_close = can_close
    extra_text = extra
    rebuild()

func rebuild():
    for c in get_children():
        c.queue_free()
    var dim = ColorRect.new()
    dim.rect_size = Vector2(1280, 720)
    dim.color = Color(0, 0, 0, 0.68)
    dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(dim)
    var t = FX.label(self, Vector2(0, 92), title_text, 32, Color(0.95, 0.78, 0.3), true)
    t.rect_size = Vector2(1280, 40)
    t.align = Label.ALIGN_CENTER
    var st = FX.label(self, Vector2(0, 142), subtitle_text, 18, Color(0.92, 0.92, 0.95))
    st.rect_size = Vector2(1280, 24)
    st.align = Label.ALIGN_CENTER
    if extra_text != "":
        var ex = FX.label(self, Vector2(880, 28), extra_text, 20, Color(0.5, 0.9, 1.0))
        ex.rect_size = Vector2(360, 26)
        ex.align = Label.ALIGN_RIGHT
    var n = options.size()
    var w = 560.0 if n == 1 else min(250.0, (1120.0 - (n - 1) * 16.0) / n)
    var gap = 16.0
    var h = 270.0
    var x0 = (1280.0 - (n * w + (n - 1) * gap)) / 2.0
    for i in range(n):
        var o = options[i]
        var disabled = o.get("disabled", false)
        var border = o.get("border", Color(0.7, 0.55, 0.2))
        var b = Button.new()
        b.rect_position = Vector2(x0 + i * (w + gap), 215)
        b.rect_size = Vector2(w, h)
        b.focus_mode = Control.FOCUS_NONE
        b.disabled = disabled
        var dim_border = Color(border.r * 0.5, border.g * 0.5, border.b * 0.5)
        b.add_stylebox_override("normal", FX.card_style(Color(0.08, 0.08, 0.14, 0.97), border if not disabled else dim_border))
        b.add_stylebox_override("hover", FX.card_style(Color(0.16, 0.14, 0.24, 0.98), Color(1.0, 0.85, 0.4)))
        b.add_stylebox_override("pressed", FX.card_style(Color(0.24, 0.2, 0.3), Color(1.0, 0.95, 0.6)))
        b.add_stylebox_override("disabled", FX.card_style(Color(0.06, 0.06, 0.09, 0.9), dim_border))
        add_child(b)
        b.connect("pressed", self, "_on_pressed", [i])
        var alpha = 0.45 if disabled else 1.0
        var hdr_text = o["name"]
        if n > 1:
            hdr_text = "[%d] %s" % [i + 1, o["name"]]
        var cpl = max(8.0, (w - 28.0) / 11.0)
        var lines = int(ceil(float(hdr_text.length()) / cpl))
        var off = (lines - 1) * 24
        var hdr = FX.label(b, Vector2(14, 14), hdr_text, 19, Color(1.0, 0.92, 0.65, alpha), true)
        hdr.autowrap = true
        hdr.rect_size = Vector2(w - 28, 26 * lines)
        if o.get("tag", "") != "":
            var tg = FX.label(b, Vector2(14, 46 + off), o["tag"], 14, o.get("tag_color", Color(0.8, 0.8, 0.85)))
            tg.modulate.a = alpha
        var dtext = o.get("desc", "")
        var dsize = 16 if dtext.length() <= 150 or n == 1 else 14
        var d = FX.label(b, Vector2(14, 78 + off), dtext, dsize, Color(0.9, 0.9, 0.95, alpha))
        d.clip_text = true
        d.autowrap = true
        d.rect_size = Vector2(w - 28, 140 - off)
        if o.get("foot", "") != "":
            var f = FX.label(b, Vector2(14, h - 38), o["foot"], 15, Color(0.7, 0.92, 1.0, alpha))
            f.rect_size = Vector2(w - 28, 22)
    var hint = "Press 1-%d or click to choose" % n if n > 1 else "Press 1 or click to continue"
    if allow_close:
        hint = hint + "      [E] or Backspace to close"
    var hl = FX.label(self, Vector2(0, 520), hint, 15, Color(1, 1, 1, 0.6))
    hl.rect_size = Vector2(1280, 20)
    hl.align = Label.ALIGN_CENTER

func _on_pressed(i):
    if not options[i].get("disabled", false):
        emit_signal("picked", i)

func _process(delta):
    if skip:
        skip = false
        return
    for i in range(int(min(options.size(), 5))):
        if Input.is_action_just_pressed("pick%d" % (i + 1)) and not options[i].get("disabled", false):
            emit_signal("picked", i)
            return
    if allow_close and (Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("interact")):
        emit_signal("closed")
