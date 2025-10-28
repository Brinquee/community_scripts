-- ===========================================================
-- COMBOS - <SEU NOME DE MACRO AQUI> (modelo padrao)
-- Seguro p/ recarregar, sem depender de 'tabName'
-- ===========================================================

-- once-flag: impede inicializacao dupla no mesmo reload
local LOADED_KEY = "__combos_<slug>_loaded__"
if _G[LOADED_KEY] then return end
_G[LOADED_KEY] = true

-- aba de destino segura
local DEST_TAB = getTab("Main") or setDefaultTab("Main")

-- helpers opcionais (fallbacks no-ops, caso precise de UI extra)
if not addScrollBar then
  function addScrollBar(...) end
end
if not addItem then
  function addItem(...) end
end
if not addSwitchBar then
  function addSwitchBar(...) end
end
if not addCheckBox then
  function addCheckBox(...) end
end

-- =======================
-- Config padrao do combo
-- =======================
local COMBO_NAME  = "<SEU NOME>"
local COMBO_DELAY = 100  -- ms

-- Exemplo: sequencia de spells com delay entre elas
-- Edite livremente conforme o combo
local cfg = {
  enabled      = true,         -- se quiser ler isso de storage, ok
  minManaPerc  = 0,            -- filtro opcional
  sayDelayMs   = 180,          -- delay entre 'say's
  spells       = {             -- ordem do combo
    -- "spell 1",
    -- "spell 2",
    -- "spell 3",
  }
}

-- anti-spam simples p/ 'say'
local function sayWithDelay(list, delayMs)
  local t = 0
  for _, s in ipairs(list) do
    schedule(t, function() say(s) end)
    t = t + (delayMs or 150)
  end
end

-- se ja existir macro/objeto anterior, apaga/para (idempotencia adicional)
if _G.__BRINQUE_COMBOS == nil then _G.__BRINQUE_COMBOS = {} end
local REG_KEY = "<slug>"     -- mude para um identificador unico

if _G.__BRINQUE_COMBOS[REG_KEY] and _G.__BRINQUE_COMBOS[REG_KEY].macro then
  -- desliga o anterior se existir (metodo setOn(false) funciona na maioria dos builds)
  pcall(function() _G.__BRINQUE_COMBOS[REG_KEY].macro:setOn(false) end)
end

-- ==================
-- Macro principal
-- ==================
local comboMacro = macro(COMBO_DELAY, COMBO_NAME, function()
  if not cfg.enabled then return end
  if manapercent() < (cfg.minManaPerc or 0) then return end
  if not g_game or not g_game.isOnline or not g_game:isOnline() then return end

  -- >>> SUA LOGICA AQUI <<<
  -- Exemplo: dispara a sequencia uma vez quando clicar uma hotkey,
  -- ou quando detectar alguma condicao (target, hp do alvo, etc.)
  -- Abaixo só um exemplo didático:
  if isKeyPressed("F8") then
    sayWithDelay(cfg.spells, cfg.sayDelayMs)
  end
end, DEST_TAB)

-- guarda referencia p/ evitar duplicatas em reload
_G.__BRINQUE_COMBOS[REG_KEY] = { macro = comboMacro, cfg = cfg }
