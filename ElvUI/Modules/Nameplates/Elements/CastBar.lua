
local E, L, V, P, G = unpack(select(2, ...)); 
local NP = E:GetModule("NamePlates")
local LSM = E.Libs.LSM

local unpack = unpack
local abs = math.abs
local CreateFrame = CreateFrame
local GetTime = GetTime
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local GetSpellInfo = GetSpellInfo
local bit_band = bit.band
local HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE

function NP:UpdateElement_CastBarOnShow()
	local parent = self:GetParent()
	local unitFrame = parent.UnitFrame
	if not unitFrame.UnitType then
		return
	end

	if NP.db.units[unitFrame.UnitType].castbar.enable ~= true then return end
	if not unitFrame.Health:IsShown() and not NP.db.units[unitFrame.UnitType].castbar.showWhenHPHidden  then return end

	if unitFrame.CastBar then
		unitFrame.CastBar:Show()
		NP:StyleFilterUpdate(unitFrame, "FAKE_Casting")
	end
end

function NP:UpdateElement_CastBarOnHide()
	local parent = self:GetParent()
	local cb = parent.UnitFrame.CastBar
	if cb then
		if not cb.fake then
			cb:Hide()
			NP:StyleFilterUpdate(parent.UnitFrame, "FAKE_Casting")
		end
	end
end

function NP:UpdateElement_CastBarOnValueChanged(value)
	local frame = self:GetParent()
	local min, max = self:GetMinMaxValues()
	local unitFrame = frame.UnitFrame
	local isChannel = value < unitFrame.CastBar:GetValue()

	unitFrame.CastBar.value = value
	unitFrame.CastBar.max = max
	unitFrame.CastBar:SetMinMaxValues(min, max)
	unitFrame.CastBar:SetValue(value)

	if isChannel then
		if unitFrame.CastBar.channelTimeFormat == "CURRENT" then
			unitFrame.CastBar.Time:SetFormattedText("%.1f", abs(unitFrame.CastBar.value - unitFrame.CastBar.max))
		elseif unitFrame.CastBar.channelTimeFormat == "CURRENTMAX" then
			unitFrame.CastBar.Time:SetFormattedText("%.1f / %.2f", abs(unitFrame.CastBar.value - unitFrame.CastBar.max), unitFrame.CastBar.max)
		elseif unitFrame.CastBar.channelTimeFormat == "REMAINING" then
			unitFrame.CastBar.Time:SetFormattedText("%.1f", unitFrame.CastBar.value)
		elseif unitFrame.CastBar.channelTimeFormat == "REMAININGMAX" then
			unitFrame.CastBar.Time:SetFormattedText("%.1f / %.2f", unitFrame.CastBar.value, unitFrame.CastBar.max)
		end
	else
		if unitFrame.CastBar.castTimeFormat == "CURRENT" then
			unitFrame.CastBar.Time:SetFormattedText("%.1f", unitFrame.CastBar.value)
		elseif unitFrame.CastBar.castTimeFormat == "CURRENTMAX" then
			unitFrame.CastBar.Time:SetFormattedText("%.1f / %.2f", unitFrame.CastBar.value, unitFrame.CastBar.max)
		elseif unitFrame.CastBar.castTimeFormat == "REMAINING" then
			unitFrame.CastBar.Time:SetFormattedText("%.1f", abs(unitFrame.CastBar.value - unitFrame.CastBar.max))
		elseif unitFrame.CastBar.castTimeFormat == "REMAININGMAX" then
			unitFrame.CastBar.Time:SetFormattedText("%.1f / %.2f", abs(unitFrame.CastBar.value - unitFrame.CastBar.max), unitFrame.CastBar.max)
		end
	end

	local unit = unitFrame.unit or unitFrame.unitName
	if unit then
		local spell, _, spellName = UnitCastingInfo(unit)
		if not spell then
			_, _, spellName = UnitChannelInfo(unit)
		end
		if spellName and unitFrame.Health:IsShown() then
			unitFrame.CastBar.Name:SetText(spellName)
		end
	else
		if unitFrame.Health:IsShown() then
			unitFrame.CastBar.Name:SetText("")
		end
	end

	unitFrame.CastBar.Icon.texture:SetTexture(self.Icon:GetTexture())
	self.Icon:Hide()
	if not self.Shield:IsShown() then
		unitFrame.CastBar:SetStatusBarColor(NP.db.colors.castColor.r, NP.db.colors.castColor.g, NP.db.colors.castColor.b)
		unitFrame.CastBar.Icon.texture:SetDesaturated(false)
	else
		unitFrame.CastBar:SetStatusBarColor(NP.db.colors.castNoInterruptColor.r, NP.db.colors.castNoInterruptColor.g, NP.db.colors.castNoInterruptColor.b)
		if NP.db.colors.castbarDesaturate then
			unitFrame.CastBar.Icon.texture:SetDesaturated(true)
		end
	end

	NP:StyleFilterUpdate(unitFrame, "FAKE_Casting")
end

