#New Level Cap System

LEVEL_CAP_IN_OPTIONS = true #This Switch will determine whether the Level Caps Option will appear in the Options Menu


#This adds compatablilty with the Voltseon Pause Menu Plugin
#Set to true if using the Voltseon Pause Menu
#Also used to hide from Pause Menu if you wish to keep that off the UI
VOLTSEON_PAUSE_MENU_USED = true

class PokemonSystem
  attr_accessor :level_caps
  attr_accessor :egg_tutor
  attr_accessor :nuzlocke
  attr_accessor :min_grinding
  alias initialize_caps initialize
  def initialize
    initialize_caps
    @level_caps = 0 #Level caps set to on by default
    @egg_tutor = 0 #Egg Tutor set to off by default
    @nuzlocke = 0
    @min_grinding = 1
  end
end

class Game_System
  attr_accessor :level_cap
  attr_accessor :egg_tutor
  alias initialize_cap initialize
  def initialize
    initialize_cap
    @level_cap          = 0
    @egg_tutor          = 0 
  end
  def level_cap
    return @level_cap
  end
  def egg_tutor
    return @egg_tutor
  end
end

#Define all your levels caps in this array. Every time you run Game.level_cap_update, it will move to the next level cap in the array.
LEVEL_CAP = [11,15]


module Level_Cap
  def self.initialize
    $game_system.initialize
  end
  def self.update
    $game_system.level_cap += 1
    $game_system.level_cap = LEVEL_CAP.size-1 if $game_system.level_cap >= LEVEL_CAP.size
  end
end

module NavNums
  Dispose = 900 #Edit this to whatever switch you would like, it's not needed unless you're using the DexNav plugin
end

class PokemonLoadScreen
  def pbStartLoadScreen
    commands = []
    cmd_continue     = -1
    cmd_new_game     = -1
    cmd_options      = -1
    cmd_language     = -1
    cmd_mystery_gift = -1
    cmd_debug        = -1
    cmd_quit         = -1
    show_continue = !@save_data.empty?
    if show_continue
      commands[cmd_continue = commands.length] = _INTL("Continue")
      if @save_data[:player].mystery_gift_unlocked
        commands[cmd_mystery_gift = commands.length] = _INTL("Mystery Gift")
      end
    end
    commands[cmd_new_game = commands.length]  = _INTL("New Game")
    commands[cmd_options = commands.length]   = _INTL("Options")
    commands[cmd_language = commands.length]  = _INTL("Language") if Settings::LANGUAGES.length >= 2
    commands[cmd_debug = commands.length]     = _INTL("Debug") if $DEBUG
    commands[cmd_quit = commands.length]      = _INTL("Quit Game")
    map_id = show_continue ? @save_data[:map_factory].map.map_id : 0
    @scene.pbStartScene(commands, show_continue, @save_data[:player],
                        @save_data[:frame_count] || 0, @save_data[:stats], map_id)
    @scene.pbSetParty(@save_data[:player]) if show_continue
    @scene.pbStartScene2
    loop do
      command = @scene.pbChoose(commands)
      pbPlayDecisionSE if command != cmd_quit
      case command
      when cmd_continue
        @scene.pbEndScene
        Game.load(@save_data)
        return
      when cmd_new_game
        @scene.pbEndScene
        Level_Cap.initialize
        Game.start_new
        return
      when cmd_mystery_gift
        pbFadeOutIn { pbDownloadMysteryGift(@save_data[:player]) }
      when cmd_options
        pbFadeOutIn do
          scene = PokemonOption_Scene.new
          screen = PokemonOptionScreen.new(scene)
          screen.pbStartScreen(true)
        end
      when cmd_language
        @scene.pbEndScene
        $PokemonSystem.language = pbChooseLanguage
        pbLoadMessages("Data/" + Settings::LANGUAGES[$PokemonSystem.language][1])
        if show_continue
          @save_data[:pokemon_system] = $PokemonSystem
          File.open(SaveData::FILE_PATH, "wb") { |file| Marshal.dump(@save_data, file) }
        end
        $scene = pbCallTitle
        return
      when cmd_debug
        pbFadeOutIn { pbDebugMenu(false) }
      when cmd_quit
        pbPlayCloseMenuSE
        @scene.pbEndScene
        $scene = nil
        return
      else
        pbPlayBuzzerSE
      end
    end
  end
end

