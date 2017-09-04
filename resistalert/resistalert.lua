local RESISTALERT_LOADED = false;

function RESISTALERT_ON_INIT(addon, frame)
	if RESISTALERT_LOADED == false then
		_G["_RESIST_ALERT_SHOW_SKILL_EFFECT"] = _G["SHOW_SKILL_EFFECT"];

		RESIST_ALERT_LOAD_SETTINGS();
		
		local acutil = require("acutil");
		
		acutil.slashCommand("/resist", RESIST_ALERT_COMMANDS);
		
		ui.SysMsg("Resist Alert loaded.");

		RESISTALERT_LOADED = true;
	end

	addon:RegisterMsg("FPS_UPDATE", "RESIST_ALERT_UPDATE");

	if _G["SHOW_SKILL_EFFECT"] ~= RESIST_ALERT_SHOW_SKILL_EFFECT then
		_G["SHOW_SKILL_EFFECT"] = RESIST_ALERT_SHOW_SKILL_EFFECT;
	end
end

function RESIST_ALERT_COMMANDS(command)
	local cmd = "";
	
	if #command > 0 then
		cmd = string.lower(table.remove(command, 1));
		
		if cmd == "balloon" then
			if _G["RESIST_ALERT"]["settings"].balloon == true then
				_G["RESIST_ALERT"]["settings"].balloon = false;
			else
				_G["RESIST_ALERT"]["settings"].balloon = true;
			end
		elseif cmd == "effect" then
			if _G["RESIST_ALERT"]["settings"].effect == true then
				_G["RESIST_ALERT"]["settings"].effect = false;
			else
				_G["RESIST_ALERT"]["settings"].effect = true;
			end
		elseif cmd == "seconds" then
			if #command > 0 then
				local arg1 = string.lower(table.remove(command, 1));
				
				if tonumber(arg1) then
					_G["RESIST_ALERT"]["settings"].seconds = tonumber(arg1);
				else
					_G["RESIST_ALERT"]["settings"].seconds = 1;
				end
			end
		end
	else
		local msg = "";

		msg = msg .. "Commands available:{nl}";
		msg = msg .. "{nl}";
		msg = msg .. "/resist ballon{nl}";
		msg = msg .. "/resist effect{nl}";
		msg = msg .. "/resist seconds N{nl}";

		return ui.MsgBox(msg, "", "Nope");
	end
end

function RESIST_ALERT_GET_FILENAME()
	return "../addons/resistalert/settings.json";
end

function RESIST_ALERT_LOAD_SETTINGS()
	_G["RESIST_ALERT"] = _G["RESIST_ALERT"] or {};

	local acutil = require("acutil");
	local settings, error = acutil.loadJSON(RESIST_ALERT_GET_FILENAME());
	
	if error then
		RESIST_ALERT_SAVE_SETTINGS();
	else
		_G["RESIST_ALERT"]["settings"] = settings;
	end
end

function RESIST_ALERT_SAVE_SETTINGS()
	_G["RESIST_ALERT"] = _G["RESIST_ALERT"] or {};
	
	if _G["RESIST_ALERT"]["settings"] == nil then
		_G["RESIST_ALERT"]["settings"] = {
			balloon	= true;
			effect = true;
			seconds = 1;
		};
	end

	local acutil = require("acutil");
	acutil.saveJSON(RESIST_ALERT_GET_FILENAME(), _G["RESIST_ALERT"]["settings"]);
end

function RESIST_ALERT_SHOW_SKILL_EFFECT(arg, argString)
	if _G["RESIST_ALERT"]["settings"].balloon == true then
		RESIST_ALERT_SHOW_BALLOON();
	end

	if _G["RESIST_ALERT"]["settings"].effect == true then
		if argString == "Debuff_Resister" then
			return string.format("This character or monster resisted a debuff.");
		end
	end

	_RESIST_ALERT_SHOW_SKILL_EFFECT(arg, argString);
end

function RESIST_ALERT_SHOW_BALLOON()
	local frame = ui.GetFrame("resistalert");
	frame:SetUserValue("resist_time", imcTime.GetAppTime());
	frame:ShowWindow(1);
end

function RESIST_ALERT_HIDE_BALLOON()
	local frame = ui.GetFrame("resistalert");
	frame:SetUserValue("resist_time", 0);
	frame:ShowWindow(0);
end

function RESIST_ALERT_UPDATE()
	local frame = ui.GetFrame("resistalert");
	
	if frame:IsVisible() == 1 then
		if (imcTime.GetAppTime() - frame:GetUserValue("resist_time")) > _G["RESIST_ALERT"]["settings"].seconds then
			RESIST_ALERT_HIDE_BALLOON();
		else
			FRAME_AUTO_POS_TO_OBJ(frame, GetMyActor():GetHandleVal(), -frame:GetWidth() * 1.5, -frame:GetHeight() / 2, 3, 1);
		end
	end
end
