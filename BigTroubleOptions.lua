BigTrouble.options = {
	type = "group",
	args = {
        lock = {
            name = "Lock",
            type = "toggle",
            desc = "Lock/Unlock BigTrouble.",
            get = "ToggleLocked",
            set = "ToggleLocked",
            map = {[false] = "Unlocked", [true] = "Locked"},
            guiNameIsMap = true,
        },
		bar = {
			name = "Bar", 
			type = 'group', 
			order = 2,
			desc = "Bar", 
			args = {
				border = {
					name = "Border",
					type = 'toggle',
					desc = "Toggle borders BigTrouble",
		            get = function() return self.opt.Bar.border end,
		            set = function(v) self.opt.Bar.border = v	end,
		            map = {[false] = "Off", [true] = "On"},
		            guiNameIsMap = true,
				},
				width = {
					name = "Width", 
					type = 'range', 
					min = 10, 
					max = 500, 
					step = 1,
					desc = "Set the width of BigTrouble.",
		            get = function() return self.opt.Bar.width end,
		            set = function(v) self.opt.Bar.width = v	end,
				},
				height = {
					name = "Height", 
					type = 'range', 
					min = 5, 
					max = 50, 
					step = 1,
					desc = "Set the height of BigTrouble.",
		            get = function() return self.opt.Bar.height end,
		            set = function(v) self.opt.Bar.height = v	end,
				},
				font = {
					name = "Font",
					type = 'group',
					desc = "Set the font size of BigTrouble.",
					args = {
						spell = {
							name = "Spell", 
							type = 'range', 
							min = 6, 
							max = 32,
							step = 1,
							desc = "Set the font size of the spellname.",
                            get = function() return self.opt.Bar.spellSize end,
                            set = function(v) self.opt.Bar.spellSize = v	end,
						},
						time = {
							name = "Time", 
							type = 'range', 
							min = 6, 
							max = 32, 
							step = 1,
							desc = "Set the font size of the spell time.",
                            get = function() return self.opt.Bar.timeSize end,
                            set = function(v) self.opt.Bar.timeSize = v	end,
						},
						delay = {
							name = "Delay", 
							type = 'range', 
							min = 6, 
							max = 32, 
							step = 1,
							desc = "Set the font size on the delay time.",
                            get = function() return self.opt.Bar.delaySize end,
                            set = function(v) self.opt.Bar.delaySize = v	end,
						}
					}
				}
			}
		}
	}
}

function BigTrouble:ToggleLocked( value )

    if not value then return self.locked end
    self.locked = value

	if( value ) then
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
	
end