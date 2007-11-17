local VERSION = tonumber(("$Revision$"):match("%d+"))

local SM = AceLibrary("SharedMedia-1.0")
SM:Register("statusbar", "BantoBar", "Interface\\AddOns\\LittleTrouble\\textures\\BantoBar.tga")
SM:Register("statusbar", "Glaze", "Interface\\AddOns\\LittleTrouble\\textures\\glaze.tga")
SM:Register("statusbar", "Gloss", "Interface\\AddOns\\LittleTrouble\\textures\\Gloss.tga")
SM:Register("statusbar", "Perl", "Interface\\AddOns\\LittleTrouble\\textures\\perl.tga")
SM:Register("statusbar", "Smooth", "Interface\\AddOns\\LittleTrouble\\textures\\smooth.tga")

LittleTrouble = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceDB-2.0", "AceConsole-2.0")
local LittleTrouble, self = LittleTrouble, LittleTrouble
LittleTrouble.version = "r" .. VERSION
LittleTrouble.revision = VERSION
LittleTrouble.date = ("$Date$"):match("%d%d%d%d%-%d%d%-%d%d")

local L = setmetatable({}, {__index = function(self, key) return key end})
local LS = AceLibrary("AceLocale-2.2"):new("LittleTrouble")

LS:RegisterTranslations("enUS", function()
return {
	["Aimed Shot"] = true,
	["Auto Shot"] = true,
}
end)

LS:RegisterTranslations("deDE", function()
return {
	["Aimed Shot"] = "Gezielter Schuss",
	["Auto Shot"] = "Automatischer Schuss",
}
end)

LS:RegisterTranslations("frFR", function()
return {
	["Aimed Shot"] = "Vis\195\169e",
	["Auto Shot"] = "Tir automatique",
}
end)

LS:RegisterTranslations("zhCN", function()
return {
	["Aimed Shot"] = "瞄准射击",
	["Auto Shot"] = "自动射击",
}
end)

LS:RegisterTranslations("zhTW", function()
return {
	["Aimed Shot"] = "瞄準射擊",
	["Auto Shot"] = "自動射擊",
}
end)

LS:RegisterTranslations("koKR", function()
return {
	["Aimed Shot"] = "조준 사격",
	["Auto Shot"] = "자동 사격",
}
end)

LS:RegisterTranslations("esES", function()
return {
	["Aimed Shot"] = "Disparo de punter\195\173a",
	["Auto Shot"] = "Disparo autom\195\161tico",
}
end)

local isAutoShot, isAimedShot, endTime, startTime
local locked = true

local GetTime = GetTime

local defaults = {
	alpha		= 1,
	scale		= 1,
	width		= 255,
	height		= 25,
	font		= "Arial Narrow",
	textDisable = false,
	timeDisable = false,
	timeSize	= 12,
	textSize	= 12,
	borderStyle = "Classic",
	texture		= "Blizzard",
	autoShotDelay = 0.8,
	pos			= {},
	colors = {
		bar = {1, .7, 0, 1},
		background = {0,0,0,1},
		border = {1,1,1,1},
		time = {1,1,1,1},
		text = {1,1,1,1}
	}
}

