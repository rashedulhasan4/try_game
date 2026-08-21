extends Control

const BG := Color("#07111F")
const SURFACE := Color("#101D2E")
const SURFACE_2 := Color("#16263A")
const TEXT := Color("#F3F7FC")
const MUTED := Color("#8FA3BA")
const GREEN := Color("#34D399")
const BLUE := Color("#4F9CF9")
const DANGER := Color("#FB7185")

var cash_label: Label
var rate_label: Label
var content: VBoxContainer
var toast: Label
var active_tab := "home"
var _toast_tween: Tween
var business_action_buttons: Dictionary = {}

func _ready() -> void:
	build_interface()
	GameState.state_changed.connect(refresh_header)
	GameState.message_requested.connect(show_toast)
	refresh_header()
	show_home()
	if not GameState.tutorial_seen:
		call_deferred("show_tutorial_dialog")
	elif GameState.pending_offline_income >= 1.0:
		call_deferred("show_offline_dialog")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GameState.save_game()

func build_interface() -> void:
	var background := ColorRect.new()
	background.color = BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var safe_margin := MarginContainer.new()
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_margin.add_theme_constant_override("margin_left", 18)
	safe_margin.add_theme_constant_override("margin_right", 18)
	safe_margin.add_theme_constant_override("margin_top", 22)
	safe_margin.add_theme_constant_override("margin_bottom", 14)
	add_child(safe_margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 16)
	safe_margin.add_child(page)

	page.add_child(build_header())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)

	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)

	page.add_child(build_navigation())

	toast = Label.new()
	toast.modulate.a = 0.0
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast.add_theme_color_override("font_color", TEXT)
	toast.add_theme_font_size_override("font_size", 14)
	toast.add_theme_stylebox_override("normal", rounded_style(Color("#21334A"), 14))
	toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast.position = Vector2(-150, -112)
	toast.size = Vector2(300, 46)
	add_child(toast)

func build_header() -> Control:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(identity)

	var eyebrow := Label.new()
	eyebrow.text = "EMPIRE LEGACY"
	eyebrow.add_theme_color_override("font_color", GREEN)
	eyebrow.add_theme_font_size_override("font_size", 12)
	identity.add_child(eyebrow)

	var title := Label.new()
	title.text = "Your Financial Command"
	title.add_theme_color_override("font_color", TEXT)
	title.add_theme_font_size_override("font_size", 18)
	identity.add_child(title)

	var balance := VBoxContainer.new()
	balance.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(balance)

	cash_label = Label.new()
	cash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cash_label.add_theme_color_override("font_color", TEXT)
	cash_label.add_theme_font_size_override("font_size", 20)
	balance.add_child(cash_label)

	rate_label = Label.new()
	rate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rate_label.add_theme_color_override("font_color", GREEN)
	rate_label.add_theme_font_size_override("font_size", 12)
	balance.add_child(rate_label)
	return header

func build_navigation() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", rounded_style(SURFACE, 18))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	for item in [["home", "Home"], ["business", "Businesses"], ["profile", "Profile"]]:
		var button := Button.new()
		button.text = item[1]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 54
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_color_override("font_color", MUTED)
		button.add_theme_color_override("font_hover_color", TEXT)
		button.add_theme_stylebox_override("normal", rounded_style(Color.TRANSPARENT, 14))
		button.add_theme_stylebox_override("hover", rounded_style(SURFACE_2, 14))
		button.add_theme_stylebox_override("pressed", rounded_style(Color("#1D3551"), 14))
		button.pressed.connect(switch_tab.bind(item[0]))
		row.add_child(button)
	return panel

func refresh_header() -> void:
	if not is_instance_valid(cash_label):
		return
	cash_label.text = GameState.format_money(GameState.cash)
	rate_label.text = "+%s / sec" % GameState.format_money(GameState.income_per_second())
	for id in business_action_buttons:
		var button: Button = business_action_buttons[id]
		if is_instance_valid(button):
			var cost := GameState.next_business_cost(id)
			button.disabled = GameState.cash < cost
			button.text = ("OPEN" if GameState.business_level(id) == 0 else "UPGRADE") + "  •  " + GameState.format_money(cost)

