-- based on mutekiattitude.lua and mutekiattitude.xml from Monogusa:
-- https://github.com/Monogusa1244

local addonName = "CARDBUFF";
local addonNameLower = string.lower(addonName);

_G["ADDONS"] = _G["ADDONS"] or {};
_G["ADDONS"]["LIBRARIAN"] = _G["ADDONS"]["LIBRARIAN"] or {};
_G["ADDONS"]["LIBRARIAN"][addonName] = _G["ADDONS"]["LIBRARIAN"][addonName] or {};

local g = _G["ADDONS"]["LIBRARIAN"][addonName];
local acutil = require("acutil");

if not g.loaded then
	g.settings = {
		enable = true,
	};
end

g.settingsFileLoc = "../addons/cardbuffduration/settings.json";

-- 4506 = Glass Mole
-- 4508 = Chapparition
g.buffs = {};
g.buffs.cards = { [4506] = true, [4508] = true };
g.buffs.melstis = 3022;

function CARDBUFFDURATION_ON_INIT(addon, frame)
	local g = _G["ADDONS"]["LIBRARIAN"]["CARDBUFF"];
	local acutil = require("acutil");
	
	g.addon = addon;
	g.frame = frame;
	
	g.chapparition = false;
	g.glassmole = false;
	
	acutil.slashCommand("/cardbuff", CARD_BUFF_COMMAND);
	
	if not g.loaded then
		local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings);
	
		if err then
			acutil.saveJSON(g.settingsFileLoc, g.settings);
		else
			g.settings = t;
		end
		
		CHAT_SYSTEM("Card buff duration loaded.");

		g.loaded = true;
	end
	
	addon:RegisterMsg("BUFF_ADD", "CARD_BUFF_UPDATE");
	addon:RegisterMsg("BUFF_UPDATE", "CARD_BUFF_UPDATE");
	addon:RegisterMsg("BUFF_REMOVE", "CARD_BUFF_UPDATE");
	
	CARD_BUFF_INIT_UI(frame);
end

function CARD_BUFF_COMMAND(words)
	local g = _G["ADDONS"]["LIBRARIAN"]["CARDBUFF"];
	local acutil = require("acutil");
	local cmd = table.remove(words, 1);
	local frame = g.frame;
	
	if not cmd then
	elseif cmd == "on" then
		g.settings.enable = true;
		frame:ShowWindow(1);
		CHAT_SYSTEM("Card buff duration enabled.");
	elseif cmd == "off" then
		g.settings.enable = false;
		frame:ShowWindow(0);
		CHAT_SYSTEM("Card buff duration disabled.");
	end
end

function CARD_BUFF_CHECK_SHOW()
	local g = _G["ADDONS"]["LIBRARIAN"]["CARDBUFF"];
	
	if not g.settings.enable then	
		return;
	else
		g.frame:ShowWindow(1);
	end
end

function CARD_BUFF_INIT_UI(frame)
	frame:ShowWindow(1);
end

function CARD_EFFECT_UPDATE(msg, argNum)
	local g = _G["ADDONS"]["LIBRARIAN"]["CARDBUFF"];
	local frame = g.frame;
	
	CARD_BUFF_CHECK_SHOW();

	local gauge = GET_CHILD(frame, "gauge_" .. argNum, "ui::CGauge");

	if gauge then
		local handle = session.GetMyHandle();
		local buff = info.GetBuff(tonumber(handle), argNum);
		
		if msg == "BUFF_ADD" or msg == "BUFF_UPDATE" then
			local time = math.floor(buff.time / 1000);
			
			gauge:SetTotalTime(time);
			gauge:SetPoint(0, time);
			
			if g.melstis then
				gauge:StopTimeProcess();
			end
			
			gauge:ShowWindow(1);
		elseif msg == "BUFF_REMOVE" then
			gauge:StopTimeProcess();
			gauge:ShowWindow(0);
		end
	end
end

function CARD_EFFECT_MELSTIS_UPDATE(msg, argNum)
	local g = _G["ADDONS"]["LIBRARIAN"]["CARDBUFF"];
	local frame = g.frame;
	
	CARD_BUFF_CHECK_SHOW();

	for id, check_buff in pairs(g.buffs.cards) do
		if check_buff then
			local gauge = GET_CHILD(frame, "gauge_" .. id, "ui::CGauge");
			
			if gauge then
				local handle = session.GetMyHandle();
				
				if msg == "BUFF_ADD" or msg == "BUFF_UPDATE" then
					g.melstis = true;
					gauge:StopTimeProcess();
					gauge:SetColorTone("FFFF0000");
				elseif msg == "BUFF_REMOVE" then
					g.melstis = false;
					
					local curPoint = gauge:GetCurPoint();
					local maxPoint = gauge:GetMaxPoint();
					
					gauge:SetColorTone("FFFFFFFF");
					gauge:SetPoint(curPoint, maxPoint);
					gauge:SetPointWithTime(maxPoint, maxPoint - curPoint, 1);
				end
			end
		end
	end
end

function CARD_BUFF_UPDATE(frame, msg, argStr, argNum)
	if g.buffs.cards[argNum] then
		CARD_EFFECT_UPDATE(msg, argNum);
	elseif argNum == g.buffs.melstis then
		CARD_EFFECT_MELSTIS_UPDATE(msg, argNum);
	end
end