local options = {
	type = "group",
	args = {
		lock = {
			name = L["Lock"],
			desc = L["Lock/Unlock the bar."],
			type = "toggle",
			get = function() return locked end,
			set = function(v)
				locked = v
				if not v then
					LittleTrouble.frame:SetScript( "OnUpdate", nil )
					LittleTrouble.frame:SetAlpha(1)
					LittleTrouble.frame:Show()
					LittleTrouble.frame.castBarTimeText:SetText("1.3")
					LittleTrouble.frame.castBarText:SetText(L["Son of a bitch must pay!"])
				else
					LittleTrouble.frame:Hide()
					LittleTrouble.frame.castBarTimeText:SetText("")
					LittleTrouble.frame.castBarText:SetText("")
					LittleTrouble.frame:SetScript( "OnUpdate", LittleTrouble.OnUpdate )
				end
			end,
		},
		autoshotdelay = {
			name = L["Autoshot delay after Aimedshot"], 
			desc = L["Sets the amount of seconds to delay the autoshot following a aimedshot."],
			type = "range", 
			min = 0,
			max = 2,
			step = 0.01,
			get = function() return LittleTrouble.db.profile.autoShotDelay end,
			set = function(v)
				LittleTrouble.db.profile.autoShotDelay = v
			end,
		},
		texture = {
			name = L["Texture"],
			desc = L["Sets the texture of the bar."],
			type = "text",
			get = function() return LittleTrouble.db.profile.texture end,
			set = function(v)
				LittleTrouble.db.profile.texture = v
				LittleTrouble:Layout()
			end,
			validate = SM:List('statusbar'),
		},
		font = {
			name = L["Font"],
			desc = L["Sets the font face of the bar."],
			type = "text",
			get = function() return LittleTrouble.db.profile.font end,
			set = function(v)
				LittleTrouble.db.profile.font = v
				LittleTrouble:Layout()
			end,
			validate = SM:List('font'),
		},
		border = {
			name = L["Border"],
			desc = L["Sets the border of the bar."],
			type = "text",
			get = function() return LittleTrouble.db.profile.borderStyle end,
			set = function(v)
				LittleTrouble.db.profile.borderStyle = v 
				LittleTrouble:Layout()
			end,
			validate = {"Classic", "Hidden"},
		},
		size = {
			name = L["Size"],
			desc = L["Size settings."],
			type = 'group',
			args = {
				scale = {
					name = L["Scale"],
					desc = L["Sets the scale of the bar."],
					type = 'range',
					isPercent = true,
					min = 0.5,
					max = 2,
					step = 0.05,
					get = function() return LittleTrouble.db.profile.scale end,
					set = function(v)
						if LittleTrouble.db.profile.scale == v then return end
						LittleTrouble.db.profile.scale = v
						LittleTrouble:Layout()
					end,
				},
				width = {
					name = L["Width"], 
					desc = L["Sets the width of the bar."],
					type = "range", 
					min = 10, 
					max = 5000, 
					step = 1,
					get = function() return LittleTrouble.db.profile.width end,
					set = function(v)
						LittleTrouble.db.profile.width = v
						LittleTrouble:Layout()
					end,
				},
				height = {
					name = L["Height"], 
					desc = L["Sets the height of the bar."],
					type = "range", 
					min = 10,
					max = 500,
					step = 1,
					get = function() return LittleTrouble.db.profile.height end,
					set = function(v)
						LittleTrouble.db.profile.height = v
						LittleTrouble:Layout()
					end,
				},
			},
		},
		text = {
			name = L["Text"],
			desc = L["Bar text settings."],
			type = "group",
			args = {
				disable = {
					name = L["Disable"],
					desc = L["Disables the text on the bar."],
					type = 'toggle',
					get = function() return LittleTrouble.db.profile.textDisable end,
					set = function(v) LittleTrouble.db.profile.textDisable = v end,
				},
				height = {
					name = L["Font height"], 
					desc = L["Sets the height of the text."],
					type = "range", 
					min = 6,
					max = 32,
					step = 1,
					get = function() return LittleTrouble.db.profile.textSize end,
					set = function(v)
						LittleTrouble.db.profile.textSize = v
						LittleTrouble:Layout()
					end,
				},
			}
		},
		time = {
			name = L["Time"],
			desc = L["Bar time settings."],
			type = "group",
			args = {
				disable = {
					name = L["Disable"],
					desc = L["Disables the time on the bar."],
					type = 'toggle',
					get = function() return LittleTrouble.db.profile.timeDisable end,
					set = function(v) LittleTrouble.db.profile.timeDisable = v end,
				},
				time = {
					name = L["Font height"], 
					desc = L["Sets the height of the time."],
					type = "range", 
					min = 6, 
					max = 32, 
					step = 1,
					get = function() return LittleTrouble.db.profile.timeSize end,
					set = function(v)
						LittleTrouble.db.profile.timeSize = v
						LittleTrouble:Layout()
					end,
				},
			}
		},
		color = {
			name = L["Color"],
			desc = L["Color settings."],
			type = 'group',
			args = {
				alpha = {
					name = L["Alpha"],
					desc = L["Sets the alpha of the bar."],
					type = "range", 
					min = 0,
					max = 1,
					step = 0.01,
					isPercent = true,
					get = function() return LittleTrouble.db.profile.alpha end,
					set = function(v)
						LittleTrouble.db.profile.alpha = v
						LittleTrouble:Layout()
					end,
				},
				time = {
					name = L["Time"], 
					desc = L["Sets the color of the time."],
					type = 'color',
					hasAlpha = true,
					get = function()
						local v = LittleTrouble.db.profile.colors.time
						return unpack(v)
					end,
					set = function(r,g,b,a) 
						LittleTrouble.db.profile.colors.time = {r,g,b,a} 
						LittleTrouble:Layout()
					end
				},
				text = {
					name = L["Text"], 
					desc = L["Sets the color of the text."],
					type = 'color',
					hasAlpha = true,
					get = function()
						local v = LittleTrouble.db.profile.colors.text
						return unpack(v)
					end,
					set = function(r,g,b,a) 
						LittleTrouble.db.profile.colors.text = {r,g,b,a} 
						LittleTrouble:Layout()
					end
				},
				bar = {
					name = L["Bar"], 
					desc = L["Sets the color of the bar."],
					type = 'color',
					hasAlpha = true,
					get = function()
						local v = LittleTrouble.db.profile.colors.bar
						return unpack(v)
					end,
					set = function(r,g,b,a) 
						LittleTrouble.db.profile.colors.bar = {r,g,b,a} 
						LittleTrouble:Layout()
					end
				},
				background = {
					name = L["Background"], 
					desc = L["Sets the color of the background."],
					type = 'color',
					hasAlpha = true,
					get = function()
						local v = LittleTrouble.db.profile.colors.background
						return unpack(v)
					end,
					set = function(r,g,b,a) 
						LittleTrouble.db.profile.colors.background = {r,g,b,a}
						LittleTrouble:Layout()
					end
				},
				border = {
					name = L["Border"], 
					desc = L["Sets the color of the border."],
					type = 'color',
					hasAlpha = true,
					get = function()
						local v = LittleTrouble.db.profile.colors.border
						return unpack(v)
					end,
					set = function(r,g,b,a) 
						LittleTrouble.db.profile.colors.border = {r,g,b,a}
						LittleTrouble:Layout()
					end
				}
			}
		}
	}
}

