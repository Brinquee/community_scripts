-- =========================================================
-- COMBOS (painel principal + sub-painel EDIT + execucao sequencial LOOP)
-- OTCv8 / aba "Tools" / sem acentos
-- =========================================================

local TARGET_TAB = "Tools"
setDefaultTab(TARGET_TAB)

local root = (g_ui and g_ui.getRootWidget and g_ui.getRootWidget()) or rootWidget
if not root then
  print("[COMBOS] root nao encontrado"); return
end

-- -------------------------
-- Defaults persistentes
-- -------------------------
-- Cada combo:
-- { on=true/false, name="texto", steps={ {spell="fala", delay=400, minMana=0}, ... }, idx=1, lastAt=0 }
if type(storage.comboList) ~= "table" then
  storage.comboList = {
    {
      on=false, name="Combo Tobirama",
      steps = {
        { spell="suiton suiryudan no jutsu", delay=300, minMana=0 },
        { spell="suiton bakusui shouha",     delay=300, minMana=0 },
        { spell="suiton teppodama",          delay=280, minMana=0 },
        { spell="suiton tenkyu",             delay=280, minMana=0 },
        { spell="daibakufu no jutsu",        delay=320, minMana=0 },
        { spell="suiton goshokuzame",        delay=320, minMana=0 },
        { spell="suiton suishoha",           delay=350, minMana=0 },
      },
      idx=1, lastAt=0
    }
  }
end

storage.comboGlobalGap = storage.comboGlobalGap or 120 -- ms entre casts globais

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
-- PAINEL PRINCIPAL
-- -------------------------
local mainUI = nil

