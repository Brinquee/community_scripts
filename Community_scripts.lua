-- ===========================================================
-- Community Scripts (Loader + Painel) - Revisado (com HOTFIX)
-- - Cria o botão "Script Manager" imediatamente
-- - Carrega Library.lua e script.list.lua do seu repo
-- - Painel centralizado, estilo madeira, com abas, busca e toggle
-- - HOTFIX no final garante que o painel SEMPRE abre (completo ou mínimo)
-- ===========================================================

-- ---------- Setup básico ----------
setDefaultTab('Main')
local ROOT_TAB = getTab('Main') or setDefaultTab('Main')

-- URLs do seu repositório (atenção ao case!)
local REMOTE = {
  LIB  = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Library.lua',
  LIST = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/script.list.lua',
}

-- Estado
script_bot = script_bot or {}
storage.community_scripts_data = storage.community_scripts_data or {}
storage.scriptManager = storage.scriptManager or { pos=nil, visible=false }

-- ---------- Logs ----------
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

-- Carrega Library + Lista (assíncrono)
fetchAndRun(REMOTE.LIB,  'Library.lua')
fetchAndRun(REMOTE.LIST, 'script.list.lua')

-- ===========================================================
-- Painel Script Manager (madeira, centralizado, arrastável)
-- ===========================================================
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

  -- restaura posição salva (se houver)
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
    for _, child in pairs(w.scriptList:getChildren()) do
      local id = child:getId() or ''
      if id:lower():find((text or ''):lower()) then child:show() else child:hide() end
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

-- ===========================================================
-- Botão: nasce IMEDIATAMENTE quando a UI está pronta
-- ===========================================================
local function createToolbarButton()
  if script_bot.button and not script_bot.button:isDestroyed() then
    script_bot.button:destroy()
  end
  script_bot.button = UI.Button('Script Manager', function()
    -- cria/mostra o painel
    if not script_bot.widget or script_bot.widget:isDestroyed() then
      buildScriptPanel()
    end
    -- se cache ainda não carregou, mostra aviso no console
    if not (script_manager and script_manager._cache and next(script_manager._cache)) then
      print('[CommunityScripts] Lista ainda carregando... abas serão preenchidas quando disponível.')
    else
      script_bot.buildTabs()
    end

    -- alterna visibilidade
    if script_bot.widget:isVisible() then
      script_bot.widget:hide()
      storage.scriptManager.visible = false
    else
      script_bot.widget:show()
      storage.scriptManager.visible = true
      -- reforça centralização
      addEvent(function()
        if script_bot.widget and script_bot.widget.centerInParent then
          pcall(function() script_bot.widget:centerInParent() end)
        end
      end)
    end
  end, ROOT_TAB)
end

-- Watcher: quando a lista carregar, preenche abas se o painel estiver aberto
local function watchCacheReady()
  if script_manager and script_manager._cache and next(script_manager._cache) then
    if script_bot.widget and script_bot.widget:isVisible() and script_bot.buildTabs then
      script_bot.buildTabs()
    end
    return -- pronto
  end
  scheduleEvent(watchCacheReady, 300)
end

-- Inicializa quando UI estiver pronta: cria o botão SEM depender da lista
local function initUI()
  if not g_ui or not g_ui.getRootWidget() then
    scheduleEvent(initUI, 150); return
  end
  createToolbarButton()
  -- se já estava visível da sessão anterior, abre
  if storage.scriptManager.visible then
    if not script_bot.widget or script_bot.widget:isDestroyed() then
      buildScriptPanel()
    end
    script_bot.widget:show()
  end
  watchCacheReady()
  logOK('UI pronta. Botão criado.')
end

initUI()

-- ===========================================================
-- =====================  H O T F I X  ========================
-- (Garante que o clique do botão SEMPRE abre um painel,
-- caindo para um painel mínimo se o completo falhar)
-- ===========================================================

