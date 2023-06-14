class DateAndTimeHud < Component
  def refresh
  levelcap = LEVEL_CAP[$game_system.level_cap]
  text = _INTL("{1} {2} {3}",Time.now.day.to_i,pbGetAbbrevMonthName(Time.now.month.to_i),Time.now.year.to_i)
  text2 = _INTL("{1}",pbGetTimeNow.strftime("%I:%M %p"))
  text3 = _INTL("Level Cap: {1}",levelcap) if VOLTSEON_PAUSE_MENU_USED && $PokemonSystem.level_caps == 0
  @sprites["overlay"].bitmap.clear
  pbSetSystemFont(@sprites["overlay"].bitmap)
  if VOLTSEON_PAUSE_MENU_USED && $PokemonSystem.level_caps == 0
    pbDrawTextPositions(@sprites["overlay"].bitmap,[[text,Graphics.width/2 - 8, 12,1,
      @baseColor,@shadowColor],[text2,Graphics.width/2 - 8,44,1,@baseColor,@shadowColor],[text3,Graphics.width/2 - 8,75,1,@baseColor,@shadowColor]])
  else
    pbDrawTextPositions(@sprites["overlay"].bitmap,[[text,Graphics.width/2 - 8, 12,1,
      @baseColor,@shadowColor],[text2,Graphics.width/2 - 8,44,1,@baseColor,@shadowColor]])
  end
  @last_time = pbGetTimeNow.strftime("%I:%M %p")
  end
 end