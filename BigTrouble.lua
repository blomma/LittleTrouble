--[[
	A big thanks to otravi and his castingbar, most of the bar code is taken 
	from his addon and warped for my evil purposes here.
	
	Textures for the castbar taken from agUF and oCB
--]]


local Colors = 
{
	complete	= {r=0, g=1, b=0},
	autoShot	= {r=1, g=.7, b=0},
	casting		= {r=.3, g=.3, b=1},
	failed		= {r=1, g=0, b=0},
}

local delayString, delayTime
local locked = true

local L = AceLibrary("AceLocale-2.2"):new("BigTrouble")
local surface = AceLibrary("Surface-1.0")

surface:Register("Perl", "Interface\\AddOns\\BigTrouble\\textures\\perl")
surface:Register("Smooth", "Interface\\AddOns\\BigTrouble\\textures\\smooth")
surface:Register("Glaze", "Interface\\AddOns\\BigTrouble\\textures\\glaze")
surface:Register("BantoBar", "Interface\\AddOns\\BigTrouble\\textures\\BantoBar")
surface:Register("Gloss", "Interface\\AddOns\\BigTrouble\\textures\\Gloss")

BigTrouble = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceDebug-2.0", "AceDB-2.0", "AceConsole-2.0")

BigTrouble.defaults = {
	width		= 255,
	height		= 25,
	timeSize	= 12,
	spellSize	= 12,
	delaySize	= 14,
	border		= true,
	texture		= "BantoBar",
	pos			= {},
	autoShotBar = true,
	aimedShotBar	= true
}

BigTrouble.options = {
	type = "group",
	args = {
		[L["lock"]] = {
			name = L["lock"],
			type = "toggle",
			desc = L["Lock/Unlock the casting bar."],
			get = function() return locked end,
			set = "SetLocked",
			map = {[false] = L["Unlocked"], [true] = L["Locked"]},
			guiNameIsMap = true,
		},
		[L["texture"]] = {
			name = L["texture"], 
			type = "text",
			desc = L["Set the texture."],
			get = function() return BigTrouble.db.profile.texture end,
			set = function(v)
				BigTrouble.db.profile.texture = v
				BigTrouble:Layout()
			end,
			validate = surface:List(),
		},
		[L["border"]] = {
			name = L["border"],
			type = "toggle",
			desc = L["Toggle the border."],
			get = function() return BigTrouble.db.profile.border end,
			set = function(v) 
				BigTrouble.db.profile.border = v 
				BigTrouble:Layout()
			end,
			map = {[false] = L["Off"], [true] = L["On"]},
			guiNameIsMap = true,
		},
		[L["width"]] = {
			name = L["width"], 
			type = "range", 
			min = 10, 
			max = 500, 
			step = 1,
			desc = L["Set the width of the casting bar."],
			get = function() return BigTrouble.db.profile.width end,
			set = function(v)
				BigTrouble.db.profile.width = v
				BigTrouble:Layout()
			end,
		},
		[L["height"]] = {
			name = L["height"], 
			type = "range", 
			min = 5, 
			max = 50, 
			step = 1,
			desc = L["Set the height of the casting bar."],
			get = function() return BigTrouble.db.profile.height end,
			set = function(v)
				BigTrouble.db.profile.height = v
				BigTrouble:Layout()
			end,
		},
		[L["font"]] = {
			name = L["font"],
			type = "group",
			desc = L["Set the font size of different elements."],
			args = {
				[L["spell"]] = {
					name = L["spell"], 
					type = "range", 
					min = 6,
					max = 32,
					step = 1,
					desc = L["Set the font size of the spellname."],
					get = function() return BigTrouble.db.profile.spellSize end,
					set = function(v)
						BigTrouble.db.profile.spellSize = v
						BigTrouble:Layout()
					end,
				},
				[L["time"]] = {
					name = L["time"], 
					type = "range", 
					min = 6, 
					max = 32, 
					step = 1,
					desc = L["Set the font size of the spell time."],
					get = function() return BigTrouble.db.profile.timeSize end,
					set = function(v)
						BigTrouble.db.profile.timeSize = v
						BigTrouble:Layout()
					end,
				},
				[L["delay"]] = {
					name = L["delay"], 
					type = "range", 
					min = 6,
					max = 32,
					step = 1,
					desc = L["Set the font size on the delay time."],
					get = function() return BigTrouble.db.profile.delaySize end,
					set = function(v)
						BigTrouble.db.profile.delaySize = v
						BigTrouble:Layout()
					end,
				}
			}
		}
	}
}

function BigTrouble:SetLocked( value )
	locked = value

	if( not value and not ( self.isCasting or self.isAutoShot )) then
		BigTrouble:Debug("test")
		self.master:SetScript( "OnUpdate", nil )
		self.master:Show()
		self.master.Bar:SetStatusBarColor(.3, .3, .3)
		self.master.Time:SetText("1.3")
		self.master.Delay:SetText("+0.8")
		self.master.Spell:SetText(L["Son of a bitch must pay!"])
	else
		self.master:SetScript( "OnUpdate", self.OnCasting )
	end
	
