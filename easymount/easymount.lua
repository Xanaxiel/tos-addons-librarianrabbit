-- dependencies

-- globals: general
_G["LUNAR"] = _G["LUNAR"] or {};
_G["LUNAR"]["EASYMOUNT"] = _G["LUNAR"]["EASYMOUNT"] or {};

-- globals: hooks
_G["LUNAR"]["EASYMOUNT"]["HOOKS"] = _G["LUNAR"]["EASYMOUNT"]["HOOKS"] or {};
_G["LUNAR"]["EASYMOUNT"]["HOOK_TABLE"] = _G["LUNAR"]["EASYMOUNT"]["HOOK_TABLE"] or {};

-- locals: refs
local g = _G["LUNAR"]["EASYMOUNT"];
local hooks = _G["LUNAR"]["EASYMOUNT"]["HOOKS"];
local hook_table = _G["LUNAR"]["EASYMOUNT"]["HOOK_TABLE"];

-- code: runtime vars
g.loaded = false;

-- functions: hooks
function EASYMOUNT_INIT_HOOK(source, target)
	if hook_table[source] == nil then
		hook_table[source] = target;
	end
end

function EASYMOUNT_SETUP_HOOKS()
	EASYMOUNT_INIT_HOOK("ON_RIDING_VEHICLE", EASYMOUNT_ON_RIDING_VEHICLE);

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
function EASYMOUNT_ON_INIT(addon, frame)
	g.addon = addon;
	g.frame = frame;

	EASYMOUNT_SETUP_HOOKS();

	if g.loaded == false then
		g.loaded = true;
	end
end

-- functions: hook targets
function EASYMOUNT_ON_RIDING_VEHICLE(onoff)
	-- Call hook source
	hooks["ON_RIDING_VEHICLE"](onoff);

	local myActor = GetMyActor();

	if myActor ~= nil then
		-- Already riding something -> return
		if myActor:GetUserIValue("CART_ATTACHED") == 1 or GetMyActor():GetVehicleState() == true or control.GetNearSitableCart() ~= 0 then
			return;
		end

		-- Only handle 'on' (to ride = true)
		if onoff == 1 then
			-- Near companion already handled by source / Needs valid companion actor to reposition
			if control.HaveNearCompanionToRide() == false and control.GetMyCompanionActor() ~= nil then
				control.GetMyCompanionActor():SetPos(myActor:GetPos());
				control.RideCompanion(1);
			end
		end
	end
end
