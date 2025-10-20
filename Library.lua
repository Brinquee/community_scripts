-- ================================================================
-- 📚 Library.lua — Widgets + utilidades para o Community Scripts
-- (compatível com storage interno; sem JSON/sem ragnarok)
-- ================================================================

script_manager = script_manager or {}

-- ------------------------------------------------
-- 🔗 Carregar script remoto com segurança (opcional)
-- ------------------------------------------------
function loadRemoteScript(url)
  modules.corelib.HTTP.get(url, function(content, err)
    if not content or #content == 0 then
      print("[Library] Falha ao baixar:", url, err or "sem conteúdo")
      return
    end
    local ok, res = pcall(loadstring(content))
    if not ok then
      print("[Library] Erro executando:", res)
    else
      print("[Library] Script carregado:", url)
    end
  end)
end

-- ================================================================
-- 🎚 Scroll Bar
-- id, title, min, max, defaultValue, dest, tooltip
-- ================================================================
local scrollBarLayout = [[
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

storage.scrollBarValues = storage.scrollBarValues or {}

function addScrollBar(id, title, min, max, defaultValue, dest, tooltip)
  local widget = setupUI(scrollBarLayout, dest)
  widget.text:setTooltip(tooltip)
  local value = storage.scrollBarValues[id]
  if value == nil then value = defaultValue end
  value = math.min(math.max(value, min), max)

  widget.scroll.onValueChange = function(_, v)
    widget.text:setText(title .. ": " .. v)
    storage.scrollBarValues[id] = v
  end

  widget.scroll:setMinimum(min)
  widget.scroll:setMaximum(max)
  widget.scroll:setValue(value)
  widget.scroll.onValueChange(widget.scroll, value)
end

-- ================================================================
-- 🔀 Switch (BotSwitch)
-- id, title, defaultValue(bool), dest, tooltip
-- ================================================================
local switchBarLayout = [[
BotSwitch
  height: 20
  margin-top: 7
]]

storage.switchStatus = storage.switchStatus or {}

function addSwitchBar(id, title, defaultValue, dest, tooltip)
  local widget = setupUI(switchBarLayout, dest)
  widget:setText(title)
  widget:setTooltip(tooltip)
  widget:setOn(storage.switchStatus[id] ~= nil and storage.switchStatus[id] or defaultValue)

  widget.onClick = function()
    widget:setOn(not widget:isOn())
    storage.switchStatus[id] = widget:isOn()
  end
end

-- ================================================================
-- 🎒 Item selector (BotItem)
-- id, title, defaultItemId, dest, tooltip
-- ================================================================
local itemWidget = [[
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

storage.itemValues = storage.itemValues or {}

function addItem(id, title, defaultItem, dest, tooltip)
  local widget = setupUI(itemWidget, dest)
  widget.text:setText(title)
  widget.text:setTooltip(tooltip)
  widget.item:setTooltip(tooltip)

  local initial = storage.itemValues[id]
  if initial == nil then initial = defaultItem end
  widget.item:setItemId(initial)

  widget.item.onItemChange = function(w)
    storage.itemValues[id] = w:getItemId()
  end

  storage.itemValues[id] = storage.itemValues[id] or defaultItem
end

-- ================================================================
-- ☑️ CheckBox
-- id, title, defaultBoolean, dest, tooltip
-- ================================================================
local checkBoxWidget = [[
CheckBox
  width: 30
]]

storage.checkBoxStatus = storage.checkBoxStatus or {}

function addCheckBox(id, title, defaultBoolean, dest, tooltip)
  local widget = setupUI(checkBoxWidget, dest)
  widget:setText(title)
  widget:setTooltip(tooltip)
  widget:setChecked(storage.checkBoxStatus[id] ~= nil and storage.checkBoxStatus[id] or defaultBoolean)

  widget.onCheckChange = function(_, checked)
    storage.checkBoxStatus[id] = checked
  end
end

print("[Library.lua] Carregado com sucesso.")
