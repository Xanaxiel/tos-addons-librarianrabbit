-- meta
local addon_dev = "LUNAR";
local addon_name = "ASPDMETER";
local addon_name_tag = "ASPDMeter";
local addon_name_lower = string.lower(addon_name);

-- dependencies
local acutil = require("acutil");

-- globals: general
_G["ADDONS"] = _G["ADDONS"] or {};
_G["ADDONS"][addon_dev] = _G["ADDONS"][addon_dev] or {};
_G["ADDONS"][addon_dev][addon_name] = _G["ADDONS"][addon_dev][addon_name] or {};

local g = _G["ADDONS"][addon_dev][addon_name];

-- globals: hooks
g["HOOKS"] = g["HOOKS"] or {};
g["HOOK_TABLE"] = g["HOOK_TABLE"] or {};

local hooks = g["HOOKS"];
local hook_table = g["HOOK_TABLE"];

-- locals: runtime vars
local aspd_timeframes = {1, 5, 10}; -- seconds
local aspd_timer = {};
local aspd_watcher = {};

-- addon: runtime vars
g.addon = nil;
g.frame = nil;
g.loaded = false;

-- addon: settings
g.settings_filename = "../addons/" .. addon_name_lower .. "/settings.json";
g.settings = {};

-- functions: settings
function ASPDMETER_SETTINGS_DEFAULT()
	g.settings = {};
	g.settings.enabled = true;
end

function ASPDMETER_SETTINGS_LOAD()
	local data, err = acutil.loadJSON(g.settings_filename);

	if err then
		ASPDMETER_SETTINGS_DEFAULT();
	else
		g.settings = data;
	end

	ASPDMETER_SETTINGS_SAVE();
end

function ASPDMETER_SETTINGS_SAVE()
	acutil.saveJSON(g.settings_filename, g.settings);
end

-- functions: commands
function ASPDMETER_COMMANDS()
	acutil.slashCommand("/aspd", ASPDMETER_COMMANDS_OP);
end

function ASPDMETER_COMMANDS_OP(args)
	local op = "";

	if #args > 0 then
		op = string.lower(table.remove(args, 1));

		if op == "on" or op == "off" then
			ASPDMETER_COMMANDS_ON_OFF(args);
		end
	end

	-- default action:
	-- toggle
	ASPDMETER_COMMANDS_ON_OFF(nil);
end

function ASPDMETER_COMMANDS_ON_OFF(args)
	-- args:
	-- 1) 'on' or 'off' or nil

	local state_change = 0; -- 2 = enabled, 1 = disabled, 0 = unchanged
	local on_off = table.remove(args, 1);

	if on_off ~= nil and on_off ≃ "" then
		on_off = string.lower(on_off);
	end

	if on_off == "on" then
		if g.enabled == false then
			state_change = 2;
		end

		g.enabled = true;
	elseif on_off == "off" then
		if g.enabled == false then
			state_change = 1;
		end

		g.enabled = false;
	else
		if g.enabled == true then
			g.enabled = false;
			state_change = 1;
		else
			g.enabled = true;
			state_change = 2;
		end
	end

	if state_change == 2 then
		-- enabled
		CHAT_SYSTEM("[" .. addon_name_tag .. "] enabled.");

		ASPDMETER_SETTINGS_SAVE();
	elseif state_change == 1 then
		-- disabled
		CHAT_SYSTEM("[" .. addon_name_tag .. "] disabled.");

		ASPDMETER_SETTINGS_SAVE();
	end
end

-- functions: hooks
function ASPDMETER_HOOKS_INIT(source, target)
	if hook_table[source] == nil then
		hook_table[source] = target;
	end
end

function ASPDMETER_HOOKS()
	-- template:
	-- ASPDMETER_HOOKS_INIT("{HOOK_SOURCE}", {HOOK_TARGET});

	-- Save hook sources only once
	if g.loaded == false then
		for hook, _ in pairs(hook_table) do
			hooks[hook] = _G[hook];
		end
	end

	-- Set hook targets
	for hook, fn in pairs(hook_table) do
		if _G[hook] ~= fn then
			_G[hook] = fn;
		end
	end
end

