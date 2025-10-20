-- ===================================================================
-- PvP - Follow Attack (revisado p/ Community Scripts)
-- - Independente de 'tabName' (usa aba Main)
-- - Corrige refs FollowPlayer -> FollowAttack
-- - Normaliza tempo (NOW()) e proteções de nil
-- - Mantém a lógica de filas (escada/porta/jump/custom)
-- Créditos originais: Victor Neox
-- ===================================================================

local MACRO_NAME  = 'Follow Attack'
local MACRO_DELAY = 100 -- ms

-- Destino seguro p/ UI (sem depender de var global)
local DEST_TAB = getTab("Main") or setDefaultTab("Main")

-- Helper de tempo (ms) – evita depender de global 'now'
local function NOW()
  if type(now) == "number" then return now end -- algumas builds expõem 'now'
  -- fallback em ms
  return math.floor((os.clock() or 0) * 1000)
end

-- =========================
-- Estrutura e configurações
-- =========================
FollowAttack = {
  targetId = nil,
  currentTargetId = nil,

  obstaclesQueue = {}, -- FIFO de obstáculos

  obstacleWalkTime = 0, -- throttle p/ ações (ms)
  keyToClearTarget = 'Escape',

  -- Tradução do path step -> direção
  walkDirTable = {
    [0] = {'y', -1},
    [1] = {'x',  1},
    [2] = {'y',  1},
    [3] = {'x', -1},
  },

  -- flags p/ findPath
  flags = {
    ignoreNonPathable = true,
    precision = 0,
    ignoreCreatures = true
  },

  -- spells de jump
  jumpSpell = {
    up   = 'jump up',
    down = 'jump down'
  },

  -- Config de Custom IDs
  defaultItem  = 1111,     -- item usado no sqm do customId (se não for cast)
  defaultSpell = 'skip',    -- spell lançado no sqm do customId (se castSpell=true)

  -- Lista de IDs especiais (buracos etc)
  -- castSpell = true  -> usa defaultSpell quando em cima do SQM
  -- castSpell = false -> usa defaultItem quando dist <= 2 do SQM
  customIds = {
    { id = 1948, castSpell = false },
    { id = 595 , castSpell = false },
    { id = 1067, castSpell = false },
    { id = 1080, castSpell = false },
    { id = 386 , castSpell = true  },
  }
}

-- =========================
-- Utils
-- =========================
function FollowAttack.distanceFromPlayer(position)
  local px, py = posx(), posy()
  local dx = math.abs(px - position.x)
  local dy = math.abs(py - position.y)
  return math.sqrt(dx*dx + dy*dy)
end

function FollowAttack.walkToPathDir(path)
  if path and path[1] then
    g_game.walk(path[1], false)
  end
end

function FollowAttack.getDirection(playerPos, direction)
  local walkDir = FollowAttack.walkDirTable[direction]
  if walkDir then
    playerPos[walkDir[1]] = playerPos[walkDir[1]] + walkDir[2]
  end
  return playerPos
end

function FollowAttack.checkItemOnTile(tile, list)
  if not tile then return nil end
  local items = tile:getItems() or {}
  for _, item in ipairs(items) do
    local itemId = item:getId()
    for _, entry in ipairs(list or {}) do
      if itemId == entry.id then
        return entry
      end
    end
  end
  return nil
end

-- =========================
-- Detectores de obstáculos
-- =========================

-- Custom ID (buracos etc.)
function FollowAttack.checkIfWentToCustomId(creature, newPos, oldPos, scheduleTime)
  local tile = g_map.getTile(oldPos)
  local customId = FollowAttack.checkItemOnTile(tile, FollowAttack.customIds)
  if not customId then return end

  scheduleTime = scheduleTime or 0
  schedule(scheduleTime, function()
    if oldPos.z == posz() or #FollowAttack.obstaclesQueue > 0 then
      table.insert(FollowAttack.obstaclesQueue, {
        oldPos  = oldPos,
        newPos  = newPos,
        tilePos = oldPos,
        customId = customId,
        tile    = g_map.getTile(oldPos),
        isCustom = true
      })
    end
  end)
end

