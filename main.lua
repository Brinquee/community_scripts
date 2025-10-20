-- Bootstrap do Community Scripts (carrega tudo do seu repo)
-- Salve como: mano.lua (ou main.lua) e execute.

local urls = {
  -- 1) caminho principal
  'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Community_scripts.lua',
  -- 2) fallback (refs/heads)
  'https://raw.githubusercontent.com/Brinquee/community_scripts/refs/heads/main/Community_scripts.lua',
}

local function carregarDaUrl(i)
  local url = urls[i]
  if not url then
    print('[CS Loader] Falha: não consegui baixar Community_scripts.lua de nenhuma URL.')
    return
  end

  print('[CS Loader] Baixando: ' .. url)
  modules.corelib.HTTP.get(url, function(content, err)
    if content and #content > 0 then
      local ok, res = pcall(loadstring(content))
      if not ok then
        print('[CS Loader] Erro executando Community_scripts.lua:', res)
      else
        print('[CS Loader] Community_scripts.lua carregado com sucesso!')
      end
    else
      print('[CS Loader] Erro no download (' .. tostring(err or 'sem conteúdo') .. '). Tentando próxima URL...')
      carregarDaUrl(i + 1)
    end
  end)
end

carregarDaUrl(1)
