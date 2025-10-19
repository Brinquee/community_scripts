script_bot = {};

-- ✅ Inicialização segura (sem RagnarokBot)
local playerName = g_game.getCharacterName() or "Player"
setDefaultTab('Main')
local tabName = getTab('Main') or setDefaultTab('Main')

-- Armazena dados de forma persistente (sem .json)
storage.script_bot_data = storage.script_bot_data or {}
local script_manager = storage.script_bot_data
local actualVersion = 0.4

-- URLs das bibliotecas
local libraryList = {
    'https://raw.githubusercontent.com/brinquee/Community_Scripts/refs/heads/main/library.lua',
    'https://raw.githubusercontent.com/brinquee/Community_Scripts/refs/heads/main/script_list.lua'
}

-- 🔒 Função segura para carregar bibliotecas remotas
for _, library in ipairs(libraryList) do
    modules._G.HTTP.get(library, function(content, error)
        if content and content ~= "" and not error then
            local ok, result = pcall(loadstring(content))
            if not ok then
                print("Erro ao carregar biblioteca:", result)
            end
        else
            print("Erro ao baixar:", library)
        end
    end)
end

-- 🧱 UI e gerenciamento
if not script_bot.widget then
    -- Template para cada script na lista
    local script_add = [[
UIWidget
  background-color: alpha
  focusable: true
  height: 30

  $focus:
    background-color: #00000055

  Label
    id: textToSet
    font: terminus-14px-bold
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter
]]

    -- Painel principal
    script_bot.widget = setupUI([[
MainWindow
  !text: tr('Community Scripts')
  font: terminus-14px-bold
  color: #d2cac5
  size: 300 400

  TabBar
    id: macrosOptions
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    width: 180

  ScrollablePanel
    id: scriptList
    layout:
      type: verticalBox
    anchors.fill: parent
    margin-top: 25
    margin-left: 2
    margin-right: 15
    margin-bottom: 30
    vertical-scrollbar: scriptListScrollBar
      
  VerticalScrollBar
    id: scriptListScrollBar
    anchors.top: scriptList.top
    anchors.bottom: scriptList.bottom
    anchors.right: scriptList.right
    step: 14
    pixels-scroll: true
    margin-right: -10

  HorizontalSeparator
    id: sep
    anchors.top: enemyList.bottom
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: prev.right
    margin-left: 10
    margin-top: 6

  TextEdit
    id: searchBar
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    margin-right: 5
    width: 130

  Button
    id: closeButton
    !text: tr('Close')
    font: cipsoftFont
    anchors.right: parent.right
    anchors.left: searchBar.right
    anchors.bottom: parent.bottom
    size: 45 21
    margin-bottom: 1
    margin-right: 5
    margin-left: 5
]], g_ui.getRootWidget())

    script_bot.widget:hide()
    script_bot.widget:setText('Community Scripts - ' .. actualVersion)

    -- Botão "Script Manager"
    script_bot.buttonWidget = UI.Button('Script Manager', function()
        if script_bot.widget:isVisible() then
            script_bot.widget:hide()
        else
            script_bot.widget:centerInParent()
            script_bot.widget:show()
        end
    end, tabName)
    script_bot.buttonWidget:setColor('#d2cac5')

    -- Fecha o painel
    script_bot.widget.closeButton.onClick = function()
        script_bot.widget:hide()
    end

    -- Filtro da barra de pesquisa
    script_bot.widget.searchBar.onTextChange = function(widget, text)
        for _, child in pairs(script_bot.widget.scriptList:getChildren()) do
            local scriptName = child:getId()
            if scriptName:lower():find(text:lower()) then
                child:show()
            else
                child:hide()
            end
        end
    end

    -- Leitura e exibição da lista (mock para evitar crash)
    local function carregarLista()
        script_bot.widget.scriptList:destroyChildren()

        local exemplo = {
            ["Macro de Teste"] = {enabled = false, description = "Macro de exemplo"},
            ["Auto Heal"] = {enabled = true, description = "Cura automática"}
        }

        for nome, info in pairs(exemplo) do
            local linha = setupUI(script_add, script_bot.widget.scriptList)
            linha.textToSet:setText(nome)
            linha.textToSet:setColor(info.enabled and 'green' or '#bdbdbd')
            linha.onClick = function()
                info.enabled = not info.enabled
                linha.textToSet:setColor(info.enabled and 'green' or '#bdbdbd')
            end
        end
    end

    carregarLista()
end
