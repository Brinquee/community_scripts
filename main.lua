-- ===========================================================
-- BRINQUE - OTC - CUSTOM  (painel compacto + Dock + isolamento de UI)
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

-- --- Utils --------------------------------------------------
local function logStatus(msg)
  print('[BRINQUE CUSTOM]', msg)
  if script_bot.widget and script_bot.widget.statusLabel then
    script_bot.widget.statusLabel:setText(msg)
  end
end

-- ===========================================================
--   ABA OCULTA + WRAPPERS para impedir UI no painel do bot
-- ===========================================================
local HIDDEN_TAB_ID = '_BRQ_MACROS'
local hiddenTab = getTab(HIDDEN_TAB_ID) or setDefaultTab(HIDDEN_TAB_ID)
pcall(function() if hiddenTab and hiddenTab.hide then hiddenTab:hide() end end)

local _orig = {}

local function beginRedirect()
  -- guardar originais uma única vez
  if not next(_orig) then
    _orig.getTab         = getTab
    _orig.setDefaultTab  = setDefaultTab
    _orig.createWidget   = g_ui.createWidget
    _orig.UI_Button      = UI.Button
    _orig.UI_Label       = UI.Label
    _orig.UI_TextEdit    = UI.TextEdit
    _orig.UI_CheckBox    = UI.CheckBox
    _orig.UI_ComboBox    = UI.ComboBox
    _orig.UI_Separator   = UI.Separator
    _orig.macro          = macro
    _orig.hotkey         = hotkey
  end

  _G.getTab = function(_) return hiddenTab end
  _G.setDefaultTab = function(_) return _orig.setDefaultTab(HIDDEN_TAB_ID) end

  g_ui.createWidget = function(style, parent)
    parent = parent or hiddenTab
    return _orig.createWidget(style, parent)
  end

  UI.Button    = function(text, cb, parent) return _orig.UI_Button(text, cb, hiddenTab) end
  UI.Label     = function(text, parent)     return _orig.UI_Label(text, hiddenTab)     end
  UI.TextEdit  = function(text, parent)     return _orig.UI_TextEdit(text or '', hiddenTab) end
  UI.CheckBox  = function(text, parent)     return _orig.UI_CheckBox(text, hiddenTab)  end
  UI.ComboBox  = function(parent)           return _orig.UI_ComboBox(hiddenTab)        end
  UI.Separator = function(parent)           return _orig.UI_Separator(hiddenTab)       end

  -- Captura nome do macro/hotkey para listar no Dock
  local function _attachToDock(obj, name)
    if not obj then return end
    local title = name
    if not title then
      if type(obj.getName) == 'function' then title = obj:getName() end
      title = title or 'Macro'
    end
    if obj.switch and obj.switch.setParent then
      pcall(function() obj.switch:setParent(hiddenTab) end)
    end
    if script_bot and script_bot._dockAdd then
      script_bot._dockAdd(title, obj)
    end
  end

  _G.macro = function(a, b, c, ...)
    local name = (type(a) == 'string' and a) or (type(b) == 'string' and b) or nil
    local m = _orig.macro(a, b, c, ...)
    _attachToDock(m, name)
    return m
  end

  _G.hotkey = function(keys, name, fn)
    local hk = _orig.hotkey(keys, name, fn)
    _attachToDock(hk, name)
    return hk
  end
end

local function endRedirect()
  if _orig.getTab then _G.getTab = _orig.getTab end
  if _orig.setDefaultTab then _G.setDefaultTab = _orig.setDefaultTab end
  if _orig.createWidget then g_ui.createWidget = _orig.createWidget end
  if _orig.UI_Button then UI.Button = _orig.UI_Button end
  if _orig.UI_Label  then UI.Label  = _orig.UI_Label  end
  if _orig.UI_TextEdit then UI.TextEdit = _orig.UI_TextEdit end
  if _orig.UI_CheckBox then UI.CheckBox = _orig.UI_CheckBox end
  if _orig.UI_ComboBox then UI.ComboBox = _orig.UI_ComboBox end
  if _orig.UI_Separator then UI.Separator = _orig.UI_Separator end
  if _orig.macro then _G.macro = _orig.macro end
  if _orig.hotkey then _G.hotkey = _orig.hotkey end
end

-- ===========================================================
--   Carregamento seguro (com cache)
-- ===========================================================
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
    beginRedirect()
    local ok, res = pcall(loadstring(content))
    endRedirect()
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
-- LISTA LOCAL (edite à vontade)
-- ===========================================================
script_manager = {
  actualVersion = actualVersion,
  _cache = {
    HEALING = {
      ['Regeneration'] = { url = RAW .. '/Healing/Regeneration.lua', description = 'Cura por % de HP.', author = 'Brinquee' },
    },
    SUPPORT = {
      ['Utana Vid']    = { url = RAW .. '/Tibia/utana_vid.lua',       description = 'Invisibilidade automática.', author = 'Brinquee' },
    },
    COMBOS = {
      ['Follow Attack']= { url = RAW .. '/PvP/follow_attack.lua',      description = 'Seguir e atacar target.',    author = 'VictorNeox' },
    },
    ESPECIALS = {
      ['Reflect']      = { url = RAW .. '/Dbo/Reflect.lua',            description = 'Reflect (DBO).',             author = 'Brinquee' },
    },
    TEAMS = {
      ['Bug Map Kunai']= { url = RAW .. '/Nto/Bug_map_kunai.lua',      description = 'Bug map kunai (PC).',        author = 'Brinquee' },
    },
    ICONS = {
      ['Dance']        = { url = RAW .. '/Utilities/dance.lua',        description = 'Dança / diversão.',          author = 'Brinquee' },
    },
  }
}

