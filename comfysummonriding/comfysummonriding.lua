-- meta
local addon_dev = "LUNAR";
local addon_name = "COMFYSUMMONRIDING";
local addon_name_tag = "ComfySummonRiding";
local addon_name_lower = string.lower(addon_name);

-- dependencies
local acutil = require("acutil");

-- globals: general
_G["ADDONS"] = _G["ADDONS"] or {};
_G["ADDONS"][addon_dev] = _G["ADDONS"][addon_dev] or {};
_G["ADDONS"][addon_dev][addon_name] = _G["ADDONS"][addon_dev][addon_name] or {};

local g = _G["ADDONS"]["LUNAR"]["COMFYSUMMONRIDING"];

-- globals: hooks
g["HOOKS"] = g["HOOKS"] or {};
g["HOOK_TABLE"] = g["HOOK_TABLE"] or {};

local hooks = g["HOOKS"];
local hook_table = g["HOOK_TABLE"];

-- addon: runtime vars
g.addon = nil;
g.frame = nil;
g.loaded = false;

g.summonCanUseSkill = false;
g.summonMonName = nil;

-- addon: settings
g.settings_filename = "../addons/" .. addon_name_lower .. "/settings.json";
g.settings = {};

-- functions: settings
function COMFYSUMMONRIDING_SETTINGS_DEFAULT()
	g.settings = {};
	g.settings.enabled = true;
end

function COMFYSUMMONRIDING_SETTINGS_LOAD()
	local data, err = acutil.loadJSON(g.settings_filename);

	if err then
		COMFYSUMMONRIDING_SETTINGS_DEFAULT();
	else
		g.settings = data;
	end

	COMFYSUMMONRIDING_SETTINGS_SAVE();
end

function COMFYSUMMONRIDING_SETTINGS_SAVE()
	acutil.saveJSON(g.settings_filename, g.settings);
end

-- functions: commands
function COMFYSUMMONRIDING_COMMANDS()
	acutil.slashCommand("/csr", COMFYSUMMONRIDING_COMMANDS_OP);
end

function COMFYSUMMONRIDING_COMMANDS_OP(args)
	local op = "";

	if args ~= nil then
		if #args > 0 then
			op = string.lower(table.remove(args, 1));

			if op == "on" or op == "off" then
				COMFYSUMMONRIDING_COMMANDS_ON_OFF({op});
			elseif op == "unride" then
				COMFYSUMMONRIDING_COMMANDS_UNRIDE();
			end

			return;
		end
	end

	-- default action:
	COMFYSUMMONRIDING_COMMANDS_ON_OFF(nil);
end

function COMFYSUMMONRIDING_COMMANDS_ON_OFF(args)
	-- args:
	-- 1) 'on' or 'off' or nil

	local state_change = 0; -- 2 = enabled, 1 = disabled, 0 = unchanged
	local on_off = nil;

	if args ~= nil then
		on_off = table.remove(args, 1);
	end

	if on_off ~= nil and on_off ~= "" then
		on_off = string.lower(on_off);
	end

	if on_off == "on" then
		if g.settings.enabled == false then
			state_change = 2;
		end

		g.settings.enabled = true;
	elseif on_off == "off" then
		if g.settings.enabled == false then
			state_change = 1;
		end

		g.settings.enabled = false;
	else
		if g.settings.enabled == true then
			g.settings.enabled = false;
			state_change = 1;
		else
			g.settings.enabled = true;
			state_change = 2;
		end
	end

	if state_change == 2 then
		-- enabled
		CHAT_SYSTEM("[" .. addon_name_tag .. "] enabled.");

		COMFYSUMMONRIDING_SETTINGS_SAVE();
	elseif state_change == 1 then
		-- disabled
		CHAT_SYSTEM("[" .. addon_name_tag .. "] disabled.");

		COMFYSUMMONRIDING_SETTINGS_SAVE();
	end
end

function COMFYSUMMONRIDING_COMMANDS_UNRIDE()
	CHAT_SYSTEM("[" .. addon_name_tag .. "] forcing summon unride...");
	geSummonControl.Unride();
end

-- functions: hooks
function COMFYSUMMONRIDING_HOOKS_INIT(source, target)
	if hook_table[source] == nil then
		hook_table[source] = target;
	end
end

function COMFYSUMMONRIDING_HOOKS()
	-- template:
	-- COMFYSUMMONRIDING_HOOKS_INIT("{HOOK_SOURCE}", {HOOK_TARGET});

	COMFYSUMMONRIDING_HOOKS_INIT("MONSTER_QUICKSLOT", COMFYSUMMONRIDING_ON_MONSTER_QUICKSLOT);

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
function COMFYSUMMONRIDING_MESSAGES_INIT(message, target)
	if g.addon == nil then
		return;
	end

	g.addon:RegisterMsg(message, target);
end

