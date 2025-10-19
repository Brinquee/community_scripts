-- ===========================================================
-- 📜 script.list.lua — Lista de scripts disponíveis
-- Compatível com Community_scripts.lua v0.4 FIX
-- ===========================================================

script_manager = script_manager or {}
script_manager._cache = script_manager._cache or {}

-- ===========================================================
-- 🗂️ Estrutura de categorias
-- ===========================================================
script_manager._cache = {
    ["DBO"] = {
        ["Reflect"] = {
            url = "https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Dbo/Reflect.lua",
            author = "Brinquee",
            description = "Ativa reflexão de dano automaticamente.",
            enabled = false
        }
    },

    ["Healing"] = {
        ["Regeneration"] = {
            url = "https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Healing/Regeneration.lua",
            author = "Brinquee",
            description = "Cura automática gradual enquanto em combate.",
            enabled = false
        }
    },

    ["NTO"] = {
        ["Bug Map Kunai"] = {
            url = "https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Nto/Bug_map_kunai.lua",
            author = "Brinquee",
            description = "Script para escapar usando Kunai no NTO.",
            enabled = false
        }
    },

    ["PvP"] = {
        ["Follow Attack"] = {
            url = "https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/PvP/follow_attack.lua",
            author = "Brinquee",
            description = "Segue e ataca o inimigo automaticamente.",
            enabled = false
        }
    },

    ["Tibia"] = {
        ["Utana Vid"] = {
            url = "https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Tibia/utana_vid.lua",
            author = "Brinquee",
            description = "Mantém invisibilidade ativa enquanto em movimento.",
            enabled = false
        }
    },

    ["Utilities"] = {
        ["Dance"] = {
            url = "https://raw.githubusercontent.com/Brinquee/community_scripts/main/Scripts/Utilities/dance.lua",
            author = "Brinquee",
            description = "Faz o personagem dançar em loop.",
            enabled = false
        }
    }
}

-- ===========================================================
-- ⚙️ Função de atualização manual
-- ===========================================================
function script_manager.loadList()
    print("[Community Scripts] Lista recarregada manualmente.")
    return script_manager._cache
end

print("[script.list.lua] Lista de scripts carregada com sucesso.")