-- Escada
function FollowAttack.checkIfWentToStair(creature, newPos, oldPos, scheduleTime)
  if g_map.getMinimapColor(oldPos) ~= 210 then return end
  local tile = g_map.getTile(oldPos)
  if tile:isPathable() then return end

  scheduleTime = scheduleTime or 0
  schedule(scheduleTime, function()
    if oldPos.z == posz() or #FollowAttack.obstaclesQueue > 0 then
      table.insert(FollowAttack.obstaclesQueue, {
        oldPos  = oldPos,
        newPos  = newPos,
        tilePos = oldPos,
        tile    = tile,
        isStair = true
      })
    end
  end)
end

-- Porta
function FollowAttack.checkIfWentToDoor(creature, newPos, oldPos)
  if FollowAttack.obstaclesQueue[1]
     and FollowAttack.distanceFromPlayer(newPos) < FollowAttack.distanceFromPlayer(oldPos) then
    return
  end

  if math.abs(newPos.x - oldPos.x) == 2 or math.abs(newPos.y - oldPos.y) == 2 then
    local doorPos = { z = oldPos.z }

    local directionX = oldPos.x - newPos.x
    local directionY = oldPos.y - newPos.y

    if math.abs(directionX) > math.abs(directionY) then
      if directionX > 0 then
        doorPos.x, doorPos.y = newPos.x + 1, newPos.y
      else
        doorPos.x, doorPos.y = newPos.x - 1, newPos.y
      end
    else
      if directionY > 0 then
        doorPos.x, doorPos.y = newPos.x, newPos.y + 1
      else
        doorPos.x, doorPos.y = newPos.x, newPos.y - 1
      end
    end

    local doorTile = g_map.getTile(doorPos)
    if doorTile:isPathable() or doorTile:isWalkable() then return end

    table.insert(FollowAttack.obstaclesQueue, {
      newPos  = newPos,
      tilePos = doorPos,
      tile    = doorTile,
      isDoor  = true
    })
  end
end

-- Jump up/down
function FollowAttack.checkifWentToJumpPos(creature, newPos, oldPos)
  -- checa arredores p/ escada (se tem, não é jump)
  local pos1 = { x = oldPos.x - 1, y = oldPos.y - 1 }
  local pos2 = { x = oldPos.x + 1, y = oldPos.y + 1 }
  local hasStair = false
  for x = pos1.x, pos2.x do
    for y = pos1.y, pos2.y do
      local tilePos = { x = x, y = y, z = oldPos.z }
      if g_map.getMinimapColor(tilePos) == 210 then
        hasStair = true
        break
      end
    end
    if hasStair then break end
  end
  if hasStair then return end

  local spell = newPos.z > oldPos.z and FollowAttack.jumpSpell.down or FollowAttack.jumpSpell.up
  local dir   = creature:getDirection()

  table.insert(FollowAttack.obstaclesQueue, {
    oldPos = oldPos,
    oldTile = g_map.getTile(oldPos),
    spell = spell,
    dir = dir,
    isJump = true
  })
end

-- =========================
-- Hooks de movimento
-- =========================
onCreaturePositionChange(function(creature, newPos, oldPos)
  if FollowAttack.mainMacro and FollowAttack.mainMacro.isOff() then return end
  if not creature or not oldPos then return end

  if creature:getId() == FollowAttack.currentTargetId and newPos and oldPos and oldPos.z == newPos.z then
    FollowAttack.checkIfWentToDoor(creature, newPos, oldPos)
  end
end)

onCreaturePositionChange(function(creature, newPos, oldPos)
  if FollowAttack.mainMacro and FollowAttack.mainMacro.isOff() then return end
  if not creature or not newPos or not oldPos then return end

  if creature:getId() == FollowAttack.currentTargetId and oldPos.z == posz() and oldPos.z ~= newPos.z then
    FollowAttack.checkifWentToJumpPos(creature, newPos, oldPos)
  end
end)

onCreaturePositionChange(function(creature, newPos, oldPos)
  if FollowAttack.mainMacro and FollowAttack.mainMacro.isOff() then return end
  if not creature or not oldPos then return end

  if creature:getId() == FollowAttack.currentTargetId and oldPos.z == posz() and (not newPos or oldPos.z ~= newPos.z) then
    FollowAttack.checkIfWentToCustomId(creature, newPos, oldPos)
  end
end)

