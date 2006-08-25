--[[
    A big thanks to otravi and his castingbar, most of the bar code is taken 
	from his addon and warped for my evil purposes here.
--]]

local Default = {
    Bar = {
		width		= 255,
		height		= 25,
		timeSize	= 12,
		spellSize	= 12,
		delaySize	= 14,
    },
    aimedDelay	= 0.35,
	pos			= {}
}

local Colors = {
	complete	= {r=0, g=1, b=0},
	autoShot	= {r=1, g=.7, b=0},
	aimedShot	= {r=.3, g=.3, b=1},
	failed		= {r=1, g=0, b=0},
}

-- Local variables
local auraGain	= string.find( AURAADDEDSELFHELPFUL, "%%s" )
local auraFade	= string.gsub( AURAREMOVEDSELF, "%%s", "" )

local startTime, endTime, delay, duration
local aimedShot, autoShot, spellFailed, skipSpellCastStop
local fadeOut, thresHold, delayString
local rapidFire, quickShots, berserker = false, false, false

BigTrouble = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceDebug-2.0", "AceHook-2.0", "AceDB-2.0", "AceConsole-2.0")
local L = AceLibrary("AceLocale-2.0"):new("BigTrouble")

function BigTrouble:OnInitialize()
	
	local Options = {
		type = "group",
		args = {
			lock = {
				name = 'Lock', type = 'toggle', order = 1,
				desc = "Lock/Unlock the bar",
				get = function() return self.lock end,
				set = function( v )
					self.lock = v
					if( v ) then
						self.master:Hide()
						self.master:SetScript( "OnUpdate", self.OnUpdate )
					else
						self:StopAutoRepeatSpell()
						aimedShot = false
						
						self.master:SetScript( "OnUpdate", nil )
						self.master:Show()
						self.master.Bar:SetStatusBarColor(.3, .3, .3)
						self.master.Time:SetText("1.3")
						self.master.Delay:SetText("+0.8")
						self.master.Spell:SetText("Son of a bitch must pay!")
					end
				end,
				map = { [false] = "Unlocked", [true] = "Locked" }
			},
			bar = {
				name = "Bar", type = 'group', order = 2,
				desc = "Bar", 
				args = {
					width = {
						name = "Width", type = 'range', min = 10, max = 500, step = 1,
						desc = "Set the width of the casting bar.",
						get = function() return self.db.profile.Bar.width end,
						set = function( v )
							self.db.profile.Bar.width = v
							self:Layout()
						end
					},
					height = {
						name = "Height", type = 'range', min = 5, max = 50, step = 1,
						desc = "Set the height of the casting bar.",
						get = function() return self.db.profile.Bar.height end,
						set = function( v )
							self.db.profile.Bar.height = v
							self:Layout()
						end
					},
					font = {
						name = "Font", type = 'group',
						desc = "Set the font size of different elements.",
						args = {
							spell = {
								name = "Spell", type = 'range', min = 6, max = 32, step = 1,
								desc = "Set the font size on the spellname.",
								get = function() return self.db.profile.Bar.spellSize end,
								set = function( v )
									self.db.profile.Bar.spellSize = v
									self:Layout()
								end
							},
							time = {
								name = "Time", type = 'range', min = 6, max = 32, step = 1,
								desc = "Set the font size on the spell time.",
								get = function() return self.db.profile.Bar.timeSize end,
								set = function( v )
									self.db.profile.Bar.timeSize = v
									self:Layout()
								end
							},
							delay = {
								name = "Delay", type = 'range', min = 6, max = 32, step = 1,
								desc = "Set the font size on the delay time.",
								get = function() return self.db.profile.Bar.delaySize end,
								set = function( v )
									self.db.profile.Bar.delaySize = v
									self:Layout()
								end
							}
						}
					}
				}
			}
		}
	}


	self:RegisterDB("BigTroubleDB")
	self:RegisterDefaults('profile', Default)
	self:RegisterChatCommand( {"/btrouble"}, Options )
	
	self:SetDebugging(false)

