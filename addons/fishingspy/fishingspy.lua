local FISHINGSPY_LOADED = false;

function FISHINGSPY_ON_INIT(addon, frame)
	if FISHINGSPY_LOADED == false then
		_G["_FISHINGSPY_ON_FISHING_ITEM_LIST"] = _G["ON_FISHING_ITEM_LIST"];
		FISHINGSPY_LOADED = true;
	end

	if _G["ON_FISHING_ITEM_LIST"] ~= FISHINGSPY_ON_FISHING_ITEM_LIST then
		_G["ON_FISHING_ITEM_LIST"] = FISHINGSPY_ON_FISHING_ITEM_LIST;
	end
end

function FISHINGSPY_ON_FISHING_ITEM_LIST(frame, msg, argStr, argNum)
	_G["_FISHINGSPY_ON_FISHING_ITEM_LIST"](frame, msg, argStr, argNum);

    if argStr == nil or argStr == 'None' then
		local header = GET_CHILD_RECURSIVELY(frame, "headerText");
		header:SetText("{@st43}Tackle Box{/}");

        return;
    end

	local PcAID = argStr;
	local list, cnt = SelectObject(GetMyPCObject(), 300, 'ALL');

	for i = 1, cnt do
		local handle = GetHandle(list[i]);

		if handle ~= nil then
			if info.IsPC(handle) == 1 then
				local AID = world.GetActor(handle):GetPCApc():GetAID();

				if PcAID == AID then
					local familyName = info.GetFamilyName(handle);
					local header = GET_CHILD_RECURSIVELY(frame, "headerText");
					header:SetText("{@st43}" .. familyName .. "'s Tackle Box{/}");

					return;
				end
			end
		end
	end
end
