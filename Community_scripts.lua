-- ===========================================================
-- Community Scripts - Diagnóstico mínimo do painel
-- Objetivo: garantir que o clique abre um MainWindow simples.
-- Depois a gente volta a plugar Library/Lista e o painel completo.
-- ===========================================================

-- Aba onde o botão vai aparecer
setDefaultTab('Main')
local ROOT_TAB = getTab('Main') or setDefaultTab('Main')

-- Estado local
script_bot = script_bot or {}
storage.scriptManager = storage.scriptManager or { pos=nil, visible=false }

-- Logs curtinhos
local function ok(...)  print('[CS][OK]', ...) end
local function err(...) print('[CS][ERRO]', ...) end
local function log(...) print('[CS]', ...) end

----------------------------------------------------------------
-- 1) Constrói um painel ULTRA SIMPLES (só para comprovar abertura)
----------------------------------------------------------------
local function build_min_panel()
  -- destrói se já existir
  if script_bot.widget and not script_bot.widget:isDestroyed() then
    pcall(function() script_bot.widget:destroy() end)
  end

  local ui = [[
MainWindow
  id: scriptManagerWin
  text: Script Manager
  size: 260 160
  color: #d2cac5
  background-color: #3a2d1e
  opacity: 0.98
  focusable: true
  padding: 6

  Label
    id: title
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    margin-top: 8
    text: Painel simples aberto!

  Button
    id: closeBtn
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    size: 60 22
    text: Close
]]

  -- cria com pcall pra capturar qualquer erro de UI
  local okSetup, wOrMsg = pcall(function()
    return setupUI(ui, g_ui.getRootWidget())
  end)

  if not okSetup then
    err('setupUI falhou:', wOrMsg)
    return nil
  end

  local w = wOrMsg
  if not w then
    err('setupUI retornou nil (sem janela).')
    return nil
  end

  script_bot.widget = w

  -- centraliza (fallback se não tiver centerInParent)
  addEvent(function()
    if w.centerInParent then
      pcall(function() w:centerInParent() end)
    else
      local root = g_ui.getRootWidget()
      local x = (root:getWidth() - w:getWidth())/2
      local y = (root:getHeight() - w:getHeight())/2
      w:move({x=x, y=y})
    end
  end)

  -- restaura posição se existir
  if storage.scriptManager.pos then
    pcall(function() w:move(storage.scriptManager.pos) end)
  end

  -- salvar posição ao mover (se for possível)
  local oldMove = w.move
  w.move = function(self, pos)
    if oldMove then oldMove(self, pos) end
    storage.scriptManager.pos = pos
  end

  -- close
  if w.closeBtn then
    w.closeBtn.onClick = function()
      w:hide()
      storage.scriptManager.visible = false
      ok('Painel fechado pelo botão Close.')
    end
  end

  ok('Painel mínimo criado.')
  return w
end

----------------------------------------------------------------
-- 2) Abre (ou cria) o painel mínimo e mostra logs
----------------------------------------------------------------
local function open_min_panel()
  log('Abrindo painel mínimo...')
  if script_bot.widget and not script_bot.widget:isDestroyed() then
    script_bot.widget:show()
    addEvent(function()
      if script_bot.widget.centerInParent then
        pcall(function() script_bot.widget:centerInParent() end)
      end
    end)
    storage.scriptManager.visible = true
    ok('Painel existente mostrado.')
    return
  end

  local w = build_min_panel()
  if not w then
    err('Falha ao construir o painel mínimo.')
    return
  end

  w:show()
  storage.scriptManager.visible = true
  ok('Painel mínimo visível.')
end

----------------------------------------------------------------
-- 3) Cria o botão imediatamente e garante onClick funcional
----------------------------------------------------------------
local function create_button()
  -- recria se já existir
  if script_bot.button and not script_bot.button:isDestroyed() then
    pcall(function() script_bot.button:destroy() end)
  end

  script_bot.button = UI.Button('Script Manager', function()
    -- toggle simples: se está visível, esconde; senão abre
    if script_bot.widget and not script_bot.widget:isDestroyed() and script_bot.widget:isVisible() then
      script_bot.widget:hide()
      storage.scriptManager.visible = false
      ok('Painel ocultado (toggle).')
    else
      open_min_panel()
    end
  end, ROOT_TAB)

  ok('Botão criado na aba Main.')
end

----------------------------------------------------------------
-- 4) Inicializa quando a UI estiver pronta
----------------------------------------------------------------
local function init_when_ready()
  if not g_ui or not g_ui.getRootWidget() then
    scheduleEvent(init_when_ready, 150); return
  end

  create_button()

  -- restaura visibilidade se estava aberto antes
  if storage.scriptManager.visible then
    open_min_panel()
  end

  ok('Diagnóstico pronto. Clique no botão para abrir o painel.')
end

init_when_ready()
