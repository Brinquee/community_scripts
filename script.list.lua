script_manager = script_manager or {}
script_manager.actualVersion = 0.4

script_manager._cache = {
  ["DBO"] = {
    ["Reflect"] = {
      url = "https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Dbo/Reflect.lua",
      description = "Ativa reflexão de dano automaticamente.",
      author = "Brinquee",
      enabled = false
    },
  },

  ["Healing"] = {
    ["Regeneration"] = {
      url = "https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Healing/Regeneration.lua",
      description = "Cura quando a vida cair abaixo da % definida.",
      author = "Brinquee",
      enabled = false
    },
  },

  ["Tibia"] = {
    ["Utana Vid"] = {
      url = "https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Tibia/utana_vid.lua",
      description = "Mantém invisibilidade ativa com mana mínima.",
      author = "Brinquee (adapt.)",
      enabled = false
    },
  },

  ["Utilities"] = {
    ["Dance"] = {
      url = "https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Utilities/dance.lua",
      description = "Gira aleatoriamente em intervalos configuráveis.",
      author = "Brinquee (adapt.)",
      enabled = false
    },
  },

  ["NTO"] = {
    ["Bug Map Kunai"] = {
      url = "https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Nto/bug_map_kunai.lua",
      description = "Bug map via kunai com atalhos WASD/QEZX.",
      author = "Brinquee (adapt.)",
      enabled = false
    },
  },

  ["PvP"] = {
    ["Follow Attack"] = {
      url = "https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/PvP/follow_attack.lua",
      description = "Segue o alvo e executa portas/escadas/jumps/custom IDs.",
      author = "Brinquee (base: Victor Neox)",
      enabled = false
    },
  }
}
