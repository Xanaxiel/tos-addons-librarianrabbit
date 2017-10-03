-- meta
local addon_dev = "LUNAR";
local addon_name = "GUILDNOCRASH";
local addon_name_tag = "GuildNoCrash";
local addon_name_lower = string.lower(addon_name);

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

-- functions: hooks
function GUILDNOCRASH_HOOKS_INIT(source, target)
	if hook_table[source] == nil then
		hook_table[source] = target;
	end
end

function GUILDNOCRASH_HOOKS()
	-- template:
	-- GUILDNOCRASH_HOOKS_INIT("{HOOK_SOURCE}", {HOOK_TARGET});

	GUILDNOCRASH_HOOKS_INIT("GUILDINFO_UPDATE_INFO", GUILDNOCRASH_UPDATE_INFO);

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

-- functions: loader
function GUILDNOCRASH_ON_INIT(addon, frame)
	g.addon = addon;
	g.frame = frame;

	GUILDNOCRASH_HOOKS();

	if g.loaded == false then
		g.loaded = true;
	end
end

-- functions: hook targets
-- template:
-- function GUILDNOCRASH_ON_{HOOK_SOURCE}({HOOK_SOURCE_ARGS})
-- 	-- Call hook source
-- 	hooks["{HOOK_SOURCE}"]({HOOK_SOURCE_ARGS});
-- end

function GUILDNOCRASH_UPDATE_INFO(frame, msg, argStr, argNum)    
    GUILDINFO_INIT_PROFILE(frame);
end

-- functions: message targets
-- template:
-- function GUILDNOCRASH_ON_{MESSAGE_MSG}(frame, msg, argStr, argNum)
-- end