end

BigTrouble:RegisterDB("BigTroubleDB")
BigTrouble:RegisterDefaults('profile', BigTrouble.defaults)
BigTrouble:RegisterChatCommand( {"/btrouble"}, BigTrouble.options )

function BigTrouble:OnInitialize()
	self.options.args[L["texture"]].validate = surface:List()
	self:RegisterEvent("Surface_Registered", function()
		self.options.args[L["texture"]].validate = surface:List()
	end)

	self:SetDebugging(false)
end

function BigTrouble:OnEnable()
	self:CreateFrameWork()

	-- Autoshot
	self:RegisterEvent("START_AUTOREPEAT_SPELL", "StartAutoRepeat")
	self:RegisterEvent("STOP_AUTOREPEAT_SPELL", "StopAutoRepeat")
	
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "SpellCastSucceeded")
	self:RegisterEvent("UNIT_SPELLCAST_START", "SpellCastStart")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED","SpellCastFailed")
--	self:RegisterEvent("UNIT_SPELLCAST_DELAYED", "SpellCastDelayed")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED", "SpellCastFailed")
end

function BigTrouble:SpellCastStart( unit )
	if unit ~= "player" then return end	
	local name, _, _, _, _, _, _ = UnitCastingInfo(unit)
	
	if name == L["Aimed Shot"] then
		self.isAutoShot = false
	end
end

function BigTrouble:SpellCastSucceeded( unit, spell, rank )
	if unit ~= "player" then return end
	if spell ~= L["Auto Shot"] or spell ~= L["Aimed Shot"] then return end

	-- if self.isAutoShot and self.master:IsShown() then
	-- 	self.master.Spark:Hide()
	-- 	self.master.Time:Hide()
	-- 	self.master.Delay:Hide()
	-- 	
	-- 	self.master.Bar:SetValue( self.maxValue )
	-- 	self.master.Bar:SetStatusBarColor( Colors.complete.r, Colors.complete.g, Colors.complete.b )
	-- end

	self.startTime = GetTime()
	self.maxValue = self.startTime + UnitRangedDamage("player")				
	self.master.Bar:SetStatusBarColor( Colors.autoShot.r, Colors.autoShot.g, Colors.autoShot.b )
	self.isAutoShot = true
	self:BarCreate(L["Auto Shot"])
end

function BigTrouble:SpellCastFailed( unit )
	if unit ~= "player" then return end
	 
	if self.isAutoShot and self.master:IsShown() then
		self.thresHold = true
		self.master.Spark:Hide()
		self.master.Time:Hide()
		self.master.Delay:Hide()

		self.master.Bar:SetValue( self.maxValue )
		self.master.Bar:SetStatusBarColor( Colors.failed.r, Colors.failed.g, Colors.failed.b )
		self.master.Spell:SetText(L[event])
	end
end

-- function BigTrouble:SpellCastDelayed( unit )
-- 	if( unit ~= "player" ) then return end
--  
-- 	if( self.master:IsShown() and self.isCasting ) then
-- 		local _, _, _, _, startTime, endTime, _, oldStart = UnitCastingInfo(unit)
-- 		
-- 		oldStart = self.startTime
-- 		self.startTime = startTime / 1000
-- 		self.maxValue = endTime / 1000
-- 		
-- 		delayTime = (delayTime or 0) + ( self.startTime - oldStart )
-- 		delayString = "+"..string.format( "%.1f", delayTime )
-- 		
-- 		self.master.Delay:Show()
-- 		self.master.Bar:SetMinMaxValues( self.startTime, self.maxValue )
-- 	end
-- end
 
function BigTrouble:StartAutoRepeat()
	self.isAutoShot = true
end

function BigTrouble:StopAutoRepeat()
	self.isAutoShot = nil
end

function BigTrouble:BarCreate(s)
	self.thresHold = nil
	self.master.Bar:SetMinMaxValues( self.startTime, self.maxValue )
	self.master.Bar:SetValue( self.startTime )
	self.master.Spell:SetText(s)
	self.master:SetAlpha(1)
	self.master.Time:SetText("")
--	self.master.Delay:SetText("")
	
--	delayTime = nil
	
	self.master:Show()
	self.master.Spark:Show()
	self.master.Time:Show()
end

function BigTrouble:SavePosition()
	local x, y = self.master:GetLeft(), self.master:GetTop()
	local s = self.master:GetEffectiveScale()

	self.db.profile.pos.x = x * s
	self.db.profile.pos.y = y * s
end

function BigTrouble:SetPosition()
	if self.db.profile.pos.x then
		local x = self.db.profile.pos.x
		local y = self.db.profile.pos.y
	
		local s = self.master:GetEffectiveScale()

		self.master:ClearAllPoints()
		self.master:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s, y / s)
	else
		self.master:ClearAllPoints()
		self.master:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
end

