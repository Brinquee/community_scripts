-- ===========================================================
-- DBO - Reflect (revisado para Community Scripts)
-- - Independente de 'tabName'
-- - Proteções de nil / timing
-- ===========================================================

local MACRO_NAME   = "Reflect"
local MACRO_DELAY  = 100         -- ms
local REFLECT_SAY  = "reflect"   -- spell/comando
local CD_SECONDS   = 2           -- cooldown após falar

-- NÃO ALTERE ABAIXO ------------------------------------------

-- garante uma aba de destino sem depender de variáveis externas
local DEST_TAB = getTab("Main") or setDefaultTab("Main")

-- util: primeiro número encontrado no texto
local function firstNumberIn(text)
  local s = text and tostring(text) or ""
  local n = s:match("%d+")
  return n and tonumber(n) or nil
end

local hasReflect   = true
local lastHitCheck = 0           -- debounce para texto de dano
local state        = { cdUntil = 0, resetAt = 0 }

-- macro principal
local reflectMacro = macro(MACRO_DELAY, MACRO_NAME, function()
  -- evita rodar antes do player existir (fase de login)
  if not g_game or not player or not player.getName then return end

  -- se não temos reflect ativo e cooldown terminou, fala o spell
  if not hasReflect and os.time() >= (state.cdUntil or 0) then
    say(REFLECT_SAY)
  end
end, DEST_TAB)

-- detecta dano recebido no texto para “armar” um novo reflect
-- exemplo: "You lose 4821 hitpoints ..."
onTextMessage(function(mode, text)
  if reflectMacro.isOff() then return end
  if not text then return end

  local lower = text:lower()
  if not lower:find("you lose") then return end

  -- evita múltiplos disparos no mesmo segundo
  local now = os.time()
  if now == lastHitCheck then return end
  lastHitCheck = now

  local dmg = firstNumberIn(text)
  if dmg and dmg > 50 then
    hasReflect = false
    state.resetAt = now + 1 -- pequena janela para reagir
  end
end)

-- confirma o cast do reflect pelo próprio jogador (feedback via onTalk)
onTalk(function(name, level, mode, text, channelId, pos)
  if reflectMacro.isOff() then return end
  if not name or not text then return end
  if name ~= player:getName() then return end

  if text:lower() == REFLECT_SAY:lower() then
    hasReflect   = true
    state.cdUntil = os.time() + CD_SECONDS
  end
end)
