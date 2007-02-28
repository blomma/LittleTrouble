--[[
	A big thanks to otravi and his castingbar, most of the bar code is taken 
	from his addon and warped for my evil purposes here.
	
	Textures for the castbar taken from agUF and oCB
--]]


local L = AceLibrary("AceLocale-2.2"):new("LittleTrouble")
local surface = AceLibrary("Surface-1.0")
surface:Register("Perl", "Interface\\AddOns\\LittleTrouble\\textures\\perl")
surface:Register("Smooth", "Interface\\AddOns\\LittleTrouble\\textures\\smooth")
surface:Register("Glaze", "Interface\\AddOns\\LittleTrouble\\textures\\glaze")
surface:Register("BantoBar", "Interface\\AddOns\\LittleTrouble\\textures\\BantoBar")
surface:Register("Gloss", "Interface\\AddOns\\LittleTrouble\\textures\\Gloss")

LittleTrouble = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceDB-2.0", "AceConsole-2.0")

LittleTrouble.defaults = {
	width		= 255,
	height		= 25,
	timeSize	= 12,
	spellSize	= 12,
	borderStyle = "Classic",
	texture		= "BantoBar",
	pos			= {},
	colors = {
		autoshot	= {r=1, g=.7, b=0},
	}
}

LittleTrouble.options = {
	type = "group",
	args = {
		[L["lock"]] = {
			name = L["lock"],
			type = "toggle",
			desc = L["Lock/Unlock the casting bar."],
			get = function() return LittleTrouble.locked end,
			set = function(v)
				LittleTrouble.locked = v
				if not v and not LittleTrouble.isAutoShot then
					LittleTrouble.master:SetScript( "OnUpdate", nil )
					LittleTrouble.master:Show()
					LittleTrouble.master.Time:SetText("1.3")
					LittleTrouble.master.Spell:SetText(L["Son of a bitch must pay!"])
				else
					LittleTrouble.master:Hide()
					LittleTrouble.master:SetScript( "OnUpdate", LittleTrouble.OnCasting )
				end
			end,
			map = {[false] = L["Unlocked"], [true] = L["Locked"]},
			guiNameIsMap = true,
		},
		[L["texture"]] = {
			name = L["texture"], 
			type = "text",
			desc = L["Set the texture."],
			get = function() return LittleTrouble.db.profile.texture end,
			set = function(v)
				LittleTrouble.db.profile.texture = v
				LittleTrouble:Layout()
			end,
			validate = surface:List(),
		},
		[L["border"]] = {
			name = L["border"],
			type = "text",
			desc = L["Set the border for the bar."],
			get = function() return LittleTrouble.db.profile.borderStyle end,
			set = function(v)
				LittleTrouble.db.profile.borderStyle = v 
				LittleTrouble:BorderBackground()
			end,
			validate = {"Classic", "Black", "Hidden"},
		},
		[L["width"]] = {
			name = L["width"], 
			type = "range", 
			min = 10, 
			max = 5000, 
			step = 1,
			desc = L["Set the width of the casting bar."],
			get = function() return LittleTrouble.db.profile.width end,
			set = function(v)
				LittleTrouble.db.profile.width = v
				LittleTrouble:Layout()
			end,
		},
		[L["height"]] = {
			name = L["height"], 
			type = "range", 
			min = 5, 
			max = 50, 
			step = 1,
			desc = L["Set the height of the casting bar."],
			get = function() return LittleTrouble.db.profile.height end,
			set = function(v)
				LittleTrouble.db.profile.height = v
				LittleTrouble:Layout()
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
					get = function() return LittleTrouble.db.profile.spellSize end,
					set = function(v)
						LittleTrouble.db.profile.spellSize = v
						LittleTrouble:Layout()
					end,
				},
				[L["time"]] = {
					name = L["time"], 
					type = "range", 
					min = 6, 
					max = 32, 
					step = 1,
					desc = L["Set the font size of the spell time."],
					get = function() return LittleTrouble.db.profile.timeSize end,
					set = function(v)
						LittleTrouble.db.profile.timeSize = v
						LittleTrouble:Layout()
					end,
				},
			}
		},
		[L["colors"]] = {
			name = L["colors"], type = 'group', order = 4,
			desc = L["Set the bar colors."],
			args = {
				[L["autoshot"]] = {
					name = L["autoshot"], type = 'color',
					desc = L["Sets the color of the auto shot bar."],
					get = function()
						local v = LittleTrouble.db.profile.colors.autoshot
						return v.r,v.g,v.b
					end,
					set = function(r,g,b) 
						LittleTrouble.db.profile.colors.autoshot = {r=r,g=g,b=b} 
						LittleTrouble:Layout()
					end
				}
			}
		}
	}
}

