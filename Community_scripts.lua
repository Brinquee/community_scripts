script_bot = {}

-- Inicialização segura (sem RagnarokBot)
setDefaultTab('Main')
local tabName = getTab('Main') or setDefaultTab('Main')

-- Sistema de armazenamento interno (sem arquivos)
storage.script_manager = storage.script_manager or {
  _cache = {},
  actualVersion = 0.4
}

local script_manager = storage.script_manager
local actualVersion = 0.4

local libraryList = {
    'https://raw.githubusercontent.com/Brinquee/community_scripts/refs/heads/main/Library.lua',
    'https://raw.githubusercontent.com/Brinquee/community_scripts/refs/heads/main/script.list.lua'
}

-- 🔒 Carregamento seguro das bibliotecas
for _, library in ipairs(libraryList) do
    modules._G.HTTP.get(library, function(content, error)
        if content and not error then
            local ok, res = pcall(loadstring(content))
            if not ok then
                print("Erro ao carregar:", res)
            end
        else
            print("Erro ao baixar biblioteca:", library)
        end
    end)
end

-- 🧱 Painel (mantido igual)
if not script_bot.widget then
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
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
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

    -- Botão principal
    script_bot.buttonWidget = UI.Button('Script Manager', function()
        if script_bot.widget:isVisible() then
            script_bot.widget:hide()
        else
            script_bot.widget:centerInParent()
            script_bot.widget:show()
        end
    end, tabName)
    script_bot.buttonWidget:setColor('#d2cac5')

    -- Botão fechar
    script_bot.widget.closeButton.onClick = function(widget)
        script_bot.widget:hide()
    end

    -- Filtro
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

    -- Funções de salvar e carregar (sem disco)
    script_bot.readScripts = function()
        script_manager = storage.script_manager
    end

    script_bot.saveScripts = function()
        storage.script_manager = script_manager
    end

    -- Monta lista (simples para teste)
    local function carregarLista()
        script_bot.widget.scriptList:destroyChildren()
        local exemplos = {
            ["Reflect"] = { enabled = true, description = "Hotkey Reflect." },
        }
        for nome, info in pairs(exemplos) do
            local label = setupUI(script_add, script_bot.widget.scriptList)
            label.textToSet:setText(nome)
            label.textToSet:setColor(info.enabled and 'green' or '#bdbdbd')
            label.onClick = function()
                info.enabled = not info.enabled
                label.textToSet:setColor(info.enabled and 'green' or '#bdbdbd')
            end
        end
    end

    carregarLista()
end
