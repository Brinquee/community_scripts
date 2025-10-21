local castBelowHp = 45
macro(100, "Kawarimi 45%",  function()
  if (hppercent() <= castBelowHp) then
    say('kawarimi no jutsu')
  end
end)