LittleTrouble.Borders = {
	["Classic"]		= {
		["texture"] = "Interface\\Tooltips\\UI-Tooltip-Border",["size"] = 16,["insets"] = 5,
		["bc"] = {r=0,g=0,b=0,a=1},
		["bbc"] = {r=TOOLTIP_DEFAULT_COLOR.r,g=TOOLTIP_DEFAULT_COLOR.g,b=TOOLTIP_DEFAULT_COLOR.b,a=1},
	},
	["Black"]		= {
		["texture"] = "Interface\\Tooltips\\UI-Tooltip-Border",["size"] = 16,["insets"] = 4,
		["bc"] = {r=0,g=0,b=0,a=1},
		["bbc"] = {r=0,g=0,b=0,a=1},
	},
	["Hidden"]		= {
		["texture"] = "",["size"] = 0,["insets"] = 4,
		["bc"] = {r=0,g=0,b=0,a=1},
		["bbc"] = {r=0,g=0,b=0,a=1},
	},
}

LittleTrouble:RegisterDB("LittleTroubleDB")
LittleTrouble:RegisterDefaults('profile', LittleTrouble.defaults)
LittleTrouble:RegisterChatCommand( {"/ltrouble"}, LittleTrouble.options )

function LittleTrouble:OnInitialize()
	self.locked = true
end

function LittleTrouble:OnEnable()
	self:CreateFrameWork()

	self:RegisterEvent("START_AUTOREPEAT_SPELL", "StartAutoRepeat")
	self:RegisterEvent("STOP_AUTOREPEAT_SPELL", "StopAutoRepeat")

	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "SpellCastSucceeded")
	self:RegisterEvent("UNIT_SPELLCAST_START", "SpellCastStart")
end

function LittleTrouble:SpellCastStart( unit )
	if unit ~= "player" then return end
	local name, _, _, _, _, _, _ = UnitCastingInfo(unit)

	if name == L["Aimed Shot"] then
		self.isAutoShot = false
	end
end

function LittleTrouble:SpellCastSucceeded( unit, spell, rank )
	if unit ~= "player" then return end
	if spell ~= L["Auto Shot"] and spell ~= L["Aimed Shot"] then return end

	self.startTime = GetTime()
	self.maxValue = self.startTime + UnitRangedDamage("player")
	self.isAutoShot = true
	self.thresHold = nil
	self.master.Bar:SetMinMaxValues( self.startTime, self.maxValue )
	self.master.Bar:SetValue( self.startTime )
	self.master.Spell:SetText(L["Auto Shot"])
	self.master:SetAlpha(1)
	self.master.Time:SetText("")
	self.master:Show()
	self.master.Spark:Show()
	self.master.Time:Show()
end

function LittleTrouble:StartAutoRepeat()
	self.fade = nil
	self.isAutoShot = true
end

function LittleTrouble:StopAutoRepeat()
	self.fade = true
	self.isAutoShot = nil
end

function LittleTrouble:SavePosition()
	local x, y = self.master:GetLeft(), self.master:GetTop()
	local s = self.master:GetEffectiveScale()
	local pos = self.db.profile.pos
	pos.x = x * s
	pos.y = y * s
end

function LittleTrouble:SetPosition()
	local pos = self.db.profile.pos
	if pos.x then
		local s = self.master:GetEffectiveScale()

		self.master:ClearAllPoints()
		self.master:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.x / s, pos.y / s)
	else
		self.master:ClearAllPoints()
		self.master:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
end