local borders = {
	["Classic"] = {"Interface\\Tooltips\\UI-Tooltip-Border", 16, 5},
	["Hidden"] = { "", 0, 3 }
}

LittleTrouble:RegisterDB("LittleTroubleDB")
LittleTrouble:RegisterDefaults('profile', defaults)

function LittleTrouble:OnInitialize()
	AceLibrary("Waterfall-1.0"):Register('LittleTrouble',
		'aceOptions', options,
		'title', L["LittleTrouble"],
		'treeLevels', 3,
		'colorR', 0.8, 'colorG', 0.8, 'colorB', 0.8
	)
	self:RegisterChatCommand({"/ltrouble"}, function()
		AceLibrary("Waterfall-1.0"):Open('LittleTrouble')
	end)
end

function LittleTrouble:OnEnable()
	self:CreateFrameWork()

	self:RegisterEvent("START_AUTOREPEAT_SPELL")
	self:RegisterEvent("UNIT_SPELLCAST_START")

	self:RegisterEvent("SharedMedia_SetGlobal", function(mtype, override)
		if mtype == "statusbar" then
			LittleTrouble.frame.castBar:SetStatusBarTexture(SM:Fetch("statusbar", override))
		end
	end)
end

function LittleTrouble:UNIT_SPELLCAST_START( unit, spell, rank )
	if unit ~= "player" or spell ~= LS["Aimed Shot"] then return end

	isAutoShot = false
	isAimedShot = true
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED","UNIT_SPELLCAST_SUCCEEDED",1)
end

function LittleTrouble:UNIT_SPELLCAST_SUCCEEDED( unit, spell, rank )
	if unit ~= "player" then return end
	if spell ~= LS["Auto Shot"] and spell ~= LS["Aimed Shot"] then return end

	startTime = GetTime()
	endTime = startTime + UnitRangedDamage("player")

	local db = self.db.profile
	if spell == LS["Aimed Shot"] then
		isAimedShot = false
		endTime = endTime + db.autoShotDelay
	end

	isAutoShot = true

	local frame = self.frame
	frame:SetAlpha(db.alpha)
	--frame.castBar:SetValue(0)
	frame.castBar:SetMinMaxValues(startTime, endTime)
	if not db.textDisable then
		frame.castBarText:SetText(LS["Auto Shot"])
	else
		frame.castBarText:SetText("")
	end
	frame.castBarTimeText:SetText("")
	frame:Show()
end

function LittleTrouble:START_AUTOREPEAT_SPELL()
	self:RegisterEvent("STOP_AUTOREPEAT_SPELL")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

function LittleTrouble:STOP_AUTOREPEAT_SPELL()
	isAutoShot = false
	self:UnregisterEvent("STOP_AUTOREPEAT_SPELL")
	if not isAimedShot then
		self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	end
end

local OnUpdateNew
do
	function OnUpdateNew( frame )
		if isAutoShot then
			local currentTime = GetTime()

			if currentTime > endTime then
				currentTime = endTime
				isAutoShot = false
			else

				local elapsed = (currentTime - startTime)
				frame.castBar:SetValue(startTime + elapsed)
				if not LittleTrouble.db.profile.timeDisable then
					frame.castBarTimeText:SetFormattedText("%.1f", endTime - currentTime)
				end
			end
		else
			local alpha = frame:GetAlpha() - .10

			if alpha > 0 then
				frame:SetAlpha(alpha)
			else
				frame:Hide()
			end
		end
	end
