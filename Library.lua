-- ===================================================================
-- 📚 Library.lua — Biblioteca principal (Community Scripts - Brinquee)
-- - Widgets de UI reutilizáveis
-- - Carregamento seguro de scripts remotos
-- - Persistência via 'storage' (sem arquivos externos)
-- ===================================================================

-- Núcleo
script_manager = script_manager or {}

-- =========================
-- Utilidades / Segurança
-- =========================
local function logOK(...)
  print("[Library]", ...)
end

local function logErr(...)
  print("[Library][ERRO]", ...)
end

-- Relógio em ms que funciona em qualquer build
local function NOW()
  if type(now) == "number" then return now end          -- algumas builds expõem 'now' (ms)
  return math.floor((os.clock() or 0) * 1000)           -- fallback (ms aproximado)
end

-- =========================
-- Loader de scripts remotos
-- =========================
function loadRemoteScript(url)
  if not url or url == "" then
    logErr("URL vazia no loadRemoteScript.")
    return
  end
  if not modules or not modules.corelib or not modules.corelib.HTTP then
    logErr("HTTP não disponível nesta build.")
    return
  end

  modules.corelib.HTTP.get(url, function(content, err)
    if not content then
      logErr("Falha ao baixar:", url, "detalhe:", err or "sem detalhe")
      return
    end
    local ok, fn = pcall(loadstring, content)
    if not ok or type(fn) ~= "function" then
      logErr("Erro ao compilar script:", url, "=>", fn)
      return
    end
    local ok2, res = pcall(fn)
    if not ok2 then
      logErr("Erro ao executar script:", url, "=>", res)
      return
    end
    logOK("Script carregado:", url)
  end)
end

-- =========================
-- Persistência (storage)
-- =========================
storage.scrollBarValues = storage.scrollBarValues or {}
storage.switchStatus    = storage.switchStatus    or {}
storage.itemValues      = storage.itemValues      or {}
storage.checkBoxStatus  = storage.checkBoxStatus  or {}

-- =========================
-- Widgets: TextEdit
-- =========================
-- addTextEdit(label, defaultValue, callback(widget, text), destParent, tooltip?)
function addTextEdit(label, defaultValue, onChange, dest, tooltip)
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
  local w = setupUI(layout, dest or (getTab("Main") or setDefaultTab("Main")))
  w.lbl:setText(label or "")
  if tooltip then
    w.lbl:setTooltip(tooltip)
    w.input:setTooltip(tooltip)
  end
  w.input:setText(defaultValue or "")
  w.input.onTextChange = function(widget, text)
    if type(onChange) == "function" then
      pcall(onChange, widget, text)
    end
  end
  return w
end

-- =========================
-- Widgets: ScrollBar
-- =========================
-- addScrollBar(id, title, min, max, defaultValue, destParent, tooltip?)
function addScrollBar(id, title, min, max, defaultValue, dest, tooltip)
  local layout = [[
Panel
  height: 28
  margin-top: 3

  UIWidget
    id: text
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    text-align: center

  HorizontalScrollBar
    id: scroll
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: prev.bottom
    margin-top: 3
    minimum: 0
    maximum: 10
    step: 1
]]
  local w = setupUI(layout, dest or (getTab("Main") or setDefaultTab("Main")))
  w.text:setTooltip(tooltip or "")
  local cur = storage.scrollBarValues[id]
  if cur == nil then cur = defaultValue end
  if cur == nil then cur = min or 0 end

  w.scroll.onValueChange = function(scroll, value)
    w.text:setText(string.format("%s: %s", title or id, value))
    storage.scrollBarValues[id] = value
  end
  w.scroll:setMinimum(min or 0)
  w.scroll:setMaximum(max or 100)
  w.scroll:setValue(cur)
  w.scroll.onValueChange(w.scroll, cur)
  return w
end

-- =========================
-- Widgets: Switch
-- =========================
-- addSwitchBar(id, title, defaultValue, destParent, tooltip?)
function addSwitchBar(id, title, defaultValue, dest, tooltip)
  -- Se a skin tiver BotSwitch
  local ok, w = pcall(function()
    local layout = [[
BotSwitch
  height: 20
  margin-top: 7
]]
    local sw = setupUI(layout, dest or (getTab("Main") or setDefaultTab("Main")))
    sw.onClick = function()
      sw:setOn(not sw:isOn())
      storage.switchStatus[id] = sw:isOn()
    end
    sw:setText(title or id)
    if tooltip then sw:setTooltip(tooltip) end
    sw:setOn(storage.switchStatus[id])
    if storage.switchStatus[id] == nil then
      sw:setOn(defaultValue and true or false)
      storage.switchStatus[id] = sw:isOn()
    end
    return sw
  end)

  if ok and w then return w end

  -- Fallback para CheckBox
  local layout = [[
CheckBox
  height: 20
  margin-top: 7
]]
  local cb = setupUI(layout, dest or (getTab("Main") or setDefaultTab("Main")))
  cb:setText(title or id)
  if tooltip then cb:setTooltip(tooltip) end
  cb.onCheckChange = function(_, checked)
    storage.switchStatus[id] = checked
  end
  local initial = storage.switchStatus[id]
  if initial == nil then initial = defaultValue and true or false end
  cb:setChecked(initial)
  storage.switchStatus[id] = initial
  return cb
end

-- =========================
-- Widgets: Item (seletor de item)
-- =========================
-- addItem(id, title, defaultItemId, destParent, tooltip?)
function addItem(id, title, defaultItem, dest, tooltip)
  local layout = [[
Panel
  height: 34
  margin-top: 7
  margin-left: 25
  margin-right: 25

  UIWidget
    id: text
    anchors.left: parent.left
    anchors.verticalCenter: next.verticalCenter

  BotItem
    id: item
    anchors.top: parent.top
    anchors.right: parent.right
]]
  local w = setupUI(layout, dest or (getTab("Main") or setDefaultTab("Main")))
  w.text:setText(title or id)
  if tooltip then
    w.text:setTooltip(tooltip)
    w.item:setTooltip(tooltip)
  end
  if storage.itemValues[id] == nil then
    storage.itemValues[id] = defaultItem
  end
  w.item:setItemId(storage.itemValues[id])
  w.item.onItemChange = function(widget)
    storage.itemValues[id] = widget:getItemId()
  end
  return w
end

-- =========================
-- Widgets: CheckBox
-- =========================
-- addCheckBox(id, title, defaultBoolean, destParent, tooltip?)
function addCheckBox(id, title, defaultBoolean, dest, tooltip)
  local layout = [[
CheckBox
  height: 20
  margin-top: 7
]]
  local w = setupUI(layout, dest or (getTab("Main") or setDefaultTab("Main")))
  w:setText(title or id)
  if tooltip then w:setTooltip(tooltip) end
  w.onCheckChange = function(_, checked)
    storage.checkBoxStatus[id] = checked
  end
  local initial = storage.checkBoxStatus[id]
  if initial == nil then initial = defaultBoolean and true or false end
  w:setChecked(initial)
  storage.checkBoxStatus[id] = initial
  return w
end

-- =========================
-- Reload de scripts ativos
-- =========================
function script_manager.reloadAll()
  logOK("Recarregando scripts habilitados...")
  local cache = script_manager._cache
  if type(cache) ~= "table" then
    logErr("Nenhum _cache encontrado.")
    return
  end
  for category, list in pairs(cache) do
    for name, data in pairs(list) do
      if data and data.enabled and data.url then
        loadRemoteScript(data.url)
      end
    end
  end
  logOK("Concluído.")
end

logOK("Carregado com sucesso. Widgets e loader prontos!")
