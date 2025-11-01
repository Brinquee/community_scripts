-- =========================================================
-- TIME DE MAGIA — fundo translucido via painel (texto nitido)
-- OTCv8 / aba "Tools" / sem acentos
-- =========================================================

local TARGET_TAB = "Tools"
setDefaultTab(TARGET_TAB)

local root = (g_ui and g_ui.getRootWidget and g_ui.getRootWidget()) or rootWidget
if not root then
  print("[TIMERS] root nao encontrado"); return
end

-- -------------------------
-- Defaults persistentes
-- -------------------------
storage.timersEnabled = (storage.timersEnabled ~= false)

-- item: { on, name, trigger, label, cd(ms), active(ms), x, y, t, a }
if type(storage.timerList) ~= "table" then
  storage.timerList = {
    { on=true, name="Kai", trigger="kai", label="Kai:", cd=5000, active=1000, x=300, y=200, t=0, a=0 },
  }
end

-- -------------------------
-- Utils
-- -------------------------
local function toNum(v, d) local n=tonumber(v); return n or d end
local function nowMs()
  if type(now)=="number" then return now end
  if type(now)=="function" then local ok,res=pcall(now); if ok and type(res)=="number" then return res end end
  if g_clock and g_clock.millis then return g_clock.millis() end
  return math.floor(os.clock()*1000)
end

-- offsets do label na tela (levemente abaixo do topo)
local XOFF, YOFF = 10, 40

-- -------------------------
-- Widgets persistentes por reload (anti-duplicata)
-- -------------------------
_TIMERS_BRQ = _TIMERS_BRQ or { labels = {}, bgs = {} }

-- limpa widgets antigos (se houver)
for _,w in pairs(_TIMERS_BRQ.labels) do if w and w.destroy then pcall(function() w:destroy() end) end end
for _,w in pairs(_TIMERS_BRQ.bgs)    do if w and w.destroy then pcall(function() w:destroy() end) end end
_TIMERS_BRQ.labels = {}
_TIMERS_BRQ.bgs    = {}

-- referencias locais
local labelsByIdx = _TIMERS_BRQ.labels
local bgByIdx     = _TIMERS_BRQ.bgs

local function setVisiblePair(idx, vis)
  local lab = labelsByIdx[idx]
  local bg  = bgByIdx[idx]
  if lab and lab.setVisible then lab:setVisible(vis) end
  if bg  and bg.setVisible  then bg:setVisible(vis)  end
end

local function adjustBg(idx)
  local lab = labelsByIdx[idx]
  local bg  = bgByIdx[idx]
  if not (lab and bg) then return end
  bg:setPosition(lab:getPosition())
  bg:setSize(lab:getSize())
end

local function ensureLabel(idx)
  local t = storage.timerList[idx]; if not t then return end
  local lab = labelsByIdx[idx]
  local bg  = bgByIdx[idx]

  -- cria fundo (fica por baixo)
  if not bg or (bg.isDestroyed and bg:isDestroyed()) then
    bg = g_ui.loadUIFromString([[
Panel
  background-color: #000000a0
  opacity: 0.35
  padding: 0
  border-width: 1px
  border-color: #000000
  border-radius: 2px
  text-horizontal-auto-resize: true
  phantom: false
]], root)
    bgByIdx[idx] = bg
  end

  -- cria label (texto nitido)
  if not lab or (lab.isDestroyed and lab:isDestroyed()) then
    lab = g_ui.loadUIFromString([[
Label
  color: white
  background-color: transparent
  text-horizontal-auto-resize: true
  padding: 3
  phantom: false
]], root)
    labelsByIdx[idx] = lab
  end

  local pos = { x = (toNum(t.x,300)) + XOFF, y = (toNum(t.y,200)) + YOFF }
  lab:setPosition(pos)
  lab:setVisible(storage.timersEnabled)

  bg:setPosition(pos)
  bg:setVisible(storage.timersEnabled)

  adjustBg(idx)
  return lab
end

local function destroyLabel(idx)
  local lab = labelsByIdx[idx]
  local bg  = bgByIdx[idx]
  if lab and lab.destroy then lab:destroy() end
  if bg  and bg.destroy  then bg:destroy()  end
  labelsByIdx[idx] = nil
  bgByIdx[idx]     = nil
end

local function refreshAllLabels()
  for i,_ in ipairs(storage.timerList) do
    local t   = storage.timerList[i]
    local lab = ensureLabel(i)
    if lab and t then
      lab:setPosition({ x = (toNum(t.x,300))+XOFF, y = (toNum(t.y,200))+YOFF })
      adjustBg(i)
    end
  end
end

