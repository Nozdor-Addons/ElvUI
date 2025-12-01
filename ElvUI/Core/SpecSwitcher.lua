local function SpecSwitcher_SetSpec(index)
    local msg = string.format("%d|%d", 8, index)
    RequestServerAction(msg)
end

SLASH_SPECSWITCH1 = "/spec"

SlashCmdList["SPECSWITCH"] = function(msg)
    local n = tonumber(msg)
    if not n then
        return
    end

    local idx = n - 1

    if idx < 0 or idx > 8 then
        return
    end

    SpecSwitcher_SetSpec(idx)
end
--[[
SLASH_RESETTALENTS1 = "/treset"
SLASH_RESETTALENTS2 = "/resettalents"

SlashCmdList["RESETTALENTS"] = function(msg)
    SpecSwitcher_ResetTalents()
end

local function TalentTest_Run()
    for i = 1, 1 do
        RequestServerAction("9|411:0")
    end
end

-- /ttest
SLASH_TALENTTEST1 = "/ttest"

SlashCmdList["TALENTTEST"] = function(msg)
    TalentTest_Run()
end
--]]