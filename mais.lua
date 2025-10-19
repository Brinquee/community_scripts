local urlScript = 'https://raw.githubusercontent.com/Brinquee/community_scripts/main/Community_scripts.lua';
modules.corelib.HTTP.get(urlScript, function(script) 
    assert(loadstring(script))() 
end);
 
 