func switch_tab(tab: String) -> void:
	active_tab = tab
	match tab:
		"home": show_home()
		"business": show_businesses()
		"profile": show_profile()

func clear_content() -> void:
	business_action_buttons.clear()
	for child in content.get_children():
		child.queue_free()

func show_home() -> void:
	clear_content()
	content.add_child(section_heading("Overview", "Build steadily. Invest intelligently."))

	var hero := PanelContainer.new()
	hero.add_theme_stylebox_override("panel", rounded_style(Color("#123A38"), 22, Color("#1E6A5F")))
	var hero_box := VBoxContainer.new()
	hero_box.add_theme_constant_override("separation", 10)
	hero.add_child(hero_box)

	var hero_title := Label.new()
	hero_title.text = "Close your next deal"
	hero_title.add_theme_color_override("font_color", TEXT)
	hero_title.add_theme_font_size_override("font_size", 22)
	hero_box.add_child(hero_title)

	var hero_copy := Label.new()
	hero_copy.text = "Earn active capital, then turn it into businesses that work around the clock."
	hero_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_copy.add_theme_color_override("font_color", Color("#BEE8DE"))
	hero_copy.add_theme_font_size_override("font_size", 14)
	hero_box.add_child(hero_copy)

	var deal_button := Button.new()
	deal_button.text = "CLOSE DEAL  +%s" % GameState.format_money(GameState.tap_value)
	deal_button.custom_minimum_size.y = 58
	deal_button.add_theme_font_size_override("font_size", 15)
	deal_button.add_theme_color_override("font_color", Color("#052E2A"))
	deal_button.add_theme_stylebox_override("normal", rounded_style(GREEN, 16))
	deal_button.add_theme_stylebox_override("hover", rounded_style(Color("#6EE7B7"), 16))
	deal_button.add_theme_stylebox_override("pressed", rounded_style(Color("#10B981"), 16))
	deal_button.pressed.connect(on_deal_pressed)
	hero_box.add_child(deal_button)
	content.add_child(hero)
	content.add_child(daily_reward_card())

	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 10)
	metrics.add_child(metric_card("NET WORTH", GameState.format_money(GameState.net_worth()), BLUE))
	metrics.add_child(metric_card("BUSINESSES", str(GameState.owned_business_count()), GREEN))
	content.add_child(metrics)

	content.add_child(section_heading("Portfolio pulse", "Your live business income"))
	if GameState.owned_business_count() == 0:
		content.add_child(empty_state("No business yet", "Close a few deals, then open Street Brew from the Businesses tab."))
	else:
		for id in GameState.business_catalog:
			if GameState.business_level(id) > 0:
				content.add_child(compact_business_row(id))

func on_deal_pressed() -> void:
	GameState.tap_income()
	show_toast("Deal closed. +%s" % GameState.format_money(GameState.tap_value))

func daily_reward_card() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", rounded_style(Color("#241E3D"), 17, Color("#55448A")))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var title := Label.new()
	title.text = "Daily capital boost"
	title.add_theme_color_override("font_color", TEXT)
	title.add_theme_font_size_override("font_size", 15)
	info.add_child(title)
	var detail := Label.new()
	detail.text = "Day %d streak • next %s" % [GameState.daily_streak, GameState.format_money(GameState.daily_reward_amount())]
	detail.add_theme_color_override("font_color", Color("#B9A7E8"))
	detail.add_theme_font_size_override("font_size", 12)
	info.add_child(detail)

	var claim := Button.new()
	claim.text = "CLAIM" if GameState.can_claim_daily_reward() else "CLAIMED"
	claim.disabled = not GameState.can_claim_daily_reward()
	claim.custom_minimum_size = Vector2(88, 44)
	claim.add_theme_color_override("font_color", TEXT)
	claim.add_theme_stylebox_override("normal", rounded_style(Color("#6D55B7"), 12))
	claim.add_theme_stylebox_override("hover", rounded_style(Color("#8068C9"), 12))
	claim.add_theme_stylebox_override("disabled", rounded_style(Color("#30294A"), 12))
	claim.pressed.connect(on_daily_reward_claimed)
	row.add_child(claim)
	return panel

