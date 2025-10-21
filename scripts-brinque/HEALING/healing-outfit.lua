macro(200, "HEAL ID BIJUU", function()
if hppercent() >99 then return end
if outfit().type == 162 then -- 340
    say("Bijuu regeneration")
else
    say("big regeneration")
 end
end)
