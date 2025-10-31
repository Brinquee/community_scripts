-- =========================
-- EDIT POTION (3 blocos: Vocacao 1/2/3, cada um HP e MP)
-- sem acentos / OTCv8
-- =========================
setDefaultTab("Tools")

local root = (g_ui and g_ui.getRootWidget and g_ui.getRootWidget()) or rootWidget
if not root then
  print("[EDIT POTION] root nao encontrado")
  return
end

-- ---------- defaults + migracao ----------
storage.potionSets = storage.potionSets or {
  { hp={on=false, title="HP%", item=266,  min=51, max=90}, mp={on=false, title="MP%", item=268,  min=51, max=90} },
  { hp={on=false, title="HP%", item=3160, min=0,  max=50}, mp={on=false, title="MP%", item=3157, min=0,  max=50} },
  { hp={on=false, title="HP%", item=266,  min=51, max=90}, mp={on=false, title="MP%", item=268,  min=51, max=90} },
}
if type(storage.hpitem1)=="table"   then storage.potionSets[1].hp = storage.hpitem1 end
if type(storage.hpitem2)=="table"   then storage.potionSets[2].hp = storage.hpitem2 end
if type(storage.manaitem1)=="table" then storage.potionSets[1].mp = storage.manaitem1 end
if type(storage.manaitem2)=="table" then storage.potionSets[2].mp = storage.manaitem2 end

-- ---------- macros (uma vez) ----------
local macrosReady = false
local potionMacros = {}  -- [setIndex] = { hp = macro, mp = macro }

local function ensurePotionMacros()
  if macrosReady then return end
  potionMacros = {}
  for setIndex=1,3 do
    storage.potionSets[setIndex] = storage.potionSets[setIndex] or {hp={}, mp={}}
    local cfgHp = storage.potionSets[setIndex].hp
    local cfgMp = storage.potionSets[setIndex].mp

    -- HP
    local mHp = macro(20, function()
      local cfg = storage.potionSets[setIndex].hp
      local percent = player:getHealthPercent()
      if cfg.on and cfg.item and cfg.item > 100 and cfg.max >= percent and percent >= cfg.min then
        if TargetBot then
          TargetBot.useItem(cfg.item, cfg.subType, player)
        else
          local thing = g_things.getThingType(cfg.item)
          local subType = (g_game.getClientVersion() >= 860) and 0 or 1
          if thing and thing:isFluidContainer() then subType = cfg.subType or 0 end
          g_game.useInventoryItemWith(cfg.item, player, subType)
        end
      end
    end)
    mHp.setOn(cfgHp.on and (cfgHp.item or 0) > 100)
    potionMacros[setIndex] = potionMacros[setIndex] or {}
    potionMacros[setIndex].hp = mHp

    -- MP
    local mMp = macro(20, function()
      local cfg = storage.potionSets[setIndex].mp
      local mp, mpMax = player:getMana(), math.max(1, player:getMaxMana())
      local percent = math.min(100, math.floor(100 * (mp / mpMax)))
      if cfg.on and cfg.item and cfg.item > 100 and cfg.max >= percent and percent >= cfg.min then
        if TargetBot then
          TargetBot.useItem(cfg.item, cfg.subType, player)
        else
          local thing = g_things.getThingType(cfg.item)
          local subType = (g_game.getClientVersion() >= 860) and 0 or 1
          if thing and thing:isFluidContainer() then subType = cfg.subType or 0 end
          g_game.useInventoryItemWith(cfg.item, player, subType)
        end
      end
    end)
    mMp.setOn(cfgMp.on and (cfgMp.item or 0) > 100)
    potionMacros[setIndex].mp = mMp
  end
  macrosReady = true
end