function NP:Configure_CastBarScale(frame, scale, noPlayAnimation)
	if frame.currentScale == scale then return end
	local db = self.db.units[frame.UnitType].castbar
	if not db.enable then return end

	local castBar = frame.CastBar

	if noPlayAnimation then
		castBar:SetSize(db.width * scale, db.height * scale)
		castBar.Icon:SetSize(db.iconSize * scale, db.iconSize * scale)
	else
		if castBar.scale:IsPlaying() or castBar.Icon.scale:IsPlaying() then
			castBar.scale:Stop()
			castBar.Icon.scale:Stop()
		end

		castBar.scale.width:SetChange(db.width * scale)
		castBar.scale.height:SetChange(db.height * scale)
		castBar.scale:Play()

		castBar.Icon.scale.width:SetChange(db.iconSize * scale)
		castBar.Icon.scale.height:SetChange(db.iconSize * scale)
		castBar.Icon.scale:Play()
	end
end

function NP:Configure_CastBar(frame, configuring)
	local db = self.db.units[frame.UnitType].castbar
	local castBar = frame.CastBar

	castBar:SetPoint("TOP", frame.Health, "BOTTOM", db.xOffset, db.yOffset)

	if db.showIcon then
		castBar.Icon:ClearAllPoints()
		castBar.Icon:SetPoint(db.iconPosition == "RIGHT" and "BOTTOMLEFT" or "BOTTOMRIGHT", castBar, db.iconPosition == "RIGHT" and "BOTTOMRIGHT" or "BOTTOMLEFT", db.iconOffsetX, db.iconOffsetY)
		castBar.Icon:Show()
	else
		castBar.Icon:Hide()
	end

	castBar.Time:ClearAllPoints()
	castBar.Name:ClearAllPoints()

	castBar.Spark:SetPoint("CENTER", castBar:GetStatusBarTexture(), "RIGHT", 0, 0)
	castBar.Spark:SetHeight(db.height * 2)

	if db.textPosition == "BELOW" then
		castBar.Time:SetPoint("TOPRIGHT", castBar, "BOTTOMRIGHT")
		castBar.Name:SetPoint("TOPLEFT", castBar, "BOTTOMLEFT")
	elseif db.textPosition == "ABOVE" then
		castBar.Time:SetPoint("BOTTOMRIGHT", castBar, "TOPRIGHT")
		castBar.Name:SetPoint("BOTTOMLEFT", castBar, "TOPLEFT")
	else
		castBar.Time:SetPoint("RIGHT", castBar, "RIGHT", -4, 0)
		castBar.Name:SetPoint("LEFT", castBar, "LEFT", 4, 0)
	end

	if configuring then
		self:Configure_CastBarScale(frame, frame.currentScale or 1, configuring)
	end

	castBar.Name:FontTemplate(LSM:Fetch("font", db.font), db.fontSize, db.fontOutline)
	castBar.Time:FontTemplate(LSM:Fetch("font", db.font), db.fontSize, db.fontOutline)

	if db.hideSpellName then
		castBar.Name:Hide()
	else
		castBar.Name:Show()
	end
	if db.hideTime then
		castBar.Time:Hide()
	else
		castBar.Time:Show()
	end

	castBar:SetStatusBarTexture(LSM:Fetch("statusbar", self.db.statusbar))

	castBar.castTimeFormat = db.castTimeFormat
	castBar.channelTimeFormat = db.channelTimeFormat
end

function NP:CastBar_OnUpdate(elapsed)
	local parent = self:GetParent()
	local unitFrame = parent.UnitFrame
	if self.casting then
		local now = GetTime()
		local v = now - (self.startTime or now)
		if v >= (self.max or 0) then
			self.casting = nil
			self.holdTime = 0
			self:SetValue(self.max or 0)
			self.Spark:Hide()
			self.fake = nil
			self:Hide()
			NP:StyleFilterUpdate(unitFrame, "FAKE_Casting")
		else
			self.value = v
			self:SetValue(v)
			if self.castTimeFormat == "CURRENT" then
				self.Time:SetFormattedText("%.1f", self.value)
			elseif self.castTimeFormat == "CURRENTMAX" then
				self.Time:SetFormattedText("%.1f / %.2f", self.value, self.max)
			elseif self.castTimeFormat == "REMAINING" then
				self.Time:SetFormattedText("%.1f", abs(self.value - self.max))
			elseif self.castTimeFormat == "REMAININGMAX" then
				self.Time:SetFormattedText("%.1f / %.2f", abs(self.value - self.max), self.max)
			end
		end
	elseif self.interrupted then
		if self.holdTime and self.holdTime > 0 then
			self.holdTime = self.holdTime - elapsed
		else
			self.interrupted = nil
			self.fake = nil
			self:Hide()
			NP:StyleFilterUpdate(unitFrame, "FAKE_Casting")
		end
	end
end

