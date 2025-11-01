-- =========================================================
-- FUGA (botao + painel EDIT + macro por HP%)
-- OTCv8 / aba "Tools" / sem acentos
-- =========================================================

local TARGET_TAB = "Tools"
setDefaultTab(TARGET_TAB)

local root = (g_ui and g_ui.getRootWidget and g_ui.getRootWidget()) or rootWidget
if not root then
  print("[FUGA] root nao encontrado"); return
end

-- -------------------------
-- Defaults persistentes
-- -------------------------
storage.escapeEnabled = (storage.escapeEnabled ~= false)

-- Cada item:
-- { on=true/false, name="texto", spell="fala", hp=65, cooldown=1000, minMana=0, safe=1500, last=0 }
if type(storage.escapeList) ~= "table" then
  storage.escapeList = {
    { on=true, name="Fuga 65%", spell="exana mas res", hp=65, cooldown=1200, minMana=0, safe=2000, last=0 },
  }
end

-- -------------------------
-- Utils
-- -------------------------
local function num(v, d) v = tonumber(v); if not v then return d end; return v end
local function nowMs()
  if type(now) == "number" then return now end
  if type(now) == "function" then local ok,res = pcall(now); if ok and type(res)=="number" then return res end end
  if g_clock and g_clock.millis then return g_clock.millis() end
  return math.floor(os.clock()*1000)
end

-- -------------------------
-- Estado de UI
-- -------------------------
local editUI = nil

local function refreshDelAllState()
  if not editUI then return end
  local delBtn = editUI:getChildById("delAllButton")
  if not delBtn then return end
  local empty = (#storage.escapeList == 0)
  delBtn:setEnabled(not empty)
  delBtn:setColor(empty and "#666666" or "#f6ff13")
  delBtn:setText(empty and "DEL LISTA (0)" or "DEL LISTA")
end

local function cardStyle(isOn)
  if isOn then
    return "min-height: 54px; padding: 6px; border-width: 1px; border-color: #1fff6a; background-color: #122a1a; border-radius: 4px;"
  else
    return "min-height: 54px; padding: 6px; border-width: 1px; border-color: #2a2a2a; background-color: #1a1a1a; border-radius: 4px;"
  end
end

local function setOnOffVisual(btn, isOn)
  if not btn then return end
  if isOn then
    btn:setText("ON");  btn:setColor("#21ff25")
  else
    btn:setText("OFF"); btn:setColor("#888888")
  end
end

-- monta/atualiza um card
local function mountEscapeCard(card, idx, rebuildEditBody)
  local b = storage.escapeList[idx]; if not b then return end
  card:destroyChildren()
  card:setStyle(cardStyle(b.on))

  local shownName = (b.name and b.name ~= "" and b.name)
                    or (b.spell and b.spell ~= "" and b.spell)
                    or ("Fuga "..idx)

  local nameLbl = UI.Label(string.format("%d) %s", idx, shownName))
  nameLbl:setColor(b.on and "#05ffec" or "#bbbbbb")
  card:addChild(nameLbl)

  local btnRow = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    fit-children: true
]], card)
  btnRow:setStyle("margin-top: 6px;")

  local btnOn = UI.Button("ON/OFF", function()
    b.on = not b.on
    rebuildEditBody()
    refreshDelAllState()
  end)
  btnOn:setWidth(60)
  btnOn:setStyle("margin-right: 6px;")
  setOnOffVisual(btnOn, b.on)
  btnRow:addChild(btnOn)

  local btnEd = UI.Button("EDIT", function()
    local old = root:getChildById("escapeItemEditor")
    if old then old:destroy() end

    local w = setupUI([[
MainWindow
  id: escapeItemEditor
  text: "EDITA FUGA"
  size: 300 360
  color: #fffe12
  background-color: black
  opacity: 0.95

  Label
    id: header
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    margin-left: 10
    margin-right: 10
    margin-top: 8
    text: "Edite e clique Salvar"

  ScrollablePanel
    id: form
    anchors.top: header.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: btnRow.top
    margin-left: 10
    margin-right: 10
    margin-top: 6
    layout:
      type: verticalBox

  Panel
    id: btnRow
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 40
    layout:
      type: horizontalBox
      fit-children: true

  Button
    id: cancelBtn
    text: "Cancelar"
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    margin-left: 10
    margin-bottom: 8
    width: 100
    color: red

  Button
    id: saveBtn
    text: "Salvar"
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-right: 10
    margin-bottom: 8
    width: 80
    color: green
]], root)

    local form    = w:getChildById("form")
    local cancelB = w:getChildById("cancelBtn")
    local saveB   = w:getChildById("saveBtn")

    local function mkLabel(t) local l = UI.Label(t); l:setColor("#dddddd"); l:setStyle("margin-top: 6px;"); form:addChild(l); return l end
    local function mkEdit(id) local e = UI.TextEdit(); e:setId(id); e:setHeight(22); e:setStyle("margin-top: 2px;"); form:addChild(e); return e end

    mkLabel("name:");                    local nameEdit = mkEdit("nameEdit")
    mkLabel("spell:");                   local spellEdit = mkEdit("spellEdit")
    mkLabel("hp% (dispara quando <=):"); local hpEdit    = mkEdit("hpEdit")
    mkLabel("cooldown(ms):");            local cdEdit    = mkEdit("cdEdit")
    mkLabel("min mana % (0 ignora):");   local mpEdit    = mkEdit("mpEdit")
    mkLabel("safe recast (ms):");        local safeEdit  = mkEdit("safeEdit")

    nameEdit:setText(b.name or "")
    spellEdit:setText(b.spell or "")
    hpEdit:setText(tostring(num(b.hp or 0, 65)))
    cdEdit:setText(tostring(num(b.cooldown or 0, 1000)))
    mpEdit:setText(tostring(num(b.minMana or 0, 0)))
    safeEdit:setText(tostring(num(b.safe or 0, 1500)))

    cancelB.onClick = function() w:destroy() end
    saveB.onClick = function()
      b.name     = nameEdit:getText()
      b.spell    = spellEdit:getText()
      b.hp       = num(hpEdit:getText(), 65)
      b.cooldown = num(cdEdit:getText(), 1000)
      b.minMana  = num(mpEdit:getText(), 0)
      b.safe     = num(safeEdit:getText(), 1500)
      w:destroy()
      rebuildEditBody()
      refreshDelAllState()
    end
  end)
  btnEd:setWidth(52)
  btnEd:setStyle("margin-right: 6px;")
  btnRow:addChild(btnEd)

  local btnDel = UI.Button("DEL", function()
    table.remove(storage.escapeList, idx)
    rebuildEditBody()
    refreshDelAllState()
  end)
  btnDel:setWidth(52)
  btnDel:setColor("#ff0404")
  btnRow:addChild(btnDel)
