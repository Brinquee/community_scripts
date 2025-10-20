-- ===========================================================
-- Community Scripts - Painel com Tabs + Lista (diagnóstico 2)
-- Remove âncoras inválidas (nada de HorizontalSeparator)
-- ===========================================================

setDefaultTab('Main')
local ROOT_TAB = getTab('Main') or setDefaultTab('Main')

script_bot = script_bot or {}
storage.scriptManager = storage.scriptManager or { pos=nil, visible=false }

local function ok(...)  print('[CS2][OK]', ...) end
local function err(...) print('[CS2][ERRO]', ...) end
local function log(...) print('[CS2]', ...) end

-- ---------- UI layout (sem o HorizontalSeparator bugado) ----------
local MAIN_UI = [[
MainWindow
  id: scriptManagerWin
  text: Community Scripts - 0.4
  size: 320 420
  color: #d2cac5
  background-color: #3a2d1e
  opacity: 0.98
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
    margin-right: 0

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

-- -------------- helpers ----------------
local function build_window()
  if script_bot.widget and not script_bot.widget:isDestroyed() then
    pcall(function() script_bot.widget:destroy() end)
  end
  local okSetup, winOrMsg = pcall(function()
    return setupUI(MAIN_UI, g_ui.getRootWidget())
  end)
  if not okSetup then
    err('setupUI falhou:', winOrMsg); return nil
  end
  local w = winOrMsg
  if not w then err('setupUI retornou nil'); return nil end

  -- centraliza e restaura posição
  addEvent(function()
    if w.centerInParent then pcall(function() w:centerInParent() end) end
    if storage.scriptManager.pos then pcall(function() w:move(storage.scriptManager.pos) end) end
  end)

  -- salvar posição ao mover
  local oldMove = w.move
  w.move = function(self, pos)
    if oldMove then oldMove(self, pos) end
    storage.scriptManager.pos = pos
  end

  -- close
  w.closeButton.onClick = function()
    w:hide(); storage.scriptManager.visible = false; ok('Fechado.')
  end

  -- busca
  w.searchBar.onTextChange = function(_, text)
    if script_bot.filterScripts then script_bot.filterScripts(text) end
  end

  script_bot.widget = w
  return w
end

local function ensure_window()
  if script_bot.widget and not script_bot.widget:isDestroyed() then return script_bot.widget end
  return build_window()
end

-- --------- dataset: usa script_manager._cache se existir, senão mock ---------
local function get_categories()
  if script_manager and script_manager._cache and next(script_manager._cache) then
    return script_manager._cache
  end
  -- mock para garantir que a UI apareça algo
  return {
    Test = {
      ['Exemplo A'] = { description='Item de teste A', author='you', enabled=false, url='' },
      ['Exemplo B'] = { description='Item de teste B', author='you', enabled=true,  url='' },
    }
  }
end

-- --------- UI logic ---------
function script_bot.filterScripts(filterText)
  local list = script_bot.widget and script_bot.widget.scriptList
  if not list then return end
  for _, child in pairs(list:getChildren()) do
    local name = child:getId() or ''
    if name:lower():find((filterText or ''):lower()) then
      child:show()
    else
      child:hide()
    end
  end
end

function script_bot.updateScriptList(tabName)
  local w = ensure_window(); if not w then return end
  w.scriptList:destroyChildren()

  local cats = get_categories()
  local macros = cats[tabName]
  if not macros then return end

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
    end
  end
end

function script_bot.onLoading()
  local w = ensure_window(); if not w then return end

  -- cria abas a partir das categorias
  w.macrosOptions:clear()
  local cats = get_categories()
  local firstTab = nil
  for categoryName, _ in pairs(cats) do
    local tab = w.macrosOptions:addTab(categoryName)
    tab:setId(categoryName)
    tab.onStyleApply = function(widget)
      if w.macrosOptions:getCurrentTab() == widget then widget:setColor('green') else widget:setColor('white') end
    end
    if not firstTab then firstTab = categoryName end
  end

  -- listeners
  w.macrosOptions.onTabChange = function(_, tab)
    script_bot.updateScriptList(tab:getText())
    script_bot.filterScripts(w.searchBar:getText())
  end

  -- seleciona a primeira aba
  if firstTab then
    script_bot.updateScriptList(firstTab)
  end
end

-- ---------- botão ----------
local function create_button()
  if script_bot.button and not script_bot.button:isDestroyed() then
    pcall(function() script_bot.button:destroy() end)
  end
  script_bot.button = UI.Button('Script Manager', function()
    local w = ensure_window()
    if not w then return end
    if w:isVisible() then
      w:hide(); storage.scriptManager.visible = false
    else
      w:show(); storage.scriptManager.visible = true
      script_bot.onLoading()
    end
  end, ROOT_TAB)
  ok('Botão criado.')
end

-- ---------- init ----------
local function init_when_ready()
  if not g_ui or not g_ui.getRootWidget() then
    scheduleEvent(init_when_ready, 150); return
  end
  create_button()
  if storage.scriptManager.visible then
    local w = ensure_window()
    if w then w:show(); script_bot.onLoading() end
  end
  ok('UI pronta. Clique no botão para abrir o painel com tabs.')
end

init_when_ready()
