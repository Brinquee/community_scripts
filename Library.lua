--[[ UTILIDADES DE INTERFACE CUSTOM PARA OTCv8 MOBILE ]]--

---------------------------------------------------------
-- Scroll Bar Function
---------------------------------------------------------
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
  if type(value) ~= "number" then value = defaultValue or min end
  value = math.min(math.max(value, min), max)

  widget.scroll.onValueChange = function(scroll, val)
    widget.text:setText(title .. ": " .. val)
    storage.scrollBarValues[id] = val
  end

  widget.scroll:setMinimum(min)
  widget.scroll:setMaximum(max)
  widget.scroll:setValue(value)
  widget.scroll.onValueChange(widget.scroll, value)
end

---------------------------------------------------------
-- Switch Bar Function
---------------------------------------------------------
local switchBarLayout = [[
Switch
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

---------------------------------------------------------
-- Item Widget Function
---------------------------------------------------------
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
  local itemId = storage.itemValues[id] or defaultItem or 100
  widget.item:setItemId(itemId)
  storage.itemValues[id] = itemId
  widget.item.onItemChange = function(w)
    storage.itemValues[id] = w:getItemId()
  end
end

---------------------------------------------------------
-- CheckBox Widget Function
---------------------------------------------------------
local checkBoxWidget = [[
CheckBox
  width: 150
  height: 20
  margin-top: 4
]]

storage.checkBoxStatus = storage.checkBoxStatus or {}

function addCheckBox(id, title, defaultBoolean, dest, tooltip)
  local widget = setupUI(checkBoxWidget, dest)
  widget:setText(title)
  widget:setTooltip(tooltip)
  widget.onCheckChange = function(w, checked)
    storage.checkBoxStatus[id] = checked
  end
  widget:setChecked(storage.checkBoxStatus[id] or defaultBoolean)
end
