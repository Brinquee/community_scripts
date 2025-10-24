-- ===========================================================
-- BRINQUE - OTC - CUSTOM  (painel compacto + Macro Dock)
-- ===========================================================

script_bot = {}

-- --- Config -------------------------------------------------
local TAB_ID = 'Main'
local actualVersion = 0.2
local RAW = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts'
local LOAD_ACTIVE_ON_START = true

-- --- Setup aba ---------------------------------------------
setDefaultTab(TAB_ID)
local tabName = getTab(TAB_ID) or setDefaultTab(TAB_ID)

-- --- Storage ------------------------------------------------
storage.cs_enabled  = storage.cs_enabled  or {}  -- [cat][name] = true/false
storage.cs_last_tab = storage.cs_last_tab or nil

-- --- Estado (novos) ----------------------------------------
script_bot.active = script_bot.active or {}  -- ["CAT::NAME"] = {cat=..., name=...}

local function keyFor(cat, name) return (cat .. "::" .. name) end

-- --- Utils --------------------------------------------------
local function logStatus(msg)
  print('[BRINQUE CUSTOM]', msg)
  if script_bot.widget and script_bot.widget.statusLabel then
    script_bot.widget.statusLabel:setText(msg)
  end
end

-- evita recarregar mesma URL no mesmo reload
loadedUrls = loadedUrls or {}
local function safeLoadUrl(url)
  if loadedUrls[url] then
    logStatus('Já carregado: ' .. url)
    return
  end
  modules.corelib.HTTP.get(url, function(content, err)
    if not content then
      logStatus('Erro ao baixar: ' .. (err or 'sem resposta'))
      return
    end
    local ok, res = pcall(loadstring(content))
    if not ok then
      logStatus('Erro ao executar: ' .. tostring(res))
    else
      loadedUrls[url] = true
      logStatus('Script carregado com sucesso.')
    end
  end)
end

local function isEnabled(cat, name)
  return storage.cs_enabled[cat] and storage.cs_enabled[cat][name] == true
end
local function setEnabled(cat, name, value)
  storage.cs_enabled[cat] = storage.cs_enabled[cat] or {}
  storage.cs_enabled[cat][name] = value and true or false
end

-- ===========================================================
-- LISTA LOCAL (podes editar/expandir à vontade)
-- ===========================================================
script_manager = {
  actualVersion = actualVersion,
  _cache = {
    HEALING = {
      ['Regeneration'] = {
        url = RAW .. '/Healing/Regeneration.lua',
        description = 'Cura por % de HP.',
        author = 'Brinquee',
      },
    },
    SUPPORT = {
      ['Utana Vid'] = {
        url = RAW .. '/Tibia/utana_vid.lua',
        description = 'Invisibilidade automática.',
        author = 'Brinquee',
      },
    },
    COMBOS = {
      ['Follow Attack'] = {
        url = RAW .. '/PvP/follow_attack.lua',
        description = 'Seguir e atacar target.',
        author = 'VictorNeox',
      },
    },
    ESPECIALS = {
      ['Reflect'] = {
        url = RAW .. '/Dbo/Reflect.lua',
        description = 'Reflect (DBO).',
        author = 'Brinquee',
      },
    },
    TEAMS = {
      ['Bug Map Kunai'] = {
        url = RAW .. '/Nto/Bug_map_kunai.lua',
        description = 'Bug map kunai (PC).',
        author = 'Brinquee',
      },
    },
    ICONS = {
      ['Dance'] = {
        url = RAW .. '/Utilities/dance.lua',
        description = 'Dança / diversão.',
        author = 'Brinquee',
      },
    },
  }
}

