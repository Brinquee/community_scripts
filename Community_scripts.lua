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
  'https://raw.githubusercontent.com/Brinquee/community_scripts/Library.lua',
  'https://raw.githubusercontent.com/Brinquee/community_scripts/script.list.lua'
}

-- ===========================================================
-- 📦 Carregamento das bibliotecas
-- ===========================================================
for _, library in ipairs(libraryList) do
  modules._G.HTTP.get(library, function(content, error)
    if not content then
      print('[CS] Falha ao baixar:', library, error or 'erro desconhecido')
      return
    end
    local ok, err = pcall(function() loadstring(content)() end)
    if not ok then
      print('[CS] Erro ao executar lib:', library, err)
      return
    end

    -- Após qualquer lib carregar, se já temos "script_manager" montado, montamos/atualizamos UI
    if script_manager then
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
    placeholder: Search...

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

        -- Botão principal (não mudo o texto/pos para não mexer na sua UI)
        script_bot.buttonWidget = UI.Button('CS Manager (NEW)', function()
          if script_bot.widget:isVisible() then
            script_bot.widget:hide()
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

        -- Fechar
        script_bot.widget.closeButton:setTooltip('Close and add macros.')
        script_bot.widget.closeButton.onClick = function()
          script_bot.widget:hide()
        end

        -- Busca
        script_bot.widget.searchBar:setTooltip('Search macros.')
        script_bot.widget.searchBar.onTextChange = function(widget, text)
          script_bot.filterScripts(text)
        end

        -- Placeholder “carregando...”
        do
          local l = UI.Label('Carregando lista de scripts...')
          l:setColor('yellow')
          l:setId('loadingLabel')
          l:setPhantom(false)
          script_bot.widget.scriptList:addChild(l)
        end

        -- Filtro
        function script_bot.filterScripts(filterText)
          for _, child in pairs(script_bot.widget.scriptList:getChildren()) do
            local scriptName = child:getId() or ''
            if scriptName ~= 'loadingLabel' then
              if scriptName:lower():find((filterText or ''):lower()) then
                child:show()
              else
                child:hide()
              end
            end
          end
        end

        -- Atualiza lista
        function script_bot.updateScriptList(tabText)
          script_bot.widget.scriptList:destroyChildren()
          local macrosCategory = script_manager._cache and script_manager._cache[tabText]
          if not macrosCategory then return end

          for key, value in pairs(macrosCategory) do
            local row = setupUI(script_add, script_bot.widget.scriptList)
            row.textToSet:setText(key)
            row.textToSet:setColor(value.enabled and 'green' or '#bdbdbd')
            row:setTooltip(('Description: %s\nAuthor: %s'):format(value.description or '-', value.author or '-'))
            row.onClick = function()
              value.enabled = not value.enabled
              row.textToSet:setColor(value.enabled and 'green' or '#bdbdbd')
              script_bot.saveScripts()
              -- opcional: carregar o script imediatamente
              -- if value.enabled then loadRemoteScript(value.url) end
            end
            row:setId(key)
          end
        end

        -- Monta abas + carrega scripts marcados
        script_bot.onLoading = function()
          script_bot.widget.scriptList:destroyChildren()

          if not (script_manager and script_manager._cache and next(script_manager._cache)) then
            -- ainda sem cache: deixa o “carregando…”
            local l = UI.Label('Carregando lista de scripts...')
            l:setColor('yellow')
            l:setId('loadingLabel')
            script_bot.widget.scriptList:addChild(l)
            return
          end

          -- cria abas
          script_bot.widget.macrosOptions:clear()
          for categoryName, categoryList in pairs(script_manager._cache) do
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

            -- carrega scripts já habilitados
            for _, value in pairs(categoryList) do
              if value.enabled then
                modules.corelib.HTTP.get(value.url, function(script)
                  local ok2, err2 = pcall(function() assert(loadstring(script))() end)
                  if not ok2 then
                    print('[CS] Erro ao carregar macro habilitado:', value.url, err2)
                  end
                end)
              end
            end
          end

          local currentTab = script_bot.widget.macrosOptions:getCurrentTab()
          if currentTab then
            script_bot.updateScriptList(currentTab.text)
          end

          script_bot.widget.macrosOptions.onTabChange = function(widget, t)
            script_bot.updateScriptList(t:getText())
            script_bot.filterScripts(script_bot.widget.searchBar:getText())
          end
        end

        -- Execução inicial
        script_bot.readScripts()
        script_bot.onLoading()
      end
    end
  end)
end

-- ===========================================================
-- ⏳ Watcher: espera o script.list popular o cache e repovoa
-- ===========================================================
local function waitForScripts()
  if script_bot and script_bot.onLoading and script_manager and script_manager._cache and next(script_manager._cache) then
    print('[CS] Lista carregada, preenchendo painel...')
    script_bot.onLoading()
    return
  end
  scheduleEvent(waitForScripts, 800)
end
scheduleEvent(waitForScripts, 800)