function NP:Construct_CastBar(parent)
	local frame = CreateFrame("StatusBar", "$parentCastBar", parent)
	NP:StyleFrame(frame)

	frame.Icon = CreateFrame("Frame", nil, frame)
	frame.Icon.texture = frame.Icon:CreateTexture(nil, "BORDER")
	frame.Icon.texture:SetAllPoints()
	frame.Icon.texture:SetTexCoord(unpack(E.TexCoords))
	NP:StyleFrame(frame.Icon)

	frame.Time = frame:CreateFontString(nil, "OVERLAY")
	frame.Time:SetJustifyH("RIGHT")
	frame.Time:SetWordWrap(false)

	frame.Name = frame:CreateFontString(nil, "OVERLAY")
	frame.Name:SetJustifyH("LEFT")
	frame.Name:SetWordWrap(false)

	frame.Spark = frame:CreateTexture(nil, "OVERLAY")
	frame.Spark:SetTexture([[Interface\CastingBar\UI-CastingBar-Spark]])
	frame.Spark:SetBlendMode("ADD")
	frame.Spark:SetSize(15, 15)

	frame.holdTime = 0
	frame.interrupted = nil

	frame.scale = CreateAnimationGroup(frame)
	frame.scale.width = frame.scale:CreateAnimation("Width")
	frame.scale.width:SetDuration(0.2)
	frame.scale.height = frame.scale:CreateAnimation("Height")
	frame.scale.height:SetDuration(0.2)

	frame.Icon.scale = CreateAnimationGroup(frame.Icon)
	frame.Icon.scale.width = frame.Icon.scale:CreateAnimation("Width")
	frame.Icon.scale.width:SetDuration(0.2)
	frame.Icon.scale.height = frame.Icon.scale:CreateAnimation("Height")
	frame.Icon.scale.height:SetDuration(0.2)

	frame:SetScript("OnUpdate", NP.CastBar_OnUpdate)
	frame:Hide()

	return frame
end

function NP:StartFakeCast(unitFrame, spellID, spellName)
	local castBar = unitFrame.CastBar
	local name, _, icon, castTimeMS = GetSpellInfo(spellID)
	local ct = (castTimeMS or 0) / 1000
	if not castBar or ct <= 0 then return end
	castBar.fake = true
	castBar.max = ct
	castBar.value = 0
	castBar.startTime = GetTime()
	castBar.delay = 0
	castBar.casting = true
	castBar.channeling = false
	castBar.notInterruptible = false
	castBar.holdTime = 0
	castBar.interrupted = nil
	castBar.spellName = spellName or name
	castBar:SetMinMaxValues(0, ct)
	castBar:SetValue(0)
	if castBar.Icon and castBar.Icon.texture then
		castBar.Icon.texture:SetTexture(icon)
		castBar.Icon.texture:SetDesaturated(false)
	end
	if castBar.Spark then castBar.Spark:Show() end
	if castBar.Name then castBar.Name:SetText(spellName or name) end
	if castBar.Time then castBar.Time:SetText() end
	if unitFrame.Health:IsShown() or NP.db.units[unitFrame.UnitType].castbar.showWhenHPHidden then
		castBar:Show()
		NP:StyleFilterUpdate(unitFrame, "FAKE_Casting")
	end
end

function NP:StopFakeCast(unitFrame, interrupted)
	local castBar = unitFrame and unitFrame.CastBar
	if not castBar or not castBar:IsShown() then return end
	if interrupted then
		if castBar.Spark then castBar.Spark:Hide() end
		if castBar.Name then castBar.Name:SetText(INTERRUPTED) end
		castBar.interrupted = true
		local db = NP.db.units[unitFrame.UnitType].castbar
		castBar.holdTime = (db and db.timeToHold) or 0
	else
		castBar.holdTime = 0
		castBar.casting = nil
		castBar.channeling = nil
		castBar.fake = nil
		castBar:Hide()
	end
	NP:StyleFilterUpdate(unitFrame, "FAKE_Casting")
end

function NP:FindPlateForCLEU(guid, name)
	if NP.SearchNameplateByGUID then
		local f = NP:SearchNameplateByGUID(guid)
		if f then return f end
	end
	if type(name) ~= "string" then return end
	local short = name:gsub("%-.+$","")
	for frame in pairs(self.VisiblePlates) do
		if frame and frame:IsShown() and frame.UnitName == short then
			return frame
		end
	end
end

function NP:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local _, ev, _, srcGUID, srcName, srcFlags, _, dstGUID, dstName, dstFlags, _, spellID, spellName = ...
	if not spellID or bit_band(srcFlags or 0, HOSTILE) == 0 then return end
	if ev == "SPELL_CAST_START" then
		local frame = self:FindPlateForCLEU(srcGUID, srcName)
		if frame and self.db.units[frame.UnitType] and self.db.units[frame.UnitType].castbar.enable then
			self:StartFakeCast(frame, spellID, spellName)
		end
	elseif ev == "SPELL_INTERRUPT" or ev == "SPELL_CAST_FAILED" then
		local frame = self:FindPlateForCLEU(srcGUID, srcName)
		if frame then self:StopFakeCast(frame, true) end
	elseif ev == "SPELL_CAST_SUCCESS" then
		local frame = self:FindPlateForCLEU(srcGUID, srcName)
		if frame then self:StopFakeCast(frame, false) end
	end
end

if not NP._cl_registered then
	NP:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	NP._cl_registered = true
end