end

-- Rebuild: 2 cards por linha (zebra)
local function rebuildEditBody()
  if not editUI then return end
  local body = editUI:getChildById("body"); if not body then return end
  body:destroyChildren()

  local n = #storage.escapeList
  if n == 0 then
    local empty = UI.Label("Lista vazia — clique em 'NOVO FUGA'")
    empty:setColor("#aaaaaa")
    empty:setStyle("margin-top: 6px;")
    body:addChild(empty)
    refreshDelAllState()
    return
  end

  local zebraA, zebraB = "#0b0b0b", "#202020"
  local i, rowIndex = 1, 1
  while i <= n do
    local row = setupUI([[
Panel
  height: 64
  layout:
    type: horizontalBox
    fit-children: true
]], body)

    local bg = (rowIndex % 2 == 1) and zebraA or zebraB
    row:setStyle("margin-top: 6px; padding: 6px; background-color: "..bg.."; border-radius: 6px;")

    local cardA = setupUI([[
Panel
  layout:
    type: verticalBox
    fit-children: true
]], row)
    cardA:setWidth(170)
    mountEscapeCard(cardA, i, rebuildEditBody)

    if i + 1 <= n then
      local cardB = setupUI([[
Panel
  layout:
    type: verticalBox
    fit-children: true
]], row)
      cardB:setWidth(170)
      cardB:setStyle("margin-left: 8px;")
      mountEscapeCard(cardB, i + 1, rebuildEditBody)
    end

    i = i + 2
    rowIndex = rowIndex + 1
  end

  refreshDelAllState()
