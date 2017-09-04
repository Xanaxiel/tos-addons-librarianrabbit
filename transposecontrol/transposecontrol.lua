local TRANSPOSECONTROL_LOADED = false;

function TRANSPOSECONTROL_ON_INIT(addon, frame)
	if TRANSPOSECONTROL_LOADED == false then
		_G["_TRANSPOSE_ICON_USE"] = _G["ICON_USE"];

		TRANSPOSECONTROL_LOADED = true;
	end
	
	if _G["ICON_USE"] ~= TRANSPOSE_USE then
		_G["ICON_USE"] = TRANSPOSE_USE;
	end
end

function TRANSPOSE_OFF()
	local handle = session.GetMyHandle();

	local buffCount = info.GetBuffCount(handle);

	for i = 0, buffCount - 1 do
		local buff = info.GetBuffIndexed(handle, i);
		
		if buff.buffID == 167 then
			packet.ReqRemoveBuff(buff.buffID);
	
			return true;
		end
	end
	
	return false;
end

function TRANSPOSE_USE(object, reAction)
	local iconPt = object;

	if iconPt ~= nil then
		local icon = tolua.cast(iconPt, "ui::CIcon");
		local iconInfo = icon:GetInfo();
		local skillInfo = session.GetSkill(iconInfo.type);
	
		if skillInfo ~= nil then
			local sklObj = GetIES(skillInfo:GetObject());
		
			if sklObj.ClassID == 20504 then			
				if TRANSPOSE_OFF() == true then
					return;
				end
			end
		end
	end
	
	_G["_TRANSPOSE_ICON_USE"](object, reAction);
end
