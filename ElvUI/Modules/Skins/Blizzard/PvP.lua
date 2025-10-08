local E, L, V, P, G = unpack(select(2, ...))
local S = E:GetModule("Skins")

local _G = _G
local CanQueueForWintergrasp = CanQueueForWintergrasp

local function MakeTextsWhite(frame)
	if not frame or not frame.GetRegions then return end
	local regs = { frame:GetRegions() }
	for i=1,#regs do
		local r = regs[i]
		if r and r.GetObjectType and r:GetObjectType()=="FontString" then
			r:SetTextColor(1,1,1)
		end
	end
end

S:AddCallback("Skin_PvP", function()
	if not (E.private and E.private.skins and E.private.skins.blizzard and E.private.skins.blizzard.enable and E.private.skins.blizzard.pvp) then return end

	if _G.PVPParentFrame then
		_G.PVPParentFrame:CreateBackdrop("Transparent")
		_G.PVPParentFrame.backdrop:Point("TOPLEFT", 11, -12)
		_G.PVPParentFrame.backdrop:Point("BOTTOMRIGHT", -32, 76)
		if S.SetUIPanelWindowInfo then S:SetUIPanelWindowInfo(_G.PVPParentFrame, "width") end
		if S.SetBackdropHitRect then
			S:SetBackdropHitRect(_G.PVPParentFrame)
			if _G.PVPFrame then S:SetBackdropHitRect(_G.PVPFrame, _G.PVPParentFrame.backdrop) end
			if _G.PVPBattlegroundFrame then S:SetBackdropHitRect(_G.PVPBattlegroundFrame, _G.PVPParentFrame.backdrop) end
		end
		if _G.PVPParentFrameCloseButton and S.HandleCloseButton then
			S:HandleCloseButton(_G.PVPParentFrameCloseButton, _G.PVPParentFrame.backdrop)
		end
		if _G.PVPParentFrameTab1 then S:HandleTab(_G.PVPParentFrameTab1) end
		if _G.PVPParentFrameTab2 then S:HandleTab(_G.PVPParentFrameTab2) end
	end

	if _G.PVPFrame then
		_G.PVPFrame:StripTextures(true)
		local MAX_ARENA_TEAMS = _G.MAX_ARENA_TEAMS or 0
		for i = 1, MAX_ARENA_TEAMS do
			local pvpTeam = _G["PVPTeam"..i]
			if pvpTeam then
				pvpTeam:StripTextures()
				pvpTeam:CreateBackdrop("Default")
				pvpTeam.backdrop:Point("TOPLEFT", 9, -4)
				pvpTeam.backdrop:Point("BOTTOMRIGHT", -24, 3)
				if S.SetBackdropHitRect then S:SetBackdropHitRect(pvpTeam) end
				pvpTeam:HookScript("OnEnter", S.SetModifiedBackdrop)
				pvpTeam:HookScript("OnLeave", S.SetOriginalBackdrop)
				local hl = _G["PVPTeam"..i.."Highlight"]; if hl then hl:Kill() end
			end
		end
		local det = _G.PVPTeamDetails
		if det then
			det:StripTextures()
			det:SetTemplate("Transparent")
			det:Point("TOPLEFT", _G.PVPFrame, "TOPRIGHT", -33, -81)
			if _G.PVPTeamDetailsCloseButton and S.HandleCloseButton then
				S:HandleCloseButton(_G.PVPTeamDetailsCloseButton, det)
			end
			for i = 1, 5 do local h=_G["PVPTeamDetailsFrameColumnHeader"..i]; if h then h:StripTextures() end end
			local MAX_ARENA_TEAM_MEMBERS = _G.MAX_ARENA_TEAM_MEMBERS or 0
			for i = 1, MAX_ARENA_TEAM_MEMBERS do
				local b=_G["PVPTeamDetailsButton"..i]; if b and S.HandleButtonHighlight then S:HandleButtonHighlight(b) end
			end
			if _G.PVPTeamDetailsAddTeamMember and S.HandleButton then
				S:HandleButton(_G.PVPTeamDetailsAddTeamMember)
				_G.PVPTeamDetailsAddTeamMember:ClearAllPoints()
				if _G.PVPTeamDetailsButton10 then
					_G.PVPTeamDetailsAddTeamMember:Point("TOPLEFT", _G.PVPTeamDetailsButton10, "BOTTOMLEFT", 5, -8)
				else
					_G.PVPTeamDetailsAddTeamMember:Point("BOTTOMLEFT", det, "BOTTOMLEFT", 10, 10)
				end
			end
			if _G.PVPTeamDetailsToggleButton and S.HandleNextPrevButton then
				S:HandleNextPrevButton(_G.PVPTeamDetailsToggleButton)
				_G.PVPTeamDetailsToggleButton:Point("BOTTOMRIGHT", -20, 25)
			end
		end
	end

	if _G.PVPBattlegroundFrame then
		_G.PVPBattlegroundFrame:StripTextures(true)
		if _G.PVPBattlegroundFrameTypeScrollFrame then
			_G.PVPBattlegroundFrameTypeScrollFrame:StripTextures()
			if S.HandleScrollBar and _G.PVPBattlegroundFrameTypeScrollFrameScrollBar then
				S:HandleScrollBar(_G.PVPBattlegroundFrameTypeScrollFrameScrollBar)
				_G.PVPBattlegroundFrameTypeScrollFrameScrollBar:Point("TOPLEFT", _G.PVPBattlegroundFrameTypeScrollFrame, "TOPRIGHT", 6, -19)
				_G.PVPBattlegroundFrameTypeScrollFrameScrollBar:Point("BOTTOMLEFT", _G.PVPBattlegroundFrameTypeScrollFrame, "BOTTOMRIGHT", 6, 19)
			end
		end
		if _G.PVPBattlegroundFrameInfoScrollFrame then
			_G.PVPBattlegroundFrameInfoScrollFrame:StripTextures()
			if S.HandleScrollBar and _G.PVPBattlegroundFrameInfoScrollFrameScrollBar then
				S:HandleScrollBar(_G.PVPBattlegroundFrameInfoScrollFrameScrollBar)
				_G.PVPBattlegroundFrameInfoScrollFrame:Point("BOTTOMLEFT", 19, 114)
				_G.PVPBattlegroundFrameInfoScrollFrameScrollBar:Point("TOPLEFT", _G.PVPBattlegroundFrameInfoScrollFrame, "TOPRIGHT", 7, -24)
				_G.PVPBattlegroundFrameInfoScrollFrameScrollBar:Point("BOTTOMLEFT", _G.PVPBattlegroundFrameInfoScrollFrame, "BOTTOMRIGHT", 7, 19)
			end
			local c = _G.PVPBattlegroundFrameInfoScrollFrameChildFrame
			if c and c.RewardsInfo and c.RewardsInfo.description then c.RewardsInfo.description:SetTextColor(1,1,1) end
			if c and c.Description then c.Description:SetTextColor(1,1,1) end
			if c then MakeTextsWhite(c) end
		end
		for i=1,5 do
			local b = _G["BattlegroundType"..i]
			if b and b.SetNormalFontObject then
				b:SetNormalFontObject(GameFontHighlightSmall)
				b:SetHighlightFontObject(GameFontNormalSmall)
			end
		end
		if _G.PVPBattlegroundFrameGroupJoinButton and S.HandleButton then S:HandleButton(_G.PVPBattlegroundFrameGroupJoinButton) end
		if _G.PVPBattlegroundFrameJoinButton and S.HandleButton then S:HandleButton(_G.PVPBattlegroundFrameJoinButton) end
		if _G.PVPBattlegroundFrameCancelButton and S.HandleButton then S:HandleButton(_G.PVPBattlegroundFrameCancelButton) end
		if _G.PVPBattlegroundFrameCancelButton and _G.PVPBattlegroundFrameJoinButton and _G.PVPBattlegroundFrameGroupJoinButton then
			_G.PVPBattlegroundFrameGroupJoinButton:Width(127)
			_G.PVPBattlegroundFrameCancelButton:Point("CENTER", _G.PVPBattlegroundFrame, "TOPLEFT", 300, -416)
			_G.PVPBattlegroundFrameJoinButton:Point("RIGHT", _G.PVPBattlegroundFrameCancelButton, "LEFT", -3, 0)
			_G.PVPBattlegroundFrameGroupJoinButton:Point("RIGHT", _G.PVPBattlegroundFrameJoinButton, "LEFT", -3, 0)
		end
		if _G.WintergraspTimer then
			_G.WintergraspTimer:Size(24)
			_G.WintergraspTimer:SetTemplate("Default")
			_G.WintergraspTimer:Point("RIGHT", _G.PVPBattlegroundFrame, "TOPRIGHT", -42, -58)
			if _G.WintergraspTimer.texture then
				_G.WintergraspTimer.texture:SetDrawLayer("ARTWORK")
				_G.WintergraspTimer.texture:SetInside()
				_G.WintergraspTimer:HookScript("OnUpdate", function(self)
					if CanQueueForWintergrasp() then
						self.texture:SetTexCoord(0.1875, 0.8125, 0.59375, 0.90575)
					else
						self.texture:SetTexCoord(0.1875, 0.8125, 0.09375, 0.40625)
					end
				end)
			end
		end
	end

	if type(_G.PVPBattlegroundFrame_UpdateInfo)=="function" then
		hooksecurefunc("PVPBattlegroundFrame_UpdateInfo", function()
			local c = _G.PVPBattlegroundFrameInfoScrollFrameChildFrame
			if c then MakeTextsWhite(c) end
		end)
	end

	if _G.BattlefieldFrame then
		_G.BattlefieldFrame:StripTextures(true)
		_G.BattlefieldFrame:CreateBackdrop("Transparent")
		_G.BattlefieldFrame.backdrop:Point("TOPLEFT", 11, -12)
		_G.BattlefieldFrame.backdrop:Point("BOTTOMRIGHT", -32, 76)
		if S.SetUIPanelWindowInfo then S:SetUIPanelWindowInfo(_G.BattlefieldFrame, "width") end
		if S.SetBackdropHitRect then S:SetBackdropHitRect(_G.BattlefieldFrame) end
		if _G.BattlefieldFrameCloseButton and S.HandleCloseButton then
			S:HandleCloseButton(_G.BattlefieldFrameCloseButton, _G.BattlefieldFrame.backdrop)
		end
		if _G.BattlefieldListScrollFrame then
			_G.BattlefieldListScrollFrame:StripTextures()
			if S.HandleScrollBar and _G.BattlefieldListScrollFrameScrollBar then
				S:HandleScrollBar(_G.BattlefieldListScrollFrameScrollBar)
				_G.BattlefieldListScrollFrameScrollBar:Point("TOPLEFT", _G.BattlefieldListScrollFrame, "TOPRIGHT", 9, -23)
				_G.BattlefieldListScrollFrameScrollBar:Point("BOTTOMLEFT", _G.BattlefieldListScrollFrame, "BOTTOMRIGHT", 9, 23)
			end
		end
		if _G.BattlefieldFrameInfoScrollFrame and S.HandleScrollBar and _G.BattlefieldFrameInfoScrollFrameScrollBar then
			S:HandleScrollBar(_G.BattlefieldFrameInfoScrollFrameScrollBar)
			_G.BattlefieldFrameInfoScrollFrame:Point("BOTTOMLEFT", 21, 113)
			_G.BattlefieldFrameInfoScrollFrameScrollBar:Point("TOPLEFT", _G.BattlefieldFrameInfoScrollFrame, "TOPRIGHT", 7, -20)
			_G.BattlefieldFrameInfoScrollFrameScrollBar:Point("BOTTOMLEFT", _G.BattlefieldFrameInfoScrollFrame, "BOTTOMRIGHT", 7, 19)
		end
		local ch = _G.BattlefieldFrameInfoScrollFrameChildFrame
		if ch then MakeTextsWhite(ch) end
		local zones = _G.BATTLEFIELD_ZONES_DISPLAYED or 0
		for i=1,zones do
			local b = _G["BattlefieldZone"..i]
			if b and b.SetNormalFontObject then
				b:SetNormalFontObject(GameFontHighlightSmall)
				b:SetHighlightFontObject(GameFontNormalSmall)
			end
		end
		if _G.BattlefieldFrameInfoScrollFrameChildFrameDescription then
			_G.BattlefieldFrameInfoScrollFrameChildFrameDescription:SetTextColor(1,1,1)
		end
		if _G.BattlefieldFrameInfoScrollFrameChildFrameRewardsInfoDescription then
			_G.BattlefieldFrameInfoScrollFrameChildFrameRewardsInfoDescription:SetTextColor(1,1,1)
		end
		if S.HandleButton then
			if _G.BattlefieldFrameGroupJoinButton then S:HandleButton(_G.BattlefieldFrameGroupJoinButton) end
			if _G.BattlefieldFrameJoinButton then S:HandleButton(_G.BattlefieldFrameJoinButton) end
			if _G.BattlefieldFrameCancelButton then S:HandleButton(_G.BattlefieldFrameCancelButton) end
		end
		for i = 1, zones do local b=_G["BattlefieldZone"..i]; if b and S.HandleButtonHighlight then S:HandleButtonHighlight(b) end end
		if _G.BattlefieldFrameNameHeader then _G.BattlefieldFrameNameHeader:Point("TOPLEFT", 73, -57) end
		if _G.BattlefieldZone1 then _G.BattlefieldZone1:Point("TOPLEFT", 25, -80) end
		if _G.BattlefieldFrameGroupJoinButton and _G.BattlefieldFrameJoinButton and _G.BattlefieldFrameCancelButton then
			_G.BattlefieldFrameGroupJoinButton:Width(127)
			_G.BattlefieldFrameGroupJoinButton:Point("RIGHT", _G.BattlefieldFrameJoinButton, "LEFT", -3, 0)
			_G.BattlefieldFrameJoinButton:Point("RIGHT", _G.BattlefieldFrameCancelButton, "LEFT", -3, 0)
			_G.BattlefieldFrameCancelButton:Point("CENTER", _G.BattlefieldFrame, "TOPLEFT", 302, -417)
		end
	end
	if _G.PVPBattlegroundFrameInfo then
  _G.PVPBattlegroundFrameInfo:HookScript("OnShow", function()
    local c = _G.PVPBattlegroundFrameInfoScrollFrameChildFrame
    if c then MakeTextsWhite(c) end
  end)
end
	if type(_G.PVPBattlegroundFrame_Update) == "function" then
  hooksecurefunc("PVPBattlegroundFrame_Update", function()
    local c = _G.PVPBattlegroundFrameInfoScrollFrameChildFrame
    if c then MakeTextsWhite(c) end
  end)
end

local function ForceWhite_BGInfo()
  local scroll = _G.PVPBattlegroundFrameInfoScrollFrame
  if not scroll then return end

  local child  = scroll.GetScrollChild and scroll:GetScrollChild() or _G.PVPBattlegroundFrameInfoScrollFrameChildFrame
  if not child then return end

  local desc = _G.PVPBattlegroundFrameInfoScrollFrameChildFrameDescription
  if desc then
    if desc.GetObjectType and desc:GetObjectType() == "SimpleHTML" then
      if desc.SetTextColor then
        pcall(desc.SetTextColor, desc, "p", 1, 1, 1)
        pcall(desc.SetTextColor, desc, "h1", 1, 0.82, 0) -- заголовок оставим золотым
        pcall(desc.SetTextColor, desc, "h2", 1, 1, 1)
        pcall(desc.SetTextColor, desc, "h3", 1, 1, 1)
      end
    elseif desc.SetTextColor then
      desc:SetTextColor(1, 1, 1)
      if desc.SetShadowColor then desc:SetShadowColor(0,0,0,0.8) end
    end
  end

  local rewardsInfo = _G.PVPBattlegroundFrameInfoScrollFrameChildFrameRewardsInfo
  if rewardsInfo then
    for i = 1, rewardsInfo:GetNumRegions() do
      local r = select(i, rewardsInfo:GetRegions())
      if r and r.GetObjectType and r:GetObjectType() == "FontString" then
        r:SetTextColor(1, 1, 1)
        if r.SetShadowColor then r:SetShadowColor(0,0,0,0.8) end
      end
    end
  end

  for i = 1, child:GetNumRegions() do
    local r = select(i, child:GetRegions())
    if r and r.GetObjectType and r:GetObjectType() == "FontString" then
      r:SetTextColor(1, 1, 1)
      if r.SetShadowColor then r:SetShadowColor(0,0,0,0.8) end
    end
  end
end

if _G.PVPBattlegroundFrameInfo then
  _G.PVPBattlegroundFrameInfo:HookScript("OnShow", ForceWhite_BGInfo)
end
if _G.PVPBattlegroundFrameInfoScrollFrame and _G.PVPBattlegroundFrameInfoScrollFrame.ScrollBar then
  _G.PVPBattlegroundFrameInfoScrollFrame.ScrollBar:HookScript("OnValueChanged", ForceWhite_BGInfo)
end
if type(_G.PVPBattlegroundFrame_Update) == "function" then
  hooksecurefunc("PVPBattlegroundFrame_Update", ForceWhite_BGInfo)
end
if type(_G.PVPBattlegroundFrameSelection_Update) == "function" then
  hooksecurefunc("PVPBattlegroundFrameSelection_Update", ForceWhite_BGInfo)
end

ForceWhite_BGInfo()


end)
