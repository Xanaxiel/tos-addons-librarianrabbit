-- meta
local addon_dev = "{$ADDON_DEV}";
local addon_name = "{$ADDON_NAME}";
local addon_name_tag = "{$ADDON_NAME_TAG}";
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

-- addon: runtime vars
g.addon = nil;
g.frame = nil;
g.loaded = false;

-- addon: settings
g.settings_filename = "../addons/" .. addon_name_lower .. "/settings.json";
g.settings = {};

-- functions: settings
function {$ADDON_NAME}_SETTINGS_DEFAULT()
	g.settings = {};
	g.settings.enabled = true;
end

function {$ADDON_NAME}_SETTINGS_LOAD()
	local data, err = acutil.loadJSON(g.settings_filename);

	if err then
		{$ADDON_NAME}_SETTINGS_DEFAULT();
	else
		g.settings = data;
	end

	{$ADDON_NAME}_SETTINGS_SAVE();
end

function {$ADDON_NAME}_SETTINGS_SAVE()
	acutil.saveJSON(g.settings_filename, g.settings);
end

-- functions: commands
function {$ADDON_NAME}_COMMANDS()
	acutil.slashCommand("/{$ADDON_COMMAND}", {$ADDON_NAME}_COMMANDS_OP);
end

function {$ADDON_NAME}_COMMANDS_OP(args)
	local op = "";

	if #args > 0 then
		op = string.lower(table.remove(args, 1));

		if op == "on" or op == "off" then
			{$ADDON_NAME}_COMMANDS_ON_OFF(args);
		end
	end

	-- default action:
	-- do nothing
end

function {$ADDON_NAME}_COMMANDS_ON_OFF(args)
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

		{$ADDON_NAME}_SETTINGS_SAVE();
	elseif state_change == 1 then
		-- disabled
		CHAT_SYSTEM("[" .. addon_name_tag .. "] disabled.");

		{$ADDON_NAME}_SETTINGS_SAVE();
	end
end

-- functions: hooks
function {$ADDON_NAME}_HOOKS_INIT(source, target)
	if hook_table[source] == nil then
		hook_table[source] = target;
	end
end

function {$ADDON_NAME}_HOOKS()
	-- template:
	-- {$ADDON_NAME}_HOOKS_INIT("{HOOK_SOURCE}", {HOOK_TARGET});

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
function {$ADDON_NAME}_MESSAGES_INIT(message, target)
	if g.addon == nil then
		return;
	end

	g.addon:RegisterMsg(message, target);
end

function {$ADDON_NAME}_MESSAGES()
	-- template:
	-- ASPDMETER_MESSAGES_INIT("{MESSAGE_MSG}", {MESSAGE_TARGET});
	-- MSG list: ui.ipf/uixml/addonmessage.xml
	-- common MSG: FPS_UPDATE,GAME_START_3SEC
end

-- functions: loader
function {$ADDON_NAME}_ON_INIT(addon, frame)
	g.addon = addon;
	g.frame = frame;

	{$ADDON_NAME}_SETTINGS_LOAD();

	{$ADDON_NAME}_COMMANDS();

	{$ADDON_NAME}_HOOKS();
	{$ADDON_NAME}_MESSAGES();

	if g.loaded == false then
		g.loaded = true;
	end

	{$ADDON_NAME}_MAIN();
end

function {$ADDON_NAME}_MAIN()
end

-- functions: hook targets
-- template:
-- function {$ADDON_NAME}_ON_{HOOK_SOURCE}({HOOK_SOURCE_ARGS})
-- 	-- Call hook source
-- 	hooks["{HOOK_SOURCE}"]({HOOK_SOURCE_ARGS});
-- end

-- functions: message targets
-- template:
-- function {$ADDON_NAME}_ON_{MESSAGE_MSG}(frame, msg, argStr, argNum)
-- end