local function refreshDelAllState()
  if not mainUI then return end
  local delBtn = mainUI:getChildById("delAllButton")
  local empty = (#storage.comboList == 0)
  delBtn:setEnabled(not empty)
  delBtn:setColor(empty and "#666666" or "#f6ff13")
  delBtn:setText(empty and "DEL LISTA (0)" or "DEL LISTA")
end

local function cardStyle(isOn)
  if isOn then
    return "min-height: 64px; padding: 6px; border-width: 1px; border-color: #1fff6a; background-color: #122a1a; border-radius: 6px;"
  else
    return "min-height: 64px; padding: 6px; border-width: 1px; border-color: #2a2a2a; background-color: #1a1a1a; border-radius: 6px;"
  end
end

-- Forward decls
local rebuildMainBody, mountComboCard

-- Sub-painel: EDITA COMBO (nome + steps)
local function openEditCombo(idx)
  local combo = storage.comboList[idx]; if not combo then return end

  -- fecha instancias antigas
  local old = root:getChildById("comboEditor")
  if old then old:destroy() end

  local w = setupUI([[
MainWindow
  id: comboEditor
  text: "EDITA COMBO"
  size: 380 420
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
    text: "Edite o nome e os passos (magias)"

  Label
    id: nameLbl
    anchors.top: header.bottom
    anchors.left: parent.left
    margin-left: 10
    margin-top: 6
    text: "name:"

  TextEdit
    id: nameEdit
    anchors.top: nameLbl.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-left: 10
    margin-right: 10
    height: 24

  ScrollablePanel
    id: stepsBody
    anchors.top: nameEdit.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: btnRow.top
    margin-left: 10
    margin-right: 10
    margin-top: 8
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
    id: closeBtn
    text: "Fechar"
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-right: 10
    margin-bottom: 10
    width: 80
    color: red

  Button
    id: addStepBtn
    text: "ADD PASSO"
    anchors.right: closeBtn.left
    anchors.bottom: parent.bottom
    margin-right: 8
    margin-bottom: 10
    width: 110
    color: #12ff3d

  Button
    id: clearStepsBtn
    text: "DEL PASSOS"
    anchors.right: addStepBtn.left
    anchors.bottom: parent.bottom
    margin-right: 8
    margin-bottom: 10
    width: 110
    color: #fcff80
]], root)

  local nameEdit      = w:getChildById("nameEdit")
  local stepsBody     = w:getChildById("stepsBody")
  local addStepBtn    = w:getChildById("addStepBtn")
  local clearStepsBtn = w:getChildById("clearStepsBtn")
  local closeBtn      = w:getChildById("closeBtn")

  nameEdit:setText(combo.name or "")

  local function mountStepRow(i)
    local step = combo.steps[i]; if not step then return end
    local row = setupUI([[
Panel
  height: 64
  layout:
    type: verticalBox
    fit-children: true
]], stepsBody)
    row:setStyle("margin-top: 6px; padding: 6px; background-color: #202020; border-radius: 6px;")

    local t = UI.Label(string.format("%d) spell: %s", i, step.spell or ""))
    t:setColor("#05ffec"); row:addChild(t)

    local info = UI.Label(string.format("delay=%dms  mana>=%d", num(step.delay,0), num(step.minMana,0)))
    info:setColor("#9aa0a6"); info:setStyle("margin-top: 2px;"); row:addChild(info)

    local btnRow = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    fit-children: true
]], row)
    btnRow:setStyle("margin-top: 6px;")

    local btnEdit = UI.Button("EDIT", function()
      local e = setupUI([[
MainWindow
  id: stepEditor
  text: "EDITA PASSO"
  size: 300 250
  color: #fffe12
  background-color: black
  opacity: 0.95

  Label
    id: l1
    anchors.top: parent.top
    anchors.left: parent.left
    margin-left: 10
    margin-top: 8
    text: "spell:"

  TextEdit
    id: spellEdit
    anchors.top: l1.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-left: 10
    margin-right: 10
    height: 22

  Label
    id: l2
    anchors.top: spellEdit.bottom
    anchors.left: parent.left
    margin-left: 10
    margin-top: 6
    text: "delay(ms):"

  TextEdit
    id: delayEdit
    anchors.top: l2.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-left: 10
    margin-right: 10
    height: 22

  Label
    id: l3
    anchors.top: delayEdit.bottom
    anchors.left: parent.left
    margin-left: 10
    margin-top: 6
    text: "min mana % (0=ignora):"

  TextEdit
    id: manaEdit
    anchors.top: l3.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-left: 10
    margin-right: 10
    height: 22

  Button
    id: cancelBtn
    text: "Cancelar"
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    margin-left: 10
    margin-bottom: 10
    width: 100
    color: red

  Button
    id: saveBtn
    text: "Salvar"
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-right: 10
    margin-bottom: 10
    width: 80
    color: green
]], root)

      local spellEdit = e:getChildById("spellEdit")
      local delayEdit = e:getChildById("delayEdit")
      local manaEdit  = e:getChildById("manaEdit")
      local cancelBtn = e:getChildById("cancelBtn")
      local saveBtn   = e:getChildById("saveBtn")

      spellEdit:setText(step.spell or "")
      delayEdit:setText(tostring(num(step.delay or 0, 0)))
      manaEdit:setText(tostring(num(step.minMana or 0, 0)))

      cancelBtn.onClick = function() e:destroy() end
      saveBtn.onClick = function()
        step.spell   = spellEdit:getText()
        step.delay   = num(delayEdit:getText(), 0)
        step.minMana = num(manaEdit:getText(), 0)
        e:destroy()
        stepsBody:destroyChildren()
        for j=1,#combo.steps do mountStepRow(j) end
      end
    end)
    btnEdit:setWidth(52); btnEdit:setStyle("margin-right: 6px;"); btnRow:addChild(btnEdit)

    local btnDel = UI.Button("DEL", function()
      table.remove(combo.steps, i)
      stepsBody:destroyChildren()
      for j=1,#combo.steps do mountStepRow(j) end
    end)
    btnDel:setWidth(52); btnDel:setColor("#ff0404"); btnRow:addChild(btnDel)
  end

  local function rebuildSteps()
    stepsBody:destroyChildren()
    for i=1,#combo.steps do mountStepRow(i) end
  end

  rebuildSteps()

  addStepBtn.onClick = function()
    table.insert(combo.steps, { spell="", delay=300, minMana=0 })
    rebuildSteps()
  end

  clearStepsBtn.onClick = function()
    combo.steps = {}
    rebuildSteps()
  end

  w:getChildById("closeBtn").onClick = function()
    combo.name = nameEdit:getText()
    w:destroy()
    if mainUI then rebuildMainBody() end
  end
end

-- monta um card de combo no painel principal
function mountComboCard(card, idx)
  local c = storage.comboList[idx]; if not c then return end

  card:destroyChildren()
  card:setStyle(cardStyle(c.on))

  local title = UI.Label(string.format("%d) %s", idx, (c.name and c.name ~= "" and c.name) or ("Combo "..idx)))
  title:setColor(c.on and "#05ffec" or "#bbbbbb"); card:addChild(title)

  local count = (type(c.steps)=="table") and #c.steps or 0
  local info = UI.Label(string.format("%d passo(s)", count))
  info:setColor("#9aa0a6"); info:setStyle("margin-top: 2px;"); card:addChild(info)

  local btnRow = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    fit-children: true
]], card)
  btnRow:setStyle("margin-top: 6px;")

  local function applyOnOffStyle(btn)
    btn:setText(c.on and "ON" or "OFF")
    btn:setColor(c.on and "#21ff25" or "#666666")
  end

  local btnOn = UI.Button("OFF", function()
    local newState = not c.on
    for i,_ in ipairs(storage.comboList) do
      local it = storage.comboList[i]
      it.on = false; it.idx = 1; it.lastAt = 0
    end
    c.on = newState
    if mainUI then rebuildMainBody() end
  end)
  btnOn:setWidth(60); btnOn:setStyle("margin-right: 6px;"); applyOnOffStyle(btnOn); btnRow:addChild(btnOn)

  local btnEd = UI.Button("EDIT", function() openEditCombo(idx) end)
  btnEd:setWidth(52); btnEd:setStyle("margin-right: 6px;"); btnRow:addChild(btnEd)

  local btnDel = UI.Button("DEL", function()
    table.remove(storage.comboList, idx)
    if mainUI then rebuildMainBody() end
  end)
  btnDel:setWidth(52); btnDel:setColor("#ff0404"); btnRow:addChild(btnDel)
