-- script.list.lua  (mínimo viável)
script_manager = script_manager or {}
script_manager.actualVersion = 0.4

script_manager._cache = {

  Dbo = {
    ['Reflect'] = {
      url = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Dbo/Reflect.lua',
      description = 'Script de reflect.',
      author = 'brinquee',
      enabled = false
    },
  },

  Nto = {
    ['Bug Map Kunai'] = {
      url = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Nto/Bug_map_kunai.lua',
      description = 'Bug map kunai (PC).',
      author = 'brinquee',
      enabled = false
    },
  },

  Tibia = {
    ['Utana Vid'] = {
      url = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Tibia/utana_vid.lua',
      description = 'Script de utana vid.',
      author = 'brinquee',
      enabled = false
    },
  },

  PvP = {
    ['Follow Attack'] = {
      url = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/PvP/follow_attack.lua',
      description = 'Seguir e atacar o target (protótipo).',
      author = 'victorneox / brinquee',
      enabled = false
    },
  },

  Healing = {
    ['Regeneration'] = {
      url = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Healing/Regeneration.lua',
      description = 'Usa spell de regen por % de vida.',
      author = 'brinquee',
      enabled = false
    },
  },

  Utilities = {
    ['Dance'] = {
      url = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Utilities/dance.lua',
      description = 'Fica dançando (gira aleatório).',
      author = 'brinquee',
      enabled = false
    },
  },

}
print('[script.list.lua] cache carregado: categorias =', (script_manager and script_manager._cache) and 'OK' or 'NIL')
