local urlScript = 'https://raw.githubusercontent.com/Brinquee/scripts-mobile/main/community_scripts.lua';
modules.corelib.HTTP.get(urlScript, function(script) 
    assert(loadstring(script))() 
end);
 