-- functions: messages
function ASPDMETER_MESSAGES_INIT(message, target)
	if g.addon == nil then
		return;
	end

	g.addon:RegisterMsg(message, target);
end

function ASPDMETER_MESSAGES()
	-- template:
	-- ASPDMETER_MESSAGES_INIT("{MESSAGE_MSG}", {MESSAGE_TARGET});
	-- MSG list: ui.ipf/uixml/addonmessage.xml
	-- common MSG: FPS_UPDATE,GAME_START_3SEC

	ASPDMETER_MESSAGES_INIT("SHOT_START", ASPDMETER_ON_SHOT_START);
	ASPDMETER_MESSAGES_INIT("FPS_UPDATE", ASPDMETER_ON_FPS_UPDATE);
end

-- functions: loader
function ASPDMETER_ON_INIT(addon, frame)
	g.addon = addon;
	g.frame = frame;

	ASPDMETER_SETTINGS_LOAD();

	ASPDMETER_COMMANDS();

	ASPDMETER_HOOKS();
	ASPDMETER_MESSAGES();

	if g.loaded == false then
		g.loaded = true;
	end

	ASPDMETER_MAIN();
end

-- functions: main
function ASPDMETER_MAIN()
	for _,timeframe in pairs(aspd_timeframes) do
		aspd_watcher[timeframe] = 0;
		aspd_timer[timeframe] = imcTime.GetAppTime();
	end

	g.frame:RunUpdateScript("ASPDMETER_UPDATE");
	g.frame:ShowWindow(0);
end

function ASPDMETER_UPDATE()
	for _,timeframe in pairs(aspd_timeframes) do
		if (imcTime.GetAppTime() - aspd_timer[timeframe]) >= timeframe then
			ASPDMETER_UPDATE_UI();

			aspd_watcher[timeframe] = 0;
			aspd_timer[timeframe] = imcTime.GetAppTime();
		end
	end
end

function ASPDMETER_UPDATE_UI()
	local msg = "ASPD Meter";

	for timeframe,watcher in pairs(aspd_watcher) do
		msg = msg .. string.format("{nl}%d sec: %d hits (%d avg hit/s)", timeframe, watcher, watcher/timeframe);
	end

	local aspd_meter = GET_CHILD(g.frame, "aspd_meter", "ui::CRichText");
	aspd_meter:SetText(msg);

	if g.frame:IsVisible() == 0 then
		g.frame:ShowWindow(1);
	end
end

-- functions: hook targets
-- template:
-- function ASPDMETER_ON_{HOOK_SOURCE}({HOOK_SOURCE_ARGS})
-- 	-- Call hook source
-- 	hooks["{HOOK_SOURCE}"]({HOOK_SOURCE_ARGS});
-- end

-- functions: message targets
-- template:
-- function ASPDMETER_ON_{MESSAGE_MSG}(frame, msg, argStr, argNum)
-- end

function ASPDMETER_ON_SHOT_START(frame, msg, argStr, argNum)
	local actor = GetMyActor();

	if actor == nil then
		return;
	end

	local skill_id = actor:GetUseSkill();
	local skill_obj = GetSkill(GetMyPCObject(), GetClassByType("Skill", skill_id).ClassName);
	local skill_prop = geSkillTable.Get(skill_obj.ClassName);

	local skills_watch = {};
	skills_watch.main_attack = false;
	skills_watch.sub_attack = false;
	skills_watch.double_punch = false;

	local watching = false;

	-- LH attack
	if skill_prop.isNormalAttack == true then
		skills_watch.main_attack = true;
		watching = true;
	-- RH attack
	elseif skill_obj.ClassName == "Pistol_Attack2" then
		skills_watch.sub_attack = true;
		watching = true;
	elseif skill_obj.ClassName == "Common_DaggerAries" then
		skills_watch.sub_attack = true;
		watching = true;
	-- Double Punch
	elseif skill_obj.ClassName == "Monk_DoublePunch" then
		skills_watch.double_punch = true;
		watching = true;
	end
	
	if watching == false then
		return;
	end

	for timeframe,watcher in pairs(aspd_watcher) do
		aspd_watcher[timeframe] = watcher+1;
	end
end
