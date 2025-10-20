-- Community_scripts.lua (diagnóstico com fallback)
script_bot = {}
local VERSION = 0.4

-- --- UI base (sempre aparece) ---
local tabName = getTab('HP') or getTab('Main') or setDefaultTab('Main')

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
    width: 200

  Button
    id: closeButton
    !text: tr('Close')
    font: cipsoftFont
    anchors.right: parent.right
    anchors.left: searchBar.right
    anchors.bottom: parent.bottom
    size: 50 21
    margin-left: 5
    margin-right: 5
]], g_ui.getRootWidget())

  wnd:hide()
  wnd:setText('Community Scripts - ' .. VERSION)
  script_bot.widget = wnd

  script_bot.buttonWidget = UI.Button('CS Manager (NEW)', function()
    if wnd:isVisible() then wnd:hide() else wnd:show(); wnd:raise(); wnd:focus() end
  end, tabName)
  script_bot.buttonWidget:setColor('#d2cac5')

  wnd.closeButton.onClick = function() wnd:hide() end
  wnd.searchBar.onTextChange = function(_, text)
    for _, child in pairs(wnd.scriptList:getChildren()) do
      local id = (child:getId() or ''):lower()
      child:setVisible(id:find((text or ''):lower()) ~= nil)
    end
  end
  print('[CS] UI pronta.')
end

buildUI()

local function clearList()
  if script_bot.widget then script_bot.widget.scriptList:destroyChildren() end
end

local function addLabel(txt, color)
  local l = UI.Label(txt)
  if color then l:setColor(color) end
  script_bot.widget.scriptList:addChild(l)
  return l
end

local loading = addLabel('Carregando lista de scripts...', 'yellow')

-- --- URLs (main) ---
local LIB_URL  = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Library.lua'
local LIST_URL = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/script.list.lua'

-- --- Baixar/rodar ---
local pending = 2

local function finishOne()
  pending = pending - 1
  if pending ~= 0 then return end

  -- Espera cache (ou cai no fallback)
  local tries = 0
  local function populateOrRetry()
    tries = tries + 1
    local ok = (script_manager and script_manager._cache and next(script_manager._cache))
    print(string.format('[CS] tentativa %d, cache pronto? %s', tries, ok and 'SIM' or 'NÃO'))

    if not ok and tries == 5 then
      -- Fallback demo
      print('[CS] Fallback DEMO ativado: mostrando categorias/itens fictícios.')
      script_manager = script_manager or {}
      script_manager._cache = {
        Dbo = { ['Reflect'] = {url='about:blank', description='Demo - reflect', author='demo', enabled=false}},
        Healing = { ['Regeneration'] = {url='about:blank', description='Demo - regen', author='demo', enabled=false}},
        PvP = { ['Follow Attack'] = {url='about:blank', description='Demo - follow', author='demo', enabled=false}},
        Tibia = { ['Utana Vid'] = {url='about:blank', description='Demo - invis', author='demo', enabled=false}},
        Nto = { ['Bug Map Kunai'] = {url='about:blank', description='Demo - kunai', author='demo', enabled=false}},
        Utilities = { ['Dance'] = {url='about:blank', description='Demo - dance', author='demo', enabled=false}},
      }
    end

    if script_manager and script_manager._cache and next(script_manager._cache) then
      if loading and loading:getParent() then loading:destroy() end
      -- Abas
      script_bot.widget.macrosOptions:clearTabs()
      local cats = {}
      for cname,_ in pairs(script_manager._cache) do table.insert(cats, cname) end
      table.sort(cats)
      for _, cname in ipairs(cats) do
        local tab = script_bot.widget.macrosOptions:addTab(cname)
        tab:setId(cname); tab:setTooltip(cname..' Macros')
        tab.onStyleApply = function(w)
          if script_bot.widget.macrosOptions:getCurrentTab() == w then w:setColor('green') else w:setColor('white') end
        end
      end

      local rowLayout = [[
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

      local function populateList(cat)
        clearList()
        local data = script_manager._cache[cat] or {}
        for key, val in pairs(data) do
          local row = setupUI(rowLayout, script_bot.widget.scriptList)
          row:setId(key)
          row.textToSet:setText(key)
          row.textToSet:setColor(val.enabled and 'green' or '#bdbdbd')
          row:setTooltip(('Description: %s\nAuthor: %s'):format(val.description or '-', val.author or '-'))
          row.onClick = function()
            val.enabled = not val.enabled
            row.textToSet:setColor(val.enabled and 'green' or '#bdbdbd')
            if val.enabled and val.url and val.url ~= 'about:blank' then
              modules.corelib.HTTP.get(val.url, function(scr, err)
                if not scr then print('[CS] erro ao baixar macro', key, err or '') return end
                local ok2, res2 = pcall(loadstring(scr))
                if not ok2 then print('[CS] erro ao executar macro', key, res2) else print('[CS] macro OK', key) end
              end)
            end
          end
        end
      end

      local current = script_bot.widget.macrosOptions:getCurrentTab()
      if current then populateList(current.text) end
      script_bot.widget.macrosOptions.onTabChange = function(_, t)
        populateList(t:getText())
        local txt = script_bot.widget.searchBar:getText() or ''
        script_bot.widget.searchBar.onTextChange(nil, txt)
      end
    else
      if tries < 5 then
        scheduleEvent(populateOrRetry, 700)
      else
        if loading then loading:setText('Falha ao carregar lista. Veja console.'); loading:setColor('red') end
      end
    end
  end
  populateOrRetry()
end

local function fetchAndRun(name, url)
  print('[CS] Baixando '..name..': '..url)
  modules._G.HTTP.get(url, function(content, err)
    if not content then
      print('[CS] ERRO baixar '..name..': '..(err or '(sem detalhe)'))
      finishOne(); return
    end
    local ok, res = pcall(loadstring(content))
    if not ok then
      print('[CS] ERRO executar '..name..': '..tostring(res))
    else
      print('[CS] OK '..name)
    end
    finishOne()
  end)
end

fetchAndRun('Library.lua',     'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Library.lua')
fetchAndRun('script.list.lua', 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/script.list.lua')
