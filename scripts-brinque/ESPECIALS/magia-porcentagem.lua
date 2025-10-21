macro(1, "MACRO DE %", function()   if g_game.isAttacking() and g_game.getAttackingCreature():isPlayer() and g_game.getAttackingCreature():getHealthPercent() < 65 then
        say(" Reddoribasaru")
    end 
end)