end

function BigTrouble:OnEnable()

	self.lock = true
	self:CreateFrameWork()

	self.tooltip = CreateFrame("GameTooltip", "BigTroubleTooltip", nil, "GameTooltipTemplate")
	self.tooltip:SetOwner(self.tooltip, "ANCHOR_NONE")
	self.tooltip.GetText = function() if BigTroubleTooltipTextLeft1:IsVisible() then return BigTroubleTooltipTextLeft1:GetText() end end

	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS", "PeriodicSelfBuffs")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "AuraGoneSelf")
	self:RegisterEvent("START_AUTOREPEAT_SPELL", "StartAutoRepeatSpell")
	self:RegisterEvent("STOP_AUTOREPEAT_SPELL", "StopAutoRepeatSpell")
	self:RegisterEvent("SPELLCAST_INTERRUPTED","SpellInterrupted")
	self:RegisterEvent("SPELLCAST_FAILED", "SpellFailed")
	self:RegisterEvent("SPELLCAST_DELAYED", "SpellCastDelayed")
	self:RegisterEvent("SPELLCAST_STOP", "SpellCastStop")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "PlayerEnteringWorld")

	self:Hook("UseAction")
	self:Hook("CastSpell")
	self:Hook("CastSpellByName")

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
    
	self.master:SetScript( "OnUpdate", self.OnUpdate )
	self.master:SetMovable(true)
	self.master:EnableMouse(true)
	self.master:RegisterForDrag("LeftButton")
	self.master:SetScript("OnDragStart", function() if not self.lock then self["master"]:StartMoving() end end)
	self.master:SetScript("OnDragStop", function() self["master"]:StopMovingOrSizing() self:SavePosition() end)

	self.master.Bar   = CreateFrame("StatusBar", nil, self.master)
	self.master.Spark = self.master.Bar:CreateTexture(nil, "OVERLAY")
	self.master.Time  = self.master.Bar:CreateFontString(nil, "OVERLAY")
	self.master.Spell = self.master.Bar:CreateFontString(nil, "OVERLAY")
	self.master.Delay = self.master.Bar:CreateFontString(nil, "OVERLAY")
    
    self:Layout()

end

function BigTrouble:Layout()

	local db = self.db.profile.Bar
	local gameFont, _, _ = GameFontHighlightSmall:GetFont()
    
	self.master:SetWidth( db.width + 9 )
	self.master:SetHeight( db.height + 10 )

	self.master:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		edgeSize = 16,
		insets = {left = 5, right = 5, top = 5, bottom = 5},
	})

    self.master:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b)
	self.master:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b)

	self.master.Bar:ClearAllPoints()
	self.master.Bar:SetPoint("CENTER", self.master, "CENTER", 0, 0)
	self.master.Bar:SetWidth( db.width )
	self.master.Bar:SetHeight( db.height )
	self.master.Bar:SetStatusBarTexture( "Interface\\TargetingFrame\\UI-StatusBar" )

	self.master.Spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	self.master.Spark:SetWidth(16)
	self.master.Spark:SetHeight( db.height + 25 )
	self.master.Spark:SetBlendMode("ADD")

	self.master.Time:SetJustifyH("RIGHT")
	self.master.Time:SetFont( gameFont, db.timeSize )
	self.master.Time:SetText("X.Y")
	self.master.Time:ClearAllPoints()
	self.master.Time:SetPoint("RIGHT", self.master.Bar, "RIGHT",-10,0)

	self.master.Spell:SetJustifyH("CENTER")
	self.master.Spell:SetWidth( db.width - self.master.Time:GetWidth() )
	self.master.Spell:SetFont( gameFont, db.spellSize )
	self.master.Spell:ClearAllPoints()
	self.master.Spell:SetPoint("LEFT", self.master, "LEFT",10,0)

	self.master.Delay:SetTextColor(1,0,0,1)
	self.master.Delay:SetJustifyH("RIGHT")
	self.master.Delay:SetFont( gameFont, db.delaySize )
	self.master.Delay:SetText("X.Y")
	self.master.Delay:ClearAllPoints()
	self.master.Delay:SetPoint("TOPRIGHT", self.master.Bar, "TOPRIGHT",-10,20)

	self:SetPosition()

