local urlScript = 'https://raw.githubusercontent.com/brinquee/Community-Scripts/main/community_scripts.lua';
modules.corelib.HTTP.get(urlScript, function(script) 
    assert(loadstring(script))() 
end);