func on_daily_reward_claimed() -> void:
	var reward := GameState.claim_daily_reward()
	if reward > 0.0:
		show_home()
		show_toast("Daily reward collected: %s" % GameState.format_money(reward))

func show_businesses() -> void:
	clear_content()
	content.add_child(section_heading("Businesses", "Open companies and increase their output."))
	for id in GameState.business_catalog:
		content.add_child(business_card(id))

func business_card(id: String) -> Control:
	var data: Dictionary = GameState.business_catalog[id]
	var level := GameState.business_level(id)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", rounded_style(SURFACE, 18, data.accent))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var top := HBoxContainer.new()
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)

	var category := Label.new()
	category.text = str(data.category).to_upper()
	category.add_theme_color_override("font_color", data.accent)
	category.add_theme_font_size_override("font_size", 11)
	info.add_child(category)

	var title := Label.new()
	title.text = data.name
	title.add_theme_color_override("font_color", TEXT)
	title.add_theme_font_size_override("font_size", 19)
	info.add_child(title)

	var badge := Label.new()
	badge.text = "LOCKED" if level == 0 else "LEVEL %d" % level
	badge.add_theme_color_override("font_color", TEXT if level > 0 else MUTED)
	badge.add_theme_stylebox_override("normal", rounded_style(SURFACE_2, 10))
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.custom_minimum_size = Vector2(78, 32)
	top.add_child(badge)
	box.add_child(top)

	var description := Label.new()
	description.text = data.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", MUTED)
	description.add_theme_font_size_override("font_size", 13)
	box.add_child(description)

	var income_text := "Potential: %s/sec" % GameState.format_money(data.base_income)
	if level > 0:
		income_text = "Current income: %s/sec" % GameState.format_money(GameState.business_income(id))
	var income := Label.new()
	income.text = income_text
	income.add_theme_color_override("font_color", GREEN)
	income.add_theme_font_size_override("font_size", 13)
	box.add_child(income)

	if level > 0:
		var milestone := Label.new()
		var next_level := GameState.next_business_milestone(level)
		if next_level > 0:
			milestone.text = "Milestone: level %d unlocks another 2x income boost" % next_level
		else:
			milestone.text = "All milestones unlocked • %.0fx total boost" % GameState.business_milestone_multiplier(level)
		milestone.add_theme_color_override("font_color", Color("#FCD34D"))
		milestone.add_theme_font_size_override("font_size", 12)
		box.add_child(milestone)

	var action := Button.new()
	var cost := GameState.next_business_cost(id)
	action.text = ("OPEN" if level == 0 else "UPGRADE") + "  •  " + GameState.format_money(cost)
	action.custom_minimum_size.y = 48
	action.disabled = GameState.cash < cost
	action.add_theme_color_override("font_color", TEXT)
	action.add_theme_color_override("font_disabled_color", Color("#5E7188"))
	action.add_theme_stylebox_override("normal", rounded_style(Color("#1D4E71"), 14))
	action.add_theme_stylebox_override("hover", rounded_style(Color("#25638E"), 14))
	action.add_theme_stylebox_override("pressed", rounded_style(Color("#173E5A"), 14))
	action.add_theme_stylebox_override("disabled", rounded_style(Color("#172536"), 14))
	action.pressed.connect(on_business_action.bind(id))
	box.add_child(action)
	business_action_buttons[id] = action
	return panel

