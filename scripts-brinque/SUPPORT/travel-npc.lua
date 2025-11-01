-- =========================================================
-- TRAVEL NPC (painel compacto + sem schedule/scheduleEvent)
-- OTCv8 / aba "Tools" / sem emojis
-- =========================================================

setDefaultTab("Tools")

local root = g_ui.getRootWidget() or rootWidget
if not root then
  print("[TRAVEL] root nao encontrado"); return
end

-- -------------------------
-- Storage (padroes editaveis)
-- -------------------------
storage.travelCfg = storage.travelCfg or {
  npcName = "Minoru",
  autoShowNearNpc = true,
  cities = {
    "Sunagakure",
    "Konohagakure",
    "Iwagakure",
    "South Florest",
    "South Desert",
    "Kumogakure",
    "West Desert",
    "Nick City"
  }
}

-- Estado interno (maquina de estados sem schedule)
local travelState = {
  pending = false,
  city = nil,
  stage = 0,       -- 0=idle, 1=hi, 2=city, 3=yes
  nextAt = 0
}

local function nowMs()
  return (g_clock and g_clock.millis and g_clock.millis()) or math.floor(os.clock()*1000)
end

-- Compat talk NPC
local NPC = {}
NPC.talk = function(text)
  if g_game.getClientVersion() >= 810 then
    g_game.talkChannel(11, 0, text)
  else
    say(text)
  end
end

-- --------------- UI (anti-dup) ---------------
local oldWin = root:getChildById("travelPanelBrq")
if oldWin then oldWin:destroy() end
if btnTravelBrq and not btnTravelBrq:isDestroyed() then btnTravelBrq:destroy() end

local travelUI = setupUI([[
MainWindow
  id: travelPanelBrq
  text: "TRAVEL"
  size: 220 150
  color: #21fff8
  background-color: black
  opacity: 0.92

  Label
    id: titleLabel
    text: "Select destination"
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    margin-top: 8
    color: white
    font: sans-bold-14px

  ComboBox
    id: travelOptions
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: titleLabel.bottom
    margin-top: 10
    text-align: center
    color: yellow
    font: sans-bold-14px

  Label
    id: statusLabel
    text: "Waiting..."
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: travelOptions.bottom
    margin-top: 8
    color: gray
    font: verdana-11px

  Button
    id: closeButton
    text: "Fechar"
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-right: 8
    margin-bottom: 8
    width: 70
    color: red

  Button
    id: editButton
    text: "EDIT"
    anchors.right: closeButton.left
    anchors.bottom: parent.bottom
    margin-right: 8
    margin-bottom: 8
    width: 60
    color: #21fff8
]], root)

travelUI:hide()
pcall(function() travelUI:move(600,150) end)

-- Preenche combo
local function reloadCities()
  travelUI.travelOptions:clearOptions()
  travelUI.travelOptions:addOption("Select destination")
  for _, city in ipairs(storage.travelCfg.cities or {}) do
    travelUI.travelOptions:addOption(city)
  end
end
reloadCities()

-- Botao principal no painel do bot
btnTravelBrq = UI.Button("(TRAVEL)", function()
  if travelUI:isVisible() then travelUI:hide() else travelUI:show() end
end)
btnTravelBrq:setWidth(90)
btnTravelBrq:setColor("#21fff8")

-- Mostrar/ocultar automatico quando perto do NPC
macro(200, "TRAVEL NEAR-NPC", function()
  if not storage.travelCfg.autoShowNearNpc then return end
  local npc = getCreatureByName(storage.travelCfg.npcName or "")
  if npc and getDistanceBetween(pos(), npc:getPosition()) <= 3 then
    travelUI:show()
  else
    -- so esconde automatico se nao estiver com viagem pendente
    if not travelState.pending then
      travelUI:hide()
    end
  end
end)

-- Fechar
travelUI.closeButton.onClick = function()
  travelUI:hide()
end