end

function BigTrouble:UseAction( id, book, onself )

	self.tooltip:SetAction( id )
	local name = self.tooltip.GetText()

	spellFailed = false
	self.hooks["UseAction"].orig( id, book, onself )
	if spellFailed then return end

	if( name == L"Aimed Shot" and not aimedShot ) then
		self:AimedShot()
	elseif( name ~= L"Auto Shot" ) then
		skipSpellCastStop = true
	end

end

function BigTrouble:CastSpell( id, book )

	local name = GetSpellName( id, book )

	spellFailed = false
	self.hooks["CastSpell"].orig( id, book )
	if spellFailed then return end

	if( name == L"Aimed Shot" and not aimedShot ) then
		self:AimedShot()
	elseif( name ~= L"Auto Shot" ) then
		skipSpellCastStop = true
	end

end

function BigTrouble:CastSpellByName( spellName )

	local _, _, name = string.find( spellName, "([%w%s]+)" )

	spellFailed = false
	self.hooks["CastSpellByName"].orig( spellName )
	if spellFailed then return end

	if( name == L"Aimed Shot" and not aimedShot ) then
		self:AimedShot()
	elseif( name ~= L"Auto Shot" ) then
		skipSpellCastStop = true
	end

end

function BigTrouble:AimedShot()

	skipSpellCastStop = true
	aimedShot = true
	
	local aimedDuration = 3

	if( rapidFire ) then aimedDuration = aimedDuration / 1.4 end
	if( quickShots ) then aimedDuration = aimedDuration / 1.3 end

	--[[ 
		The formula for calculating Berserking Haste value was taken from the 
		BerserkMeter Addon by Axelrod of Mannoroth (axelrod@deschi.com)
	--]]
	if( berserker ) then
		local percentHealth = (UnitHealth("player") / UnitHealthMax("player")) * 100
		local berserkValue = ( 130 / 3 ) - (( 1 / 3 ) * percentHealth )
		if( berserkValue > 30 ) then berserkValue = 30 end
		local multiplier = 1 / ( 1 + ( berserkValue / 100 ))
		aimedDuration = aimedDuration * multiplier
	end

	duration = aimedDuration + self.db.profile.aimedDelay
	
	self.master.Bar:SetStatusBarColor( Colors.aimedShot.r, Colors.aimedShot.g, Colors.aimedShot.b )
	self:BarCreate(L"Aimed Shot")

end

function BigTrouble:BarCreate(s)

	startTime = GetTime()
	endTime = startTime + duration

	self.master.Bar:SetMinMaxValues( startTime, endTime )
	self.master.Bar:SetValue( startTime )
	self.master.Spell:SetText(s)
	self.master:SetAlpha(1)
	self.master.Time:SetText("")
	self.master.Delay:SetText("")

	delay = 0
	fadeOut	= false
	thresHold = false

	self.master:Show()
	self.master.Spark:Show()

end

