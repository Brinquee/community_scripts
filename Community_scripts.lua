-- === URLs (use 'main', sem refs/heads) ===
local libraryList = {
  'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Library.lua',
  'https://raw.githubusercontent.com/Brinquee/community_scripts/main/script.list.lua'
}

-- Mostra “carregando...” na lista
local loadingLabel = UI.Label('Carregando lista de scripts...')
loadingLabel:setColor('yellow')
if script_bot and script_bot.widget then
  script_bot.widget.scriptList:addChild(loadingLabel)
end

-- Baixa cada lib com log de erro/ok
local pending = #libraryList
for _, url in ipairs(libraryList) do
  print('[CS Loader] Baixando: ' .. url)
  modules._G.HTTP.get(url, function(content, err)
    if not content then
      print('[CS Loader] ERRO ao baixar:', url, err or '(sem detalhe)')
    else
      local ok, res = pcall(loadstring(content))
      if not ok then
        print('[CS Loader] ERRO ao executar:', url, res)
      else
        print('[CS Loader] OK:', url)
      end
    end
    pending = pending - 1
    -- quando terminar todos, dispara verificação do _cache_
    if pending == 0 then
      scheduleEvent(function()
        local has = (script_manager and script_manager._cache and next(script_manager._cache))
        print('[CS Loader] cache pronto?', has and 'SIM' or 'NÃO')
        if has and script_bot and script_bot.onLoading then
          -- remove o “carregando...” e popula
          if loadingLabel and loadingLabel:getParent() then loadingLabel:destroy() end
          script_bot.onLoading()
        else
          -- tenta mais algumas vezes se ainda não chegou
          local tentativas = 0
          local function retry()
            tentativas = tentativas + 1
            local ready = (script_manager and script_manager._cache and next(script_manager._cache))
            print(string.format('[CS Loader] tentativa %d, cache pronto? %s', tentativas, ready and 'SIM' or 'NÃO'))
            if ready then
              if loadingLabel and loadingLabel:getParent() then loadingLabel:destroy() end
              script_bot.onLoading()
            elseif tentativas < 5 then
              scheduleEvent(retry, 600)
            else
              -- mantém uma mensagem de falha visível
              if loadingLabel then
                loadingLabel:setText('Falha ao carregar lista. Verifique URLs e nomes (maiúsc./minúsc.).')
                loadingLabel:setColor('red')
              end
            end
          end
          scheduleEvent(retry, 600)
        end
      end, 300)
    end
  end)
end
