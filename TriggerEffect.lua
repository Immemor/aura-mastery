require "Window"

local TriggerEffect  = {} 
TriggerEffect .__index = TriggerEffect

setmetatable(TriggerEffect, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function TriggerEffect.new(trigger, effectType)
	local self = setmetatable({}, TriggerEffect)
	self.Trigger = trigger
	self.Type = effectType or "Icon Color"
	self.When = "Pass"
	self.triggerStarted = true
	self.triggerTime = 0

	self:Init()
	return self
end

function TriggerEffect:SetDefaultConfig()
	if self.Type == "Icon Color" then
		self.EffectDetails = {
		Color = { r = 1, g = 0, b = 0, a = 1 }
		}
	elseif self.Type == "Activation Border" then
		self.EffectDetails = {
			BorderSprite = "CRB_ActionBarIconSprites:sprActionBar_YellowBorder"
		}
	end
end

function TriggerEffect:Load(saveData)
	if saveData ~= nil then
		self.Type = saveData.Type
		self.EffectDetails = saveData.EffectDetails
		self.When = saveData.When
		self:Init()
	end
end

function TriggerEffect:Init()
	if self.Type == "Activation Border" then
		self.activationBorder = Apollo.LoadForm("AuraMastery.xml", "IconEffectModifiers.ActivationBorder", self.Trigger.Icon.icon, self)
		self.activationBorder:SetSprite(self.EffectDetails.BorderSprite)
		self.activationBorder:Show(false)
	end
end

function TriggerEffect:Save()
	local saveData = { }
	saveData.Type = self.Type
	saveData.When = self.When
	saveData.EffectDetails = self.EffectDetails
	return saveData
end

function TriggerEffect:SetConfig(configWnd)
	if configWnd:FindChild("TriggerEffectOnFail"):IsChecked() then
		self.When = "Fail"
	else
		self.When = "Pass"
	end

	if self.Type == "Icon Color" then
		self.EffectDetails = {
			Color = configWnd:FindChild("IconColor"):FindChild("ColorSample"):GetBGColor():ToTable()
		}
	elseif self.Type == "Activation Border" then
		for _, border in pairs(configWnd:FindChild("BorderSelect"):GetChildren()) do
			Print(border:GetName())
			if border:IsChecked() then
				self.EffectDetails = {
					BorderSprite = border:FindChild("Window"):GetSprite()
				}
				self.activationBorder:SetSprite(self.EffectDetails.BorderSprite)
				break
			end
		end
	end
end

function TriggerEffect:Update(triggerPassed)
	if (self.When == "Pass" and triggerPassed) or (self.When == "Fail" and not triggerPassed) then
		if self.Type == "Icon Color" then
			self:UpdateIconColor()
		elseif self.Type == "Flash" or self.Type == "Activation Border" then
			self:UpdateTimed()
		end
	else
		if self.Type == "Flash" or self.Type == "Activation Border" then
			if self.Type == "Activation Border" then
				self:StopActivationBorder()
			end
			self:EndTimed()
		end
	end
end

function TriggerEffect:UpdateIconColor()
	self.Trigger.Icon:SetIconColor(self.EffectDetails.Color)
end

function TriggerEffect:UpdateTimed()
	if not self.triggerStarted then
		self.triggerStarted = true
		self.triggerTime = os.clock()
	end

	if os.clock() - self.triggerTime < 5 then
		if self.Type == "Flash" then
			self:UpdateFlash()
		elseif self.Type == "Activation Border" then
			self:UpdateActivationBorder()
		end
	else
		if self.Type == "Activation Border" then
			self:StopActivationBorder()
		end
	end
end

function TriggerEffect:UpdateFlash()
	local iconColor = self.Trigger.Icon.icon:GetBGColor():ToTable()
	iconColor.a = math.abs(math.sin((os.clock() - self.triggerTime)*2))
	self.Trigger.Icon:SetIconColor(iconColor)
end

function TriggerEffect:UpdateActivationBorder()
	self.activationBorder:Show(true)
end

function TriggerEffect:StopActivationBorder()
	self.activationBorder:Show(false)
end

function TriggerEffect:EndTimed()
	self.triggerStarted = false
end

local GeminiPackages = _G["GeminiPackages"]
GeminiPackages:NewPackage(TriggerEffect, "AuraMastery:TriggerEffect", 1)