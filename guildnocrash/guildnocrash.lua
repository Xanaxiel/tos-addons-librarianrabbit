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

-- addon: runtime vars
g.addon = nil;
g.frame = nil;
g.loaded = false;

-- functions: loader
function GUILDNOCRASH_ON_INIT(addon, frame)
	g.addon = addon;
	g.frame = frame;

	if g.loaded == false then
		CHAT_SYSTEM("IMC issued a hotfix to prevent guild members from crashing. This addon is no longer needed, please uninstall 'Guild no-crash!' from Addon Manager.");

		g.loaded = true;
	end
end