end

function rebuildMainBody()
  if not mainUI then return end
  local body = mainUI:getChildById("body"); if not body then return end
  body:destroyChildren()

  local n = #storage.comboList
  if n == 0 then
    local empty = UI.Label("Lista vazia — clique em 'ADD COMBO'")
    empty:setColor("#aaaaaa"); empty:setStyle("margin-top: 6px;")
    body:addChild(empty); refreshDelAllState(); return
  end

  local zebraA, zebraB = "#0b0b0b", "#202020"
  local i, rowIndex = 1, 1
  while i <= n do
    local row = setupUI([[
Panel
  height: 76
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
    cardA:setWidth(180); mountComboCard(cardA, i)

    if i + 1 <= n then
      local cardB = setupUI([[
Panel
  layout:
    type: verticalBox
    fit-children: true
]], row)
      cardB:setWidth(180); cardB:setStyle("margin-left: 8px;")
      mountComboCard(cardB, i + 1)
    end

    i = i + 2; rowIndex = rowIndex + 1
  end

  refreshDelAllState()
end

local function toggleMainPanel()
  local old = root:getChildById("combosMain")
  if old then old:destroy(); old = nil; return end

  mainUI = setupUI([[
MainWindow
  id: combosMain
  text: "CENTRAL DE COMBOS"
  size: 420 420
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
    text: "FECHAR"
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    margin-right: 10
    margin-bottom: 10
    width: 90
    color: red

  Button
    id: addButton
    text: "ADD COMBO"
    anchors.bottom: parent.bottom
    anchors.right: closeButton.left
    margin-right: 8
    margin-bottom: 10
    width: 120
    color: #12ff3d

  Button
    id: delAllButton
    text: "DEL LISTA"
    anchors.bottom: parent.bottom
    anchors.right: addButton.left
    margin-right: 8
    margin-bottom: 10
    width: 120
    color: #fcff80
]], root)

  local closeBtn  = mainUI:getChildById("closeButton")
  local addBtn    = mainUI:getChildById("addButton")
  local delAllBtn = mainUI:getChildById("delAllButton")

  closeBtn.onClick = function() if mainUI then mainUI:destroy(); mainUI = nil end end

  addBtn.onClick = function()
    table.insert(storage.comboList, { on=false, name="Combo", steps={}, idx=1, lastAt=0 })
    rebuildMainBody(); refreshDelAllState()
  end

  delAllBtn.onClick = function()
    storage.comboList = {}
    rebuildMainBody(); refreshDelAllState()
  end

  rebuildMainBody()
end

-- Botao para abrir o painel principal (sem duplicar)
if btnCombos and not btnCombos:isDestroyed() then btnCombos:destroy() end
btnCombos = UI.Button("(COMBOS)", toggleMainPanel)
btnCombos:setWidth(100)
btnCombos:setColor("#ecff21")

-- -------------------------
-- MACRO: executa o primeiro combo ON (LOOP continuo)
-- -------------------------
local lastGlobalCast = 0
macro(100, function()
  -- encontra o primeiro combo ligado
  local activeIdx = nil
  for i,c in ipairs(storage.comboList) do
    if c.on then activeIdx = i; break end
  end
  if not activeIdx then return end

  local combo = storage.comboList[activeIdx]
  combo.idx = num(combo.idx, 1)
  if type(combo.steps) ~= "table" or #combo.steps == 0 then
    combo.on = false; return
  end

  local tnow = nowMs()
  if tnow - lastGlobalCast < num(storage.comboGlobalGap, 120) then return end

  local mp = (manapercent and manapercent()) or 100
  local step = combo.steps[combo.idx]; if not step then combo.idx = 1; return end

  local needMana = num(step.minMana, 0)
  if needMana > 0 and mp < needMana then return end

  local needDelay = num(step.delay, 0)
  local lastAt    = num(combo.lastAt, 0)
  if tnow - lastAt < needDelay then return end

  if modules and modules.game_cooldown and modules.game_cooldown.isCoolingDown and modules.game_cooldown:isCoolingDown() then
    return
  end

  local sp = (step.spell or "")
  if sp ~= "" then say(sp) end

  combo.lastAt = tnow
  lastGlobalCast = tnow

  -- avanca passo (loop)
  combo.idx = combo.idx + 1
  if combo.idx > #combo.steps then combo.idx = 1 end
end)