-- ---------- UI helper (fallback leve se nao existir UI.DualScrollItemPanel) ----------
local function addDualPanelLite(parent, cfg, onChange)
  -- painel container
  local p = UI.Widget()
  p:setHeight(80)
  parent:addChild(p)

  -- titulo
  local title = UI.Label(cfg.title or "")
  title:setColor("#21fff8")
  title:setId("title")
  title:setAnchor(AnchorTop, "parent", AnchorTop, 0)
  title:setMarginTop(2)
  p:addChild(title)

  -- toggle
  local chk = UI.CheckBox("ON")
  chk:setChecked(cfg.on and true or false)
  chk:setAnchor(AnchorTop, "title", AnchorBottom, 2)
  p:addChild(chk)

  -- item id
  local idLbl = UI.Label("Item:")
  idLbl:setAnchor(AnchorLeft, "chk", AnchorRight, 8)
  idLbl:setAnchor(AnchorTop, "chk", AnchorTop, 0)
  p:addChild(idLbl)

  local idEdit = UI.TextEdit()
  idEdit:setWidth(60)
  idEdit:setText(tostring(cfg.item or 0))
  idEdit:setAnchor(AnchorLeft, "idLbl", AnchorRight, 4)
  idEdit:setAnchor(AnchorTop, "chk", AnchorTop, -2)
  p:addChild(idEdit)

  -- barras
  local minLbl = UI.Label("Min")
  minLbl:setAnchor(AnchorTop, "chk", AnchorBottom, 4)
  p:addChild(minLbl)

  local minBar = UI.HorizontalScrollBar()
  minBar:setMinimum(0); minBar:setMaximum(100); minBar:setStep(1)
  minBar:setValue(cfg.min or 0)
  minBar:setAnchor(AnchorLeft, "minLbl", AnchorRight, 4)
  minBar:setAnchor(AnchorRight, "parent", AnchorRight, -60)
  minBar:setAnchor(AnchorTop, "minLbl", AnchorTop, -2)
  p:addChild(minBar)

  local minVal = UI.Label(tostring(cfg.min or 0).."%")
  minVal:setAnchor(AnchorLeft, "minBar", AnchorRight, 4)
  minVal:setAnchor(AnchorTop, "minBar", AnchorTop, 0)
  p:addChild(minVal)

  local maxLbl = UI.Label("Max")
  maxLbl:setAnchor(AnchorTop, "minBar", AnchorBottom, 4)
  p:addChild(maxLbl)

  local maxBar = UI.HorizontalScrollBar()
  maxBar:setMinimum(0); maxBar:setMaximum(100); maxBar:setStep(1)
  maxBar:setValue(cfg.max or 100)
  maxBar:setAnchor(AnchorLeft, "maxLbl", AnchorRight, 4)
  maxBar:setAnchor(AnchorRight, "parent", AnchorRight, -60)
  maxBar:setAnchor(AnchorTop, "maxLbl", AnchorTop, -2)
  p:addChild(maxBar)

  local maxVal = UI.Label(tostring(cfg.max or 100).."%")
  maxVal:setAnchor(AnchorLeft, "maxBar", AnchorRight, 4)
  maxVal:setAnchor(AnchorTop, "maxBar", AnchorTop, 0)
  p:addChild(maxVal)

  -- eventos
  local function commit()
    local newCfg = {
      on    = chk:isChecked(),
      title = cfg.title,
      item  = tonumber(idEdit:getText()) or 0,
      min   = minBar:getValue(),
      max   = maxBar:getValue(),
      subType = cfg.subType
    }
    onChange(nil, newCfg)
  end
  chk.onCheckChange      = function() commit() end
  idEdit.onTextChange    = function() commit() end
  minBar.onValueChange   = function(_,v) minVal:setText(v.."%"); commit() end
  maxBar.onValueChange   = function(_,v) maxVal:setText(v.."%"); commit() end

  return p
end

local function DualPanel(parent, cfg, onChange)
  if UI.DualScrollItemPanel then
    return UI.DualScrollItemPanel(cfg, onChange, parent)
  else
    return addDualPanelLite(parent, cfg, onChange)
  end
end

-- ---------- UI ----------
local function toggleEditPanel()
  local win = root:getChildById("editPotionPanel")
  if win then win:destroy(); return end

  local ui = setupUI([[
MainWindow
  id: editPotionPanel
  text: "PAINEL EDIT POTION"
  size: 300 420
  color: #21fff8
  background-color: black
  opacity: 0.9

  ScrollablePanel
    id: body
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeButton.top
    margin-left: 6
    margin-right: 6
    margin-top: 6
    margin-bottom: 6
    layout:
      type: verticalBox
      fit-children: true

  Button
    id: closeButton
    text: "Fechar"
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    margin-right: 6
    margin-bottom: 6
    width: 72
    color: red
]], root)

  ui:centerIn(root)
  ui.closeButton.onClick = function() ui:destroy() end
  ensurePotionMacros()

  local function addSet(setIndex)
    local title = UI.Label("Vocacao " .. tostring(setIndex))
    title:setColor("#21fff8")
    ui.body:addChild(title)

    DualPanel(ui.body, storage.potionSets[setIndex].hp, function(_, newParams)
      storage.potionSets[setIndex].hp = newParams
      local m = potionMacros[setIndex] and potionMacros[setIndex].hp
      if m then m.setOn(newParams.on and (newParams.item or 0) > 100) end
    end)

    DualPanel(ui.body, storage.potionSets[setIndex].mp, function(_, newParams)
      storage.potionSets[setIndex].mp = newParams
      local m = potionMacros[setIndex] and potionMacros[setIndex].mp
      if m then m.setOn(newParams.on and (newParams.item or 0) > 100) end
    end)

    local sep = UI.Label(" ")
    sep:setColor("black")
    ui.body:addChild(sep)
  end

  addSet(1); addSet(2); addSet(3)

  if g_game.getClientVersion() < 780 then
    local warn = UI.Label("Old tibia: abrir mochila com potions para funcionar.")
    warn:setColor("white"); ui.body:addChild(warn)
  end
end

-- botao no painel do bot (sem duplicar)
if btnEditPotions and not btnEditPotions:isDestroyed() then
  btnEditPotions:destroy()
end
btnEditPotions = UI.Button("EDIT POTION", toggleEditPanel)
btnEditPotions:setColor("#21fff8")
