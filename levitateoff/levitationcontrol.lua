function LEVITATIONCONTROL_ON_INIT(addon, frame)
	_G["_LEVITATION_ICON_USE"] = _G["ICON_USE"];
	_G["ICON_USE"] = LEVITATION_USE;
end

function LEVITATION_OFF()
	local handle = session.GetMyHandle();

	local buffCount = info.GetBuffCount(handle);

	for i = 0, buffCount - 1 do
		local buff = info.GetBuffIndexed(handle, i);
		
		if buff.buffID == 3070 then
			packet.ReqRemoveBuff(buff.buffID);
	
			return true;
		end
	end
	
	return false;
end

function LEVITATION_USE(object, reAction)
	local iconPt = object;

	if iconPt ~= nil then
		local icon = tolua.cast(iconPt, "ui::CIcon");
		local iconInfo = icon:GetInfo();
		local skillInfo = session.GetSkill(iconInfo.type);
	
		if skillInfo ~= nil then
			local sklObj = GetIES(skillInfo:GetObject());
		
			if sklObj.ClassID == 21107 then			
				if LEVITATION_OFF() == true then
					return;
				end
			end
		end
	end
	
	_G["_LEVITATION_ICON_USE"](object, reAction);
end