local function setAllLabelsVisible(vis)
  for i,_ in ipairs(storage.timerList) do setVisiblePair(i, vis) end
end

-- -------------------------
-- Painel EDIT
-- -------------------------
local editUI = nil
local rebuildEditBody

local function refreshDelAllState()
  if not editUI then return end
  local delBtn = editUI:recursiveGetChildById("delAllButton"); if not delBtn then return end
  local empty = (#storage.timerList == 0)
  delBtn:setEnabled(not empty)
  delBtn:setColor(empty and "#666666" or "#f6ff13")
  delBtn:setText(empty and "DEL LISTA (0)" or "DEL LISTA")
end

local function toggleEditPanel()
  if editUI and editUI.destroy then editUI:destroy(); editUI=nil; return end

  editUI = setupUI([[
MainWindow
  id: editPanelTimers
  text: "CENTRAL DE TIMERS"
  size: 540 430
  background-color: black
  opacity: 0.92

  ScrollablePanel
    id: body
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: btnBar.top
    margin-left: 10
    margin-right: 10
    margin-top: 10
    layout:
      type: verticalBox

  Panel
    id: btnBar
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 42
    padding: 6
    layout:
      type: horizontalBox
      fit-children: true
    spacing: 10

    Button
      id: onOffButton
      text: ""
      width: 110
      height: 22

    Button
      id: delAllButton
      text: "DEL LISTA"
      width: 95
      height: 22
      color: #fcff80

    Button
      id: addButton
      text: "NOVO TIMER"
      width: 105
      height: 22
      color: #12ff3d

    UIWidget
      id: spacer
      width: 0
      horizontal-expanding: true

    Button
      id: closeButton
      text: "Fechar"
      width: 85
      height: 22
      color: red
]], root)

  local function refreshGlobalOnOffBtn()
    local b = editUI:recursiveGetChildById("onOffButton")
    if not b then return end
    local s = storage.timersEnabled and "TIMERS: ON" or "TIMERS: OFF"
    b:setText(s)
    b:setColor(storage.timersEnabled and "#21ff25" or "#666666")
    setAllLabelsVisible(storage.timersEnabled)
  end

  local closeBtn  = editUI:recursiveGetChildById("closeButton")
  local addBtn    = editUI:recursiveGetChildById("addButton")
  local delAllBtn = editUI:recursiveGetChildById("delAllButton")
  local onOffBtn  = editUI:recursiveGetChildById("onOffButton")

  onOffBtn.onClick = function()
    storage.timersEnabled = not storage.timersEnabled
    refreshGlobalOnOffBtn()
  end

  closeBtn.onClick = function() editUI:destroy(); editUI=nil end
  addBtn.onClick = function()
    table.insert(storage.timerList, { on=true, name="Timer", trigger="", label="Timer:", cd=5000, active=1000, x=300, y=200, t=0, a=0 })
    rebuildEditBody(); refreshDelAllState(); refreshAllLabels()
  end
  delAllBtn.onClick = function()
    for i=1,#storage.timerList do destroyLabel(i) end
    storage.timerList = {}
    rebuildEditBody(); refreshDelAllState()
  end

  refreshGlobalOnOffBtn()
  rebuildEditBody()
end

-- botoes no painel do bot (evita duplicar)
if btnTimersToggleBrq and not btnTimersToggleBrq:isDestroyed() then btnTimersToggleBrq:destroy() end
if btnTimersEditBrq   and not btnTimersEditBrq:isDestroyed()   then btnTimersEditBrq:destroy()   end

btnTimersToggleBrq = UI.Button("(TIMERS "..(storage.timersEnabled and "ON" or "OFF")..")", function()
  storage.timersEnabled = not storage.timersEnabled
  btnTimersToggleBrq:setText("(TIMERS "..(storage.timersEnabled and "ON" or "OFF")..")")
  btnTimersToggleBrq:setColor(storage.timersEnabled and "#21fff8" or "#666666")
  setAllLabelsVisible(storage.timersEnabled)
end)
btnTimersToggleBrq:setWidth(110)
btnTimersToggleBrq:setStyle("margin-right: 6px;")
btnTimersToggleBrq:setColor(storage.timersEnabled and "#21fff8" or "#666666")

btnTimersEditBrq = UI.Button("(EDITAR TIMERS)", toggleEditPanel)
btnTimersEditBrq:setWidth(120)
btnTimersEditBrq:setHeight(20)
btnTimersEditBrq:setColor("#ecff21")

-- -------------------------
-- Cards e editor por item
-- -------------------------
local function cardStyle(isOn)
  return (isOn and
    "min-height: 110px; padding: 8px; border-width: 1px; border-color: #1fff6a; background-color: #122a1a; border-radius: 6px;"
    or
    "min-height: 110px; padding: 8px; border-width: 1px; border-color: #2a2a2a; background-color: #1a1a1a; border-radius: 6px;")
end

local function mountTimerCard(card, idx)
  local t = storage.timerList[idx]; if not t then return end
  card:destroyChildren()
  card:setStyle(cardStyle(t.on))

  local shownName = (t.name and t.name ~= "" and t.name) or (t.trigger and t.trigger ~= "" and t.trigger) or ("Timer "..idx)
  local nameLbl = UI.Label(string.format("%d) %s", idx, shownName))
  nameLbl:setColor(t.on and "#05ffec" or "#bbbbbb")
  card:addChild(nameLbl)

  local btnRow = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    fit-children: true
    spacing: 6
]], card)
  btnRow:setStyle("margin-top: 6px;")

  local btnOn = UI.Button("ON/OFF", function()
    t.on = not t.on
    rebuildEditBody(); refreshDelAllState()
  end)
  btnOn:setWidth(52); btnOn:setHeight(20); btnOn:setColor("#21ff25")
  btnRow:addChild(btnOn)

  local btnEd = UI.Button("EDIT", function()
    local w = setupUI([[
MainWindow
  id: timerItemEditor
  text: "EDITA TIMER"
  size: 380 360
  background-color: black
  opacity: 0.95

  ScrollablePanel
    id: form
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: eBtnRow.top
    margin-left: 10
    margin-right: 10
    margin-top: 8
    layout:
      type: verticalBox
]], root)

    local eBtnRow = setupUI([[
Panel
  id: eBtnRow
  anchors.bottom: parent.bottom
  anchors.left: parent.left
  anchors.right: parent.right
  height: 34
  layout:
    type: horizontalBox
    fit-children: true
    spacing: 8
]], w)

    local saveBtn = UI.Button("Salvar", function() end, eBtnRow)
    saveBtn:setWidth(84); saveBtn:setHeight(22); saveBtn:setColor("green")

    local cancelBtn = UI.Button("Fechar", function() if w and w.destroy then w:destroy() end end, eBtnRow)
    cancelBtn:setWidth(76); cancelBtn:setHeight(22); cancelBtn:setColor("red")

    local form = w:recursiveGetChildById("form")
    local function mkLabel(tl) local l=UI.Label(tl); l:setColor("#dddddd"); l:setStyle("margin-top:6px;"); form:addChild(l); return l end
    local function mkEdit(id) local e=UI.TextEdit(); e:setId(id); e:setHeight(20); e:setStyle("margin-top:2px;"); form:addChild(e); return e end
    local function mkSpin(id,min,max,step,val)
      local s=setupUI([[
SpinBox
  minimum: 0
  maximum: 600000
  step: 1
  width: 140
  height: 20
]], form)
      s:setId(id); s:setMinimum(min); s:setMaximum(max); s:setStep(step or 1); s:setValue(val or 0); return s
    end

    mkLabel("name:");                         local nameEdit = mkEdit("nameEdit")
    mkLabel("trigger (palavra falada):");     local trigEdit = mkEdit("trigEdit")
    mkLabel("label (texto antes do tempo):"); local labEdit  = mkEdit("labEdit")
    mkLabel("cooldown (ms):");                local cdSpin   = mkSpin("cdSpin",0,600000,1000,toNum(t.cd,5000))
    mkLabel("tempo ativo (ms):");             local actSpin  = mkSpin("actSpin",0,600000,1000,toNum(t.active,1000))
    mkLabel("X:");                            local xEdit    = mkEdit("xEdit")
    mkLabel("Y:");                            local yEdit    = mkEdit("yEdit")

    nameEdit:setText(t.name or "")
    trigEdit:setText((t.trigger or ""))
    labEdit:setText(t.label or "Timer:")
    xEdit:setText(tostring(toNum(t.x,300)))
    yEdit:setText(tostring(toNum(t.y,200)))

    saveBtn.onClick = function()
      t.name    = nameEdit:getText() or ""
      t.trigger = (trigEdit:getText() or ""):lower()
      t.label   = labEdit:getText() or "Timer:"
      t.cd      = toNum(cdSpin:getValue(), 5000)
      t.active  = toNum(actSpin:getValue(), 1000)
      t.x       = toNum(xEdit:getText(), 300)
      t.y       = toNum(yEdit:getText(), 200)
      t.t, t.a  = 0, 0
      local lab = ensureLabel(idx)
      if lab then
        lab:setPosition({ x = t.x + XOFF, y = t.y + YOFF })
        adjustBg(idx)
      end
      if w and w.destroy then w:destroy() end
      rebuildEditBody()
    end
  end)
  btnEd:setWidth(48); btnEd:setHeight(20)
  btnRow:addChild(btnEd)

  local btnDel = UI.Button("DEL", function()
    destroyLabel(idx)
    table.remove(storage.timerList, idx)
    rebuildEditBody(); refreshDelAllState()
  end)
  btnDel:setWidth(48); btnDel:setHeight(20); btnDel:setColor("#ff0404")
  btnRow:addChild(btnDel)

  local posInfo = UI.Label(string.format("X:%d  Y:%d", toNum(t.x,300), toNum(t.y,200)))
  posInfo:setColor("#aaaaaa"); posInfo:setStyle("margin-top: 6px;")
  card:addChild(posInfo)
