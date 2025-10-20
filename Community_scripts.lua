-- ===========================================================
-- Community Scripts (Loader + Painel) - Brinquee
-- - Sem ragnarokBot, sem JSON, sem paths locais
-- - Usa Library.lua (widgets/helpers) e script.list.lua do seu repo
-- - Painel centralizado com abas, busca e toggle de macros
-- ===========================================================

-- ---------- Setup básico ----------
setDefaultTab('Main')
local ROOT_TAB = getTab('Main') or setDefaultTab('Main')

-- URLs do seu repositório (atenção ao case!)
local REMOTE = {
  LIB  = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Library.lua',
  LIST = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/script.list.lua',
}

-- Estado local
script_bot = script_bot or {}
storage.community_scripts_data = storage.community_scripts_data or {}

-- ---------- Helpers de log ----------
local function logOK(...)  print('[CommunityScripts]', ...) end
local function logERR(...) print('[CommunityScripts][ERRO]', ...) end

-- ---------- Baixa e executa um arquivo remoto ----------
local function fetchAndRun(url, tag)
  modules.corelib.HTTP.get(url, function(content, err)
    if not content then logERR('Falha ao baixar', tag or url, '=>', err or 'sem detalhe'); return end
    local ok, fn = pcall(loadstring, content)
    if not ok then logERR('Compilando', tag or url, '=>', fn); return end
    local ok2, res = pcall(fn)
    if not ok2 then logERR('Executando', tag or url, '=>', res); return end
    logOK('OK ->', tag or url)
  end)
end

-- ---------- Carrega Library + Lista ----------
fetchAndRun(REMOTE.LIB,  'Library.lua')
fetchAndRun(REMOTE.LIST, 'script.list.lua')

-- ===========================================================
-- Painel Script Manager (madeira, centralizado, arrastável)
-- ===========================================================
-- (Se a sua skin não suportar draggable/moveable, mantém centralizado)