-- ===========================================================
-- UI principal (Manager)
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
    anchors.left: toggleAllButton.right
    anchors.bottom: parent.bottom
    size: 60 20
    margin-bottom: 1
    margin-left: 5

  Button
    id: closeButton
    !text: tr('Fechar')
    font: cipsoftFont
    anchors.right: parent.right
    anchors.left: dockButton.right
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

-- Botão principal no painel
script_bot.buttonWidget = UI.Button('BRINQUE CUSTOM', function()
  if script_bot.widget:isVisible() then
    reload()
  else
    script_bot.widget:show()
    local last = storage.cs_last_tab
    if last then
      for _, w in ipairs(script_bot.widget.macrosOptions:getChildren()) do
        if w.getText and w:getText() == last then
          script_bot.widget.macrosOptions:selectTab(w)
          break
        end
      end
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
-- Macro Dock (janela secundária com X no topo)
-- ===========================================================
script_bot._dockItems = script_bot._dockItems or {}

script_bot.dockWidget = setupUI([[
MainWindow
  id: dockRoot
  !text: tr('BRINQUE - Macro Dock')
  font: terminus-14px-bold
  color: #05fff5
  size: 260 420

  Button
    id: closeDock
    !text: tr('X')
    anchors.top: parent.top
    anchors.right: parent.right
    size: 24 22

  ScrollablePanel
    id: dockList
    layout:
      type: verticalBox
    anchors.top: closeDock.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-top: 6
    margin-left: 6
    margin-right: 12
    margin-bottom: 8
    vertical-scrollbar: dockScroll

  VerticalScrollBar
    id: dockScroll
    anchors.top: dockList.top
    anchors.bottom: dockList.bottom
    anchors.right: dockList.right
    step: 14
    pixels-scroll: true
    margin-right: -8
]], g_ui.getRootWidget())
script_bot.dockWidget:hide()
pcall(function() script_bot.dockWidget:move(320, 40) end)

script_bot.dockWidget.closeDock.onClick = function()
  script_bot.dockWidget:hide()
end
script_bot.widget.dockButton.onClick = function()
  if script_bot.dockWidget:isVisible() then
    script_bot.dockWidget:hide()
  else
    script_bot.dockWidget:show()
  end
end

-- Row visual do Dock
local dockRow = [[
UIWidget
  background-color: #2a1e17e0
  height: 26
  margin-top: 4
  padding-left: 8
  padding-right: 8
  focusable: true
  $hover:
    background-color: #3a2a20e0
  Label
    id: rowText
    anchors.verticalCenter: parent.verticalCenter
    font: terminus-14px-bold
    color: #a0a0a0
]]

-- adiciona/atualiza item no dock
function script_bot._dockAdd(name, obj)
  if not name or not obj then return end
  -- evita duplicata pelo próprio objeto
  for _, it in ipairs(script_bot._dockItems) do
    if it.obj == obj then
      it.name = name
      if it.widget and it.widget.rowText then
        it.widget.rowText:setText(name)
      end
      return
    end
  end
  local w = setupUI(dockRow, script_bot.dockWidget.dockList)
  w.rowText:setText(name)
  local function paint()
    local isOn = false
    if type(obj.isOn) == 'function' then
      local ok, v = pcall(obj.isOn, obj); if ok then isOn = v end
    end
    w.rowText:setColor(isOn and 'green' or '#a0a0a0')
  end
  w.onClick = function()
    if type(obj.isOn) == 'function' and type(obj.setOn) == 'function' then
      local ok, v = pcall(obj.isOn, obj); v = ok and v or false
      pcall(obj.setOn, obj, not v)
      paint()
    end
  end
  w.onMousePress = function(_, _, button)
    if button == MouseRightButton then
      -- destruir macro opcionalmente (se suportado)
      if type(obj.destroy) == 'function' then pcall(obj.destroy, obj) end
      w:destroy()
      -- remove do cache
      for i, it in ipairs(script_bot._dockItems) do
        if it.obj == obj then table.remove(script_bot._dockItems, i) break end
      end
      return true
    end
    return false
  end
  table.insert(script_bot._dockItems, {name=name, obj=obj, widget=w, paint=paint})
  paint()
end

-- ===========================================================
-- Lógica de lista/filtro no Manager
-- ===========================================================
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

    row.onClick = function()
      local newState = not isEnabled(tabText, name)
      setEnabled(tabText, name, newState)
      row.textToSet:setColor(newState and 'green' or '#bdbdbd')
      if newState and data.url then
        safeLoadUrl(data.url)
      end
    end

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
    if turnOn and data.url then
      safeLoadUrl(data.url)
    end
  end
  script_bot.updateScriptList(cat)
end

-- Recarregar (limpa cache dos ON e baixa de novo)
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

-- Carrega automaticamente os que estavam ON
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
  if bootCount > 0 then
    logStatus('Scripts ativos carregados: ' .. bootCount)
  end
end

logStatus('Pronto. Selecione uma aba e ative scripts.')