end

rebuildEditBody = function()
  if not editUI then return end
  local body = editUI:recursiveGetChildById("body"); if not body then return end
  body:destroyChildren()

  local n = #storage.timerList
  if n == 0 then
    local empty = UI.Label("Lista vazia — clique em 'NOVO TIMER'")
    empty:setColor("#aaaaaa"); empty:setStyle("margin-top: 6px;")
    body:addChild(empty)
    refreshDelAllState()
    return
  end

  local zebraA, zebraB = "#0b0b0b", "#202020"
  local i, rowIndex = 1, 1
  while i <= n do
    local row = setupUI([[
Panel
  height: 116
  layout:
    type: horizontalBox
    fit-children: true
    spacing: 8
]], body)
    row:setStyle("margin-top: 6px; padding: 6px; background-color: "..((rowIndex%2==1) and zebraA or zebraB).."; border-radius: 6px;")

    local cardA = setupUI([[
Panel
  layout:
    type: verticalBox
    fit-children: true
]], row)
    cardA:setWidth(230)
    mountTimerCard(cardA, i)

    if i+1 <= n then
      local cardB = setupUI([[
Panel
  layout:
    type: verticalBox
    fit-children: true
]], row)
      cardB:setWidth(230)
      mountTimerCard(cardB, i+1)
    end

    i = i + 2
    rowIndex = rowIndex + 1
  end

  refreshDelAllState()
