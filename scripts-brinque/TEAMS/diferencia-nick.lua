--SCRIPT PARA DIFERENCIAR NOME DE RIVAIS DE GUILD

local monstercolor = macro(10000, "- Colorir Nomes -", function() end)
onCreatureAppear(function(creature)
  if monstercolor:isOff() then creature:setInformationColor('#00cc00') return end
  if creature:isPlayer() and creature:getEmblem() == 3 then 
        creature:setInformationColor("red") -- inimigos cor
  elseif creature:isPlayer() and creature:getEmblem() == 1 then
        creature:setInformationColor("white") -- amigos cor
  elseif creature:isPlayer() and creature:getEmblem() == 0 then
        creature:setInformationColor("green") -- Sem Time cor
  end
end)
