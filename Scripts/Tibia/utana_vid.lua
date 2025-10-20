-- ===========================================================
-- Tibia - Utana Vid (revisado para Community Scripts)
-- - Independente de 'tabName' (usa aba Main)
-- - UI: spell, % mana mínima, usar em PZ
-- - Cooldown para evitar spam
-- ===========================================================

local MACRO_NAME   = "Utana Vid"
local MACRO_DELAY  = 100           -- ms
local CD_SECONDS   = 1.0           -- tempo mínimo entre casts

-- ===== Destino seguro da UI (sem depender de tabName) =====
local DEST_TAB = getTab("Main") or setDefaultTab("Main")

-- ===== Estado salvo =====
storage.utanaVid = storage.utanaVid or {
  spell = "Utana Vid",
  minManaPercent = 10,
  useOnPz = false
}

-- ===== Helpers de UI (fallbacks) =====
local function ensureTextInput(storageKey, label, defaultValue, dest, tooltip)
  if type(addTextEdit) == "function" then
    addTextEdit(label, storage[storageKey] or defaultValue, function(_, txt)
      storage[storageKey] = txt
    end, dest)
    return
  end
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

  TextEdit
    id: input
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: lbl.bottom
    margin-top: 3
  ]]
  local w = setupUI(layout, dest)
  w.lbl:setText(label)
  if tooltip then
    w.lbl:setTooltip(tooltip)
    w.input:setTooltip(tooltip)
  end
  w.input:setText(storage[storageKey] or defaultValue)
  w.input.onTextChange = function(_, txt)
    storage[storageKey] = txt
  end
  storage[storageKey] = storage[storageKey] or defaultValue
end

-- Switch (usa o addSwitchBar da Library.lua se existir)
local function ensureSwitch(id, title, defaultValue, dest, tooltip)
  if type(addSwitchBar) == "function" then
    addSwitchBar(id, title, defaultValue, dest, tooltip)
  else
    -- fallback simples
    local layout = [[
CheckBox
  height: 20
  margin-top: 7
]]
    local w = setupUI(layout, dest)
    w:setText(title)
    if tooltip then w:setTooltip(tooltip) end
    w.onCheckChange = function(_, checked)
      storage.switchStatus = storage.switchStatus or {}
      storage.switchStatus[id] = checked
    end
    storage.switchStatus = storage.switchStatus or {}
    w:setChecked(storage.switchStatus[id] or defaultValue)
  end
end

-- Scroll (usa o addScrollBar da Library.lua se existir)
local function ensurePercentScroll(id, title, min, max, defaultValue, dest, tooltip)
  if type(addScrollBar) == "function" then
    addScrollBar(id, title, min, max,
      (storage.scrollBarValues and storage.scrollBarValues[id]) or defaultValue,
      dest, tooltip)
  else
    -- fallback: só garante o valor salvo
    storage.scrollBarValues = storage.scrollBarValues or {}
    storage.scrollBarValues[id] = storage.scrollBarValues[id] or defaultValue
    local lbl = UI.Label(string.format("%s: %d (sem slider - Library.lua não carregada)", title, storage.scrollBarValues[id]), dest)
    if tooltip then lbl:setTooltip(tooltip) end
  end
end

-- ===== Construção de UI =====
ensureTextInput("utanaVid_spell", "Spell de invisibilidade", storage.utanaVid.spell, DEST_TAB,
                "Texto/comando a dizer para ativar invisibilidade.")
ensurePercentScroll("utana_minMana", "Mana mínima (%)", 1, 100,
                    storage.utanaVid.minManaPercent or 10, DEST_TAB,
                    "Não castea abaixo desta porcentagem de mana.")
ensureSwitch("utana_useOnPz", "Permitir em PZ", storage.utanaVid.useOnPz, DEST_TAB,
             "Se ligado, pode usar dentro de Protection Zone.")

-- sincroniza fallback -> storage.utanaVid
storage.scrollBarValues = storage.scrollBarValues or {}
storage.switchStatus = storage.switchStatus or {}
storage.utanaVid.spell = storage.utanaVid.spell or storage.utanaVid_spell or "Utana Vid"
storage.utanaVid.minManaPercent = storage.scrollBarValues.utana_minMana or storage.utanaVid.minManaPercent or 10
storage.utanaVid.useOnPz = storage.switchStatus.utana_useOnPz or storage.utanaVid.useOnPz or false

-- ===== Macro principal =====
local lastCast = 0

local utanaMacro = macro(MACRO_DELAY, MACRO_NAME, function()
  if not player or not g_game then return end

  -- lê config “ao vivo” da UI
  local spell = storage.utanaVid_spell or storage.utanaVid.spell or "Utana Vid"
  local minMana = (storage.scrollBarValues and storage.scrollBarValues.utana_minMana) or storage.utanaVid.minManaPercent or 10
  local allowPz = (storage.switchStatus and storage.switchStatus.utana_useOnPz) or storage.utanaVid.useOnPz or false

  -- condições
  local isVisible = not player:isInvisible()
  local hasMana = manapercent() > minMana
  local inPzOk = allowPz or not isInPz()

  if isVisible and hasMana and inPzOk then
    local now = os.time()
    if now - lastCast >= CD_SECONDS then
      if spell and spell ~= "" then
        say(spell)
        lastCast = now
      end
    end
  end
end, DEST_TAB)

-- Separador visual (se existir no tema)
pcall(function() if UI and UI.Separator then UI.Separator(DEST_TAB) end end)
