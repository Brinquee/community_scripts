-- Community_scripts.lua (final robusto)
script_bot = {}

-- ========= TABS (garantia do botão aparecer) =========
local function pickTab()
  return getTab('HP') or getTab('Main') or setDefaultTab('Main')
end
local tabName = pickTab()

-- ========= Versão =========
local actualVersion = 0.4

-- ========= Janela + Botão (criados já no início) =========
local function buildUI()
  if script_bot.widget then return end

  local wnd = setupUI([[
MainWindow
  !text: tr('Community Scripts')
  font: terminus-14px-bold
  color: #d2cac5
  size: 360 460

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
    margin-bottom: 34
    vertical-scrollbar: scriptListScrollBar

  VerticalScrollBar
    id: scriptListScrollBar
    anchors.top: scriptList.top
    anchors.bottom: scriptList.bottom
    anchors.right: scriptList.right
    step: 14
    pixels-scroll: true
    margin-right: -10

  TextEdit
    id: searchBar
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    margin-right: 5
    width: 200

  Button
    id: closeButton
    !text: tr('Close')
    font: cipsoftFont
    anchors.right: parent.right
    anchors.left: searchBar.right
    anchors.bottom: parent.bottom
    size: 50 21
    margin-bottom: 1
    margin-right: 5
    margin-left: 5
]], g_ui.getRootWidget())

  wnd:hide()
  wnd:setText('Community Scripts - ' .. actualVersion)
  script_bot.widget = wnd

  -- botão no painel
  script_bot.buttonWidget = UI.Button('CS Manager (NEW)', function()
    if script_bot.widget:isVisible() then
      script_bot.widget:hide()
    else
      script_bot.widget:show()
      script_bot.widget:raise()
      script_bot.widget:focus()
    end
  end, tabName)
  script_bot.buttonWidget:setColor('#d2cac5')

  -- fechar
  wnd.closeButton.onClick = function()
    wnd:hide()
  end

  -- busca
  wnd.searchBar:setTooltip('Search macros.')
  wnd.searchBar.onTextChange = function(widget, text)
    if not script_bot.widget then return end
    for _, child in pairs(script_bot.widget.scriptList:getChildren()) do
      local id = child:getId() or ''
      child:setVisible(id:lower():find(text:lower() or '') ~= nil)
    end
  end

  print('[CS UI] Janela e botão prontos.')
end

buildUI()

-- ========= Helpers UI =========
local function addLoading(text, color)
  if not script_bot.widget then return nil end
  local lbl = UI.Label(text or 'Carregando...')
  if color then lbl:setColor(color) end
  script_bot.widget.scriptList:addChild(lbl)
  return lbl
end

local function clearList()
  if script_bot.widget then
    script_bot.widget.scriptList:destroyChildren()
  end
end

-- ========= URLs (sempre branch main) =========
local LIB_URL  = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Library.lua'
local LIST_URL = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/script.list.lua'

-- ========= Carregamento com logs =========
local pending = 2
local loadingLabel = addLoading('Carregando lista de scripts...', 'yellow')

local function doneOne()
  pending = pending - 1
  if pending == 0 then
    -- verificar cache e popular
    local tries = 0
    local function tryPopulate()
      tries = tries + 1
      local ready = (script_manager and script_manager._cache and next(script_manager._cache))
      print(string.format('[CS Loader] tentativa %d, cache pronto? %s', tries, ready and 'SIM' or 'NÃO'))
      if ready then
        if loadingLabel and loadingLabel:getParent() then loadingLabel:destroy() end

        -- criar abas
        script_bot.widget.macrosOptions:clearTabs()
        local categories = {}
        for cname, _ in pairs(script_manager._cache) do table.insert(categories, cname) end
        table.sort(categories)

        for _, cname in ipairs(categories) do
          local tab = script_bot.widget.macrosOptions:addTab(cname)
          tab:setId(cname)
          tab:setTooltip(cname .. ' Macros')
          tab.onStyleApply = function(w)
            if script_bot.widget.macrosOptions:getCurrentTab() == w then
              w:setColor('green')
            else
              w:setColor('white')
            end
          end
        end

        -- item layout
        local itemLayout = [[
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

        local function populateList(catName)
          clearList()
          local cat = script_manager._cache[catName]
          if not cat then return end
          for key, value in pairs(cat) do
            local row = setupUI(itemLayout, script_bot.widget.scriptList)
            row:setId(key)
            row.textToSet:setText(key)
            row.textToSet:setColor(value.enabled and 'green' or '#bdbdbd')
            row:setTooltip(('Description: %s\nAuthor: %s'):format(value.description or '-', value.author or '-'))
            row.onClick = function()
              value.enabled = not value.enabled
              row.textToSet:setColor(value.enabled ? 'green' : '#bdbdbd')
              -- carregar script quando ligar
              if value.enabled and value.url then
                modules.corelib.HTTP.get(value.url, function(scr, err)
                  if scr then
                    local ok, res = pcall(loadstring(scr))
                    if not ok then
                      print('[CS Script] erro executar', key, res)
                    else
                      print('[CS Script] OK', key)
                    end
                  else
                    print('[CS Script] erro baixar', key, err or '(sem detalhe)')
                  end
                end)
              end
            end
          end
        end

        -- primeira aba + handler
        local current = script_bot.widget.macrosOptions:getCurrentTab()
        if current then populateList(current.text) end
        script_bot.widget.macrosOptions.onTabChange = function(_, tab)
          populateList(tab:getText())
          local t = script_bot.widget.searchBar:getText()
          script_bot.widget.searchBar.onTextChange(nil, t)
        end
      else
        if tries < 6 then
          scheduleEvent(tryPopulate, 600)
        else
          if loadingLabel then
            loadingLabel:setText('Falha ao carregar lista. Verifique URLs/nomes (maiúsc./minúsc.).')
            loadingLabel:setColor('red')
          end
        end
      end
    end
    tryPopulate()
  end
end

-- baixa Library.lua
print('[CS Loader] Baixando:', LIB_URL)
modules._G.HTTP.get(LIB_URL, function(content, err)
  if not content then
    print('[CS Loader] ERRO Library.lua:', err or '(sem detalhe)')
  else
    local ok, res = pcall(loadstring(content))
    if not ok then
      print('[CS Loader] ERRO executar Library.lua:', res)
    else
      print('[CS Loader] OK Library.lua')
    end
  end
  doneOne()
end)

-- baixa script.list.lua
print('[CS Loader] Baixando:', LIST_URL)
modules._G.HTTP.get(LIST_URL, function(content, err)
  if not content then
    print('[CS Loader] ERRO script.list.lua:', err or '(sem detalhe)')
  else
    local ok, res = pcall(loadstring(content))
    if not ok then
      print('[CS Loader] ERRO executar script.list.lua:', res)
    else
      print('[CS Loader] OK script.list.lua')
    end
  end
  doneOne()
end)
