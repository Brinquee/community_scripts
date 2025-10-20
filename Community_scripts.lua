-- ===========================================================
-- Community Scripts (NEW) - Painel com Tabs + Lista (isolado)
-- Evita conflito com painel antigo ("Painel simples aberto!")
-- Botão: "CS Manager (NEW)"
-- ===========================================================

setDefaultTab('Main')
local ROOT_TAB = getTab('Main') or setDefaultTab('Main')

script_bot = script_bot or {}
storage.cs_new_ui = storage.cs_new_ui or { pos=nil, visible=false }

local function ok(...)  print('[CS-NEW][OK]', ...) end
local function err(...) print('[CS-NEW][ERRO]', ...) end
local function log(...) print('[CS-NEW]', ...) end

-- UI principal (sem âncoras quebradas)
local MAIN_UI = [[
MainWindow
  id: csNewWindow
  text: Community Scripts - 0.4
  size: 320 420
  color: #d2cac5
  background-color: #3a2d1e
  focusable: true
  padding: 6

  TabBar
    id: macrosOptions
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 24

  ScrollablePanel
    id: scriptList
    layout:
      type: verticalBox
    anchors.top: macrosOptions.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: searchBar.top
    margin-top: 6
    margin-left: 4
    margin-right: 12
    margin-bottom: 8
    vertical-scrollbar: scriptListScrollBar

  VerticalScrollBar
    id: scriptListScrollBar
    anchors.top: scriptList.top
    anchors.bottom: scriptList.bottom
    anchors.right: parent.right
    step: 14
    pixels-scroll: true

  TextEdit
    id: searchBar
    anchors.left: parent.left
    anchors.right: closeButton.left
    anchors.bottom: parent.bottom
    height: 24
    margin-right: 6
    placeholder: Search...

  Button
    id: closeButton
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 68 24
    text: Close
]]

local ITEM_UI = [[
UIWidget
  background-color: alpha
  focusable: true
  height: 28

  $focus:
    background-color: #00000055

  Label
    id: textToSet
    font: terminus-14px-bold
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    margin-left: 8
]]

-- cria/recupera janela
local function build_window()
  if script_bot.csNewWin and not script_bot.csNewWin:isDestroyed() then
    pcall(function() script_bot.csNewWin:destroy() end)
  end
  local okSetup, winOrMsg = pcall(function()
    return setupUI(MAIN_UI, g_ui.getRootWidget())
  end)
  if not okSetup then err('setupUI falhou:', winOrMsg) return nil end
  local w = winOrMsg
  if not w then err('setupUI retornou nil') return nil end

  -- posição
  addEvent(function()
    if w.centerInParent then pcall(function() w:centerInParent() end) end
    if storage.cs_new_ui.pos then pcall(function() w:move(storage.cs_new_ui.pos) end) end
  end)
  local oldMove = w.move
  w.move = function(self, pos)
    if oldMove then oldMove(self, pos) end
    storage.cs_new_ui.pos = pos
  end

  -- fechar
  w.closeButton.onClick = function()
    w:hide(); storage.cs_new_ui.visible = false; ok('Fechado')
  end

  -- busca
  w.searchBar.onTextChange = function(_, text)
    if script_bot.filterScripts then script_bot.filterScripts(text) end
  end

  script_bot.csNewWin = w
  return w
end

local function ensure_window()
  if script_bot.csNewWin and not script_bot.csNewWin:isDestroyed() then return script_bot.csNewWin end
  return build_window()
end

-- pega categorias do cache, ou mocka “Test”
local function get_categories()
  if script_manager and script_manager._cache and next(script_manager._cache) then
    return script_manager._cache
  end
  return {
    Test = {
      ['Exemplo A'] = { description='Item de teste A', author='you', enabled=false, url='' },
      ['Exemplo B'] = { description='Item de teste B', author='you', enabled=true,  url='' },
    }
  }
end

-- lógica de lista + filtro
function script_bot.filterScripts(filterText)
  local w = script_bot.csNewWin; if not w then return end
  local list = w.scriptList
  for _, child in pairs(list:getChildren()) do
    local name = child:getId() or ''
    if name:lower():find((filterText or ''):lower()) then child:show() else child:hide() end
  end
end

function script_bot.updateScriptList(tabName)
  local w = ensure_window(); if not w then return end
  w.scriptList:destroyChildren()
  local macros = get_categories()[tabName]; if not macros then return end
  for key, value in pairs(macros) do
    local row = setupUI(ITEM_UI, w.scriptList)
    row:setId(key)
    row.textToSet:setText(key)
    row.textToSet:setColor(value.enabled and 'green' or '#bdbdbd')
    row:setTooltip(('Description: %s\nAuthor: %s'):format(value.description or '-', value.author or '-'))
    row.onClick = function()
      value.enabled = not value.enabled
      row.textToSet:setColor(value.enabled and 'green' or '#bdbdbd')
      ok('Toggled', key, '=>', tostring(value.enabled))
      -- aqui depois podemos dar loadRemoteScript(value.url) se quiser
    end
  end
end

function script_bot.onLoading()
  local w = ensure_window(); if not w then return end
  w.macrosOptions:clear()
  local cats = get_categories()
  local firstTab
  for categoryName, _ in pairs(cats) do
    local tab = w.macrosOptions:addTab(categoryName)
    tab:setId(categoryName)
    tab.onStyleApply = function(widget)
      if w.macrosOptions:getCurrentTab() == widget then widget:setColor('green') else widget:setColor('white') end
    end
    if not firstTab then firstTab = categoryName end
  end
  w.macrosOptions.onTabChange = function(_, tab)
    script_bot.updateScriptList(tab:getText())
    script_bot.filterScripts(w.searchBar:getText())
  end
  if firstTab then script_bot.updateScriptList(firstTab) end
end

-- botão sem conflito
local function create_button()
  if script_bot.csNewBtn and not script_bot.csNewBtn:isDestroyed() then
    pcall(function() script_bot.csNewBtn:destroy() end)
  end
  script_bot.csNewBtn = UI.Button('CS Manager (NEW)', function()
    local w = ensure_window(); if not w then return end
    if w:isVisible() then
      w:hide(); storage.cs_new_ui.visible = false
    else
      w:show(); storage.cs_new_ui.visible = true
      script_bot.onLoading()
    end
  end, ROOT_TAB)
  ok('Botão criado: CS Manager (NEW)')
end

-- init depois que o UI raiz existir
local function init_when_ready()
  if not g_ui or not g_ui.getRootWidget() then
    scheduleEvent(init_when_ready, 150); return
  end
  create_button()
  if storage.cs_new_ui.visible then
    local w = ensure_window(); if w then w:show(); script_bot.onLoading() end
  end
  ok('Pronto. Clique no botão "CS Manager (NEW)".')
end

init_when_ready()
