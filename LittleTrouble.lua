local SM = AceLibrary("SharedMedia-1.0")
SM:Register("statusbar", "BantoBar", "Interface\\AddOns\\LittleTrouble\\textures\\BantoBar.tga")
SM:Register("statusbar", "Glaze", "Interface\\AddOns\\LittleTrouble\\textures\\glaze.tga")
SM:Register("statusbar", "Gloss", "Interface\\AddOns\\LittleTrouble\\textures\\Gloss.tga")
SM:Register("statusbar", "Perl", "Interface\\AddOns\\LittleTrouble\\textures\\perl.tga")
SM:Register("statusbar", "Smooth", "Interface\\AddOns\\LittleTrouble\\textures\\smooth.tga")

LittleTrouble = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceDB-2.0", "AceConsole-2.0")

local localeTables = {}
function LittleTrouble:L(name)
	if not localeTables[name] then
		localeTables[name] = setmetatable({}, {__index = function(self, key)
			self[key] = key
			return key
		end})
	end
	return localeTables[name]
end

local L = LittleTrouble:L("LittleTrouble")
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
	["Auto Shot"] = "Autom. Schuss",
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

local Dewdrop = AceLibrary("Dewdrop-2.0")

local isAutoShot, endTime, startTime, fade
local locked = true

local defaults = {
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
					LittleTrouble.frame:SetScript( "OnUpdate", LittleTrouble.OnCasting )
				end
			end,
		},
		texture = {
			name = L["Texture"],
			desc = L["Texture setting."],
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
			desc = L["Texture setting."],
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
			desc = L["Border settings."],
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
					desc = L["Scale"],
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
					desc = L["Width"],
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
					desc = L["Height"],
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
					desc = L["Disables bar text."],
					type = 'toggle',
					get = function() return LittleTrouble.db.profile.textDisable end,
					set = function(v) LittleTrouble.db.profile.textDisable = v end,
				},
				height = {
					name = L["Font height"], 
					desc = L["Font height."],
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
					desc = L["Disables bar time."],
					type = 'toggle',
					get = function() return LittleTrouble.db.profile.timeDisable end,
					set = function(v) LittleTrouble.db.profile.timeDisable = v end,
				},
				time = {
					name = L["Font height"], 
					desc = L["Font height."],
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
				time = {
					name = L["Time"], 
					desc = L["Time"],
					type = 'color',
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
					desc = L["Text"],
					type = 'color',
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
					desc = L["Bar"],
					type = 'color',
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
					desc = L["Background"],
					type = 'color',
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
					desc = L["Border"],
					type = 'color',
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

function LittleTrouble:OnEnable()
	Dewdrop:InjectAceOptionsTable(self, options)
	self:RegisterChatCommand('/ltrouble', {
		type = 'execute',
		func = function()
			Dewdrop:Open("LittleTrouble")
		end
	})
	Dewdrop:Register("LittleTrouble",
		'children', options,
		'cursorX', true,
		'cursorY', true
	)

	self:CreateFrameWork()

	self:RegisterEvent("START_AUTOREPEAT_SPELL")
	self:RegisterEvent("STOP_AUTOREPEAT_SPELL")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_START")
end

function LittleTrouble:UNIT_SPELLCAST_START( unit )
	if unit ~= "player" then return end
	local name, _, _, _, _, _, _ = UnitCastingInfo(unit)
	if name == LS["Aimed Shot"] then
		fade = true
		isAutoShot = false
	end
end

function LittleTrouble:UNIT_SPELLCAST_SUCCEEDED( unit, spell, rank )
	if unit ~= "player" then return end
	if spell ~= LS["Auto Shot"] and spell ~= LS["Aimed Shot"] then return end

	startTime = GetTime()
	endTime = startTime + UnitRangedDamage("player")
	fade = false
	isAutoShot = true

    local frame = self.frame
	frame:SetAlpha(1)

	frame.castBar:SetMinMaxValues(startTime, endTime)
	frame.castBar:SetValue(startTime)
	if not self.db.profile.textDisable then
		frame.castBarText:SetText(LS["Auto Shot"])
	else
		frame.castBarText:SetText("")
	end
	frame.castBarTimeText:SetText("")
	frame:Show()
end

function LittleTrouble:START_AUTOREPEAT_SPELL()
	fade = false
	isAutoShot = true
end

function LittleTrouble:STOP_AUTOREPEAT_SPELL()
	fade = true
	isAutoShot = false
end

function LittleTrouble:OnCasting()
	if isAutoShot then
		local currentTime = GetTime()

		if currentTime > endTime then
			currentTime = endTime
			isAutoShot = false
			fade = true
		end

		LittleTrouble.frame.castBar:SetValue(currentTime)
		if not LittleTrouble.db.profile.timeDisable then
			LittleTrouble.frame.castBarTimeText:SetText(("%.1f"):format(endTime - currentTime))
		end
	elseif fade then
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

	frame:SetScript( "OnUpdate", self.OnCasting )
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

	self.frame:SetBackdrop({
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