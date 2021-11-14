extends PanelContainer

func set_player_data(player_data):
	for sprite_name in Globals.player_sprites.keys():
		if sprite_name == player_data.char:
			$MC/HB/CC/MC/Sprite.texture = Globals.player_sprites[sprite_name]
	$MC/HB/MC/VB/VB/NameValue.text = str(player_data.tag)
	$MC/HB/MC/VB/HBoxContainer/MoneyValue.text = "$ " + str(player_data.money)
	$MC/HB/MC/VB/LevelValue.text = "Level %s (%s / %s)" % [str(player_data.level), str(player_data.xp), str(PlayersData.get_xp_for_level(player_data.level+1) - PlayersData.get_xp_for_level(player_data.level))]

	var fraction = (player_data.xp * 1.0) / (PlayersData.get_xp_for_level(player_data.level+1) - PlayersData.get_xp_for_level(player_data.level))
	$MC/HB/MC/VB/LevelProgress.value = round(fraction * 100)
