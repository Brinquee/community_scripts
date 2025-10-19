-- ===================================================================
-- 📚 Library.lua — Biblioteca principal do Script Manager Brinquee
-- Combina os widgets visuais e as funções de carregamento dos scripts
-- ===================================================================

-- ================================================================
-- 🌐 Núcleo de Gerenciamento de Scripts
-- ================================================================

script_manager = script_manager or {}

-- Função segura para carregar scripts remotos
function loadRemoteScript(url)
  modules.corelib.HTTP.get(url, function(content, err)
    if not content then
      print("[Script Manager] Erro ao baixar script:", err or "sem resposta")
      return
    end
    local ok, res = pcall(loadstring(content))
    if not ok then
      print("[Script Manager] Erro ao executar script:", res)
    else
      print("[Script Manager] Script carregado:", url)
    end
  end)
end

-- ================================================================
-- 🎛️ Widgets visuais
-- ================================================================

-- ScrollBar
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
  local value = math.min(math.max(storage.scrollBarValues[id] or defaultValue, min), max)
  widget.scroll.onValueChange = function(scroll, value)
    widget.text:setText(title .. ": " .. value)
    storage.scrollBarValues[id] = value
  end
  widget.scroll:setMinimum(min)
  widget.scroll:setMaximum(max)
  widget.scroll:setValue(value)
  widget.scroll.onValueChange(widget.scroll, value)
end

-- Switch
local switchBarLayout = [[
BotSwitch
  height: 20
  margin-top: 7
]]

storage.switchStatus = storage.switchStatus or {}

function addSwitchBar(id, title, defaultValue, dest, tooltip)
  local widget = setupUI(switchBarLayout, dest)
  widget.onClick = function()
    widget:setOn(not widget:isOn())
    storage.switchStatus[id] = widget:isOn()
  end
  widget:setText(title)
  widget:setTooltip(tooltip)
  widget:setOn(storage.switchStatus[id] or defaultValue)
end

-- Item selector
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
  widget.item:setItemId(storage.itemValues[id] or defaultItem)
  widget.item.onItemChange = function(widget)
    storage.itemValues[id] = widget:getItemId()
  end
  storage.itemValues[id] = storage.itemValues[id] or defaultItem
end

-- Checkbox
local checkBoxWidget = [[
CheckBox
  width: 30
]]

storage.checkBoxStatus = storage.checkBoxStatus or {}

function addCheckBox(id, title, defaultBoolean, dest, tooltip)
  local widget = setupUI(checkBoxWidget, dest)
  widget:setText(title)
  widget:setTooltip(tooltip)
  widget.onCheckChange = function(widget, checked)
    widget:setChecked(checked)
    storage.checkBoxStatus[id] = checked
  end
  widget:setChecked(storage.checkBoxStatus[id] or defaultBoolean)
end

-- ================================================================
-- 🔁 Atualizador opcional (ex: reload, limpeza)
-- ================================================================

function script_manager.reloadAll()
  print("[Script Manager] Recarregando todos os scripts ativos...")
  if script_manager._cache then
    for category, list in pairs(script_manager._cache) do
      for name, data in pairs(list) do
        if data.enabled then
          loadRemoteScript(data.url)
        end
      end
    end
  end
  print("[Script Manager] Concluído.")
end

print("[Library.lua] Carregado com sucesso. Funções e widgets prontos!")