function COMFYSUMMONRIDING_MESSAGES()
	-- template:
	-- COMFYSUMMONRIDING_MESSAGES_INIT("{MESSAGE_MSG}", "{MESSAGE_TARGET}");
	-- MSG list: ui.ipf/uixml/addonmessage.xml
	-- common MSG: FPS_UPDATE,GAME_START_3SEC

	COMFYSUMMONRIDING_MESSAGES_INIT("GAME_START_3SEC", "COMFYSUMMONRIDING_ON_GAME_START_3SEC");
end

-- functions: loader
function COMFYSUMMONRIDING_ON_INIT(addon, frame)
	g.addon = addon;
	g.frame = frame;

	COMFYSUMMONRIDING_SETTINGS_LOAD();

	COMFYSUMMONRIDING_COMMANDS();

	COMFYSUMMONRIDING_HOOKS();
	COMFYSUMMONRIDING_MESSAGES();

	if g.loaded == false then
		g.loaded = true;
	end
end

function COMFYSUMMONRIDING_ON_GAME_START_3SEC()
	local f_monsterquickslot = ui.GetFrame("monsterquickslot");

	if f_monsterquickslot ~= nil then
		f_monsterquickslot:RunUpdateScript("COMFYSUMMONRIDING_ON_JOYSTICK_INPUT", 0);
	else
		ReserveScript("COMFYSUMMONRIDING_ON_GAME_START_3SEC()", 3.0);
	end
end

function COMFYSUMMONRIDING_IS_RIDING()
	if g.summonCanUseSkill ~= 1 then
		return false;
	end

	if g.settings.enabled == false then
		return false;
	end

	local f_monsterquickslot = ui.GetFrame("monsterquickslot");

	if f_monsterquickslot == nil then
		return false;
	end

	if f_monsterquickslot:IsVisible() == 1 then
		return true;
	end

	return false;
end

function COMFYSUMMONRIDING_ON_JOYSTICK_INPUT()
	if COMFYSUMMONRIDING_IS_RIDING() == true then
		local joy_X = joystick.IsKeyPressed("JOY_BTN_1");
		local joy_A = joystick.IsKeyPressed("JOY_BTN_2");
		local joy_B = joystick.IsKeyPressed("JOY_BTN_3");
		local joy_Y = joystick.IsKeyPressed("JOY_BTN_4");
		local joy_L1 = joystick.IsKeyPressed("JOY_BTN_5");
		local joy_L2 = joystick.IsKeyPressed("JOY_BTN_7");
		local joy_R1 = joystick.IsKeyPressed("JOY_BTN_6");
		local joy_R2 = joystick.IsKeyPressed("JOY_BTN_8");

		if joy_L1 == 0 and joy_L2 == 0 and joy_R1 == 0 and joy_R2 == 0 then
			local skill_count = 0;

			if g.summonMonName ~= nil then
				local monCls = GetClass("Monster", monName);

				if monCls ~= nil then
					local list = GetMonsterSkillList(monCls.ClassID);

					if list ~= nil then
						skill_count = list:Count();
					end
				end
			end

			if skill_count == 0 then
				local f_monsterquickslot = ui.GetFrame("monsterquickslot");
				local slotset = GET_CHILD(f_monsterquickslot, "slotset", "ui::CSlotSet");

				skill_count = (slotset:GetSlotCount() - 1);
			end

			local cast_lock = false;

			if skill_count >= 1 and cast_lock == false then
				if joy_B == 1 then
					geSummonControl.UseSkill(0);
					cast_lock = true;
				end
			end

			if skill_count >= 2 and cast_lock == false then
				if joy_X == 1 then
					geSummonControl.UseSkill(1);
					cast_lock = true;
				end
			end

			if skill_count >= 3 and cast_lock == false then
				if joy_Y == 1 then
					geSummonControl.UseSkill(2);
					cast_lock = true;
				end
			end

			if skill_count >= 4 and cast_lock == false then
				if joy_A == 1 then
					geSummonControl.UseSkill(3);
					cast_lock = true;
				end
			end
		end
	end

	return 1;
end

-- functions: hook targets
-- template:
-- function COMFYSUMMONRIDING_ON_{HOOK_SOURCE}({HOOK_SOURCE_ARGS})
-- 	-- Call hook source
-- 	hooks["{HOOK_SOURCE}"]({HOOK_SOURCE_ARGS});
-- end


function COMFYSUMMONRIDING_ON_MONSTER_QUICKSLOT(isOn, monName, buffType, ableToUseSkill)
	hooks["MONSTER_QUICKSLOT"](isOn, monName, buffType, ableToUseSkill);

	g.summonCanUseSkill = ableToUseSkill;
	g.summonMonName = monName;
end

-- functions: message targets
-- template:
-- function COMFYSUMMONRIDING_ON_{MESSAGE_MSG}(frame, msg, argStr, argNum)
-- end
