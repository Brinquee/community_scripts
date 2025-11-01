-- ===========================================================
-- BRINQUE - OTC - CUSTOM  (painel compacto + sem scheduleEvent)
-- ===========================================================

script_bot = {}                               -- tabela raiz para evitar poluir o global

-- --- Config -------------------------------------------------
local TAB_ID = 'Main'                         -- aba do vBot onde o botão principal será criado
local actualVersion = 0.2                     -- versão só para exibir no título/log
local RAW = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/scripts-brinque'
                                              -- raiz do seu repo (aponta para /scripts-brinque)
local LOAD_ACTIVE_ON_START = true             -- se true, recarrega scripts que já estavam ON no boot

-- --- Setup aba ---------------------------------------------
setDefaultTab(TAB_ID)                         -- garante que estamos na aba desejada
local tabName = getTab(TAB_ID) or setDefaultTab(TAB_ID)
                                              -- referência da aba (usada ao criar o botão principal)

-- --- Storage ------------------------------------------------
storage.cs_enabled  = storage.cs_enabled  or {}  -- mapa: [categoria][nome] = true/false
storage.cs_last_tab = storage.cs_last_tab or nil -- lembra a última aba selecionada

-- --- Utils --------------------------------------------------
local function logStatus(msg)                 -- helper para logar e refletir no statusLabel do painel
  print('[BRINQUE CUSTOM]', msg)
  if script_bot.widget and script_bot.widget.statusLabel then
    script_bot.widget.statusLabel:setText(msg)
  end
end

loadedUrls = loadedUrls or {}                 -- cache por URL (evita carregar a mesma duas vezes)
local function safeLoadUrl(url)               -- baixa e executa um script remoto com proteção
  if loadedUrls[url] then                     -- se já carregado nesta sessão, não repete
    logStatus('Ja carregado: ' .. url)
    return
  end
  modules.corelib.HTTP.get(url, function(content, err)    -- baixa via HTTP do OTClient
    if not content then
      logStatus('Erro ao baixar: ' .. (err or 'sem resposta'))
      return
    end
    local ok, res = pcall(loadstring(content))            -- executa com pcall para não quebrar tudo
    if not ok then
      logStatus('Erro ao executar: ' .. tostring(res))
    else
      loadedUrls[url] = true
      logStatus('Script carregado com sucesso.')
    end
  end)
end

local function isEnabled(cat, name)           -- consulta estado ON/OFF de um item
  return storage.cs_enabled[cat] and storage.cs_enabled[cat][name] == true
end
local function setEnabled(cat, name, value)   -- seta estado ON/OFF de um item
  storage.cs_enabled[cat] = storage.cs_enabled[cat] or {}
  storage.cs_enabled[cat][name] = value and true or false
end

-- ===========================================================
-- LISTA LOCAL (você pode editar/expandir à vontade)
-- ===========================================================
script_manager = {
  actualVersion = actualVersion,              -- só informativo
  _cache = {                                  -- categorias -> itens (nome/URL/descrição/autor)
    HEALING = {
      ['HEAL ID BIJUU+'] = {
        url = RAW .. '/HEALING/heal-id-bijuu-plus.lua',
        description = 'Heal com histerese + listas Normal/Especial.',
        author = 'Brinquee',
      },
      ['EDIT POTION'] = {
        url = RAW .. '/HEALING/edit-potion.lua',
        description = 'Auto-uso de potions por percentuais (3 sets).',
        author = 'Brinquee',
      },
    },

    SUPPORT = {
      ['BUFFS CENTER'] = {
        url = RAW .. '/SUPPORT/buffs-center.lua',
        description = 'Recast por duracao, editor de lista.',
        author = 'Brinquee',
      },
      ['FUGA CENTER'] = {
        url = RAW .. '/SUPPORT/escape-center.lua',
        description = 'Fuga por HP%, editor de lista.',
        author = 'Brinquee',
      },
      ['TIMERS CENTER'] = {
        url = RAW .. '/SUPPORT/timers-center.lua',
        description = 'Timers on-screen com fundo translucido e editor.',
        author = 'Brinquee',
      },
      ['TRAVEL NPC'] = {
        url = RAW .. '/SUPPORT/travel-npc.lua',
        description = 'Janela de viagem (hi/city/yes).',
        author = 'Brinquee',
      },
    },

    COMBOS = {
      ['CENTRAL DE COMBOS'] = {
        url = RAW .. '/COMBOS/combos-main.lua',
        description = 'Painel + editor de combos (execucao sequencial).',
        author = 'Brinquee',
      },
    },

    ESPECIALS = {                             -- placeholders (deixe vazio ou adicione quando tiver)
    },
    TEAMS = {
    },
    ICONS = {
    },
  }
}

