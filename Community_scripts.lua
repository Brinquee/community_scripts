-- ===================================================================
-- Community Scripts (OTCv8 Mobile) - Adaptado
-- - Sem ragnarokBot.path / sem JSON em disco
-- - Usa storage (persistente) para estado
-- - Painel madeira, flutuante, central-top, não arrastável
-- - Baixa e executa scripts SEMPRE online (fresh)
-- ===================================================================

local VERSION = "0.4-mobile"
local LIST_URL = "https://raw.githubusercontent.com/Brinquee/scripts-mobile/main/script_list.lua"

-- ---------- Utilidades seguras ----------
local function safeHttpGet(url, onOk, onErr)
  local ok, err = pcall(function()
    modules.corelib.HTTP.get(url, function(code, httpErr)
      if httpErr or not code or code == "" then
        if onErr then onErr(httpErr or "empty") end
        return
      end
      if onOk then onOk(code) end
    end)
  end)
  if not ok and onErr then onErr(err or "pcall http error") end
end

local function safeLoadAndRun(chunk, label)
  local ok, fn = pcall(loadstring, chunk)
  if not ok or not fn then
    print(string.format("[ScriptMgr] erro ao compilar %s: %s", label or "chunk", fn or ok))
    return false
  end
  local ok2, runErr = pcall(fn)
  if not ok2 then
    print(string.format("[ScriptMgr] erro executando %s: %s", label or "chunk", runErr))
    return false
  end
  return true
end

-- ---------- Estado (sem arquivos) ----------
storage.script_bot_data = storage.script_bot_data or { _cache = {}, actualVersion = VERSION }
local script_manager = storage.script_bot_data  -- sempre referência

local function saveState()
  storage.script_bot_data = script_manager
end

-- ---------- UI: botão no painel do Bot ----------
setDefaultTab("Main")
local TAB = getTab("Main") or setDefaultTab("Main")

local btnOpen = nil
local win = nil

-- Centraliza no topo (não arrastável)
local function centerTop(widget)
  local root = g_ui.getRootWidget()
  if not root then return end
  local x = math.floor((root:getWidth() - widget:getWidth())/2)
  widget:move({x = x, y = 18})
end

-- ---------- UI: janela principal (madeira) ----------
local function buildWindow()
  if win and not win:isDestroyed() then win:destroy() end

  win = setupUI([[
MainWindow
  id: scriptManagerWin
  !text: tr('SCRIPT MANAGER')
  size: 320 360
  color: #d2cac5
  background-color: #3a2d1e
  opacity: 0.96
  padding: 8
  draggable: false
  moveable: false
  focusable: true

  TabBar
    id: tabs
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 22

  ScrollablePanel
    id: list
    anchors.top: tabs.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    layout:
      type: verticalBox
    vertical-scrollbar: vbar
    margin-top: 6
    margin-left: 2
    margin-right: 12
    margin-bottom: 6

  VerticalScrollBar
    id: vbar
    anchors.top: list.top
    anchors.bottom: list.bottom
    anchors.right: list.right
    step: 16
    pixels-scroll: true
    margin-right: -8
  ]], g_ui.getRootWidget())

  centerTop(win)
  win:hide()
end

-- Item de lista (linha clicável)
local ROW_UI = [[
UIWidget
  background-color: alpha
  height: 28
  focusable: true
  $focus:
    background-color: #00000055

  Label
    id: name
    font: terminus-14px-bold
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 6

  Label
    id: state
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    margin-right: 6
    text: 'off'
]]

-- ---------- Lógica: carregar lista remota ----------
local function rebuildTabsAndList()
  if not win or win:isDestroyed() then return end
  local tabs = win.tabs
  local list = win.list
  tabs:clear()
  list:destroyChildren()

  -- cria abas por categoria
  local firstTab = nil
  for category, _ in pairs(script_manager._cache or {}) do
    local tab = tabs:addTab(category)
    if not firstTab then firstTab = category end
    tab.onStyleApply = function(w)
      if tabs:getCurrentTab() == w then w:setColor("green") else w:setColor("white") end
    end
  end

  local function fill(cat)
    list:destroyChildren()
    local catTable = (script_manager._cache or {})[cat]
    if not catTable then return end

    for scriptName, meta in pairs(catTable) do
      local row = setupUI(ROW_UI, list)
      row.name:setText(scriptName)
      row.state:setText(meta.enabled and "on" or "off")
      row.state:setColor(meta.enabled and "green" or "#bdbdbd")
      row:setTooltip((meta.description or "") .. "\nAutor: " .. (meta.author or "n/d"))

      row.onClick = function()
        -- alterna estado e executa SEMPRE fresh online
        meta.enabled = not meta.enabled
        row.state:setText(meta.enabled and "on" or "off")
        row.state:setColor(meta.enabled and "green" or "#bdbdbd")
        saveState()

        if meta.enabled and meta.url and meta.url ~= "" then
          safeHttpGet(meta.url,
            function(code)
              safeLoadAndRun(code, scriptName)
            end,
            function(err)
              print("[ScriptMgr] falha ao baixar '" .. scriptName .. "': " .. tostring(err))
            end
          )
        end
      end
    end
  end

  if firstTab then
    tabs.onTabChange = function(_, tabWidget) fill(tabWidget:getText()) end
    tabs:select(firstTab)
    fill(firstTab)
  end
end

local function downloadListAndBuild()
  safeHttpGet(
    LIST_URL,
    function(code)
      -- Executa a lista: ela define 'script_manager' global? Garantimos que apontará pro nosso.
      -- Para evitar sobrescrever o nosso, isolamos:
      local before = _G.script_manager
      local ok = safeLoadAndRun(code, "script_list.lua")
      if ok and type(_G.script_manager) == "table" and _G.script_manager._cache then
        -- copia cache da lista remota
        script_manager._cache = _G.script_manager._cache
        script_manager.actualVersion = _G.script_manager.actualVersion or VERSION
        saveState()
      else
        print("[ScriptMgr] lista remota não retornou cache válido.")
      end
      -- restaura global anterior pra não sujar ambiente
      _G.script_manager = before

      rebuildTabsAndList()
    end,
    function(err)
      print("[ScriptMgr] erro baixando lista: " .. tostring(err))
      rebuildTabsAndList() -- ainda constrói UI vazia
    end
  )
end

-- ---------- Montagem ----------
buildWindow()

if btnOpen and not btnOpen:isDestroyed() then btnOpen:destroy() end
btnOpen = UI.Button("Script Manager", function()
  if win:isVisible() then
    win:hide()
  else
    centerTop(win)
    win:show()
    win:raise()
    win:focus()
  end
end, TAB)
btnOpen:setColor("#d2cac5")

-- baixa/atualiza a lista e constrói UI
downloadListAndBuild()

print(string.format("[ScriptMgr] carregado (v%s).", VERSION))
