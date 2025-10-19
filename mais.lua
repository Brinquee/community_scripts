local urlScript = 'https://raw.githubusercontent.com/brinquee/Community_Scripts/main/community_scripts.lua';
modules.corelib.HTTP.get(urlScript, function(script) 
    assert(loadstring(script))() 
end);