-- ===========================================================
-- UI (template da linha da lista e janela principal)
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
-- itemRow: define um widget clicável (cada linha de script), com rótulo centralizado.

script_bot.widget = setupUI([[
MainWindow
  !text: tr('BRINQUE - OTC - CUSTOM')    # título da janela
  font: terminus-14px-bold
  color: #05fff5                          # cor do texto do título
  size: 350 450                           # dimensões do painel

  TabBar                                  # barra de abas (categorias)
    id: macrosOptions
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    width: 180

  ScrollablePanel                         # container da lista (scroll vertical)
    id: scriptList
    layout:
      type: verticalBox
    anchors.fill: parent
    margin-top: 45
    margin-left: 2
    margin-right: 15
    margin-bottom: 52
    vertical-scrollbar: scriptListScrollBar

  VerticalScrollBar                       # barra de rolagem vertical (ligada ao scriptList)
    id: scriptListScrollBar
    anchors.top: scriptList.top
    anchors.bottom: scriptList.bottom
    anchors.right: scriptList.right
    step: 14
    pixels-scroll: true
    margin-right: -10

  Label                                   # label de status (mensagens do logStatus)
    id: statusLabel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-bottom: 28
    text-align: center
    font: terminus-14px
    color: yellow

  TextEdit                                # caixa de busca (filtra por nome)
    id: searchBar
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    margin-right: 5
    width: 90

  Button                                  # botão Recarregar (re-baixa ON)
    id: refreshButton
    !text: tr('Recarregar')
    font: cipsoftFont
    anchors.left: searchBar.right
    anchors.bottom: parent.bottom
    size: 84 22
    margin-bottom: 1
    margin-left: 5

  Button                                  # botão All ON/OFF (liga/desliga todos da aba atual)
    id: toggleAllButton
    !text: tr('All ON/OFF')
    font: cipsoftFont
    anchors.left: refreshButton.right
    anchors.bottom: parent.bottom
    size: 80 20
    margin-bottom: 1
    margin-left: 5

  Button                                  # botão Fechar (esconde e dá reload limpo)
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

script_bot.widget:hide()                       -- inicia oculto
script_bot.widget:setText('BRINQUE - OTC - CUSTOM') -- reforça texto do título (opcional)
script_bot.widget.statusLabel:setText('Pronto.')    -- status inicial
pcall(function() script_bot.widget:move(10, 10) end) -- posiciona canto sup. esquerdo (seguro no pcall)

-- Botão principal no painel (aba TAB_ID)
script_bot.buttonWidget = UI.Button('BRINQUE CUSTOM', function()   -- cria botão e define callback
  if script_bot.widget:isVisible() then       -- se já está visível...
    reload()                                  -- ...faz um reload limpo do script
  else
    script_bot.widget:show()                  -- mostra a janela
    local last = storage.cs_last_tab          -- tenta restaurar a aba usada por último
    if last then
      -- busca por texto/id da aba com segurança (sem quebrar se não existir)
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
script_bot.buttonWidget:setColor('#11ffecff')     -- cor do botão principal (neon ciano)

-- Fechar (reload + hide)
script_bot.widget.closeButton:setTooltip('Fechar e recarregar.')
script_bot.widget.closeButton.onClick = function()
  reload()
  script_bot.widget:hide()
end

-- Busca (filtra linhas em tempo real, sem scheduleEvent)
script_bot.widget.searchBar:setTooltip('Buscar...')
script_bot.widget.searchBar.onTextChange = function(_, text)
  script_bot.filterScripts(text)
end

-- === Lista / filtro ========================================
function script_bot.filterScripts(filterText)    -- esconde/mostra linhas pelo nome (id do row)
  local q = (filterText or ''):lower()
  for _, child in pairs(script_bot.widget.scriptList:getChildren()) do
    local scriptName = child:getId() or ''
    child:setVisible(scriptName:lower():find(q, 1, true) ~= nil)
  end
end

function script_bot.updateScriptList(tabText)    -- reconstrói a lista com base na aba atual
  script_bot.widget.scriptList:destroyChildren()
  local list = script_manager._cache[tabText]
  if not list then return end

  for name, data in pairs(list) do
    local row = setupUI(itemRow, script_bot.widget.scriptList)   -- cria linha
    row:setId(name)                                              -- usamos o nome como id (para filtro)
    row.textToSet:setText(name)                                  -- exibe o nome
    row.textToSet:setColor(isEnabled(tabText, name) and 'green' or '#bdbdbd')
    row:setTooltip(('Description: %s\nAuthor: %s\n(Click = ON/OFF | Right-click = abrir URL)')
      :format(data.description or '-', data.author or '-'))

    -- Click esquerdo: ON/OFF + (se ligar) carrega a URL remota
    row.onClick = function()
      local newState = not isEnabled(tabText, name)
      setEnabled(tabText, name, newState)
      row.textToSet:setColor(newState and 'green' or '#bdbdbd')
      if newState and data.url then
        safeLoadUrl(data.url)
      end
    end

    -- Click direito: abre a URL no navegador (se plataforma suportar)
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

-- Toggle All (liga/desliga todos os itens da aba atual)
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
  local turnOn = onCount < allCount          -- se maioria OFF, liga tudo; se não, desliga tudo

  for name, data in pairs(list) do
    setEnabled(cat, name, turnOn)
    if turnOn and data.url then
      safeLoadUrl(data.url)
    end
  end
  script_bot.updateScriptList(cat)           -- reflete estados na UI
end

-- Recarregar (só os que estão ON): limpa cache e baixa/executa novamente
script_bot.widget.refreshButton.onClick = function()
  for cat, list in pairs(script_manager._cache) do
    for name, data in pairs(list) do
      if isEnabled(cat, name) and data.url then
        loadedUrls[data.url] = nil           -- libera no cache para poder recarregar
      end
    end
  end

  local loaded = 0
  for cat, list in pairs(script_manager._cache) do
    for name, data in pairs(list) do
      if isEnabled(cat, name) and data.url then
        loaded = loaded + 1
        safeLoadUrl(data.url)                -- baixa/executa novamente
      end
    end
  end
  logStatus('Recarregado(s): ' .. loaded)
end

-- Monta as abas (uma para cada categoria)
do
  local cats = {}
  for cat in pairs(script_manager._cache) do table.insert(cats, cat) end
  table.sort(cats)                           -- mantém ordem previsível

  for _, cat in ipairs(cats) do
    local tab = script_bot.widget.macrosOptions:addTab(cat)
    tab:setId(cat)
    tab:setTooltip(cat .. ' macros')
    tab.onStyleApply = function(widget)      -- cor da aba ativa x inativa
      if script_bot.widget.macrosOptions:getCurrentTab() == widget then
        widget:setColor('#05fff5')
      else
        widget:setColor('red')
      end
    end
  end

  local startTab = storage.cs_last_tab or cats[1]     -- escolhe a aba inicial
  for _, w in ipairs(script_bot.widget.macrosOptions:getChildren()) do
    if w.getText and w:getText() == startTab then
      script_bot.widget.macrosOptions:selectTab(w)
      break
    end
  end

  local cur = script_bot.widget.macrosOptions:getCurrentTab()
  if cur and cur.getText then
    script_bot.updateScriptList(cur:getText())        -- popula a lista da aba inicial
  end

  -- troca de aba: persiste escolha, reconstrói lista e reaplica filtro
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

-- Carrega automaticamente os que estavam ON (boot suave)
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