function BigTrouble:OnUpdate()

	local self = BigTrouble

	if( ( aimedShot or autoShot ) and not thresHold ) then
		local currentTime = GetTime()
	
		if( currentTime > endTime ) then
			currentTime = endTime
			thresHold = true

			if( aimedShot ) then 
                aimedShot = false 
                self.master.Bar:SetStatusBarColor( Colors.complete.r, Colors.complete.g, Colors.complete.b )
            end
		end

		self.master.Time:SetText(string.format( "%.1f", ( endTime - currentTime )))
		if( delay ~= 0 ) then self.master.Delay:SetText( delayString ) end
		self.master.Bar:SetValue( currentTime )

		local sparkProgress = (( currentTime - startTime ) / ( endTime - startTime )) * self.db.profile.Bar.width
		self.master.Spark:SetPoint("CENTER", self["master"]["Bar"], "LEFT", sparkProgress, 0)

	elseif( fadeOut ) then
		local a = self.master:GetAlpha() - .05

		if( a > 0 ) then
			self.master:SetAlpha(a)
		else
			fadeOut = false
			
			self.master:Hide()
			self.master.Time:SetText("")
			self.master.Delay:SetText("")
			self.master:SetAlpha(1)
		end
	end

end

--[[
	Stupid fix for reseting state when zoning and AutoShot or
	Aimed Shot is casting
--]]
function BigTrouble:PlayerEnteringWorld()

	autoShot = false
	fadeOut = false
	aimedShot = false
	
	if( self.lock ) then self.master:Hide() end

end

function BigTrouble:SpellCastStop()

	if( skipSpellCastStop ) then skipSpellCastStop = false return end

	if( autoShot and not aimedShot ) then
		duration = UnitRangedDamage("player")
		self.master.Bar:SetStatusBarColor( Colors.autoShot.r, Colors.autoShot.g, Colors.autoShot.b )
		self:BarCreate(L"Auto Shot") 
	end

end

function BigTrouble:SpellInterrupted()

	if aimedShot then aimedShot = false end
	if( self.master:IsShown() ) then
		self.master.Spark:Hide()

		self.master.Spell:SetText(L"Interrupted")
		if not autoShot then fadeOut = true end

		self.master.Bar:SetStatusBarColor( Colors.failed.r, Colors.failed.g, Colors.failed.b )
	end

end

function BigTrouble:SpellFailed()

	spellFailed = true

	--[[ 
		If we are still doing an Auto Shot while getting a SpellFailed
		it means we failed either a Aimed Shot or a sting during a cycle
		this we can safley ignore and just return from it.
		
		The exception to this being if were in the middle of an Aimed Shot and
		were still also Auto Shoting
	--]]
	if autoShot and not aimedShot then return end
    
	aimedShot = false

	--[[
		We use this to check if we are actaully shooting anything, this since
		autoShot is turned off before this event gets called and hence cannot
		be used to check that we are doing something
	--]]
	if( self.master:IsShown() ) then
		self.master.Spark:Hide()
		self.master.Spell:SetText(L"Failed")
		fadeOut = true
		self.master.Bar:SetStatusBarColor( Colors.failed.r, Colors.failed.g, Colors.failed.b )
	end

end

function BigTrouble:SpellCastDelayed( d )

	if( self.master:IsShown() ) then
		d = d / 1000

		startTime = startTime + d
		endTime = endTime + d
		delay = delay + d
        
        delayString = "+"..string.format( "%.1f", delay )
        
		self.master.Bar:SetMinMaxValues( startTime, endTime )
	end

end

function BigTrouble:PeriodicSelfBuffs( name )

	local _,_, match = string.find( name, "([%w%s]+)%.", auraGain)

	if( match == L"Rapid Fire" ) then
		rapidFire = true
	elseif( match == L"Quick Shots" ) then
		quickShots = true
	elseif( match == L"Berserking" ) then
		berserker = true
	end

end

function BigTrouble:AuraGoneSelf( name )

	local match = string.gsub( name, auraFade, "" )

	if( match == L"Rapid Fire" ) then
		rapidFire = false
	elseif( match == L"Quick Shots" ) then
		quickShots = false
	elseif( match == L"Berserking" ) then
		berserker = false
	end
	
end

function BigTrouble:StartAutoRepeatSpell()

	autoShot = true

end

function BigTrouble:StopAutoRepeatSpell()

	autoShot = false
	fadeOut = true

end