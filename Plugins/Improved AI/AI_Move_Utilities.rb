class Battle::AI
  def pbCalcTypeLinear(moveType, user, target)
    ret = pbCalcTypeMod(moveType, user, target)
    # triple-type support
    ret *= ret
    # convert to linear scale
    ret = Math.log(ret, 2).round(0)
    # offset values so that 0 = neutral, <0 = not very effective, >0 = super
    ret -= 6
    return ret
  end
end