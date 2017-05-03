local flist = {};
local ftype = "";

function export_friends(list_type)
	flist = {};
	ftype = "";

	if list_type == FRIEND_LIST_COMPLETE then
		ftype = "friends";
	elseif list_type == FRIEND_LIST_BLOCKED then
		ftype = "blocked";
	else
		ui.SysMsg("Invalid friendlist type.");
		return;
	end

	local flog = "";
	local _msg = "";

	local count = session.friends.GetFriendCount(list_type);

	_msg = string.format("%d %s.", count, ftype);
	ui.SysMsg(_msg);

	for i = 0, count do
		local friend = session.friends.GetFriendByIndex(list_type, i);

		if friend ~= nil then
			local finfo = friend:GetInfo();

			if finfo ~= nil then
				local accid = finfo:GetACCID();

				if accid ~= nil and accid ~= "" and accid ~= "None" and accid ~= 0 and accid ~= "0" and flist[accid] == nil then
					flist[friend] = accid;

					local fname = finfo:GetFamilyName();

					if fname == "" then
						_msg = string.format("Empty FamilyName found on %s. ACCID: %d", ftype, accid);
						ui.SysMsg(_msg);
					end

					flog = flog .. fname .. ":" .. accid .. "\n";
				end
			end
		end
	end

	local fname = string.format("C:/%s_%s", ftype, os.date("%d-%b-%Y_%H.%M.%S.txt"));
	
	local file, error = io.open(fname, "w");

	if error then
		_msg = string.format("Failed to export %s list.", ftype);
		ui.SysMsg(_msg);
		return;
	end

	file:write(flog);
	file:flush();
	file:close();
	
	_msg = string.format("%d '%s' exported to file: %s", count, ftype, fname);
	ui.SysMsg(_msg);

	_msg = string.format("Delete %d friends?", count);
	ui.MsgBox(_msg, "pre_delete_friends", "None");
end

function pre_delete_friends()
	local _msg = string.format("Are you really sure you want to clear your entire %s list?", ftype);
	ui.MsgBox(_msg, "delete_friends", "None");
end

function delete_friends()
	for _friend, _accid in pairs(flist) do
		friends.RequestDelete(_accid);
	end
	
	local _msg = string.format("%d friends deleted.");

	ui.SysMsg(_msg);
	
	flist = {};
end

function __no_friends_friendlist()
	export_friends(FRIEND_LIST_COMPLETE);
end

function __no_friends_blocklist()
	export_friends(FRIEND_LIST_BLOCKED);
end

function __no_friends_main()
	local _msg = string.format("Click 'Yes' to export Friendlist. Click 'No' to export Blocklist.");
	
	ui.MsgBox(_msg, "__no_friends_friendlist", "__no_friends_blocklist");
end

__no_friends_main();