-- ===========================================================
-- UI principal
-- ===========================================================
local itemRow = [[
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
  !text: tr('BRINQUE - OTC - CUSTOM')
  font: terminus-14px-bold
  color: #05fff5
  size: 350 450

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
    margin-top: 45
    margin-left: 2
    margin-right: 15
    margin-bottom: 52
    vertical-scrollbar: scriptListScrollBar

  VerticalScrollBar
    id: scriptListScrollBar
    anchors.top: scriptList.top
    anchors.bottom: scriptList.bottom
    anchors.right: scriptList.right
    step: 14
    pixels-scroll: true
    margin-right: -10

  Label
    id: statusLabel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-bottom: 28
    text-align: center
    font: terminus-14px
    color: yellow

  TextEdit
    id: searchBar
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    margin-right: 5
    width: 90

  Button
    id: refreshButton
    !text: tr('Recarregar')
    font: cipsoftFont
    anchors.left: searchBar.right
    anchors.bottom: parent.bottom
    size: 84 22
    margin-bottom: 1
    margin-left: 5

  Button
    id: toggleAllButton
    !text: tr('All ON/OFF')
    font: cipsoftFont
    anchors.left: refreshButton.right
    anchors.bottom: parent.bottom
    size: 80 20
    margin-bottom: 1
    margin-left: 5

  Button
    id: dockButton
    !text: tr('Dock')
    font: cipsoftFont
    anchors.right: closeButton.left
    anchors.bottom: parent.bottom
    size: 60 20
    margin-bottom: 1
    margin-right: 5

  Button
    id: closeButton
    !text: tr('Fechar')
    font: cipsoftFont
    anchors.right: parent.right
    anchors.left: toggleAllButton.right
    anchors.bottom: parent.bottom
    size: 80 20
    margin-bottom: 1
    margin-right: 5
    margin-left: 5
]], g_ui.getRootWidget())

script_bot.widget:hide()
script_bot.widget:setText('BRINQUE - OTC - CUSTOM')
script_bot.widget.statusLabel:setText('Pronto.')
pcall(function() script_bot.widget:move(10, 10) end)

-- Botão principal no painel do bot
script_bot.buttonWidget = UI.Button('BRINQUE CUSTOM', function()
  if script_bot.widget:isVisible() then
    reload()
  else
    script_bot.widget:show()
    local last = storage.cs_last_tab
    if last then
      local function findTabByTextOrId(tabbar, key)
        if not tabbar or not key then return nil end
        for _, w in ipairs(tabbar:getChildren()) do
          if w.getText and (w:getText() == key) then return w end
          if w.getId   and (w:getId()   == key) then return w end
        end
        return nil
      end
      local w = findTabByTextOrId(script_bot.widget.macrosOptions, last)
      if w then script_bot.widget.macrosOptions:selectTab(w) end
    end
  end
end, tabName)
script_bot.buttonWidget:setColor('#11ffecff')

-- Fechar
script_bot.widget.closeButton:setTooltip('Fechar e recarregar.')
script_bot.widget.closeButton.onClick = function()
  reload()
  script_bot.widget:hide()
end

-- Busca
script_bot.widget.searchBar:setTooltip('Buscar...')
script_bot.widget.searchBar.onTextChange = function(_, text)
  script_bot.filterScripts(text)
end

-- ===========================================================
-- Macro Dock (painel secundário)
-- ===========================================================
local dockItemRow = [[
UIWidget
  height: 26
  background-color: alpha
  focusable: true

  $hover:
    background-color: #00000055

  Label
    id: label
    font: terminus-14px-bold
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 8
]]

function script_bot.ensureDock()
  if script_bot.dockWidget and not script_bot.dockWidget:isDestroyed() then return end
  script_bot.dockWidget = setupUI([[
MainWindow
  id: macroDock
  !text: tr('BRINQUE - Macro Dock')
  font: terminus-14px-bold
  color: #05fff5
  size: 260 360

  Button
    id: dockClose
    !text: tr('X')
    anchors.top: parent.top
    anchors.right: parent.right
    size: 18 18
    margin-top: 6
    margin-right: 6

  ScrollablePanel
    id: macroDockList
    layout:
      type: verticalBox
    anchors.fill: parent
    margin-top: 30
    margin-left: 6
    margin-right: 16
    margin-bottom: 10
    vertical-scrollbar: macroDockScroll

  VerticalScrollBar
    id: macroDockScroll
    anchors.top: macroDockList.top
    anchors.bottom: macroDockList.bottom
    anchors.right: macroDockList.right
    step: 14
    pixels-scroll: true
    margin-right: -10
]], g_ui.getRootWidget())
  script_bot.dockWidget:hide()

  script_bot.dockWidget.dockClose.onClick = function()
    script_bot.dockWidget:hide()
  end