function LittleTrouble:CreateFrameWork()
	self.master = CreateFrame("Frame", "LittleTroubleFrame", UIParent)
	self.master:Hide()

	self.master:SetScript( "OnUpdate", self.OnCasting )
	self.master:SetMovable(true)
	self.master:EnableMouse(true)
	self.master:RegisterForDrag("LeftButton")
	self.master:SetScript("OnDragStart", function() if not self.locked then self["master"]:StartMoving() end end)
	self.master:SetScript("OnDragStop", function() self["master"]:StopMovingOrSizing() self:SavePosition() end)

	self.master.Bar	  = CreateFrame("StatusBar", nil, self.master)
	self.master.Spark = self.master.Bar:CreateTexture(nil, "OVERLAY")
	self.master.Time  = self.master.Bar:CreateFontString(nil, "OVERLAY")
	self.master.Spell = self.master.Bar:CreateFontString(nil, "OVERLAY")

	self:Layout()
end

function LittleTrouble:Layout()
	local gameFont, _, _ = GameFontHighlightSmall:GetFont()
	local db = self.db.profile

	self.master:SetWidth( db.width + 9 )
	self.master:SetHeight( db.height + 10 )

	self:BorderBackground()
	
	self.master.Bar:ClearAllPoints()
	self.master.Bar:SetPoint("CENTER", self.master, "CENTER", 0, 0)
	self.master.Bar:SetWidth( db.width )
	self.master.Bar:SetHeight( db.height )
	self.master.Bar:SetStatusBarTexture( surface:Fetch( db.texture ))
	self.master.Bar:SetStatusBarColor( db.colors.autoshot.r, db.colors.autoshot.g, db.colors.autoshot.b )

	self.master.Spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	self.master.Spark:SetWidth(16)
	self.master.Spark:SetHeight( db.height*2.44 )
	self.master.Spark:SetBlendMode("ADD")

	self.master.Time:SetJustifyH("RIGHT")
	self.master.Time:SetFont( gameFont, db.timeSize )
	self.master.Time:SetText("X.Y")
	self.master.Time:ClearAllPoints()
	self.master.Time:SetPoint("RIGHT", self.master.Bar, "RIGHT",-10,0)
	self.master.Time:SetShadowOffset(.8, -.8)
	self.master.Time:SetShadowColor(0, 0, 0, 1)

	self.master.Spell:SetJustifyH("CENTER")
	self.master.Spell:SetWidth( db.width - self.master.Time:GetWidth() )
	self.master.Spell:SetFont( gameFont, db.spellSize )
	self.master.Spell:ClearAllPoints()
	self.master.Spell:SetPoint("LEFT", self.master, "LEFT",10,0)
	self.master.Spell:SetShadowOffset(.8, -.8)
	self.master.Spell:SetShadowColor(0, 0, 0, 1)

	self:SetPosition()
end

function LittleTrouble:BorderBackground()
	local borderstyle = self.db.profile.borderStyle
	local color = self.Borders[borderstyle]
	
	self.master:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
		tile = true, 
		tileSize = 16,
		edgeFile = self.Borders[borderstyle].texture,
		edgeSize = self.Borders[borderstyle].size,
		insets = {
			left = self.Borders[borderstyle].insets, 
			right = self.Borders[borderstyle].insets, 
			top = self.Borders[borderstyle].insets, 
			bottom = self.Borders[borderstyle].insets
		},
	})
		
	self.master:SetBackdropColor(color.bc.r,color.bc.g,color.bc.b,color.bc.a)
	self.master:SetBackdropBorderColor(color.bbc.r,color.bbc.g,color.bbc.b,color.bbc.a)
end

function LittleTrouble:OnCasting()
	if LittleTrouble.isAutoShot and not LittleTrouble.thresHold then
		local currentTime = GetTime()

		if( currentTime > LittleTrouble.maxValue ) then
			currentTime = LittleTrouble.maxValue
			LittleTrouble.thresHold = true
		end

		LittleTrouble.master.Bar:SetValue( currentTime )		
		local sparkProgress = (( currentTime - LittleTrouble.startTime ) / ( LittleTrouble.maxValue - LittleTrouble.startTime )) * LittleTrouble.db.profile.width
		LittleTrouble.master.Spark:SetPoint("CENTER", LittleTrouble.master.Bar, "LEFT", sparkProgress, 0)		
		LittleTrouble.master.Time:SetText( string.format( "%.1f", ( LittleTrouble.maxValue - currentTime )))
	elseif LittleTrouble.fade then
		local a = LittleTrouble.master:GetAlpha() - .05

		if( a > 0 ) then
			LittleTrouble.master:SetAlpha(a)
		else
			LittleTrouble.master:Hide()
			LittleTrouble.master:SetAlpha(1)
		end
	end
end