class PokemonPauseMenu_Scene
  alias pbStartSceneCap pbStartScene
  def pbStartScene
    if !VOLTSEON_PAUSE_MENU_USED
      if $game_switches[NavNums::Dispose] == false
        cap = LEVEL_CAP[$game_system.level_cap]
        @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @viewport.z = 99999
        @sprites = {}
        @sprites["cmdwindow"] = Window_CommandPokemon.new([])
        @sprites["cmdwindow"].visible = false
        @sprites["cmdwindow"].viewport = @viewport
        @sprites["infowindow"] = Window_UnformattedTextPokemon.newWithSize("", 0, 0, 32, 32, @viewport)
        @sprites["infowindow"].visible = false
        @sprites["helpwindow"] = Window_UnformattedTextPokemon.newWithSize("", 0, 0, 32, 32, @viewport)
        @sprites["helpwindow"].visible = false
        @sprites["levelcapwindow"] = Window_UnformattedTextPokemon.newWithSize("Level Cap: #{cap}",0,64,208,64,@viewport)
        @sprites["levelcapwindow"].visible = false
        @infostate = false
        @helpstate = false
        $close_dexnav = 0
        $sprites = @sprites
        pbSEPlay("GUI menu open")
      else
        $viewport1.dispose
        $currentDexSearch = nil
        $close_dexnav = 1
        $game_switches[NavNums::Dispose] = false
        pbSEPlay("GUI menu close")
        return
      end
    else
      pbStartSceneCap
    end
  end
  alias pbShowCommandsCap pbShowCommands
  def pbShowCommands(commands)
    if !VOLTSEON_PAUSE_MENU_USED
      if $game_switches[NavNums::Dispose] == false && $close_dexnav < 1
        ret = -1
        cmdwindow = @sprites["cmdwindow"]
        cmdwindow.commands = commands
        cmdwindow.index    = $game_temp.menu_last_choice
        cmdwindow.resizeToFit(commands)
        cmdwindow.x        = Graphics.width - cmdwindow.width
        cmdwindow.y        = 0
        cmdwindow.visible  = true
        loop do
          cmdwindow.update
          Graphics.update
          Input.update
          pbUpdateSceneMap
          if Input.trigger?(Input::BACK) || Input.trigger?(Input::ACTION)
            ret = -1
            break
          elsif Input.trigger?(Input::USE)
            ret = cmdwindow.index
            $game_temp.menu_last_choice = ret
            break
          end
        end
      else
        ret = -1
      end
      $close_dexnav -= 1
      return ret
    else
      pbShowCommandsCap(commands)
    end
  end
  def pbShowLevelCap
    if $PokemonSystem.level_caps == 0 && !$currentDexSearch
      @sprites["levelcapwindow"].visible = true if !VOLTSEON_PAUSE_MENU_USED
    end
  end
  def pbHideLevelCap
    @sprites["levelcapwindow"].visible = false if !VOLTSEON_PAUSE_MENU_USED
  end
end

class PokemonPauseMenu
  def pbShowLevelCap
    @scene.pbShowLevelCap if !VOLTSEON_PAUSE_MENU_USED
  end

  def pbHideLevelCap
    @scene.pbHideLevelCap if !VOLTSEON_PAUSE_MENU_USED
  end
  alias pbStartPokemonMenuCap pbStartPokemonMenu
  def pbStartPokemonMenu
    if !VOLTSEON_PAUSE_MENU_USED
      if !$player
        if $DEBUG
          pbMessage(_INTL("The player trainer was not defined, so the pause menu can't be displayed."))
          pbMessage(_INTL("Please see the documentation to learn how to set up the trainer player."))
        end
        return
      end
      @scene.pbStartScene
      # Show extra info window if relevant
      pbShowInfo
      if $close_dexnav != 1 && !VOLTSEON_PAUSE_MENU_USED
        $PokemonSystem.level_caps == 0 ? pbShowLevelCap : pbHideLevelCap
      end
      # Get all commands
      command_list = []
      commands = []
      MenuHandlers.each_available(:pause_menu) do |option, hash, name|
        command_list.push(name)
        commands.push(hash)
      end
      # Main loop
      end_scene = false
      loop do
        if !$currentDexSearch
          choice = @scene.pbShowCommands(command_list)
        else
          choice = -1
        end
        if choice < 0
          pbPlayCloseMenuSE if !$currentDexSearch
          end_scene = true
          break
        end
        break if commands[choice]["effect"].call(@scene)
      end
      if $close_dexnav != 0
        @scene.pbEndScene if end_scene
      end
    else
      pbStartPokemonMenuCap
    end
  end
end

