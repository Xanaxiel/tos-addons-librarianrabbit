function REMOVESUMMON_ON_INIT(addon, frame)
	local acutil = require("acutil");

    acutil.slashCommand("/removesummon", REMOVE_SUMMON);
    acutil.slashCommand("/rs", REMOVE_SUMMON);
end

function REMOVE_SUMMON()
	local handle = session.GetMyHandle();

	local buffCount = info.GetBuffCount(handle);

	for i = 0, buffCount - 1 do
		local buff = info.GetBuffIndexed(handle, i);
		
		if buff.buffID == 3038 then
			packet.ReqRemoveBuff(buff.buffID);
	
			return true;
		end
	end
	
	return false;
end