end

function LittleTrouble:OnUpdate()
	if isAutoShot then
		local currentTime = GetTime()

		if currentTime > endTime then
			currentTime = endTime
			isAutoShot = false
		end

		local elapsed = (currentTime - startTime)
		LittleTrouble.frame.castBar:SetValue(startTime + elapsed)
		if not LittleTrouble.db.profile.timeDisable then
			LittleTrouble.frame.castBarTimeText:SetFormattedText("%.1f", endTime - currentTime)
		end
	else
		local alpha = LittleTrouble.frame:GetAlpha() - .10

		if alpha > 0 then
			LittleTrouble.frame:SetAlpha(alpha)
		else
			LittleTrouble.frame:Hide()
		end
	end
end

function LittleTrouble:CreateFrameWork()
	local frame = CreateFrame("Frame", "LittleTroubleFrame", UIParent)
	self.frame = frame
	frame:Hide()

	local pos = self.db.profile.pos

	if pos.x and pos.y then
		local uis = UIParent:GetScale()
		local s = frame:GetEffectiveScale()
		frame:SetPoint("CENTER", pos.x*uis/s, pos.y*uis/s)
	else
		frame:SetPoint("CENTER", 0, 50)
	end

	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function() if not locked then this:StartMoving() end end)
	frame:SetScript("OnDragStop", function(this)
		this:StopMovingOrSizing()
		local pos = self.db.profile.pos
		local x, y = this:GetCenter()
		local s = this:GetEffectiveScale()
		local uis = UIParent:GetScale()
		this:ClearAllPoints()
		x = x*s - GetScreenWidth()*uis/2
		y = y*s - GetScreenHeight()*uis/2
		pos.x, pos.y = x/uis, y/uis
		this:SetPoint("CENTER", UIParent, "CENTER", x/s, y/s)
	end)

	frame:SetScript( "OnUpdate", OnUpdateNew )
	frame:SetClampedToScreen(true)

	frame.castBar = CreateFrame("StatusBar", "LittleTroubleStatusBar", frame)
	frame.castBarText = frame.castBar:CreateFontString("LittleTroubleFontStringText", "OVERLAY")
	frame.castBarTimeText  = frame.castBar:CreateFontString("LittleTroubleFontStringTimeText", "OVERLAY")

	self:Layout()
end

function LittleTrouble:Layout()
	local db = self.db.profile
	local border = borders[self.db.profile.borderStyle]

	local frame = self.frame
	frame:SetWidth(db.width)
	frame:SetHeight(db.height)
	frame:SetScale(db.scale)

	frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		tile = true,
		tileSize = 16,
		edgeFile = border[1],
		edgeSize = border[2],
		insets = {
			left = border[3],
			right = border[3],
			top = border[3],
			bottom = border[3]
		},
	})

	frame:SetBackdropColor(unpack(db.colors.background))
	frame:SetBackdropBorderColor(unpack(db.colors.border))

	local font = SM:Fetch('font', db.font)

	local castBar = frame.castBar
	castBar:SetWidth(db.width - border[3] * 2)
	castBar:SetHeight(db.height - border[3] * 2)
	castBar:SetStatusBarTexture( SM:Fetch("statusbar", db.texture))
	castBar:SetStatusBarColor(unpack(db.colors.bar))
	castBar:SetMinMaxValues(0, 1)
	castBar:ClearAllPoints()
	castBar:SetPoint("CENTER", frame, "CENTER", 0, 0)

	local castBarText = frame.castBarText
	castBarText:SetJustifyH("CENTER")
	castBarText:SetFont( font, db.textSize )
	castBarText:SetTextColor(unpack(db.colors.text))
	castBarText:SetShadowOffset(.8, -.8)
	castBarText:SetShadowColor(0, 0, 0, 1)
	castBarText:ClearAllPoints()
	castBarText:SetAllPoints(castBar)

	local castBarTimeText = frame.castBarTimeText
	castBarTimeText:SetJustifyH("RIGHT")
	castBarTimeText:SetFont( font, db.timeSize )
	castBarTimeText:SetTextColor(unpack(db.colors.time))
	castBarTimeText:SetShadowOffset(.8, -.8)
	castBarTimeText:SetShadowColor(0, 0, 0, 1)
	castBarTimeText:ClearAllPoints()
	castBarTimeText:SetAllPoints(castBar)
end
