
-- Initialize script_manager with script cache
script_manager = {
    actualVersion = 0.4,
    _cache = {

        Dbo = {

            ['Reflect'] = {
                url = 'https://raw.githubusercontent.com/Brinquee/community_scripts/refs/heads/main/Scripts/Dbo/Reflect.lua',
                description = 'Script de reflect.',
                author = 'brinquee',
                enabled = false
            },
        },

        Nto = {
            ['Bug Map Kunai'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Nto/bug_map_kunai.lua',
                description = 'Script de bug map kunai para pc.',
                author = 'brinquee',
                enabled = false
            },
            ['Bug Map Kunai Mobile'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Nto/bug_map_mobile_kunai.lua',
                description = 'Script de bug map kunai para mobile.',
                author = 'brinquee',
                enabled = false
            },
            ['Stack'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Nto/stack.lua',
                description = 'Script de stack, vai soltar a spell no monstro mais distante da tela.',
                author = 'brinquee',
                enabled = false
            },

        },
        Tibia = {

            ['Auto Mount'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Tibia/auto_mount.lua',
                description = 'Script de montagem automatica.',
                author = 'brinquee',
                enabled = false
            },
            ['Cast Food'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Tibia/cast_food.lua',
                description = 'Script de castar/usar a food.',
                author = 'brinquee',
                enabled = false
            },
            ['E Ring'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Tibia/e_ring.lua',
                description = 'Script de e-ring.',
                author = 'brinquee',
                enabled = false
            },
            ['Exeta Res'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Tibia/exeta_res.lua',
                description = 'Script de exeta res.',
                author = 'brinquee',
                enabled = false
            },
            ['MW Timer'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Tibia/mwall_timer.lua',
                description = 'Script de timer de MW.',
                author = 'brinquee',
                enabled = false
            },
            ['Safe UE/SD'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Tibia/safe_ue_sd.lua',
                description = 'Script de safe UE/SD.',
                author = 'brinquee',
                enabled = false
            },
            ['Share Exp'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Tibia/share_exp.lua',
                description = 'Script de safe UE/SD.',
                author = 'brinquee',
                enabled = false
            },
            ['Utana Vid'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Tibia/utana_vid.lua',
                description = 'Script de utana vid.',
                author = 'brinquee',
                enabled = false
            },
            ['Utura'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Tibia/utura.lua',
                description = 'Script de utura.',
                author = 'brinquee',
                enabled = false
            },

        },

        PvP = {
            ['Attack Target'] = {
                url = 'https://raw.githubusercontent.com/brinquee/OTCV8/main/ATTACK-TARGET.lua',
                description = 'Script de manter o target mesmo se ele sair da tela.',
                author = 'brinquee',
                enabled = false
            },
            ['Change Weapon'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/PvP/change_weapons.lua',
                description = 'Script trocar a arma baseado na distancia do target.',
                author = 'brinquee',
                enabled = false
            },
            ['Follow Attack'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/PvP/follow_attack.lua',
                description = 'Script de follow attack, seguir o target.',
                author = 'brinquee',
                enabled = false
            },
            ['Enemy'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/PvP/enemy.lua',
                description = 'Script enemy, atacar o inimigo com menos hp na tela.',
                author = 'brinquee',
                enabled = false
            },
            ['Pvp Mode Icon'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/PvP/pvp_mode_icon.lua',
                description = 'Script alterar o modo da maozinha(pvp).',
                author = 'brinquee',
                enabled = false
            },
            ['Chase Mode Icon'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/PvP/chase_icon.lua',
                description = 'Script alterar o modo do chase.',
                author = 'brinquee',
                enabled = false
            },
            ['Sense Target'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/PvP/sense_target.lua',
                description = 'Script de dar sense no target.',
                author = 'brinquee',
                enabled = false
            },
            ['Anti Push'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/PvP/anti_push.lua',
                description = 'Script de anti push.',
                author = 'brinquee',
                enabled = false
            },
            ['MW Frente Target'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/PvP/mwall_target.lua',
                description = 'Script de soltar MW na frente do target.',
                author = 'brinquee',
                enabled = false
            },
        },

        Healing = {
            ['Heal Friend'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Healing/heal_friend.lua',
                description = 'Script curar os amigos/party.',
                author = 'brinquee',
                enabled = false
            },
            ['Potion'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Healing/potion.lua',
                description = 'Script de potion HP/MP.',
                author = 'brinquee',
                enabled = false
            },
            ['Regeneration'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Healing/regeneration.lua',
                description = 'Script de regeneration.',
                author = 'brinquee',
                enabled = false
            },
        },

        Utilities = {
            ['Bug Map'] = {
                url = 'https://raw.githubusercontent.com/brinquee/OTCV8/main/BUG-MAP.lua',
                description = 'Script de Bug Map PC.',
                author = 'brinquee',
                enabled = false
            },
            ['Sense'] = {
                url = 'https://raw.githubusercontent.com/brinquee/OTCV8/main/xNameSense.lua',
                description = 'Script de sense, escreva "xNICK" para dar sense no nick e x0 para limpar o sense.',
                author = 'brinquee',
                enabled = false
            },
            ['Auto Party'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/auto_party.lua',
                description = 'Script de auto party.',
                author = 'brinquee',
                enabled = false
            },
            ['Buff'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/buff.lua',
                description = 'Script de buff pela mensagem laranja.',
                author = 'brinquee',
                enabled = false
            },
            ['Bug Map Mobile'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/bug_map_mobile.lua',
                description = 'Script de bug map mobile.',
                author = 'brinquee',
                enabled = false
            },
            ['Cave/Target Bot Icon'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/cavebot_targetbot_icon.lua',
                description = 'Script de icone de targetbot e cavebot.',
                author = 'brinquee',
                enabled = false
            },
            ['Change Gold'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/change_gold.lua',
                description = 'Script de change gold.',
                author = 'brinquee',
                enabled = false
            },
            ['Combo + Combo Interrupt'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/combo_interrumpt.lua',
                description = 'Script de Combo+Combo Interrupt.',
                author = 'brinquee.',
                enabled = false
            },
            ['Creature HealthPercent'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/creature_hppercent.lua',
                description = 'Script de mostrar a % de todos as creatures na tela.',
                author = 'brinquee.',
                enabled = false
            },
            ['Death Counter'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/death_counter.lua',
                description = 'Script de contagem de morte.',
                author = 'brinquee',
                enabled = false
            },
            ['Follow Player'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/follow_player.lua',
                description = 'Script de follow player.',
                author = 'brinquee',
                enabled = false
            },
            ['Hide Effects'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/hide_effects.lua',
                description = 'Script de esconder os efeitos.',
                author = 'brinquee',
                enabled = false
            },
            ['Hide Texts'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/hide_texts.lua',
                description = 'Script de esconder os textos.',
                author = 'brinquee',
                enabled = false
            },
            ['Kill Count'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/kill_count.lua',
                description = 'Script que conta os monstros que voce matou.',
                author = 'brinquee',
                enabled = false
            },
            ['Last Exiva'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/last_exiva.lua',
                description = 'Script de last sense/exiva.',
                author = 'brinquee',
                enabled = false
            },
            ['Loot Channel'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/loot_channel.lua',
                description = 'Script de canal exclusivo para loots.',
                author = 'brinquee',
                enabled = false
            },
            ['MW Cursor'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/mw_cursor.lua',
                description = 'Script de soltar MW onde o cursor do mouse esta.',
                author = 'brinquee',
                enabled = false
            },
            ['Shield Defense'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/mystic_defense.lua',
                description = 'Script de shield defense.',
                author = 'brinquee',
                enabled = false
            },
            ['Open Main BP'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/open_main_bp.lua',
                description = 'Script de abrir a bp principal.',
                author = 'brinquee',
                enabled = false
            },
            ['Trade Message'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/send_message_trade.lua',
                description = 'Script de mandar msg no trade.',
                author = 'brinquee',
                enabled = false
            },
            ['Speed'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/speed.lua',
                description = 'Script de speed.',
                author = 'brinquee',
                enabled = false
            },
            ['Spy Level'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/spy_level.lua',
                description = 'Script de mostrar o andar de cima(=)/baixo(-)',
                author = 'brinquee',
                enabled = false
            },
            ['Storage Cave/Target Bot'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/storage_cavebot.lua',
                description = 'Script que ira separar o cavebot/targetbot atual de cada personagem.',
                author = 'brinquee',
                enabled = false
            },
            ['Time Spell'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/time_spell.lua',
                description = 'Script de Time Spell.',
                author = 'brinquee',
                enabled = false
            },

            ['Turn Target'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/turn.lua',
                description = 'Script virar o personagem para onde o target se encontra.',
                author = 'brinquee',
                enabled = false
            },
            ['Use Nearby Door'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/use_nearby_door.lua',
                description = 'Script de usar a porta mais proxima(5 sqm).',
                author = 'brinquee',
                enabled = false
            },
            ['Use Nearby Door'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/widget_train.lua',
                description = 'Script de mostrar as porcentagens de treino.',
                author = 'brinquee',
                enabled = false
            },
            ['Stamina'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/stamina.lua',
                description = 'Script de usar stamina.',
                author = 'Asking',
                enabled = false
            },
            ['Script Manager'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/script_manager.lua',
                description = 'Script de script manager, podendo adicionar icones e arquivos otuis de uma maneira mais simples.',
                author = 'brinquee',
                enabled = false
            },
            ['Alarm'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/alarm.lua',
                description = 'Script de alarm.',
                author = 'brinquee',
                enabled = false
            },
            ['Dance'] = {
                url = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/Scripts/Utilities/dance.lua',
                description = 'Script de dance.',
                author = 'brinquee',
                enabled = false
            },

        },

    },
};
