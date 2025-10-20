script_manager = script_manager or {}
script_manager._cache = {
  ["DBO"] = {
    ["Reflect"] = {
      url = "https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Dbo/Reflect.lua",
      author = "Brinquee",
      description = "Reflete dano automaticamente.",
      enabled = false
    }
  },
  ["NTO"] = {
    ["Bug Map Kunai"] = {
      url = "https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Nto/Bug_map_kunai.lua",
      author = "Brinquee",
      description = "Escape com kunai no NTO.",
      enabled = false
    }
  },
  ["PvP"] = {
    ["Follow Attack"] = {
      url = "https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/PvP/follow_attack.lua",
      author = "Brinquee",
      description = "Segue e ataca o alvo.",
      enabled = false
    }
  },
  ["Tibia"] = {
    ["Utana Vid"] = {
      url = "https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Tibia/utana_vid.lua",
      author = "Brinquee",
      description = "Mantém invisibilidade.",
      enabled = false
    }
  },
  ["Healing"] = {
    ["Regeneration"] = {
      url = "https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Healing/Regeneration.lua",
      author = "Brinquee",
      description = "Cura gradual automática.",
      enabled = false
    }
  },
  ["Utilities"] = {
    ["Dance"] = {
      url = "https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Utilities/dance.lua",
      author = "Brinquee",
      description = "Dança em loop.",
      enabled = false
    }
  }
}

function script_manager.loadList()
  print("[script.list.lua] Lista recarregada.")
  return script_manager._cache
end

print("[script.list.lua] Lista de scripts carregada com sucesso.")
