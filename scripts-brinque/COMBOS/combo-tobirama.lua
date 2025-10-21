-- Combo Tobirama Configurável com Delay Individual e Botão Flutuante
setDefaultTab("Main")

local panelName = "comboTobirama"

if not storage[panelName] then
  storage[panelName] = {
    spells = {
      "suiton suiryudan no jutsu",
      "suiton bakusui shouha",
      "suiton teppodama",
      "suiton tenkyu",
      "daibakufu no jutsu",
      "suiton goshokuzame",
      "suiton suishoha"
    },
    delay = 300
  }
end

---------------------------------------------------------------------
-- 🪟 Janela de Configuração
---------------------------------------------------------------------
local comboWindow = setupUI([[
UIWindow
  !text: tr('Combo Tobirama - Configuração')
  color: #99d6ff
  font: verdana-11px-rounded
  size: 270 280
  background-color: black
  opacity: 0.9
  anchors.left: parent.left
  anchors.top: parent.top
  margin-left: 600
  margin-top: 180

  Label
    id: titleLabel
    text: Edite suas magias abaixo:
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    margin-top: 8
    color: white
    font: verdana-11px-rounded

  TextEdit
    id: spellsEdit
    anchors.top: titleLabel.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-left: 10
    margin-right: 10
    margin-top: 10
    height: 140
    multiline: true
    font: verdana-11px-rounded
    color: yellow

  Label
    id: delayLabel
    text: Delay entre magias (ms):
    anchors.left: parent.left
    margin-left: 10
    anchors.top: spellsEdit.bottom
    margin-top: 8
    color: white
    font: verdana-11px-rounded

  HorizontalScrollBar
    id: delayScroll
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: delayLabel.bottom
    margin-left: 10
    margin-right: 10
    margin-top: 3
    minimum: 100
    maximum: 2000
    step: 100
    height: 15

  Label
    id: delayValue
    text: 300
    anchors.right: parent.right
    anchors.top: delayLabel.top
    margin-right: 10
    color: yellow
    font: verdana-11px-rounded

  Button
    id: saveButton
    text: Salvar
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    margin-left: 15
    margin-bottom: 10
    width: 100
    height: 22
    color: green
    font: verdana-11px-rounded

  Button
    id: closeButton
    text: Fechar
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-right: 15
    margin-bottom: 10
    width: 100
    height: 22
    color: red
    font: verdana-11px-rounded
]], g_ui.getRootWidget())

comboWindow:hide()

---------------------------------------------------------------------
-- 🎛️ Botão Flutuante (fora do vBot)
---------------------------------------------------------------------
local comboButton = setupUI([[
UIButton
  id: openComboButton
  text: Editar Combo
  color: #00FF8C
  font: verdana-11px-rounded
  size: 120 25
  opacity: 0.9
  anchors.right: parent.right
  anchors.verticalCenter: parent.verticalCenter
  margin-right: 20
]], g_ui.getRootWidget())

---------------------------------------------------------------------
-- ⚙️ Funções e Eventos
---------------------------------------------------------------------
comboButton.onClick = function()
  local spellsText = table.concat(storage[panelName].spells, "\n")
  comboWindow.spellsEdit:setText(spellsText)
  comboWindow.delayScroll:setValue(storage[panelName].delay)
  comboWindow.delayValue:setText(storage[panelName].delay .. " ms")
  comboWindow:show()
  comboWindow:raise()
  comboWindow:focus()
end

comboWindow.closeButton.onClick = function()
  comboWindow:hide()
end

comboWindow.delayScroll.onValueChange = function(widget, value)
  storage[panelName].delay = value
  comboWindow.delayValue:setText(value .. " ms")
end

comboWindow.saveButton.onClick = function()
  local text = comboWindow.spellsEdit:getText()
  local spells = {}
  for line in text:gmatch("[^\r\n]+") do
    table.insert(spells, line)
  end
  storage[panelName].spells = spells
  comboWindow:hide()
  info("Combo Tobirama atualizado com sucesso!")
end

---------------------------------------------------------------------
-- 🔁 Macro Principal (delay entre magias)
---------------------------------------------------------------------
macro(100, "Combo Tobirama", function()
  if g_game.isAttacking() then
    local delayValue = storage[panelName].delay or 300
    local totalDelay = 0

    for _, spell in ipairs(storage[panelName].spells) do
      schedule(totalDelay, function()
        if g_game.isAttacking() then
          say(spell)
        end
      end)
      totalDelay = totalDelay + delayValue
    end
  end
end)