class Battle
  def pbGainExpOne(idxParty, defeatedBattler, numPartic, expShare, expAll, showMessages = true)
    pkmn = pbParty(0)[idxParty]   # The Pokémon gaining Exp from defeatedBattler
    growth_rate = pkmn.growth_rate
    # Don't bother calculating if gainer is already at max Exp
    if pkmn.exp >= growth_rate.maximum_exp
      pkmn.calc_stats   # To ensure new EVs still have an effect
      return
    end
    isPartic    = defeatedBattler.participants.include?(idxParty)
    hasExpShare = expShare.include?(idxParty)
    level = defeatedBattler.level
    level_cap = $PokemonSystem.level_caps == 0 ? LEVEL_CAP[$game_system.level_cap] : Settings::MAXIMUM_LEVEL
    level_cap_gap = growth_rate.exp_values[level_cap] - pkmn.exp
    # Main Exp calculation
    exp = 0
    a = level * defeatedBattler.pokemon.base_exp
    if expShare.length > 0 && (isPartic || hasExpShare)
      if numPartic == 0   # No participants, all Exp goes to Exp Share holders
        exp = a / (Settings::SPLIT_EXP_BETWEEN_GAINERS ? expShare.length : 1)
      elsif Settings::SPLIT_EXP_BETWEEN_GAINERS   # Gain from participating and/or Exp Share
        exp = a / (2 * numPartic) if isPartic
        exp += a / (2 * expShare.length) if hasExpShare
      else   # Gain from participating and/or Exp Share (Exp not split)
        exp = (isPartic) ? a : a / 2
      end
    elsif isPartic   # Participated in battle, no Exp Shares held by anyone
      exp = a / (Settings::SPLIT_EXP_BETWEEN_GAINERS ? numPartic : 1)
    elsif expAll   # Didn't participate in battle, gaining Exp due to Exp All
      # NOTE: Exp All works like the Exp Share from Gen 6+, not like the Exp All
      #       from Gen 1, i.e. Exp isn't split between all Pokémon gaining it.
      exp = a / 2
    end
    return if exp <= 0
    # Pokémon gain more Exp from trainer battles
    exp = (exp * 1.5).floor if trainerBattle?
    # Scale the gained Exp based on the gainer's level (or not)
    if Settings::SCALED_EXP_FORMULA
      exp /= 5
      levelAdjust = ((2 * level) + 10.0) / (pkmn.level + level + 10.0)
      levelAdjust = levelAdjust**5
      levelAdjust = Math.sqrt(levelAdjust)
      exp *= levelAdjust
      exp = exp.floor
      exp += 1 if isPartic || hasExpShare
      if pkmn.level >= level_cap
        exp /= 250
      end
      if exp >= level_cap_gap
        exp = level_cap_gap + 1
      end
    else
      if a <= level_cap_gap
        exp = a
      else
        exp /= 7
      end
    end
    # Foreign Pokémon gain more Exp
    isOutsider = (pkmn.owner.id != pbPlayer.id ||
                 (pkmn.owner.language != 0 && pkmn.owner.language != pbPlayer.language))
    if isOutsider
      if pkmn.owner.language != 0 && pkmn.owner.language != pbPlayer.language
        exp = (exp * 1.7).floor
      else
        exp = (exp * 1.5).floor
      end
    end
    # Exp. Charm increases Exp gained
    exp = exp * 3 / 2 if $bag.has?(:EXPCHARM)
    # Modify Exp gain based on pkmn's held item
    i = Battle::ItemEffects.triggerExpGainModifier(pkmn.item, pkmn, exp)
    if i < 0
      i = Battle::ItemEffects.triggerExpGainModifier(@initialItems[0][idxParty], pkmn, exp)
    end
    exp = i if i >= 0
    # Boost Exp gained with high affection
    if Settings::AFFECTION_EFFECTS && @internalBattle && pkmn.affection_level >= 4 && !pkmn.mega?
      exp = exp * 6 / 5
      isOutsider = true   # To show the "boosted Exp" message
    end
    # Make sure Exp doesn't exceed the maximum
    expFinal = growth_rate.add_exp(pkmn.exp, exp)
    expGained = expFinal - pkmn.exp
    return if expGained <= 0
    # "Exp gained" message
    if showMessages
      if isOutsider
        pbDisplayPaused(_INTL("{1} got a boosted {2} Exp. Points!", pkmn.name, expGained))
      else
        pbDisplayPaused(_INTL("{1} got {2} Exp. Points!", pkmn.name, expGained))
      end
    end
    curLevel = pkmn.level
    newLevel = growth_rate.level_from_exp(expFinal)
    if newLevel < curLevel
      debugInfo = "Levels: #{curLevel}->#{newLevel} | Exp: #{pkmn.exp}->#{expFinal} | gain: #{expGained}"
      raise _INTL("{1}'s new level is less than its\r\ncurrent level, which shouldn't happen.\r\n[Debug: {2}]",
                  pkmn.name, debugInfo)
    end
    # Give Exp
    if pkmn.shadowPokemon?
      if pkmn.heartStage <= 3
        pkmn.exp += expGained
        $stats.total_exp_gained += expGained
      end
      return
    end
    $stats.total_exp_gained += expGained
    tempExp1 = pkmn.exp
    battler = pbFindBattler(idxParty)
    loop do   # For each level gained in turn...
      # EXP Bar animation
      levelMinExp = growth_rate.minimum_exp_for_level(curLevel)
      levelMaxExp = growth_rate.minimum_exp_for_level(curLevel + 1)
      tempExp2 = (levelMaxExp < expFinal) ? levelMaxExp : expFinal
      pkmn.exp = tempExp2
      @scene.pbEXPBar(battler, levelMinExp, levelMaxExp, tempExp1, tempExp2)
      tempExp1 = tempExp2
      curLevel += 1
      if curLevel > newLevel
        # Gained all the Exp now, end the animation
        pkmn.calc_stats
        battler&.pbUpdate(false)
        @scene.pbRefreshOne(battler.index) if battler
        break
      end
      # Levelled up
      pbCommonAnimation("LevelUp", battler) if battler
      oldTotalHP = pkmn.totalhp
      oldAttack  = pkmn.attack
      oldDefense = pkmn.defense
      oldSpAtk   = pkmn.spatk
      oldSpDef   = pkmn.spdef
      oldSpeed   = pkmn.speed
      if battler&.pokemon
        battler.pokemon.changeHappiness("levelup")
      end
      pkmn.calc_stats
      battler&.pbUpdate(false)
      @scene.pbRefreshOne(battler.index) if battler
      pbDisplayPaused(_INTL("{1} grew to Lv. {2}!", pkmn.name, curLevel))
      @scene.pbLevelUp(pkmn, battler, oldTotalHP, oldAttack, oldDefense,
                       oldSpAtk, oldSpDef, oldSpeed)
      # Learn all moves learned at this level
      moveList = pkmn.getMoveList
      moveList.each { |m| pbLearnMove(idxParty, m[1]) if m[0] == curLevel }
    end
  end
