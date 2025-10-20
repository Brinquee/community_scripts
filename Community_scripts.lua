-- ===================================================================
-- 🧩 Community_scripts.lua - Brinquee (v0.4 PATCH)
-- ===================================================================

script_bot = {}

-- === Inicialização sem ragnarok/json ===
local tabName = getTab('Main') or setDefaultTab('Main')
local actualVersion = 0.4

-- guarda interna (sem arquivo .json)
storage.community_scripts_data = storage.community_scripts_data or {}

-- funções compatíveis com o resto do código
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

-- === Bibliotecas remotas: seu repositório ===
local libraryList = {
  'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Library.lua',
  'https://raw.githubusercontent.com/Brinquee/community_scripts/main/script.list.lua'
}

-- === Carregar bibliotecas (Library.lua + script.list.lua) ===
for _, url in ipairs(libraryList) do
  modules.corelib.HTTP.get(url, function(content, err)
    if not content then
      print("[Community Scripts] Falha ao baixar:", url, err or "erro")
      return
    end
    local ok, res = pcall(loadstring(content))
    if not ok then
      print("[Community Scripts] Erro executando:", url, res)
    else
      print("[Community Scripts] Carregado:", url)
    end
  end)
end

-- === UI: layout de cada item da lista ===
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

-- === Criar janela principal (oculta inicialmente) ===
local function createPanelIfNeeded()
  if script_bot.widget then return end

  script_bot.widget = setupUI([[
MainWindow
  id: communityPanel
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

  -- botão fechar
  script_bot.widget.closeButton:setTooltip('Close and add macros.')
  script_bot.widget.closeButton.onClick = function()
    reload()
    script_bot.widget:hide()
  end

  -- busca
  script_bot.widget.searchBar:setTooltip('Search macros.')
  script_bot.widget.searchBar.onTextChange = function(_, text)
    script_bot.filterScripts(text)
  end

  print("[Script Manager] Painel carregado com sucesso!")
end

-- === Filtro de busca ===
function script_bot.filterScripts(filterText)
  for _, child in pairs(script_bot.widget.scriptList:getChildren()) do
    local scriptName = child:getId() or ""
    if scriptName:lower():find((filterText or ""):lower()) then
      child:show()
    else
      child:hide()
    end
  end
end

-- === Preencher lista da aba selecionada ===
function script_bot.updateScriptList(categoryName)
  local ui = script_bot.widget
  if not ui or not script_manager or not script_manager._cache then return end

  ui.scriptList:destroyChildren()
  local macrosCategory = script_manager._cache[categoryName]
  if not macrosCategory then return end

  for key, value in pairs(macrosCategory) do
    local row = setupUI(script_add, ui.scriptList)
    row.textToSet:setText(key)
    row.textToSet:setColor(value.enabled and 'green' or '#bdbdbd')
    row:setTooltip('Description: ' .. (value.description or 'N/A') .. '\nAuthor: ' .. (value.author or 'N/A'))
    row:setId(key)

    row.onClick = function()
      value.enabled = not value.enabled
      script_bot.saveScripts()
      row.textToSet:setColor(value.enabled and 'green' or '#bdbdbd')

      if value.enabled then
        -- carrega o script remoto ao ativar
        if loadRemoteScript then
          loadRemoteScript(value.url)
        else
          modules.corelib.HTTP.get(value.url, function(script)
            if script then pcall(loadstring(script)) end
          end)
        end
      end
    end
  end
end

-- === Montar as abas a partir do _cache ===
function script_bot.onLoading()
  local ui = script_bot.widget
  if not ui or not script_manager or not script_manager._cache then return end

  ui.scriptList:destroyChildren()
  ui.macrosOptions:clearTabs()

  local categories = {}
  for categoryName, categoryList in pairs(script_manager._cache) do
    table.insert(categories, categoryName)
    -- carrega scripts já marcados como enabled
    for _, value in pairs(categoryList) do
      if value.enabled and value.url then
        modules.corelib.HTTP.get(value.url, function(script)
          if script then pcall(loadstring(script)) end
        end)
      end
    end
  end

  -- cria abas
  for _, categoryName in ipairs(categories) do
    local tab = ui.macrosOptions:addTab(categoryName)
    tab:setId(categoryName)
    tab:setTooltip(categoryName .. " Macros")
    tab.onStyleApply = function(widget)
      if ui.macrosOptions:getCurrentTab() == widget then
        widget:setColor('green')
      else
        widget:setColor('white')
      end
    end
  end

  -- seleção inicial e callback
  local currentTab = ui.macrosOptions:getCurrentTab()
  if currentTab and currentTab.text then
    script_bot.updateScriptList(currentTab.text)
  end

  ui.macrosOptions.onTabChange = function(_, tab)
    script_bot.updateScriptList(tab:getText())
    script_bot.filterScripts(ui.searchBar:getText())
  end
end

-- === Botões "Script Manager" e "Update Files" fixos na aba Main ===
local function ensureTopButtons()
  if not script_bot.buttonWidget then
    script_bot.buttonWidget = UI.Button('Script Manager', function()
      if not script_bot.widget then return end
      local vis = script_bot.widget:isVisible()
      script_bot.widget:setVisible(not vis)
      if not vis then
        script_bot.onLoading()
      end
    end, tabName)
    script_bot.buttonWidget:setColor('#d2cac5')
  end

  if not script_bot.buttonRemoveJson then
    script_bot.buttonRemoveJson = UI.Button('Update Files', function()
      script_bot.restartStorage()
    end, tabName)
    script_bot.buttonRemoveJson:setColor('#d2cac5')
    script_bot.buttonRemoveJson:setTooltip('Click here only when there is an update.')
    script_bot.buttonRemoveJson:hide()
  end
end

-- === Espera a lista (_cache) ficar pronta antes de montar UI ===
local function waitForScripts()
  if not script_manager or not script_manager._cache or next(script_manager._cache) == nil then
    print("[Community Scripts] Aguardando lista de scripts carregar...")
    return scheduleEvent(waitForScripts, 1000)
  end

  createPanelIfNeeded()
  ensureTopButtons()
  script_bot.readScripts()
  script_bot.onLoading()

  -- aviso de versão
  if script_manager.actualVersion and script_manager.actualVersion ~= actualVersion then
    if script_bot.buttonRemoveJson then script_bot.buttonRemoveJson:show() end
  end

  print("[Community Scripts] Lista carregada. UI pronta.")
end

scheduleEvent(waitForScripts, 1000)

-- ==== DEBUG opcional (pode deixar) ====
print("---- DEBUG INÍCIO ----")
print("Tem script_manager:", script_manager ~= nil)
print("Tem cache:", script_manager and script_manager._cache ~= nil)
if script_manager and script_manager._cache then
  print("Categorias encontradas:")
  for k in pairs(script_manager._cache) do
    print("  -", k)
  end
else
  print("Nenhum _cache ainda (script.list.lua pode não ter carregado).")
end
print("---- DEBUG FIM ----")