-- =========================
-- Limpeza de obstáculos inválidos
-- =========================
macro(1, function()
  if FollowAttack.mainMacro and FollowAttack.mainMacro.isOff() then return end
  local first = FollowAttack.obstaclesQueue[1]
  if not first then return end

  if (not first.isJump and first.tilePos.z ~= posz())
     or (first.isJump and first.oldPos.z ~= posz()) then
    table.remove(FollowAttack.obstaclesQueue, 1)
  end
end)

-- =========================
-- Execução dos obstáculos
-- =========================

-- Escadas
macro(100, function()
  if FollowAttack.mainMacro and FollowAttack.mainMacro.isOff() then return end
  local ob = FollowAttack.obstaclesQueue[1]
  if not ob or not ob.isStair then return end

  local startMs   = NOW()
  local playerPos = pos()
  local walkingTile    = ob.tile
  local walkingTilePos = ob.tilePos

  if FollowAttack.distanceFromPlayer(walkingTilePos) < 2 then
    if FollowAttack.obstacleWalkTime < startMs then
      local nextFloor = g_map.getTile(walkingTilePos) -- refresh
      FollowAttack.obstacleWalkTime = startMs + 250
      if nextFloor:isPathable() then
        use(nextFloor:getTopUseThing())
      else
        FollowAttack.walkToPathDir(findPath(playerPos, walkingTilePos, 1, { ignoreCreatures=false, precision=0, ignoreNonPathable=true }))
      end
      table.remove(FollowAttack.obstaclesQueue, 1)
      return
    end
  end

  local path = findPath(playerPos, walkingTilePos, 50, { ignoreNonPathable=true, precision=0, ignoreCreatures=false })
  if not path or #path <= 1 then
    if not path and walkingTile then
      use(walkingTile:getTopUseThing())
    end
    return
  end

  local tileToUse = playerPos
  for i, step in ipairs(path) do
    if i > 5 then break end
    tileToUse = FollowAttack.getDirection(tileToUse, step)
  end
  tileToUse = g_map.getTile(tileToUse)
  if tileToUse then use(tileToUse:getTopUseThing()) end
end)

-- Portas
macro(1, function()
  if FollowAttack.mainMacro and FollowAttack.mainMacro.isOff() then return end
  local ob = FollowAttack.obstaclesQueue[1]
  if not ob or not ob.isDoor then return end

  local playerPos     = pos()
  local walkingTile   = ob.tile
  local walkingTilePos= ob.tilePos

  local target = g_game.getAttackingCreature()
  if table.compare(playerPos, ob.newPos) then
    FollowAttack.obstacleWalkTime = 0
    table.remove(FollowAttack.obstaclesQueue, 1)
    if target then
      local otherPath = findPath(playerPos, target:getPosition(), 50, { ignoreNonPathable=true, precision=0, ignoreCreatures=false })
      if otherPath and #otherPath > 0 then
        g_game.walk(otherPath[1], false)
      end
    end
    return
  end

  local path = findPath(playerPos, walkingTilePos, 50, { ignoreNonPathable=true, precision=0, ignoreCreatures=false })
  if not path or #path <= 1 then
    if not path and walkingTile then
      if FollowAttack.obstacleWalkTime < NOW() then
        g_game.use(walkingTile:getTopThing())
        FollowAttack.obstacleWalkTime = NOW() + 500
      end
    end
    return
  end
end)