-- 1) Constrói um painel MÍNIMO (à prova de erro)
local function cs_buildMinimalPanel()
  if script_bot.widget and not script_bot.widget:isDestroyed() then
    script_bot.widget:destroy()
  end

  local ui = [[
MainWindow
  id: scriptManagerWin
  text: Script Manager
  size: 300 220
  color: #d2cac5
  background-color: #3a2d1e
  opacity: 0.96
  focusable: true
  padding: 8

  Label
    id: title
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    margin-top: 6
    text: Painel carregado!

  TextEdit
    id: searchBar
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: title.bottom
    margin-top: 8
    text: digite para filtrar...

  ScrollablePanel
    id: scriptList
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: searchBar.bottom
    anchors.bottom: parent.bottom
    margin-top: 6
    layout:
      type: verticalBox
]]
  local ok, w = pcall(function() return setupUI(ui, g_ui.getRootWidget()) end)
  if not ok or not w then
    print("[CommunityScripts][ERRO] setupUI falhou no painel mínimo:", ok, w)
    return nil
  end

  script_bot.widget = w

  -- centraliza com fallback
  addEvent(function()
    local root = g_ui.getRootWidget()
    if w.centerInParent then
      pcall(function() w:centerInParent() end)
    else
      local x = (root:getWidth() - w:getWidth())/2
      local y = (root:getHeight() - w:getHeight())/2
      w:move({x=x, y=y})
    end
  end)

  -- restaura posição salva (se existir)
  storage.scriptManager = storage.scriptManager or { pos=nil, visible=false }
  if storage.scriptManager.pos then w:move(storage.scriptManager.pos) end
  local oldMove = w.move
  w.move = function(self, pos)
    if oldMove then oldMove(self, pos) end
    storage.scriptManager.pos = pos
  end

  -- filtro simples
  w.searchBar.onTextChange = function(_, text)
    for _, child in pairs(w.scriptList:getChildren()) do
      local id = (child:getId() or ""):lower()
      if id:find((text or ""):lower()) then child:show() else child:hide() end
    end
  end

  print("[CommunityScripts] Painel mínimo criado.")
  return w
end

-- 2) Se o painel "completo" falhar, cai no mínimo
local function cs_openPanel()
  -- tenta usar painel existente
  if script_bot.widget and not script_bot.widget:isDestroyed() then
    script_bot.widget:show()
    addEvent(function() if script_bot.widget.centerInParent then pcall(function() script_bot.widget:centerInParent() end) end end)
    print("[CommunityScripts] Painel já existia; mostrando.")
    return
  end

  -- tenta reconstruir o painel completo se a função existir
  if type(buildScriptPanel) == "function" then
    local ok, w = pcall(buildScriptPanel)
    if ok and w then
      w:show()
      addEvent(function() if w.centerInParent then pcall(function() w:centerInParent() end) end end)
      print("[CommunityScripts] Painel completo criado.")
      -- se já tem cache, popula abas/lista
      if script_manager and script_manager._cache and script_bot.buildTabs then
        pcall(script_bot.buildTabs)
      end
      return
    else
      print("[CommunityScripts][WARN] Painel completo falhou, abrindo mínimo:", w)
    end
  end

  -- fallback: painel mínimo
  local w2 = cs_buildMinimalPanel()
  if w2 then
    w2:show()
  end
end

-- 3) Substitui o clique do botão para SEMPRE abrir algo
local function cs_patchButton()
  if not script_bot.button or script_bot.button:isDestroyed() then
    -- tenta recriar caso não exista
    if UI and UI.Button then
      script_bot.button = UI.Button('Script Manager', function() end, getTab('Main') or setDefaultTab('Main'))
    else
      print("[CommunityScripts][ERRO] UI.Button indisponível.")
      return
    end
  end

  script_bot.button.onClick = function()
    -- se visível, alterna; se não existir, cria
    if script_bot.widget and not script_bot.widget:isDestroyed() and script_bot.widget:isVisible() then
      script_bot.widget:hide()
      storage.scriptManager.visible = false
      return
    end

    -- abre (completo -> mínimo)
    cs_openPanel()
    storage.scriptManager.visible = true

    -- quando a lista carregar, se o painel mínimo estiver aberto, injeta linhas simples
    if script_bot.widget and script_bot.widget.scriptList and script_manager and script_manager._cache then
      local list = script_bot.widget.scriptList
      list:destroyChildren()
      for cat, macros in pairs(script_manager._cache) do
        -- título de categoria
        local catLabel = UI.Label(("== %s =="):format(cat), list)
        catLabel:setColor("yellow")
        catLabel:setId(("cat_%s"):format(cat))
        -- itens
        for name, data in pairs(macros) do
          local row = UI.Label(("- %s"):format(name), list)
          row:setId(name)
          row:setTooltip((data.description or "-") .. "\n" .. (data.url or ""))
        end
      end
    end
  end
  print("[CommunityScripts] Botão patchado: clique garantido abre o painel (completo ou mínimo).")
end

-- 4) Aplica o patch assim que a UI estiver pronta
local function cs_waitUI()
  if not g_ui or not g_ui.getRootWidget() then
    scheduleEvent(cs_waitUI, 150); return
  end
  cs_patchButton()
end
cs_waitUI()