func on_business_action(id: String) -> void:
	if GameState.buy_or_upgrade_business(id):
		show_businesses()

func compact_business_row(id: String) -> Control:
	var data: Dictionary = GameState.business_catalog[id]
	var row_panel := PanelContainer.new()
	row_panel.add_theme_stylebox_override("panel", rounded_style(SURFACE, 15))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row_panel.add_child(row)

	var marker := ColorRect.new()
	marker.color = data.accent
	marker.custom_minimum_size = Vector2(5, 42)
	row.add_child(marker)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var name_label := Label.new()
	name_label.text = data.name
	name_label.add_theme_color_override("font_color", TEXT)
	name_label.add_theme_font_size_override("font_size", 14)
	info.add_child(name_label)
	var level_label := Label.new()
	level_label.text = "Level %d" % GameState.business_level(id)
	level_label.add_theme_color_override("font_color", MUTED)
	level_label.add_theme_font_size_override("font_size", 12)
	info.add_child(level_label)

	var income := Label.new()
	income.text = "+%s/sec" % GameState.format_money(GameState.business_income(id))
	income.add_theme_color_override("font_color", GREEN)
	income.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(income)
	return row_panel

func show_profile() -> void:
	clear_content()
	content.add_child(section_heading("Profile", "Your empire at a glance."))
	content.add_child(profile_stat("Current cash", GameState.format_money(GameState.cash)))
	content.add_child(profile_stat("Net worth", GameState.format_money(GameState.net_worth())))
	content.add_child(profile_stat("Lifetime earnings", GameState.format_money(GameState.lifetime_earnings)))
	content.add_child(profile_stat("Income per hour", GameState.format_money(GameState.income_per_second() * 3600.0)))
	content.add_child(profile_stat("Businesses owned", str(GameState.owned_business_count())))
	content.add_child(profile_stat("Achievements", "%d / %d" % [GameState.unlocked_achievement_count(), GameState.achievement_catalog.size()]))

	content.add_child(section_heading("Achievements", "Milestones from your business journey."))
	for id in GameState.achievement_catalog:
		content.add_child(achievement_row(id))

	content.add_child(section_heading("Feedback", "Control lightweight sound and vibration."))
	content.add_child(setting_toggle("Sound effects", GameState.sound_enabled, GameState.set_sound_enabled))
	content.add_child(setting_toggle("Haptic feedback", GameState.haptics_enabled, GameState.set_haptics_enabled))

	var note := Label.new()
	note.text = "Progress is saved automatically on this device every 10 seconds. Offline earnings are capped at 8 hours."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", MUTED)
	note.add_theme_font_size_override("font_size", 13)
	content.add_child(note)

	var reset := Button.new()
	reset.text = "RESET GAME DATA"
	reset.custom_minimum_size.y = 50
	reset.add_theme_color_override("font_color", DANGER)
	reset.add_theme_stylebox_override("normal", rounded_style(Color("#2A1823"), 14, Color("#6B263C")))
	reset.pressed.connect(confirm_reset)
	content.add_child(reset)

func achievement_row(id: String) -> Control:
	var data: Dictionary = GameState.achievement_catalog[id]
	var unlocked := GameState.achievement_unlocked(id)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", rounded_style(Color("#153129") if unlocked else SURFACE, 14, GREEN if unlocked else Color.TRANSPARENT))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var status := Label.new()
	status.text = "DONE" if unlocked else "LOCKED"
	status.custom_minimum_size.x = 58
	status.add_theme_color_override("font_color", GREEN if unlocked else MUTED)
	status.add_theme_font_size_override("font_size", 10)
	row.add_child(status)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var title := Label.new()
	title.text = data.name
	title.add_theme_color_override("font_color", TEXT)
	title.add_theme_font_size_override("font_size", 14)
	info.add_child(title)
	var description := Label.new()
	description.text = data.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", MUTED)
	description.add_theme_font_size_override("font_size", 12)
	info.add_child(description)
	return panel

