script_bot = {};

-- ===========================================================
-- 🔧 Inicialização (sem ragnarokBot.path e sem JSON externo)
-- ===========================================================
tabName = nil
setDefaultTab('Main')
tabName = getTab('Main') or setDefaultTab('Main')

-- Persiste dados internamente (sem arquivos externos)
storage.community_scripts_data = storage.community_scripts_data or {}

-- ===========================================================
-- ⚙️ Versão e bibliotecas remotas (seu repositório)
-- ===========================================================
actualVersion = 0.4

local libraryList = {
    'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Library.lua',
    'https://raw.githubusercontent.com/Brinquee/community_scripts/refs/heads/main/script.list.lua'
}

-- ===========================================================
-- 📦 Carregamento das bibliotecas
-- ===========================================================
for _, library in ipairs(libraryList) do
    modules._G.HTTP.get(library, function(content, error)
        if content then
            loadstring(content)()
            if not error then
                if script_manager then
                    local _G = modules._G
                    local g_resources = _G.g_resources

                    -- ===============================================
                    -- 📁 Funções de leitura/gravação (usando storage)
                    -- ===============================================
                    script_bot.readScripts = function()
                        local data = script_manager
                        if type(storage.community_scripts_data) == "table" and next(storage.community_scripts_data) ~= nil then
                            data = storage.community_scripts_data
                        else
                            storage.community_scripts_data = data
                        end
                        script_manager = data
                    end

                    script_bot.saveScripts = function()
                        storage.community_scripts_data = script_manager
                    end

                    script_bot.restartStorage = function()
                        storage.community_scripts_data = {}
                        reload()
                    end

                    -- ===================================================
                    -- 🪟 Interface do Script Manager
                    -- ===================================================
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

                        local updateLabel = UI.Label('Community Scripts. \n New version available, click "Update Files". \nVersion: ' .. actualVersion)
                        updateLabel:setColor('yellow')
                        updateLabel:hide()

                        -- Botão principal
                        script_bot.buttonWidget = UI.Button('Script Manager', function()
                            if script_bot.widget:isVisible() then
                                reload()
                            else
                                script_bot.widget:show()
                                script_bot.widget.macrosOptions:selectPrevTab()
                            end
                        end, tabName)
                        script_bot.buttonWidget:setColor('#d2cac5')

                        -- Botão de atualização
                        script_bot.buttonRemoveJson = UI.Button('Update Files', function()
                            script_bot.restartStorage()
                        end, tabName)
                        script_bot.buttonRemoveJson:setColor('#d2cac5')
                        script_bot.buttonRemoveJson:setTooltip('Click here only when there is an update.')
                        script_bot.buttonRemoveJson:hide()

                        -- Botão de fechar
                        script_bot.widget.closeButton:setTooltip('Close and add macros.')
                        script_bot.widget.closeButton.onClick = function(widget)
                            reload()
                            script_bot.widget:hide()
                        end

                        -- Barra de busca
                        script_bot.widget.searchBar:setTooltip('Search macros.')
                        script_bot.widget.searchBar.onTextChange = function(widget, text)
                            script_bot.filterScripts(text)
                        end

                        -- Filtro de scripts
                        function script_bot.filterScripts(filterText)
                            for _, child in pairs(script_bot.widget.scriptList:getChildren()) do
                                local scriptName = child:getId()
                                if scriptName:lower():find(filterText:lower()) then
                                    child:show()
                                else
                                    child:hide()
                                end
                            end
                        end

                        -- Atualiza lista
                        function script_bot.updateScriptList(tabName)
                            script_bot.widget.scriptList:destroyChildren()
                            local macrosCategory = script_manager._cache[tabName]

                            if macrosCategory then
                                for key, value in pairs(macrosCategory) do
                                    local label = setupUI(script_add, script_bot.widget.scriptList)
                                    label.textToSet:setText(key)
                                    label.textToSet:setColor('#bdbdbd')
                                    label:setTooltip('Description: ' .. value.description .. '\nAuthor: ' .. value.author)

                                    label.onClick = function(widget)
                                        value.enabled = not value.enabled
                                        script_bot.saveScripts()
                                        label.textToSet:setColor(value.enabled and 'green' or '#bdbdbd')
                                        if value.enabled then
                                            -- loadRemoteScript(value.url)
                                        end
                                    end

                                    if value.enabled then
                                        label.textToSet:setColor('green')
                                    end

                                    label:setId(key)
                                end
                            end
                        end

                        -- Carregamento
                        script_bot.onLoading = function()
                            script_bot.widget.scriptList:destroyChildren()

                            local categories = {}
                            for categoryName, categoryList in pairs(script_manager._cache) do
                                table.insert(categories, categoryName)
                                for key, value in pairs(categoryList) do
                                    if value.enabled then
                                        modules.corelib.HTTP.get(value.url, function(script)
                                            assert(loadstring(script))()
                                        end)
                                    end
                                end
                            end

                            local numSteps = 6
                            local numCategories = #categories
                            local numLoops = math.ceil(numCategories / numSteps)

                            for i = 1, numLoops do
                                for j = 1, numSteps do
                                    local index = (i - 1) * numSteps + j
                                    if index <= numCategories then
                                        local categoryName = categories[index]
                                        local tab = script_bot.widget.macrosOptions:addTab(categoryName)
                                        tab:setId(categoryName)
                                        tab:setTooltip(categoryName .. ' Macros')

                                        tab.onStyleApply = function(widget)
                                            if script_bot.widget.macrosOptions:getCurrentTab() == widget then
                                                widget:setColor('green')
                                            else
                                                widget:setColor('white')
                                            end
                                        end
                                    end
                                end
                            end

                            local currentTab = script_bot.widget.macrosOptions:getCurrentTab().text
                            script_bot.updateScriptList(currentTab)

                            script_bot.widget.macrosOptions.onTabChange = function(widget, tabName)
                                script_bot.updateScriptList(tabName:getText())
                                script_bot.filterScripts(script_bot.widget.searchBar:getText())
                            end
                        end

                        -- Execução principal
                        do
                            script_bot.readScripts()
                            script_bot.onLoading()
                        end

                        if script_manager.actualVersion ~= actualVersion then
                            script_bot.buttonRemoveJson:show()
                            updateLabel:show()
                        end
                    end
                end
            end
        end
    end)
end
