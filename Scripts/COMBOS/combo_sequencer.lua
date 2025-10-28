-- ===========================================================
-- COMBOS - Combo Sequencer (com Editor in-game)
-- - Botão "Editar Combo" abre um mini painel para mudar spells
-- - Sem scheduleEvent: usa fila + timer no macro
-- - Independente de 'tabName'
-- ===========================================================

-- once-flag para evitar instanciar 2x no mesmo reload
local LOADED_KEY = "__combos_combo_sequencer_loaded__"
if _G[LOADED_KEY] then return end
_G[LOADED_KEY] = true

-- aba de destino segura
local DEST_TAB = getTab("Main") or setDefaultTab("Main")

-- storage do combo
storage.combo_sequencer = storage.combo_sequencer or {
  spells_str = "suiton suiryudan no jutsu, suiton bakusui shouha, daibakufu no jutsu",
  delay_ms   = 180,
  hotkey     = "F8"
}

-- parser de lista: "a, b , c" -> {"a","b","c"}
local function parseList(str)
  local t = {}
  if not str or str == "" then return t end
  for s in tostring(str):gmatch("[^,]+") do
    local clean = s:gsub("^%s+", ""):gsub("%s+$", "")
    if clean ~= "" then table.insert(t, clean) end
  end
  return t
end

-- teclado seguro
local keyIsDown = (modules and modules.corelib and modules.corelib.g_keyboard and modules.corelib.g_keyboard.isKeyPressed)
  or function() return false end

-- estado do sequenciador
local seq = {
  queue      = {},
  nextAt     = 0,
  running    = false
}

-- carrega do storage para memoria
local cfg = {
  delay  = tonumber(storage.combo_sequencer.delay_ms) or 180,
  hotkey = tostring(storage.combo_sequencer.hotkey or "F8"),
  spells = parseList(storage.combo_sequencer.spells_str)
}

-- garante sem duplicar UI caso recarregue
if _G.__COMBO_SEQ_UI and _G.__COMBO_SEQ_UI.window and not _G.__COMBO_SEQ_UI.window:isDestroyed() then
  _G.__COMBO_SEQ_UI.window:destroy()
end
if _G.__COMBO_SEQ_UI and _G.__COMBO_SEQ_UI.btn and not _G.__COMBO_SEQ_UI.btn:isDestroyed() then
  _G.__COMBO_SEQ_UI.btn:destroy()
end
_G.__COMBO_SEQ_UI = {}

-- cria mini painel do editor
local editor = setupUI([[
MainWindow
  id: comboSequencerWin
  text: "COMBOS - Editor"
  size: 280 170
  color: white
  background-color: #111111
  opacity: 0.92
  padding: 6

  Label
    id: labSpells
    anchors.top: parent.top
    anchors.left: parent.left
    text: "Spells (separe por vírgula):"

  TextEdit
    id: spellsBox
    anchors.top: labSpells.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 4
    height: 44

  Label
    id: labDelay
    anchors.top: spellsBox.bottom
    anchors.left: parent.left
    margin-top: 6
    text: "Delay (ms) e Hotkey:"

  TextEdit
    id: delayBox
    anchors.top: labDelay.bottom
    anchors.left: parent.left
    width: 80
    margin-top: 4

  TextEdit
    id: hotkeyBox
    anchors.top: labDelay.bottom
    anchors.left: delayBox.right
    margin-left: 8
    width: 80
    margin-top: 4

  Button
    id: saveBtn
    !text: tr("Salvar")
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    size: 70 22
    margin-bottom: 2

  Button
    id: testBtn
    !text: tr("Testar")
    anchors.left: saveBtn.right
    anchors.bottom: parent.bottom
    size: 70 22
    margin-left: 6
    margin-bottom: 2

  Button
    id: closeBtn
    !text: tr("Fechar")
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 70 22
    margin-bottom: 2
]], g_ui.getRootWidget())

editor:hide()
pcall(function() editor:move(40, 60) end)

-- preenche campos
editor.spellsBox:setText(storage.combo_sequencer.spells_str or "")
editor.delayBox:setText(tostring(cfg.delay))
editor.hotkeyBox:setText(cfg.hotkey)

-- salvar
editor.saveBtn.onClick = function()
  local spells_str = editor.spellsBox:getText() or ""
  local delay_txt  = editor.delayBox:getText() or ""
  local hk_txt     = editor.hotkeyBox:getText() or "F8"

  local delay_val = tonumber(delay_txt) or 180
  if delay_val < 10 then delay_val = 10 end
  if delay_val > 3000 then delay_val = 3000 end

  storage.combo_sequencer.spells_str = spells_str
  storage.combo_sequencer.delay_ms   = delay_val
  storage.combo_sequencer.hotkey     = hk_txt

  cfg.spells = parseList(spells_str)
  cfg.delay  = delay_val
  cfg.hotkey = hk_txt

  info("Combo salvo. Spells: " .. (spells_str ~= "" and spells_str or "(vazio)"))
end

-- testar uma rodada agora
editor.testBtn.onClick = function()
  if #cfg.spells == 0 then
    warn("Nenhuma spell configurada.")
    return
  end
  seq.queue = {}
  for i = 1, #cfg.spells do seq.queue[i] = cfg.spells[i] end
  seq.nextAt  = now
  seq.running = true
end

-- fechar
editor.closeBtn.onClick = function()
  editor:hide()
end

_G.__COMBO_SEQ_UI.window = editor

-- botão para abrir o editor
local btn = UI.Button("Editar Combo", function()
  if editor:isVisible() then editor:hide() else editor:show() end
end, DEST_TAB)
btn:setColor("#d2cac5")
_G.__COMBO_SEQ_UI.btn = btn

-- macro principal do sequenciador
local comboMacro = macro(50, "Combo Sequencer", function()
  -- gatilho: hotkey pressionada dispara uma rodada
  if cfg.hotkey and cfg.hotkey ~= "" and keyIsDown(cfg.hotkey) then
    if not seq.running then
      if #cfg.spells == 0 then return end
      seq.queue = {}
      for i = 1, #cfg.spells do seq.queue[i] = cfg.spells[i] end
      seq.nextAt  = now
      seq.running = true
    end
  end

  -- executa fila
  if seq.running and now >= (seq.nextAt or 0) then
    local s = table.remove(seq.queue, 1)
    if s then
      say(s)
      seq.nextAt = now + (cfg.delay or 180)
    else
      seq.running = false
    end
  end
end, DEST_TAB)

-- registro opcional para inspeção
_G.__BRINQUE_COMBOS = _G.__BRINQUE_COMBOS or {}
_G.__BRINQUE_COMBOS["combo_sequencer"] = { macro = comboMacro, ui = editor, button = btn }
