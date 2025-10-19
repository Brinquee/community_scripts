script_bot = {}

-- ===========================================================
-- 🔧 Inicialização
-- ===========================================================
setDefaultTab("Main")
storage.community_scripts_data = storage.community_scripts_data or {}

actualVersion = 0.4

local libraryList = {
    "https://raw.githubusercontent.com/Brinquee/community_scripts/main/Library.lua",
    "https://raw.githubusercontent.com/Brinquee/community_scripts/main/script.list.lua"
}

-- ===========================================================
-- 📦 Carregamento das bibliotecas remotas
-- ===========================================================
for _, url in ipairs(libraryList) do
    modules.corelib.HTTP.get(url, function(content, err)
        if not content then
            print("[Community Scripts] Falha ao baixar:", url, err or "erro desconhecido")
            return
        end
        local ok, res = pcall(loadstring(content))
        if not ok then
            print("[Community Scripts] Erro executando:", url, res)
        else
            print("[Community Scripts] Carregado com sucesso:", url)
        end
    end)
end

-- ===========================================================
-- 🔁 Inicialização retardada (garante _cache)
-- ===========================================================
local function ensureCache()
    if not script_manager then
        print("[Community Scripts] Aguardando script_manager...")
        return scheduleEvent(ensureCache, 500)
    end

    if not script_manager._cache or next(script_manager._cache) == nil then
        print("[Community Scripts] Cache ainda vazio, recarregando lista...")
        if script_manager.loadList then
            pcall(script_manager.loadList)
        end
        return scheduleEvent(ensureCache, 1000)
    end

    print("[Community Scripts] Lista carregada, inicializando painel...")
    script_bot.initUI()
end
scheduleEvent(ensureCache, 1000)

-- ===========================================================
-- 🪟 Interface visual
-- ===========================================================
function script_bot.initUI()
    if script_bot.widget then
        script_bot.widget:destroy()
    end

    local ui = setupUI([[
MainWindow
  !text: tr('Community Scripts')
  size: 300 400
  color: #d2cac5
  background-color: #201a15

  TabBar
    id: tabs
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    width: 180

  ScrollablePanel
    id: list
    anchors.top: tabs.bottom
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    layout:
      type: verticalBox
    vertical-scrollbar: scroll

  VerticalScrollBar
    id: scroll
    anchors.top: list.top
    anchors.bottom: list.bottom
    anchors.right: list.right
]], g_ui.getRootWidget())

    script_bot.widget = ui
    ui:setText("Community Scripts - " .. actualVersion)
    ui:hide()

    -- Botão no painel principal
    if not script_bot.button then
        script_bot.button = UI.Button("Community Scripts", function()
            ui:setVisible(not ui:isVisible())
            if ui:isVisible() then
                script_bot.loadTabs()
            end
        end)
        script_bot.button:setColor("#d2cac5")
    end

    script_bot.loadTabs()
end

-- ===========================================================
-- 🗂️ Carregar abas e scripts
-- ===========================================================
function script_bot.loadTabs()
    local tabs = script_bot.widget.tabs
    local list = script_bot.widget.list
    list:destroyChildren()
    tabs:clearTabs()

    for category, scripts in pairs(script_manager._cache or {}) do
        local tab = tabs:addTab(category)
        tab:setTooltip("Scripts da categoria " .. category)

        for name, data in pairs(scripts) do
            local btn = UI.Button(name, function()
                data.enabled = not data.enabled
                if data.enabled then
                    loadRemoteScript(data.url)
                    btn:setColor("green")
                    print("[Community Scripts] Ativado:", name)
                else
                    btn:setColor("#bdbdbd")
                    print("[Community Scripts] Desativado:", name)
                end
            end, list)
            btn:setColor(data.enabled and "green" or "#bdbdbd")
        end
    end

    print("[Community Scripts] Abas e scripts carregados!")
end