end

-- -------------------------
-- Loop de exibicao (cores/estados)
-- -------------------------
macro(200, "TIMERS LOOP", function()
  local tnow = nowMs()
  if not storage.timersEnabled then
    setAllLabelsVisible(false)
    return
  else
    setAllLabelsVisible(true)
  end

  for i,t in ipairs(storage.timerList) do
    local lab = ensureLabel(i); if not lab then goto continue end
    local ready  = (not t.t) or (tnow >= (t.t or 0))
    local active = (t.a or 0) >= tnow

    if ready then
      lab:setText(string.format("%s OK!", t.label or "")); lab:setColor("green")
    elseif active then
      local s = math.max(0, math.floor((t.a - tnow)/1000))
      lab:setText(string.format("%s%ds ", t.label or "", s)); lab:setColor("blue")
    else
      local s = math.max(0, math.floor((t.t - tnow)/1000))
      lab:setText(string.format("%s%ds ", t.label or "", s)); lab:setColor("red")
    end
    adjustBg(i)
    ::continue::
  end
end)

-- -------------------------
-- Disparo via fala do proprio player
-- -------------------------
if not __brqTimersOnTalkRegistered then
  __brqTimersOnTalkRegistered = true
  onTalk(function(name, level, mode, text, channelId, pos)
    if name ~= player:getName() then return end
    if not storage.timersEnabled then return end
    local said = (text or ""):lower()
    local tnow = nowMs()
    for _,t in ipairs(storage.timerList) do
      if t.on and (t.trigger or "") ~= "" and said == (t.trigger or "") then
        if (not t.t) or tnow >= t.t then
          t.cd     = toNum(t.cd, 5000)
          t.active = toNum(t.active, 1000)
          t.t = tnow + t.cd
          t.a = tnow + t.active
        end
      end
    end
  end)
end

-- -------------------------
-- Saneamento inicial
-- -------------------------
for _,t in ipairs(storage.timerList) do
  if type(t.t) ~= "number" or (t.t - nowMs()) > 60000 then t.t = 0 end
  if type(t.a) ~= "number" or (t.a - nowMs()) > 60000 then t.a = 0 end
  t.cd     = toNum(t.cd, 5000)
  t.active = toNum(t.active, 1000)
  t.x      = toNum(t.x, 300)
  t.y      = toNum(t.y, 200)
end

refreshAllLabels()
setAllLabelsVisible(storage.timersEnabled)
