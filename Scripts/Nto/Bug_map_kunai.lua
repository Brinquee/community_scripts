-- ===========================================================
-- NTO - Bug Map Kunai (revisado p/ Community Scripts)
-- - Independente de 'tabName' (usa aba Main)
-- - Fallback se addItem não existir
-- - Uso do item robusto (objeto ou id)
-- ===========================================================

local MACRO_NAME  = 'Bug Map Kunai'
local MACRO_DELAY = 100

-- Destino seguro de UI
local DEST_TAB = getTab("Main") or setDefaultTab("Main")

-- Estado salvo (kunai id)
storage.itemValues = storage.itemValues or {}
storage.itemValues.kunaiId = storage.itemValues.kunaiId or 11863

-- UI para escolher o item (usa addItem da Library se existir)
if type(addItem) == "function" then
  addItem('kunaiId', 'ID Kunai', storage.itemValues.kunaiId, DEST_TAB,
          'Selecione o item/ID usado para o bug com kunai.')
else
  -- fallback simples: mostra e permite editar via TextEdit
  local layout = [[
Panel
  height: 36
  margin-top: 6
  margin-left: 6
  margin-right: 6

  UILabel
    id: lbl
    anchors.left: parent.left
    anchors.top: parent.top
    text-align: left
    color: #d2cac5
    text: ID Kunai

  TextEdit
    id: input
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: lbl.bottom
    margin-top: 3
  ]]
  local w = setupUI(layout, DEST_TAB)
  w.input:setText(tostring(storage.itemValues.kunaiId))
  w.input.onTextChange = function(_, txt)
    local n = tonumber(txt)
    if n then storage.itemValues.kunaiId = n end
  end
end

-- Direções (WASD + QEZX). Ajuste conforme seu servidor
local bugMap = {}
bugMap.directions = {
  -- key = offset + direction(optional) | direction: 0=N,1=E,2=S,3=W
  ["W"] = { x =  0, y = -5, direction = 0 },
  ["E"] = { x =  3, y = -3 },               -- diag NE (sem turn)
  ["D"] = { x =  5, y =  0, direction = 1 },
  ["C"] = { x =  3, y =  3 },               -- diag SE
  ["S"] = { x =  0, y =  5, direction = 2 },
  ["Z"] = { x = -3, y =  3 },               -- diag SW
  ["A"] = { x = -5, y =  0, direction = 3 },
  ["Q"] = { x = -3, y = -3 }                -- diag NW (corrigido)
}

-- Helpers
local function isCtrl()
  return modules.corelib and modules.corelib.g_keyboard and modules.corelib.g_keyboard.isCtrlPressed and modules.corelib.g_keyboard.isCtrlPressed()
end

local function keyPressed(k)
  return modules.corelib and modules.corelib.g_keyboard and modules.corelib.g_keyboard.isKeyPressed and modules.corelib.g_keyboard.isKeyPressed(k)
end

local function topUseThingAt(pos)
  local tile = g_map.getTile(pos)
  return tile and tile:getTopUseThing() or nil
end

local function getUseItem(id)
  -- tenta pegar o objeto do item; se não achar, retorna só o id
  local obj = findItem and findItem(id) or nil
  return obj or id
end

-- Macro principal
macro(MACRO_DELAY, MACRO_NAME, function()
  if modules.game_console and modules.game_console.isChatEnabled and modules.game_console:isChatEnabled() then return end
  if isCtrl() then return end

  local p = pos()
  if not p then return end

  for key, cfg in pairs(bugMap.directions) do
    if keyPressed(key) then
      if cfg.direction then turn(cfg.direction) end
      local tgt = { x = p.x + (cfg.x or 0), y = p.y + (cfg.y or 0), z = p.z }
      local thing = topUseThingAt(tgt)
      if thing then
        local item = getUseItem(storage.itemValues.kunaiId or 11863)
        return useWith(item, thing)
      end
    end
  end
end, DEST_TAB)

-- Separador visual (se existir)
pcall(function() if UI and UI.Separator then UI.Separator(DEST_TAB) end end)