end

function script_bot.toggleDock()
  script_bot.ensureDock()
  if script_bot.dockWidget:isVisible() then
    script_bot.dockWidget:hide()
  else
    script_bot.dockWidget:show()
  end
end

script_bot.widget.dockButton.onClick = function() script_bot.toggleDock() end

-- preenche o Dock a partir do mapa "active"
function script_bot.rebuildDock()
  script_bot.ensureDock()
  local list = script_bot.dockWidget.macroDockList
  if not list then return end
  list:destroyChildren()

  -- ordenado por categoria/nome
  local keys = {}
  for k in pairs(script_bot.active) do table.insert(keys, k) end
  table.sort(keys)

  for _, k in ipairs(keys) do
    local info = script_bot.active[k]
    local row = setupUI(dockItemRow, list)
    row:setId(k)
    row.label:setText(('%s • %s'):format(info.cat, info.name))
    row:setTooltip('Clique para desligar este macro.')

    -- desligar pelo Dock
    row.onClick = function()
      setEnabled(info.cat, info.name, false)
      script_bot.active[k] = nil
      script_bot.rebuildDock()
      -- repinta a lista da aba atual
      local cur = script_bot.widget.macrosOptions:getCurrentTab()
      if cur and cur.getText then
        script_bot.updateScriptList(cur:getText())
      end
    end
  end
end

-- sincroniza 1 macro no Dock
function script_bot.syncDockFor(cat, name, isOn)
  local k = keyFor(cat, name)
  if isOn then
    script_bot.active[k] = { cat = cat, name = name }
  else
    script_bot.active[k] = nil
  end
end

-- varre o storage e reconstrói "active"
function script_bot.scanStorageToActive()
  script_bot.active = {}
  for cat, list in pairs(script_manager._cache) do
    for name, _ in pairs(list) do
      if isEnabled(cat, name) then
        script_bot.active[keyFor(cat, name)] = { cat = cat, name = name }
      end
    end
  end
end

-- === Lista / filtro ========================================
function script_bot.filterScripts(filterText)
  local q = (filterText or ''):lower()
  for _, child in pairs(script_bot.widget.scriptList:getChildren()) do
    local scriptName = child:getId() or ''
    child:setVisible(scriptName:lower():find(q, 1, true) ~= nil)
  end
end

function script_bot.updateScriptList(tabText)
  script_bot.widget.scriptList:destroyChildren()
  local list = script_manager._cache[tabText]
  if not list then return end

  for name, data in pairs(list) do
    local row = setupUI(itemRow, script_bot.widget.scriptList)
    row:setId(name)
    row.textToSet:setText(name)
    row.textToSet:setColor(isEnabled(tabText, name) and 'green' or '#bdbdbd')
    row:setTooltip(('Description: %s\nAuthor: %s\n(Click = ON/OFF | Right-click = abrir URL)')
      :format(data.description or '-', data.author or '-'))

    -- ON/OFF
    row.onClick = function()
      local newState = not isEnabled(tabText, name)
      setEnabled(tabText, name, newState)
      row.textToSet:setColor(newState and 'green' or '#bdbdbd')
      -- carrega o script se ligou
      if newState and data.url then safeLoadUrl(data.url) end
      -- sincroniza Dock
      script_bot.syncDockFor(tabText, name, newState)
      script_bot.rebuildDock()
    end

    -- abrir URL com botão direito
    row.onMousePress = function(_, _, button)
      if button == MouseRightButton and data.url then
        if g_platform and g_platform.openUrl then
          g_platform.openUrl(data.url)
        end
        return true
      end
      return false
    end
  end
