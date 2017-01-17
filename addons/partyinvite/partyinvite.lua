local PARTYINVITE_LOADED = false;

function PARTYINVITE_ON_INIT(addon, frame)
	if PARTYINVITE_LOADED == false then
		PARTYINVITE_LOADED = true;
		
		local acutil = require("acutil");

		acutil.slashCommand("/party", ADDON_PARTY_INVITE);
	end
end

function ADDON_PARTY_INVITE(params)
	for team in pairs(params) do
		PARTY_INVITE(team);
	end
end
