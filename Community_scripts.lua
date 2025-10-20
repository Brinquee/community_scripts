-- Community_scripts.lua (versão adaptada p/ Brinquee repo + storage interno)
script_bot = {}
 
----------------------------------------------------------------------
-- Inicialização (sem arquivo JSON)
----------------------------------------------------------------------
tabName = nil
setDefaultTab('Main')
tabName = getTab('Main') or setDefaultTab('Main')

-- Versão
actualVersion = 0.4

-- Persistência interna
storage.community_scripts_data = storage.community_scripts_data or {}

----------------------------------------------------------------------
-- URLs das bibliotecas (SEU repositório)
----------------------------------------------------------------------
local libraryList = {
  'https://raw.githubusercontent.com/Brinquee/community_scripts/main/script.list.lua',
  'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Library.lua'
}

----------------------------------------------------------------------
-- Loader das bibliotecas
----------------------------------------------------------------------
local function loadUrl(url, onOk)
  modules.corelib.HTTP.get(url, function(content, err)
    if not content or #content == 0 then
      print('[Community Scripts] Falha ao baixar:', url, err or 'sem conteúdo')
      return
    end
    local ok, res = pcall(loadstring(content))
    if not ok then
      print('[Community Scripts] Erro executando lib:', res)
      return
    end
    if onOk then onOk() end
  end)
end

for _, url in ipairs(libraryList) do
  loadUrl(url)
end

----------------------------------------------------------------------
-- Leitura/Gravação usando storage
----------------------------------------------------------------------
script_bot.readScripts = function()
  local data = script_manager
  if type(storage.community_scripts_data) == 'table' and next(storage.community_scripts_data) then
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

----------------------------------------------------------------------
-- UI
----------------------------------------------------------------------
if not script_bot.widget then
  local script_item_row = [[
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

  -- Label de status/atualização
  local statusLabel = UI.Label('Carregando lista de scripts...')
  statusLabel:setColor('yellow')
  statusLabel:setId('statusLabel')
  statusLabel:setParent(script_bot.widget.scriptList)

  -- Botão principal
  script_bot.buttonWidget = UI.Button('CS Manager (NEW)', function()
    if script_bot.widget:isVisible() then
      reload()
    else
      script_bot.widget:show()
      script_bot.widget.macrosOptions:selectPrevTab()
    end
  end, tabName)
  script_bot.buttonWidget:setColor('#d2cac5')

  -- Botão “update”
  script_bot.buttonRemoveJson = UI.Button('Update Files', function()
    script_bot.restartStorage()
  end, tabName)
  script_bot.buttonRemoveJson:setColor('#d2cac5')
  script_bot.buttonRemoveJson:setTooltip('Click here only when there is an update.')
  script_bot.buttonRemoveJson:hide()

  -- Fechar
  script_bot.widget.closeButton:setTooltip('Close and add macros.')
  script_bot.widget.closeButton.onClick = function()
    reload()
    script_bot.widget:hide()
  end

  -- Busca
  script_bot.widget.searchBar:setTooltip('Search macros.')
  script_bot.widget.searchBar.onTextChange = function(_, text)
    for _, child in pairs(script_bot.widget.scriptList:getChildren()) do
      if child:getId() ~= 'statusLabel' then
        local name = child:getId() or ''
        if name:lower():find(text:lower()) then child:show() else child:hide() end
      end
    end
  end

  ------------------------------------------------------------------
  -- Render da lista
  ------------------------------------------------------------------
  function script_bot.updateScriptList(currentTabName)
    script_bot.widget.scriptList:destroyChildren()

    local macrosCategory = script_manager and script_manager._cache and script_manager._cache[currentTabName]
    if not macrosCategory then
      local lbl = UI.Label('Nenhum script nesta categoria.')
      lbl:setColor('#bdbdbd')
      lbl:setParent(script_bot.widget.scriptList)
      return
    end

    for key, value in pairs(macrosCategory) do
      local row = setupUI(script_item_row, script_bot.widget.scriptList)
      row.textToSet:setText(key)
      row.textToSet:setColor(value.enabled and 'green' or '#bdbdbd')
      row:setTooltip('Description: ' .. (value.description or '-') .. '\nAuthor: ' .. (value.author or '-'))
      row.onClick = function()
        value.enabled = not value.enabled
        row.textToSet:setColor(value.enabled and 'green' or '#bdbdbd')
        script_bot.saveScripts()
        -- Se quiser carregar imediatamente quando marcar:
        -- if value.enabled then loadRemoteScript(value.url) end
      end
      row:setId(key)
    end
  end

  ------------------------------------------------------------------
  -- Monta abas e carrega scripts marcados
  ------------------------------------------------------------------
  script_bot.onLoading = function()
    script_bot.widget.scriptList:destroyChildren()
    local cache = script_manager and script_manager._cache or {}

    local categories = {}
    for cat, list in pairs(cache) do
      table.insert(categories, cat)
      for _, v in pairs(list) do
        if v.enabled and v.url then
          modules.corelib.HTTP.get(v.url, function(scr)
            if scr and #scr > 0 then
              local ok, res = pcall(loadstring(scr))
              if not ok then print('[CS] Erro macro:', res) end
            end
          end)
        end
      end
    end

    -- cria abas
    for _, cat in ipairs(categories) do
      local tab = script_bot.widget.macrosOptions:addTab(cat)
      tab:setId(cat)
      tab:setTooltip(cat .. ' Macros')
      tab.onStyleApply = function(widget)
        if script_bot.widget.macrosOptions:getCurrentTab() == widget then
          widget:setColor('green')
        else
          widget:setColor('white')
        end
      end
    end

    -- seleciona e popula
    local cur = script_bot.widget.macrosOptions:getCurrentTab()
    if cur and cur.text then
      script_bot.updateScriptList(cur.text)
    end

    script_bot.widget.macrosOptions.onTabChange = function(_, t)
      script_bot.updateScriptList(t:getText())
      script_bot.widget.searchBar:onTextChange(script_bot.widget.searchBar, script_bot.widget.searchBar:getText())
    end
  end
end

-- ===========================================================
-- ⏳ Espera o script.list.lua montar o _cache antes de popular a UI
-- ===========================================================
local function waitForCache()
  -- ainda não chegou ou veio vazio?
  if not script_manager or not script_manager._cache or next(script_manager._cache) == nil then
    if script_bot and script_bot.buttonWidget then
      script_bot.buttonWidget:setTooltip('Carregando lista de scripts...')
    end
    scheduleEvent(waitForCache, 800)
    return
  end

  -- chegou: atualiza dica do botão e monta a UI
  if script_bot and script_bot.buttonWidget then
    script_bot.buttonWidget:setTooltip('Abrir Community Scripts')
  end

  if script_bot and script_bot.readScripts then
    script_bot.readScripts()
  end
  if script_bot and script_bot.onLoading then
    script_bot.onLoading()
  end

  -- botão de “Update Files” se versão mudou
  if script_manager and script_manager.actualVersion and script_manager.actualVersion ~= actualVersion then
    if script_bot and script_bot.buttonRemoveJson then
      script_bot.buttonRemoveJson:show()
    end
  end

  -- remove eventual label “carregando…”
  if script_bot and script_bot.widget and script_bot.widget.scriptList then
    local lbl = script_bot.widget.scriptList:getChildById('statusLabel')
    if lbl then lbl:destroy() end
  end
end

scheduleEvent(waitForCache, 1000)