func setting_toggle(label_text: String, enabled: bool, callback: Callable) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", rounded_style(SURFACE, 14))
	var row := HBoxContainer.new()
	panel.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", TEXT)
	row.add_child(label)
	var toggle := CheckButton.new()
	toggle.button_pressed = enabled
	toggle.toggled.connect(callback)
	row.add_child(toggle)
	return panel

func profile_stat(label_text: String, value_text: String) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", rounded_style(SURFACE, 14))
	var row := HBoxContainer.new()
	panel.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", MUTED)
	row.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.add_theme_color_override("font_color", TEXT)
	row.add_child(value)
	return panel

func confirm_reset() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Reset your empire?"
	dialog.dialog_text = "This permanently clears all local progress."
	dialog.ok_button_text = "Reset"
	dialog.confirmed.connect(func():
		GameState.reset_game()
		show_profile()
		show_toast("Game data reset.")
	)
	dialog.canceled.connect(dialog.queue_free)
	dialog.confirmed.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(330, 180))

func show_offline_dialog() -> void:
	var amount := GameState.pending_offline_income
	var dialog := AcceptDialog.new()
	dialog.title = "Welcome back"
	dialog.dialog_text = "Your businesses earned %s while you were away." % GameState.format_money(amount)
	dialog.ok_button_text = "Collect"
	dialog.confirmed.connect(func():
		GameState.claim_offline_income()
		if active_tab == "home": show_home()
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered(Vector2i(330, 180))

func show_tutorial_dialog() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Welcome to Empire Legacy"
	dialog.dialog_text = "1. Close deals to earn starting capital.\n\n2. Open Street Brew from Businesses.\n\n3. Upgrade companies to grow passive income. Levels 5, 10 and 25 unlock permanent 2x boosts.\n\nYour progress saves automatically."
	dialog.ok_button_text = "Start building"
	dialog.confirmed.connect(func():
		GameState.mark_tutorial_seen()
		dialog.queue_free()
		if GameState.pending_offline_income >= 1.0:
			show_offline_dialog()
	)
	add_child(dialog)
	dialog.popup_centered(Vector2i(340, 390))

func section_heading(title_text: String, subtitle_text: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	var title := Label.new()
	title.text = title_text
	title.add_theme_color_override("font_color", TEXT)
	title.add_theme_font_size_override("font_size", 21)
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = subtitle_text
	subtitle.add_theme_color_override("font_color", MUTED)
	subtitle.add_theme_font_size_override("font_size", 13)
	box.add_child(subtitle)
	return box

func metric_card(label_text: String, value_text: String, accent: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", rounded_style(SURFACE, 16, accent))
	var box := VBoxContainer.new()
	panel.add_child(box)
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", MUTED)
	label.add_theme_font_size_override("font_size", 10)
	box.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.add_theme_color_override("font_color", TEXT)
	value.add_theme_font_size_override("font_size", 18)
	box.add_child(value)
	return panel

func empty_state(title_text: String, copy_text: String) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", rounded_style(SURFACE, 16))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	var title := Label.new()
	title.text = title_text
	title.add_theme_color_override("font_color", TEXT)
	title.add_theme_font_size_override("font_size", 16)
	box.add_child(title)
	var copy := Label.new()
	copy.text = copy_text
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_theme_color_override("font_color", MUTED)
	copy.add_theme_font_size_override("font_size", 13)
	box.add_child(copy)
	return panel

func rounded_style(color: Color, radius: int, border_color: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 13
	style.content_margin_bottom = 13
	if border_color.a > 0.0:
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = border_color
	return style

func show_toast(text: String) -> void:
	toast.text = text
	if _toast_tween and _toast_tween.is_running():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(toast, "modulate:a", 1.0, 0.16)
	_toast_tween.tween_interval(1.5)
	_toast_tween.tween_property(toast, "modulate:a", 0.0, 0.25)