local function buildScriptPanel()
  if script_bot.widget and not script_bot.widget:isDestroyed() then
    script_bot.widget:destroy()
  end

  local ui = [[
MainWindow
  id: scriptManagerWin
  !text: tr('Community Scripts')
  size: 300 400
  color: #d2cac5
  background-color: #3a2d1e
  opacity: 0.95
  draggable: true
  moveable: true
  focusable: true
  padding: 8

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
    margin-top: 28
    margin-left: 4
    margin-right: 16
    margin-bottom: 36
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
    width: 160

  Button
    id: closeButton
    !text: tr('Close')
    anchors.right: parent.right
    anchors.left: searchBar.right
    anchors.bottom: parent.bottom
    size: 45 21
    margin-bottom: 1
    margin-right: 5
    margin-left: 5
]]
  local w = setupUI(ui, g_ui.getRootWidget())
  script_bot.widget = w
  w:hide()

  -- centraliza (com fallback)
  addEvent(function()
    if w.centerInParent then
      pcall(function() w:centerInParent() end)
    else
      local root = g_ui.getRootWidget()
      local x = (root:getWidth() - w:getWidth())/2
      local y = (root:getHeight() - w:getHeight())/2
      w:move({x=x,y=y})
    end
  end)

  -- salva posição quando mover (se a skin permitir)
  storage.scriptManager = storage.scriptManager or { pos=nil, visible=false }
  if storage.scriptManager.pos then
    w:move(storage.scriptManager.pos)
  end
  local oldMove = w.move
  w.move = function(self, pos)
    if oldMove then oldMove(self, pos) end
    storage.scriptManager.pos = pos
  end

  -- fechar
  w.closeButton.onClick = function()
    w:hide()
    storage.scriptManager.visible = false
  end

  -- busca
  w.searchBar:setTooltip('Search macros')
  w.searchBar.onTextChange = function(_, text)
    if not w or w:isDestroyed() then return end
    for _, child in pairs(w.scriptList:getChildren()) do
      local id = child:getId() or ''
      if id:lower():find(text:lower()) then child:show() else child:hide() end
    end
  end

  -- item da lista
  local itemLayout = [[
UIWidget
  height: 28
  margin-top: 3
  background-color: alpha
  focusable: true

  $focus:
    background-color: #00000055

  Label
    id: textToSet
    font: terminus-14px-bold
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    margin-left: 8

  UILabel
    id: author
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    margin-right: 8
    color: #bdbdbd
]]

  -- atualiza lista ao trocar de aba
  function script_bot.updateScriptList(tabText)
    if not script_manager or not script_manager._cache then return end
    w.scriptList:destroyChildren()
    local list = script_manager._cache[tabText]
    if not list then return end

    for name, data in pairs(list) do
      local row = setupUI(itemLayout, w.scriptList)
      row:setId(name)
      row.textToSet:setText(name)
      row.textToSet:setColor(data.enabled and 'green' or '#d2cac5')
      row.author:setText(data.author and ('by ' .. data.author) or '')
      row:setTooltip(string.format("Description: %s\nURL: %s",
                      data.description or '-', data.url or '-'))

      row.onClick = function()
        data.enabled = not data.enabled
        row.textToSet:setColor(data.enabled and 'green' or '#d2cac5')
        -- persiste em storage (sem JSON)
        storage.community_scripts_data = storage.community_scripts_data or {}
        storage.community_scripts_data._cache = storage.community_scripts_data._cache or {}
        storage.community_scripts_data._cache[tabText] = storage.community_scripts_data._cache[tabText] or {}
        storage.community_scripts_data._cache[tabText][name] = data

        -- carrega quando ligar
        if data.enabled and data.url and type(loadRemoteScript) == 'function' then
          loadRemoteScript(data.url)
        end
      end
    end
  end

  -- cria abas
  function script_bot.buildTabs()
    if not script_manager or not script_manager._cache then return end
    w.macrosOptions:destroyChildren()
    for categoryName, _ in pairs(script_manager._cache) do
      local tab = w.macrosOptions:addTab(categoryName)
      tab:setId(categoryName)
      tab:setTooltip(categoryName .. ' Macros')
      tab.onStyleApply = function(widget)
        if w.macrosOptions:getCurrentTab() == widget then widget:setColor('green') else widget:setColor('white') end
      end
    end

    local current = w.macrosOptions:getCurrentTab()
    if current and current.text then
      script_bot.updateScriptList(current.text)
    end

    w.macrosOptions.onTabChange = function(_, tab)
      script_bot.updateScriptList(tab:getText())
      w.searchBar.onTextChange(w.searchBar, w.searchBar:getText() or '')
    end
  end

  logOK('Painel pronto.')
  return w
end

-- ---------- Botão na toolbar ----------
local function ensureToolbarButton()
  if script_bot.button and not script_bot.button:isDestroyed() then
    script_bot.button:destroy()
  end
  script_bot.button = UI.Button('Script Manager', function()
    if not script_bot.widget or script_bot.widget:isDestroyed() then
      buildScriptPanel()
    end
    if script_bot.widget:isVisible() then
      script_bot.widget:hide()
      storage.scriptManager.visible = false
    else
      script_bot.widget:show()
      storage.scriptManager.visible = true
      -- reforça centralização na abertura
      addEvent(function()
        if script_bot.widget.centerInParent then
          pcall(function() script_bot.widget:centerInParent() end)
        end
      end)
      -- se ainda não criou abas/lista (ex.: primeira vez)
      if script_manager and script_manager._cache then
        script_bot.buildTabs()
      end
    end
  end, ROOT_TAB)
end

-- ---------- Inicialização orquestrada ----------
local function initWhenReady()
  -- espera UI
  if not g_ui or not g_ui.getRootWidget() then
    scheduleEvent(initWhenReady, 200); return
  end
  -- espera Library + Lista popularem 'script_manager._cache'
  if not script_manager or not script_manager._cache or next(script_manager._cache) == nil then
    logOK('Aguardando script.list.lua carregar...')
    scheduleEvent(initWhenReady, 300); return
  end

  ensureToolbarButton()
  buildScriptPanel()
  script_bot.buildTabs()

  -- restaura visibilidade
  if storage.scriptManager and storage.scriptManager.visible then
    script_bot.widget:show()
  end

  logOK('Inicializado: categorias detectadas:', tostring(next(script_manager._cache) ~= nil))
end

initWhenReady()
