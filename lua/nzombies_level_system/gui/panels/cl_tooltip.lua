local PANEL = {}

function PANEL:Init()
	self:SetDrawOnTop(true)
	self.DeleteContentsOnClose = false
	self:SetText("")
	self:SetFont("Default")
	self:SetSkin("BloodyNazis")
end

function PANEL:GenerateExample(class_name, property_sheet, w, h)
	local button = vgui.Create("DButton")
	
	button:SetSkin("BloodyNazis")
	button:SetText("Hover me")
	button:SetTooltipPanelOverride("NZLSToolTip")
	button:SetTooltip("This is a tooltip with the skin forced to BloodyNazis")
	button:SetWide(200)
	
	property_sheet:AddSheet(class_name, button, nil, true, true)
end

derma.DefineControl("NZLSToolTip", "DTooltip with the skin forced to the BloodyNazis skin.", PANEL, "DTooltip")