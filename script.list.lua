-- ===============================
-- script.list.lua  (carrega a lista de macros do seu repositório)
-- ===============================

script_manager = script_manager or {}

script_manager.actualVersion = 0.4

script_manager._cache = {
  Dbo = {
    ['Reflect'] = {
      url = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Dbo/Reflect.lua',
      description = 'Macro de Reflect (DBO).',
      author = 'Brinquee',
      enabled = false
    },
  },

  Healing = {
    ['Regeneration'] = {
      url = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Healing/Regeneration.lua',
      description = 'Casta a spell de regeneration abaixo da % configurada.',
      author = 'Brinquee',
      enabled = false
    },
  },

  Nto = {
    ['Bug Map Kunai'] = {
      url = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Nto/Bug_map_kunai.lua',
      description = 'Bug map com kunai (NTO).',
      author = 'Brinquee',
      enabled = false
    },
  },

  PvP = {
    ['Follow Attack'] = {
      url = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/PvP/follow_attack.lua',
      description = 'Protótipo de follow attack (abre portas/jumps etc.).',
      author = 'Victor Neox / Brinquee',
      enabled = false
    },
  },

  Tibia = {
    ['Utana Vid'] = {
      url = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Tibia/utana_vid.lua',
      description = 'Casta Utana Vid com mana mínima configurada.',
      author = 'VivoDibra / Brinquee',
      enabled = false
    },
  },

  Utilities = {
    ['Dance'] = {
      url = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Utilities/dance.lua',
      description = 'Gira aleatoriamente (macro de teste).',
      author = 'Brinquee',
      enabled = false
    },
  },
}

-- Log de depuração: conta quantas categorias e itens existem
local catCount, itemCount = 0, 0
for _, cat in pairs(script_manager._cache) do
  catCount = catCount + 1
  for _ in pairs(cat) do itemCount = itemCount + 1 end
end
print(string.format('[script.list.lua] OK - categorias: %d, itens: %d', catCount, itemCount))