end

ItemHandlers::UseOnPokemonMaximum.add(:RARECANDY, proc { |item, pkmn|
  if $PokemonSystem.level_caps == 1
    next GameData::GrowthRate.max_level - pkmn.level
  else
    next LEVEL_CAP[$game_system.level_cap] - pkmn.level
  end
})

ItemHandlers::UseOnPokemon.add(:RARECANDY, proc { |item, qty, pkmn, scene|
  if pkmn.shadowPokemon?
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  end
  if $PokemonSystem.level_caps == 1
    if pkmn.level >= GameData::GrowthRate.max_level
      new_species = pkmn.check_evolution_on_level_up
      if !Settings::RARE_CANDY_USABLE_AT_MAX_LEVEL || !new_species
        scene.pbDisplay(_INTL("It won't have any effect."))
        next false
      end
      # Check for evolution
      pbFadeOutInWithMusic {
        evo = PokemonEvolutionScene.new
        evo.pbStartScreen(pkmn, new_species)
        evo.pbEvolution
        evo.pbEndScreen
        scene.pbRefresh if scene.is_a?(PokemonPartyScreen)
      }
      next true
    end
  else
    if pkmn.level >= LEVEL_CAP[$game_system.level_cap]
      new_species = pkmn.check_evolution_on_level_up
      if !Settings::RARE_CANDY_USABLE_AT_MAX_LEVEL || !new_species
        scene.pbDisplay(_INTL("It won't have any effect."))
        next false
      end
      # Check for evolution
      pbFadeOutInWithMusic {
        evo = PokemonEvolutionScene.new
        evo.pbStartScreen(pkmn, new_species)
        evo.pbEvolution
        evo.pbEndScreen
        scene.pbRefresh if scene.is_a?(PokemonPartyScreen)
      }
      next true
    end
  end
  # Level up
  pbChangeLevel(pkmn, pkmn.level + qty, scene)
  scene.pbHardRefresh
  next true
})

MenuHandlers.add(:options_menu, :level_caps, {
  "name"        => _INTL("Level Caps"),
  "order"       => 90,
  "type"        => EnumOption,
  "parameters"  => [_INTL("On"), _INTL("Off")],
  "description" => _INTL("Choose whether you will have hard level caps."),
  "condition"   => proc { next LEVEL_CAP_IN_OPTIONS },
  "get_proc"    => proc { next $PokemonSystem.level_caps},
  "set_proc"    => proc { |value, _scene| $PokemonSystem.level_caps = value }
})