end

-- Abre/fecha painel
local function toggleEditPanel()
  local old = root:getChildById("editPanelEscape")
  if old then old:destroy(); editUI = nil; return end

  editUI = setupUI([[
MainWindow
  id: editPanelEscape
  text: "CENTRAL DE FUGA"
  size: 380 380
  color: #f7ff12
  background-color: black
  opacity: 0.92

  ScrollablePanel
    id: body
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeButton.top
    margin-left: 10
    margin-right: 10
    margin-top: 10
    layout:
      type: verticalBox

  Button
    id: closeButton
    text: "Fechar"
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    margin-right: 10
    margin-bottom: 10
    width: 80
    color: red

  Button
    id: addButton
    text: "NOVO FUGA"
    anchors.bottom: parent.bottom
    anchors.right: closeButton.left
    margin-right: 8
    margin-bottom: 10
    width: 100
    color: #12ff3d

  Button
    id: delAllButton
    text: "DEL LISTA"
    anchors.bottom: parent.bottom
    anchors.right: addButton.left
    margin-right: 8
    margin-bottom: 10
    width: 100
    color: #fcff80
]], root)

  editUI:getChildById("closeButton").onClick = function() if editUI then editUI:destroy(); editUI = nil end end
  editUI:getChildById("addButton").onClick = function()
    table.insert(storage.escapeList, { on=true, name="Fuga", spell="", hp=65, cooldown=1000, minMana=0, safe=1500, last=0 })
    rebuildEditBody(); refreshDelAllState()
  end
  editUI:getChildById("delAllButton").onClick = function()
    storage.escapeList = {}
    rebuildEditBody(); refreshDelAllState()
  end

  rebuildEditBody()
end

-- -------------------------
-- Botoes no painel do bot (sem duplicar)
-- -------------------------
if btnEscapeBrq and not btnEscapeBrq:isDestroyed() then btnEscapeBrq:destroy() end
if btnEscapeEditBrq and not btnEscapeEditBrq:isDestroyed() then btnEscapeEditBrq:destroy() end

btnEscapeBrq = UI.Button("(FUGA)", function()
  storage.escapeEnabled = not storage.escapeEnabled
  local state = storage.escapeEnabled and "ON" or "OFF"
  btnEscapeBrq:setText("(FUGA "..state..")")
  btnEscapeBrq:setColor(storage.escapeEnabled and "#21fff8" or "#666666")
end)
btnEscapeBrq:setWidth(100)
btnEscapeBrq:setStyle("margin-right: 6px;")
btnEscapeBrq:setText("(FUGA "..(storage.escapeEnabled and "ON" or "OFF")..")")
btnEscapeBrq:setColor(storage.escapeEnabled and "#21fff8" or "#666666")

btnEscapeEditBrq = UI.Button("(EDITAR FUGA)", toggleEditPanel)
btnEscapeEditBrq:setWidth(120)
btnEscapeEditBrq:setColor("#ecff21")

-- -------------------------
-- MACRO: dispara spell quando HP% <= alvo
-- -------------------------
local lastCastAt = 0
macro(150, function()
  if not storage.escapeEnabled then return end
  if modules and modules.game_cooldown and modules.game_cooldown.isCoolingDown and modules.game_cooldown:isCoolingDown() then return end

  local hp = (hppercent and hppercent()) or 100
  local mp = (manapercent and manapercent()) or 100
  local tnow = nowMs()

  for _, b in ipairs(storage.escapeList) do
    if b.on and (b.spell or "") ~= "" then
      local needMana = num(b.minMana, 0)
      local hpTrig   = num(b.hp, 65)
      local cd       = num(b.cooldown, 1000)
      local safe     = num(b.safe, 1500)
      b.last         = num(b.last, 0)

      local shouldFire = (hp <= hpTrig)
      local cdReady = (tnow - lastCastAt >= 300) and (tnow - b.last >= math.max(0, cd - safe))

      if shouldFire and cdReady and (needMana == 0 or mp >= needMana) then
        say(b.spell)
        b.last = tnow
        lastCastAt = tnow
        break -- evita flood
      end
    end
  end
end)