-- Jumps
macro(100, function()
  if FollowAttack.mainMacro and FollowAttack.mainMacro.isOff() then return end
  local ob = FollowAttack.obstaclesQueue[1]
  if not ob or not ob.isJump then return end

  local playerPos     = pos()
  local walkingTilePos= ob.oldPos
  local distance      = FollowAttack.distanceFromPlayer(walkingTilePos)
  if playerPos.z ~= walkingTilePos.z then
    table.remove(FollowAttack.obstaclesQueue, 1)
    return
  end

  local path = findPath(playerPos, walkingTilePos, 50, { ignoreNonPathable=true, precision=0, ignoreCreatures=false })

  if distance == 0 then
    g_game.turn(ob.dir)
    schedule(50, function()
      if FollowAttack.obstaclesQueue[1] == ob then
        say(ob.spell)
      end
    end)
    return
  elseif distance < 2 then
    if FollowAttack.obstacleWalkTime < NOW() then
      FollowAttack.walkToPathDir(findPath(playerPos, walkingTilePos, 1, { ignoreCreatures=false, precision=0, ignoreNonPathable=true }))
      FollowAttack.obstacleWalkTime = NOW() + 500
    end
    return
  elseif distance >= 2 and distance < 5 and path then
    if ob.oldTile then
      use(ob.oldTile:getTopUseThing())
    end
  elseif path then
    local tileToUse = playerPos
    for i, step in ipairs(path) do
      if i > 5 then break end
      tileToUse = FollowAttack.getDirection(tileToUse, step)
    end
    tileToUse = g_map.getTile(tileToUse)
    if tileToUse then use(tileToUse:getTopUseThing()) end
  end
end)

-- Custom IDs
macro(100, function()
  if FollowAttack.mainMacro and FollowAttack.mainMacro.isOff() then return end
  local ob = FollowAttack.obstaclesQueue[1]
  if not ob or not ob.isCustom then return end

  local playerPos     = pos()
  local walkingTile   = ob.tile
  local walkingTilePos= ob.tilePos
  local distance      = FollowAttack.distanceFromPlayer(walkingTilePos)

  if playerPos.z ~= walkingTilePos.z then
    table.remove(FollowAttack.obstaclesQueue, 1)
    return
  end

  if distance == 0 then
    if ob.customId.castSpell then
      say(FollowAttack.defaultSpell)
      return
    end
  elseif distance < 2 then
    local item = findItem and findItem(FollowAttack.defaultItem) or nil
    if ob.customId.castSpell or not item then
      if FollowAttack.obstacleWalkTime < NOW() then
        FollowAttack.walkToPathDir(findPath(playerPos, walkingTilePos, 1, { ignoreCreatures=false, precision=0, ignoreNonPathable=true }))
        FollowAttack.obstacleWalkTime = NOW() + 500
      end
    else
      g_game.useWith(item, walkingTile)
      table.remove(FollowAttack.obstaclesQueue, 1)
    end
    return
  end

  local path = findPath(playerPos, walkingTilePos, 50, { ignoreNonPathable=true, precision=0, ignoreCreatures=false })
  if not path or #path <= 1 then
    if not path and walkingTile then
      use(walkingTile:getTopUseThing())
    end
    return
  end

  local tileToUse = playerPos
  for i, step in ipairs(path) do
    if i > 5 then break end
    tileToUse = FollowAttack.getDirection(tileToUse, step)
  end
  tileToUse = g_map.getTile(tileToUse)
  if tileToUse then use(tileToUse:getTopUseThing()) end
end)

-- =========================
-- Macro principal (Follow)
-- =========================
FollowAttack.mainMacro = macro(MACRO_DELAY, MACRO_NAME, function()
  if not g_game or not g_game.isAttacking or not g_game.isAttacking() then return end

  local playerPos = pos()
  local target    = g_game.getAttackingCreature()
  if not target or not target.getPosition then return end

  local targetPosition = target:getPosition()
  if getDistanceBetween(playerPos, targetPosition) <= 1 then
    return
  end

  local path = findPath(playerPos, targetPosition, 30, FollowAttack.flags)
  if not path then return end

  g_game.setChaseMode(1)

  local tileToUse = playerPos
  for i, step in ipairs(path) do
    if i > 5 then break end
    tileToUse = FollowAttack.getDirection(tileToUse, step)
  end
  tileToUse = g_map.getTile(tileToUse)
  if tileToUse then
    use(tileToUse:getTopUseThing())
  end
end, DEST_TAB)

-- =========================
-- Atualização de currentTargetId e tecla p/ limpar
-- =========================
macro(1, function()
  local target = g_game.getAttackingCreature()
  if target then
    local tid = target:getId()
    if tid ~= FollowAttack.currentTargetId then
      FollowAttack.currentTargetId = tid
    end
  end
end)

onKeyDown(function(key)
  if key == FollowAttack.keyToClearTarget then
    FollowAttack.currentTargetId = nil
  end
end)