function BigTrouble:CreateFrameWork()
	self.master = CreateFrame("Frame", "BigTroubleFrame", UIParent)
	self.master:Hide()
	
	self.master:SetScript( "OnUpdate", self.OnCasting )
	self.master:SetMovable(true)
	self.master:EnableMouse(true)
	self.master:RegisterForDrag("LeftButton")
	self.master:SetScript("OnDragStart", function() if not locked then self["master"]:StartMoving() end end)
	self.master:SetScript("OnDragStop", function() self["master"]:StopMovingOrSizing() self:SavePosition() end)

	self.master.Bar	  = CreateFrame("StatusBar", nil, self.master)
	self.master.Spark = self.master.Bar:CreateTexture(nil, "OVERLAY")
	self.master.Time  = self.master.Bar:CreateFontString(nil, "OVERLAY")
	self.master.Spell = self.master.Bar:CreateFontString(nil, "OVERLAY")
	self.master.Delay = self.master.Bar:CreateFontString(nil, "OVERLAY")
	
	self:Layout()
end

function BigTrouble:Layout()
	local gameFont, _, _ = GameFontHighlightSmall:GetFont()
	
	self.master:SetWidth( self.db.profile.width + 9 )
	self.master:SetHeight( self.db.profile.height + 10 )

	local edgeFile, edgeSize
	if self.db.profile.border then 
		edgeFile, edgeSize = "Interface\\Tooltips\\UI-Tooltip-Border", 16 
	end
	
	self.master:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
		edgeFile = edgeFile or "", 
		edgeSize = edgeSize or "",
		insets = {left = 4, right = 4, top = 4, bottom = 4},
	})

	self.master:SetBackdropBorderColor(0, 0, 0)
	self.master:SetBackdropColor(0, 0, 0)

	self.master.Bar:ClearAllPoints()
	self.master.Bar:SetPoint("CENTER", self.master, "CENTER", 0, 0)
	self.master.Bar:SetWidth( self.db.profile.width )
	self.master.Bar:SetHeight( self.db.profile.height )
	self.master.Bar:SetStatusBarTexture( surface:Fetch( self.db.profile.texture ))

	self.master.Spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	self.master.Spark:SetWidth(16)
	self.master.Spark:SetHeight( self.db.profile.height*2.44 )
	self.master.Spark:SetBlendMode("ADD")

	self.master.Time:SetJustifyH("RIGHT")
	self.master.Time:SetFont( gameFont, self.db.profile.timeSize )
	self.master.Time:SetText("X.Y")
	self.master.Time:ClearAllPoints()
	self.master.Time:SetPoint("RIGHT", self.master.Bar, "RIGHT",-10,0)
	self.master.Time:SetShadowOffset(.8, -.8)
	self.master.Time:SetShadowColor(0, 0, 0, 1)

	self.master.Spell:SetJustifyH("CENTER")
	self.master.Spell:SetWidth( self.db.profile.width - self.master.Time:GetWidth() )
	self.master.Spell:SetFont( gameFont, self.db.profile.spellSize )
	self.master.Spell:ClearAllPoints()
	self.master.Spell:SetPoint("LEFT", self.master, "LEFT",10,0)
	self.master.Spell:SetShadowOffset(.8, -.8)
	self.master.Spell:SetShadowColor(0, 0, 0, 1)

	self.master.Delay:SetJustifyH("RIGHT")
	self.master.Delay:SetFont( gameFont, self.db.profile.delaySize )
	self.master.Delay:SetTextColor(1,0,0,1)
	self.master.Delay:SetText("X.Y")
	self.master.Delay:ClearAllPoints()
	self.master.Delay:SetPoint("TOPRIGHT", self.master.Bar, "TOPRIGHT",-10,20)
	self.master.Delay:SetShadowOffset(.8, -.8)
	self.master.Delay:SetShadowColor(0, 0, 0, 1)

	self:SetPosition()
end

function BigTrouble:OnCasting()
	if BigTrouble.isAutoShot and not thresHold then
		local currentTime = GetTime()
		
		if( currentTime > BigTrouble.maxValue ) then
			currentTime = BigTrouble.maxValue
			thresHold = true
		end
		
		BigTrouble.master.Bar:SetValue( currentTime )		
		local sparkProgress = (( currentTime - BigTrouble.startTime ) / ( BigTrouble.maxValue - BigTrouble.startTime )) * BigTrouble.db.profile.width
		BigTrouble.master.Spark:SetPoint("CENTER", BigTrouble.master.Bar, "LEFT", sparkProgress, 0)
		
		BigTrouble.master.Time:SetText( string.format( "%.1f", ( BigTrouble.maxValue - currentTime )))
--		if( delayTime ~= nil ) then BigTrouble.master.Delay:SetText( delayString ) end

	else
		local a = BigTrouble.master:GetAlpha() - .05

		if( a > 0 ) then
			BigTrouble.master:SetAlpha(a)
		else
			BigTrouble.master:Hide()
			BigTrouble.master:SetAlpha(1)
		end
	end
end