end

-- Toggle All
script_bot.widget.toggleAllButton.onClick = function()
  local tab = script_bot.widget.macrosOptions:getCurrentTab()
  if not tab then return end
  local cat = tab.text
  local list = script_manager._cache[cat]
  if not list then return end

  local onCount, allCount = 0, 0
  for name, _ in pairs(list) do
    allCount = allCount + 1
    if isEnabled(cat, name) then onCount = onCount + 1 end
  end
  local turnOn = onCount < allCount

  for name, data in pairs(list) do
    setEnabled(cat, name, turnOn)
    if turnOn and data.url then safeLoadUrl(data.url) end
    script_bot.syncDockFor(cat, name, turnOn)
  end

  script_bot.updateScriptList(cat)
  script_bot.rebuildDock()
end

-- Recarregar (limpa cache dos que estão ON e baixa de novo)
script_bot.widget.refreshButton.onClick = function()
  for cat, list in pairs(script_manager._cache) do
    for name, data in pairs(list) do
      if isEnabled(cat, name) and data.url then
        loadedUrls[data.url] = nil
      end
    end
  end
  local loaded = 0
  for cat, list in pairs(script_manager._cache) do
    for name, data in pairs(list) do
      if isEnabled(cat, name) and data.url then
        loaded = loaded + 1
        safeLoadUrl(data.url)
      end
    end
  end
  script_bot.scanStorageToActive()
  script_bot.rebuildDock()
  logStatus('Recarregado(s): ' .. loaded)
end

-- Monta as abas
do
  local cats = {}
  for cat in pairs(script_manager._cache) do table.insert(cats, cat) end
  table.sort(cats)

  for _, cat in ipairs(cats) do
    local tab = script_bot.widget.macrosOptions:addTab(cat)
    tab:setId(cat)
    tab:setTooltip(cat .. ' macros')
    tab.onStyleApply = function(widget)
      if script_bot.widget.macrosOptions:getCurrentTab() == widget then
        widget:setColor('#05fff5')
      else
        widget:setColor('red')
      end
    end
  end

  local startTab = storage.cs_last_tab or cats[1]
  for _, w in ipairs(script_bot.widget.macrosOptions:getChildren()) do
    if w.getText and w:getText() == startTab then
      script_bot.widget.macrosOptions:selectTab(w)
      break
    end
  end

  local cur = script_bot.widget.macrosOptions:getCurrentTab()
  if cur and cur.getText then
    script_bot.updateScriptList(cur:getText())
  end

  script_bot.widget.macrosOptions.onTabChange = function(_, t)
    local name = (type(t) == 'userdata' and t.getText) and t:getText() or t
    if not name or name == '' then
      local c = script_bot.widget.macrosOptions:getCurrentTab()
      name = (c and c.getText) and c:getText() or name
    end
    if not name then return end
    storage.cs_last_tab = name
    script_bot.updateScriptList(name)
    script_bot.filterScripts(script_bot.widget.searchBar:getText())
  end
end

-- Boot: carrega ON e sincroniza Dock
if LOAD_ACTIVE_ON_START then
  local bootCount = 0
  for cat, list in pairs(script_manager._cache) do
    for name, data in pairs(list) do
      if isEnabled(cat, name) and data.url then
        bootCount = bootCount + 1
        safeLoadUrl(data.url)
      end
    end
  end
  script_bot.scanStorageToActive()
  script_bot.rebuildDock()
  if bootCount > 0 then
    logStatus('Scripts ativos carregados: ' .. bootCount)
  end
else
  -- mesmo que não carregue, ainda assim mostra os que estão ON no Dock
  script_bot.scanStorageToActive()
  script_bot.rebuildDock()
end

logStatus('Pronto. Selecione uma aba e ative scripts.')
