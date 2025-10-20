-- script.list.lua
script_manager = script_manager or {}
script_manager.actualVersion = 0.4

script_manager._cache = {
  Dbo = {
    ['Reflect'] = {
      url = 'https://raw.githubusercontent.com/Brinquee/community_scripts/Scripts/Dbo/Reflect.lua',
      description = 'Macro de Reflect (DBO).',
      author = 'Brinquee',
      enabled = false
    },
  },
  Healing = {
    ['Regeneration'] = {
      url = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Healing/Regeneration.lua',
      description = 'Casta regeneration abaixo da % configurada.',
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
      description = 'Protótipo follow attack.',
      author = 'Victor Neox / Brinquee',
      enabled = false
    },
  },
  Tibia = {
    ['Utana Vid'] = {
      url = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Tibia/utana_vid.lua',
      description = 'Casta Utana Vid com mana mínima.',
      author = 'VivoDibra / Brinquee',
      enabled = false
    },
  },
  Utilities = {
    ['Dance'] = {
      url = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Utilities/dance.lua',
      description = 'Gira aleatoriamente (teste).',
      author = 'Brinquee',
      enabled = false
    },
  },
}

local cats, items = 0, 0
for _, c in pairs(script_manager._cache) do
  cats = cats + 1
  for _ in pairs(c) do items = items + 1 end
end
print(string.format('[script.list.lua] OK - categorias: %d, itens: %d', cats, items))
