-- ===================================================================
-- 🧩 Community_scripts.lua - Gerenciador de Scripts Brinquee (v0.4 FINAL-FIX)
-- ===================================================================
-- ✅ Compatível com Library.lua e script.list.lua
-- ✅ Armazenamento interno via storage (sem JSON externo)
-- ✅ Botão fixo “Script Manager” na aba Main
-- ✅ Painel flutuante funcional e dinâmico
-- ===================================================================

script_bot = {}

---------------------------------------------------------------------
-- 🔧 Inicialização
---------------------------------------------------------------------
local tabName = getTab("Main") or setDefaultTab("Main")
storage.community_scripts_data = storage.community_scripts_data or {}
local actualVersion = 0.4

---------------------------------------------------------------------
-- 🌐 Links de biblioteca e lista
---------------------------------------------------------------------
local libraryList = {
    'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Library.lua',
    'https://raw.githubusercontent.com/Brinquee/community_scripts/main/script.list.lua'
}

---------------------------------------------------------------------
-- ⚙️ Função para inicializar o painel
---------------------------------------------------------------------
function script_bot.initUI()
    if script_bot.widget then return end

    -- Estrutura do painel
    script_bot.widget = setupUI([[
MainWindow
  id: communityPanel
  !text: tr('Community Scripts')
  size: 300 400
  color: #d2cac5
  font: terminus-14px-bold

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
    margin-left: 4
    margin-right: 12
    margin-bottom: 30
    vertical-scrollbar: scriptListScrollBar

  VerticalScrollBar
    id: scriptListScrollBar
    anchors.top: scriptList.top
    anchors.bottom: scriptList.bottom
    anchors.right: scriptList.right
    step: 14
    pixels-scroll: true
    margin-right: -8

  TextEdit
    id: searchBar
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    width: 130
    margin-left: 5
    margin-bottom: 4

  Button
    id: closeButton
    !text: tr('Close')
    anchors.left: searchBar.right
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    size: 60 21
    margin-left: 5
    margin-right: 5
    margin-bottom: 4
]], g_ui.getRootWidget())

    script_bot.widget:hide()
    print("[Script Manager] Painel carregado com sucesso!")
end

---------------------------------------------------------------------
-- 🧱 Função para criar o botão principal fixo na aba “Main”
---------------------------------------------------------------------
function script_bot.createMainButton()
    if script_bot.button then return end

    local tabMain = getTab("Main") or setDefaultTab("Main")

    script_bot.button = UI.Button("Script Manager", function()
        local ui = script_bot.widget
        if not ui then return end
        ui:setVisible(not ui:isVisible())
        if ui:isVisible() then
            script_bot.loadTabs()
        end
    end, tabMain)

    script_bot.button:setColor("#d2cac5")
    script_bot.button:setTooltip("Abrir o painel de scripts")
    print("[Community Scripts] Botão principal criado na aba 'Main'")
end

---------------------------------------------------------------------
-- 🔁 Atualiza a lista de scripts no painel
---------------------------------------------------------------------
function script_bot.updateScriptList(tabName)
    if not script_bot.widget or not script_manager then return end
    local scriptList = script_bot.widget.scriptList
    scriptList:destroyChildren()

    local macrosCategory = script_manager._cache[tabName]
    if not macrosCategory then return end

    for key, value in pairs(macrosCategory) do
        local label = setupUI([[
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
]], scriptList)

        label.textToSet:setText(key)
        label.textToSet:setColor(value.enabled and "green" or "#bdbdbd")
        label:setTooltip("Descrição: " .. (value.description or "Sem descrição") .. "\nAutor: " .. (value.author or "Desconhecido"))

        label.onClick = function(widget)
            value.enabled = not value.enabled
            script_bot.saveScripts()
            label.textToSet:setColor(value.enabled and "green" or "#bdbdbd")

            if value.enabled then
                loadRemoteScript(value.url)
            end
        end
    end
end

---------------------------------------------------------------------
-- 🧩 Função principal de carregamento de abas
---------------------------------------------------------------------
function script_bot.loadTabs()
    local ui = script_bot.widget
    if not ui or not script_manager or not script_manager._cache then return end

    local tabBar = ui.macrosOptions
    tabBar:clearTabs()

    for categoryName in pairs(script_manager._cache) do
        local tab = tabBar:addTab(categoryName)
        tab:setId(categoryName)
        tab.onStyleApply = function(widget)
            if tabBar:getCurrentTab() == widget then
                widget:setColor("green")
            else
                widget:setColor("white")
            end
        end
    end

    tabBar.onTabChange = function(widget, tab)
        script_bot.updateScriptList(tab:getText())
    end

    local firstTab = tabBar:getCurrentTab()
    if firstTab then
        script_bot.updateScriptList(firstTab:getText())
    end
end

---------------------------------------------------------------------
-- 💾 Leitura e salvamento interno
---------------------------------------------------------------------
function script_bot.readScripts()
    if type(storage.community_scripts_data) == "table" and next(storage.community_scripts_data) ~= nil then
        script_manager = storage.community_scripts_data
    else
        storage.community_scripts_data = script_manager
    end
end

function script_bot.saveScripts()
    storage.community_scripts_data = script_manager
end

---------------------------------------------------------------------
-- 🔄 Reinicialização
---------------------------------------------------------------------
function script_bot.restartStorage()
    storage.community_scripts_data = {}
    reload()
end

---------------------------------------------------------------------
-- 🕓 Carregamento das bibliotecas
---------------------------------------------------------------------
for _, library in ipairs(libraryList) do
    modules._G.HTTP.get(library, function(content, error)
        if not content then
            print("[Community Scripts] Falha ao carregar:", library)
            return
        end
        local ok, err = pcall(loadstring(content))
        if not ok then
            print("[Community Scripts] Erro:", err)
            return
        end
    end)
end

---------------------------------------------------------------------
-- ⏳ Aguarda lista de scripts e inicia UI
---------------------------------------------------------------------
local function waitForScripts()
    if not script_manager or not script_manager._cache or next(script_manager._cache) == nil then
        print("[Community Scripts] Aguardando lista de scripts carregar...")
        scheduleEvent(waitForScripts, 1000)
        return
    end

    script_bot.initUI()
    script_bot.createMainButton()
    print("[Community Scripts] Lista carregada, painel pronto.")
end

scheduleEvent(waitForScripts, 1200)