-- Editor simples (NPC + cidades separadas por virgula)
local editWin = nil
local function toggleEdit()
  if editWin and not editWin:isDestroyed() then editWin:destroy(); editWin=nil; return end
  editWin = setupUI([[
MainWindow
  id: travelEditBrq
  text: "EDIT TRAVEL"
  size: 300 220
  color: #21fff8
  background-color: black
  opacity: 0.94

  Label
    id: l1
    text: "NPC name:"
    anchors.top: parent.top
    anchors.left: parent.left
    margin-left: 10
    margin-top: 10
    color: #cccccc

  TextEdit
    id: npcEdit
    anchors.top: l1.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-left: 10
    margin-right: 10
    height: 22

  Label
    id: l2
    text: "Cities (comma separated):"
    anchors.top: npcEdit.bottom
    anchors.left: parent.left
    margin-left: 10
    margin-top: 8
    color: #cccccc

  TextEdit
    id: citiesEdit
    anchors.top: l2.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: btnRow.top
    margin-left: 10
    margin-right: 10
    margin-top: 2
    height: 70
    multiline: true

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
    id: saveBtn
    text: "Salvar"
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-right: 10
    margin-bottom: 8
    width: 80
    color: green

  Button
    id: cancelBtn
    text: "Fechar"
    anchors.right: saveBtn.left
    anchors.bottom: parent.bottom
    margin-right: 8
    margin-bottom: 8
    width: 80
    color: red
]], root)

  editWin.npcEdit:setText(storage.travelCfg.npcName or "Minoru")
  editWin.citiesEdit:setText(table.concat(storage.travelCfg.cities or {}, ", "))

  editWin.cancelBtn.onClick = function() if editWin then editWin:destroy(); editWin=nil end end
  editWin.saveBtn.onClick = function()
    storage.travelCfg.npcName = editWin.npcEdit:getText()
    local raw = editWin.citiesEdit:getText() or ""
    local list = {}
    for token in string.gmatch(raw, "([^,]+)") do
      local city = token:gsub("^%s+", ""):gsub("%s+$","")
      if city ~= "" then table.insert(list, city) end
    end
    if #list > 0 then storage.travelCfg.cities = list end
    reloadCities()
    if editWin then editWin:destroy(); editWin=nil end
  end
end

travelUI.editButton.onClick = toggleEdit

-- Selecionar destino -> inicia sequencia (sem schedule)
travelUI.travelOptions.onOptionChange = function(_, option)
  if option == "Select destination" then return end
  travelState.city = option
  travelState.pending = true
  travelState.stage = 1
  travelState.nextAt = nowMs()            -- pode mandar "hi" imediatamente
  travelUI.statusLabel:setText("Talking to ".. (storage.travelCfg.npcName or "NPC") .."...")
  travelUI.statusLabel:setColor("orange")
end

-- Loop da sequencia de fala (hi -> city -> yes)
macro(100, "TRAVEL SEQ", function()
  if not travelState.pending then return end

  local npcName = storage.travelCfg.npcName or ""
  local npc = getCreatureByName(npcName)
  if not (npc and getDistanceBetween(pos(), npc:getPosition()) <= 3) then
    travelUI.statusLabel:setText("Aproxime-se de ".. npcName ..".")
    travelUI.statusLabel:setColor("red")
    return
  end

  local tnow = nowMs()
  if tnow < (travelState.nextAt or 0) then return end

  if travelState.stage == 1 then
    say("hi")
    travelState.stage = 2
    travelState.nextAt = tnow + 400
    return
  elseif travelState.stage == 2 then
    NPC.talk(travelState.city or "")
    travelState.stage = 3
    travelState.nextAt = tnow + 400
    return
  elseif travelState.stage == 3 then
    NPC.talk("yes")
    travelUI.statusLabel:setText("Traveling to ".. (travelState.city or "") .."!")
    travelUI.statusLabel:setColor("#00FF8C")
    -- reset
    travelState.pending = false
    travelState.stage = 0
    travelState.city = nil
    -- volta combo para "Select destination"
    pcall(function() travelUI.travelOptions:setCurrentIndex(0) end)
    return
  end
end)
