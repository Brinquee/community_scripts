-- ===========================================================
-- Utilities - Dance (revisado para Community Scripts)
-- - Independente de 'tabName' (usa aba Main)
-- - Controle de velocidade via slider (se Library.lua tiver addScrollBar)
-- - Sem spam; usa relógio interno
-- ===========================================================

local NAME       = "Dance"
local TICK_MS    = 50               -- frequência do macro
local DEFAULT_MS = 200              -- intervalo padrão entre giros

-- Destino seguro sem depender de variáveis externas
local DEST_TAB = getTab("Main") or setDefaultTab("Main")

-- Estado salvo
storage.scrollBarValues = storage.scrollBarValues or {}
storage.scrollBarValues.dance_interval = storage.scrollBarValues.dance_interval or DEFAULT_MS

-- Slider de velocidade (se existir na Library)
if type(addScrollBar) == "function" then
  -- id, título, min, max, default, dest, tooltip
  addScrollBar("dance_interval", "Intervalo (ms)", 50, 1000, storage.scrollBarValues.dance_interval,
               DEST_TAB, "Tempo entre giros (quanto menor, mais rápido).")
else
  -- Fallback simples: avisa o valor atual sem slider
  local lbl = UI.Label(string.format("Dance interval: %d ms", storage.scrollBarValues.dance_interval), DEST_TAB)
  lbl:setTooltip("Sem slider: Library.lua não carregada.")
end

-- Relógio (ms); funciona mesmo se 'now' global não existir
local function NOW()
  if type(now) == "number" then return now end
  return math.floor((os.clock() or 0) * 1000)
end

-- Macro principal
local lastTurn = 0
macro(TICK_MS, NAME, function()
  if not g_game or not player then return end
  local gap = storage.scrollBarValues.dance_interval or DEFAULT_MS
  local t = NOW()
  if t - lastTurn >= gap then
    turn(math.random(0, 3))
    lastTurn = t
  end
end, DEST_TAB)

-- Separador visual, se existir
pcall(function() if UI and UI.Separator then UI.Separator(DEST_TAB) end end)
