_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['BARRACKITEMLIST'] = _G['ADDONS']['BARRACKITEMLIST'] or {};
local acutil = require('acutil')
local g = _G['ADDONS']['BARRACKITEMLIST']
g.settingPath = '../addons/barrackitemlist/'
g.userlist = acutil.loadJSON(g.settingPath..'userlist.json',nil) or {}
g.warehouseList = nil;
g.nodeList = {
        {"Unused" , "シルバー"}
        ,{"Weapon" , "武器"}
        ,{"SubWeapon" , "サブ武器"}
        ,{"Armor" , "アーマー"}
        ,{"Drug" , "消費アイテム"}
        ,{"Recipe" ,"レシピ"}
        ,{"Material","素材"}
        ,{"Gem","ジェム"}
        ,{"Card","カード"}
        ,{"Collection","コレクション"}
        ,{"Quest" ,"クエスト"}
        ,{"Event" ,"イベント"}
        ,{"Cube" , "キューブ"}
        ,{"Premium" ,"プレミアム"}
        ,{"warehouse","倉庫"}
    }
g.setting = acutil.loadJSON(g.settingPath..'setting.json',nil)
if not g.setting then
    g.setting = {}
    g.setting.col = 14
    g.setting.hideNode = {}
    g.setting.OpenNodeAll = false
    g.setting.lang = "jp";
    acutil.saveJSON(g.settingPath..'setting.json',g.setting)
end

g.itemlist = g.itemlist or {}

function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end

g.TR_lang = g.setting.lang;

g.TR_strings = {};

g.TR_strings["en"] = {
    ["シルバー"]="Silver",
    ["武器"]="Weapon",
    ["サブ武器"]="SubWeapon",
    ["アーマー"]="Armor",
    ["消費アイテム"]="Consumable",
    ["レシピ"]="Recipe",
    ["素材"]="Material",
    ["ジェム"]="Gem",
    ["カード"]="Card",
    ["コレクション"]="Collection",
    ["クエスト"]="Quest",
    ["イベント"]="Event",
    ["キューブ"]="Cube",
    ["プレミアム"]="Premium",
    ["倉庫"]="Storage",
    ["現在のキャラのインベントリを保存する"]="Save the current character's inventory",
    ["インベントリ"]="Inventory",
    ["アイテムリスト"]=" List ",
    ["アイテム検索"]=" Search ",
    ["設定"]=" Settings ",
    ["保存"]=" Save ",
    ["一行のスロット数"]="Slots per line",
    ["始めからノードを展開する"]="All open"
};

function BARRACKITEMLIST_TR(str)
    if not g.TR_lang then return str; end

    local tr = g.TR_strings[g.TR_lang];
    if not tr then return str; end

    local tr_str = tr[str];
    if not tr_str then return str; end

    return tr_str;
end

function BARRACKITEMLIST_SET_LANG(lang)
    g.TR_lang = nil;

    lang = string.lower(lang);

    for lang_tr, strings in pairs(g.TR_strings) do
        if string.lower(lang_tr) == lang then
            g.TR_lang = lang_tr;
            g.setting.lang = lang_tr;
        end
    end

    BARRACKITEMLIST_TRANSLATE_UI();
end

function BARRACKITEMLIST_TRANSLATE_UI()
    local frame = ui.GetFrame("barrackitemlist");

    local ui_tab = GET_CHILD(frame, "tab", "ui::CTabControl");
    ui_tab:ChangeCaption(0, BARRACKITEMLIST_TR("アイテムリスト"));
    ui_tab:ChangeCaption(1, BARRACKITEMLIST_TR("アイテム検索"));
    ui_tab:ChangeCaption(2, BARRACKITEMLIST_TR("設定"));

    local ui_saveBtn = GET_CHILD_RECURSIVELY(frame, "saveBtn");
    local ui_slotColTxt = GET_CHILD_RECURSIVELY(frame, "slotColTxt");
    local ui_openNodeChbox = GET_CHILD_RECURSIVELY(frame, "openNodeChbox");

    ui_saveBtn:SetText(BARRACKITEMLIST_TR("保存"));
    ui_slotColTxt:SetText(BARRACKITEMLIST_TR("一行のスロット数"));
    ui_openNodeChbox:SetText("{s30}{#000000}" .. BARRACKITEMLIST_TR("始めからノードを展開する"));

    BARRACKITEMLIST_CREATE_SETTINGMENU();
end

function BARRACKITEMLIST_GET_SERVER_ID()
    local f = io.open('../release/user.xml', "rb");
    local content = f:read("*all");
    f:close();
    return content:match('RecentServer="(.-)"');
end

function BARRACKITEMLIST_WRITE_FILE(file, content)
    local file, error = io.open(file, "w");

    if error then
        return;
    end

    file:write(content);
    file:flush();
    file:close();
end

g.listSeparator = ";";
g.itemMatch = "([^" .. g.listSeparator .. "]+)" .. g.listSeparator .. "([^" .. g.listSeparator .. "]+)" .. g.listSeparator .. "([^" .. g.listSeparator .. "]+)";

-- S:<ServerID>
-- C:<CID>
-- I:<Name, Count, Icon>
function _BARRACKITEMLIST_SAVE_WAREHOUSE()
    local sid = BARRACKITEMLIST_GET_SERVER_ID();
    local data = "S" .. g.listSeparator .. sid .. "\n";

    if g.warehouseList[sid] then
        for cid, items in pairs(g.warehouseList[sid]) do
            data = data .. "C" .. g.listSeparator .. cid .. "\n";

            if items.warehouse then
                for _, item in pairs(items.warehouse) do
                    data = data .. "I" .. g.listSeparator .. item[1] .. g.listSeparator .. item[2] .. g.listSeparator .. item[3] .. "\n";
                end
            end
        end
    end

    BARRACKITEMLIST_WRITE_FILE(g.settingPath..'warehouse_'..sid..'.txt', data);
end

function _BARRACKITEMLIST_LOAD_WAREHOUSE()
    g.warehouseList = {};

    local current_server = false;
    local current_sid = BARRACKITEMLIST_GET_SERVER_ID();

    g.warehouseList[current_sid] = {};

    local sid = nil;
    local cid = nil;
    local itemName = nil;
    local itemCount = nil;
    local iconImg = nil;

    for line in io.lines(g.settingPath..'warehouse_'..current_sid..'.txt') do
        if string.starts(line, "S" .. g.listSeparator) then
            sid = string.sub(line, 3);
            current_server = (sid == current_sid);
        elseif string.starts(line, "C" .. g.listSeparator) and current_server then
            cid = string.sub(line, 3);
            g.warehouseList[sid][cid] = g.warehouseList[sid][cid] or {};
            g.warehouseList[sid][cid].warehouse = g.warehouseList[sid][cid].warehouse or {};
        elseif string.starts(line, "I" .. g.listSeparator) and current_server then
            if cid and g.warehouseList[sid][cid].warehouse then
                itemName, itemCount, iconImg = string.match(string.sub(line, 3), g.itemMatch);
                table.insert(g.warehouseList[sid][cid].warehouse, {itemName, itemCount, iconImg});
            end
        end
    end

    return g.warehouseList;
end

-- S:<ServerID>
-- G:<GROUP>
-- I:<Name, Count, Icon>
function _BARRACKITEMLIST_SAVE_LIST()
    local sid = BARRACKITEMLIST_GET_SERVER_ID();
    local data = "S" .. g.listSeparator .. sid .. "\n";
    local cid = info.GetCID(session.GetMyHandle());

    if g.itemlist[sid] then
        if g.itemlist[sid][cid] then
            for group, items in pairs(g.itemlist[sid][cid]) do
                data = data .. "G" .. g.listSeparator .. group .. "\n";

                for _, item in pairs(items) do
                    data = data .. "I" .. g.listSeparator .. item[1] .. g.listSeparator .. item[2] .. g.listSeparator .. item[3] .. "\n";
                end
            end
        end
    end

    BARRACKITEMLIST_WRITE_FILE(g.settingPath..cid..'_'..sid..'.txt', data);
end

function _BARRACKITEMLIST_LOAD_LIST(cid)
    local current_server = false;
    local current_sid = BARRACKITEMLIST_GET_SERVER_ID();

    g.itemlist[current_sid] = g.itemlist[current_sid] or {};
    g.itemlist[current_sid][cid] = {};

    local sid = nil;
    local group = nil;
    local itemName = nil;
    local itemCount = nil;
    local iconImg = nil;

    for line in io.lines(g.settingPath..cid..'_'..current_sid..'.txt') do
        if string.starts(line, "S" .. g.listSeparator) then
            sid = string.sub(line, 3);
            current_server = (sid == current_sid);
        elseif string.starts(line, "G" .. g.listSeparator) and current_server then
            group = string.sub(line, 3);
            g.itemlist[sid] = g.itemlist[sid] or {};
            g.itemlist[sid][cid] = g.itemlist[sid][cid] or {};
            g.itemlist[sid][cid][group] = g.itemlist[sid][cid][group] or {};
        elseif string.starts(line, "I" .. g.listSeparator) and current_server then
            if group then
                if g.itemlist[sid][cid][group] then
                    itemName, itemCount, iconImg = string.match(string.sub(line, 3), g.itemMatch);
                    table.insert(g.itemlist[sid][cid][group], {itemName, itemCount, iconImg});
                end
            end
        end
    end

    return g.itemlist[sid][cid];
end

function BARRACKITEMLIST_ON_INIT(addon,frame)
    local sid = BARRACKITEMLIST_GET_SERVER_ID();
    g.userlist[sid] = g.userlist[sid] or {};
    local cid = info.GetCID(session.GetMyHandle())
    g.userlist[sid][cid] = info.GetPCName(session.GetMyHandle())
    acutil.saveJSON(g.settingPath..'userlist.json',g.userlist)
    acutil.slashCommand('/itemlist', BARRACKITEMLIST_COMMAND)
    acutil.slashCommand('/il',BARRACKITEMLIST_COMMAND)

    acutil.setupEvent(addon,'GAME_TO_BARRACK','BARRACKITEMLIST_SAVE_LIST')
    acutil.setupEvent(addon,'GAME_TO_LOGIN','BARRACKITEMLIST_SAVE_LIST')
    acutil.setupEvent(addon,'DO_QUIT_GAME','BARRACKITEMLIST_SAVE_LIST')
    acutil.setupEvent(addon,'WAREHOUSE_CLOSE','BARRACKITEMLIST_SAVE_WAREHOUSE')
    -- acutil.setupEvent(addon, 'SELECT_CHARBTN_LBTNUP', 'SELECT_CHARBTN_LBTNUP_EVENT')

    addon:RegisterMsg('GAME_START_3SEC','BARRACKITEMLIST_CREATE_VAR_ICONS')

    local droplist = tolua.cast(frame:GetChild("droplist"), "ui::CDropList");
    droplist:ClearItems()
    droplist:AddItem(1,'None',0,'BARRACKITEMLIST_SHOW_LIST()')
    for k,v in pairs(g.userlist[sid]) do
        droplist:AddItem(k,"{s20}"..v.."{/}",0,'BARRACKITEMLIST_SHOW_LIST()');
    end
    tolua.cast(frame:GetChild('tab'), "ui::CTabControl"):SelectTab(0)
    frame:GetChild('saveBtn'):SetTextTooltip(BARRACKITEMLIST_TR('現在のキャラのインベントリを保存する'))
    BARRACKITEMLIST_CREATE_SETTINGMENU()
    BARRACKITEMLIST_TAB_CHANGE(frame)
    frame:ShowWindow(0);
    BARRACKITEMLIST_SAVE_LIST()

    BARRACKITEMLIST_TRANSLATE_UI();
end

-- function SELECT_CHARBTN_LBTNUP_EVENT(addonFrame, eventMsg)
--     local parent, ctrl, cid, argNum = acutil.getEventArgs(eventMsg);
--     BARRACKITEMLIST_SHOW_LIST(cid)
-- end

function BARRACKITEMLIST_TAB_CHANGE(frame, obj, argStr, argNum)
    local treeGbox = frame:GetChild('treeGbox')
    local droplist = frame:GetChild("droplist")
    local searchGbox = frame:GetChild('searchGbox')
    local settingGbox = frame:GetChild('settingGbox')
    local tabObj = tolua.cast(frame:GetChild('tab'), "ui::CTabControl");
    local tabIndex = tabObj:GetSelectItemIndex();

    if (tabIndex == 0) then
        treeGbox:ShowWindow(1)
        droplist:ShowWindow(1)
        searchGbox:ShowWindow(0)
        settingGbox:ShowWindow(0)
        BARRACKITEMLIST_SHOW_LIST()
        BARRACKITEMLIST_SAVE_SETTINGMENU()
    elseif (tabIndex == 1) then
        treeGbox:ShowWindow(0)
        droplist:ShowWindow(0)
        searchGbox:ShowWindow(1)
        settingGbox:ShowWindow(0)
        BARRACKITEMLIST_SAVE_SETTINGMENU()
        BARRACKITEMLIST_SHOW_SEARCH_ITEMS()
    else
        treeGbox:ShowWindow(0)
        droplist:ShowWindow(0)
        searchGbox:ShowWindow(0)
        settingGbox:ShowWindow(1)
    end

    BARRACKITEMLIST_TRANSLATE_UI();
end

function BARRACKITEMLIST_COMMAND(command)
    local cmd = table.remove(command, 1);

    if next(command) ~= nil then
        if cmd == "lang" and next(command) ~= nil then
            local lang = string.lower(table.remove(command, 1));
            BARRACKITEMLIST_SET_LANG(lang);
            ui.GetFrame('barrackitemlist'):ShowWindow(1);
            return;
        end
    end

    BARRACKITEMLIST_CREATE_SETTINGMENU()
    ui.ToggleFrame('barrackitemlist')
end

function BARRACKITEMLIST_SAVE_LIST()
    local list = {}
    session.BuildInvItemSortedList()
    local invItemList = session.GetInvItemSortedList();

    for i = 1, invItemList:size() - 1 do
        local invItem = invItemList:at(i);
        if invItem ~= nil then
            local obj = GetIES(invItem:GetObject());
            list[obj.GroupName] = list[obj.GroupName] or {}
            table.insert(list[obj.GroupName],GetItemData(obj,invItem))
        end
    end
    local sid = BARRACKITEMLIST_GET_SERVER_ID();
    g.itemlist[sid] = g.itemlist[sid] or {};
    local cid = info.GetCID(session.GetMyHandle())
    g.itemlist[sid][cid] = list;
    _BARRACKITEMLIST_SAVE_LIST();
end

function BARRACKITEMLIST_SHOW_LIST(cid)
    local sid = BARRACKITEMLIST_GET_SERVER_ID();
    local frame = ui.GetFrame('barrackitemlist')
    --frame:ShowWindow(1)
    local gbox = GET_CHILD(frame,'treeGbox','ui::CGroupBox');
    local droplist = GET_CHILD(frame,'droplist', "ui::CDropList")
    if not cid then cid= droplist:GetSelItemKey() end
    for k,v in pairs(g.userlist[sid]) do
        local child = gbox:GetChild("tree"..k) 
        if child then
            child:ShowWindow(0)
        end
    end
    local child = gbox:GetChild("tree1");
    if child then
        child:ShowWindow(0)
    end

    if not cid or cid == 1 then return; end

    g.itemlist[sid] = g.itemlist[sid] or {};
    local list = g.itemlist[sid][cid]
    if not list then
        list = _BARRACKITEMLIST_LOAD_LIST(cid);
        if not list then return end
    end

    if g.warehouseList == nil then _BARRACKITEMLIST_LOAD_WAREHOUSE(); end

    g.warehouseList[sid][tostring(cid)] = g.warehouseList[sid][tostring(cid)] or {}
    list.warehouse =  g.warehouseList[sid][tostring(cid)].warehouse or {};

    local tree = gbox:CreateOrGetControl('tree','tree'..cid,25,50,545,0)
    -- if tree:GetUserValue('exist_data') ~= '1' then
        -- tree:SetUserValue('exist_data',1) 
        tolua.cast(tree,'ui::CTreeControl')
        tree:ResizeByResolutionRecursively(1)
        tree:Clear()
        tree:EnableDrawFrame(true);
        tree:SetFitToChild(true,60); 
        tree:SetFontName("white_20_ol");
        local nodeName,parentCategory
        local slot,slotset,icon
        local nodeList = g.nodeList
        for i,value in ipairs(nodeList) do
            local nodeItemList = list[value[1]]
            if nodeItemList and not g.setting.hideNode[i] then
                if value[1] == "Unused" then
                    tree:Add(BARRACKITEMLIST_TR("シルバー") .. " : " .. acutil.addThousandsSeparator(nodeItemList[1][2]));
                else
                    tree:Add(BARRACKITEMLIST_TR(value[2]));
                    parentCategory = tree:FindByCaption(BARRACKITEMLIST_TR(value[2]));
                    slotset = BARRACKITEMLIST_MAKE_SLOTSET(tree,value[1])
                    tree:Add(parentCategory,slotset, 'slotset_'..value[1]);
                    for i ,v in ipairs(nodeItemList) do
                        slot = slotset:GetSlotByIndex(i - 1)
                        slot:SetText(string.format(v[2]))
                        slot:SetTextMaxWidth(1000)
                        icon = CreateIcon(slot)
                        icon:SetImage(v[3])
                        icon:SetTextTooltip(string.format("%s : %s",v[1],v[2]))
                        if (i % g.setting.col) == 0 then
                            slotset:ExpandRow()
                        end
                    end
                end
            end
        -- end
    end
    if g.setting.OpenNodeAll then
        tree:OpenNodeAll()
    end
    tree:ShowWindow(1)
    --frame:ShowWindow(1)
end
function BARRACKITEMLIST_MAKE_SLOTSET(tree, name)
    local col = g.setting.col
    local slotsize = math.floor(tree:GetWidth() / (col + 1))
    local slotsetTitle = 'slotset_titile_'..name
    local newslotset = tree:CreateOrGetControl('slotset','slotset_'..name,0,0,0,0) 
    tolua.cast(newslotset, "ui::CSlotSet");

    newslotset:EnablePop(0)
    newslotset:EnableDrag(0)
    newslotset:EnableDrop(0)
    newslotset:SetMaxSelectionCount(999)
    newslotset:SetSlotSize(slotsize,slotsize);
    newslotset:SetColRow(col,1)
    newslotset:SetSpc(0,0)
    newslotset:SetSkinName('invenslot2')
    newslotset:EnableSelection(0)
    newslotset:ResizeByResolutionRecursively(1)
    newslotset:CreateSlots()
    return newslotset;
end

function BARRACKITEMLIST_SEARCH_ITEMS(itemlist,itemName,iswarehouse)
    local sid = BARRACKITEMLIST_GET_SERVER_ID();
    local items = {}
    for cid,name in pairs(g.userlist[sid]) do
        if not itemlist[cid] then
            if iswarehouse == false then
                itemlist[cid] = _BARRACKITEMLIST_LOAD_LIST(cid);
            end
        end

        if itemlist[cid] then
            for group,list in pairs(itemlist[cid]) do
                if group ~= 'warehouse' or iswarehouse then
                    for i ,v in ipairs(list) do
                        if string.find(string.lower(v[1]),string.lower(itemName)) then
                            items[cid] = items[cid] or {}
                            table.insert(items[cid],v)
                        end
                    end
                end
            end
        end
    end
    return items
end

function BARRACKITEMLIST_SHOW_SEARCH_ITEMS(frame, obj, argStr, argNum)
    local frame = ui.GetFrame('barrackitemlist')
    local searchGbox = frame:GetChild('searchGbox')
    local editbox = tolua.cast(searchGbox:GetChild('searchEdit'), "ui::CEditControl");
    local tree = searchGbox:CreateOrGetControl('tree','saerchTree',25,50,545,0)
    tolua.cast(tree,'ui::CTreeControl')
    tree:ResizeByResolutionRecursively(1)
    tree:Clear()
    tree:EnableDrawFrame(true);
    tree:SetFitToChild(true,60); 
    tree:SetFontName("white_20_ol");
    if editbox:GetText() == '' or not editbox:GetText() then return end
    local sid = BARRACKITEMLIST_GET_SERVER_ID();
    local invItems = BARRACKITEMLIST_SEARCH_ITEMS(g.itemlist[sid],editbox:GetText(),false)

    if g.warehouseList == nil then _BARRACKITEMLIST_LOAD_WAREHOUSE(); end

    local warehouseItems = BARRACKITEMLIST_SEARCH_ITEMS(g.warehouseList[sid],editbox:GetText(),true)
    tree:Add(BARRACKITEMLIST_TR('インベントリ'))
    _BARRACKITEMLIST_SEARCH_ITEMS(tree,invItems,'_i')
    tree:Add(BARRACKITEMLIST_TR('倉庫'))
    _BARRACKITEMLIST_SEARCH_ITEMS(tree,warehouseItems,'_w')
    tree:OpenNodeAll()
    tree:ShowWindow(1)
end

function _BARRACKITEMLIST_SEARCH_ITEMS(tree,items,type)
    local sid = BARRACKITEMLIST_GET_SERVER_ID();
    local nodeName,parentCategory
    local slot,slotset,icon
    for k,value in pairs(items) do
        tree:Add(g.userlist[sid][k]..type);
        parentCategory = tree:FindByCaption(g.userlist[sid][k]..type);
        slotset = BARRACKITEMLIST_MAKE_SLOTSET(tree,k..type)
        tree:Add(parentCategory,slotset, 'slotset_'..k..type);
        for i ,v in ipairs(value) do
            slot = slotset:GetSlotByIndex(i - 1)
            slot:SetText(string.format('{s20}%s',v[2]))
            slot:SetTextAlign(30,30)
            -- slot:SetTextMaxWidth(1000)
            icon = CreateIcon(slot)
            icon:SetImage(v[3])
            icon:SetTextTooltip(string.format("%s : %s",v[1],v[2]))
            if (i % g.setting.col) == 0 then
                slotset:ExpandRow()
            end
        end
    end

end

function BARRACKITEMLIST_SAVE_WAREHOUSE()
    local frame = ui.GetFrame('warehouse')
    local slotset = frame:GetChild("gbox"):GetChild('slotset')
    tolua.cast(slotset,'ui::CSlotSet')
    local items = {}
    local slot , item
    for i = 0 , slotset:GetSlotCount() -1 do
        slot = slotset:GetSlotByIndex(i)
        item = GetItemData(GetObjBySlot(slot))
        if item then
            table.insert(items,item)
        end
    end
    local sid = BARRACKITEMLIST_GET_SERVER_ID();
    local cid = tostring(info.GetCID(session.GetMyHandle()))

    if g.warehouseList == nil then _BARRACKITEMLIST_LOAD_WAREHOUSE(); end

    g.warehouseList[sid][cid] = {}
    g.warehouseList[sid][cid].warehouse = items
    _BARRACKITEMLIST_SAVE_WAREHOUSE();
end

function GetItemData(obj,item)
    if not obj then return end
    local itemName = dictionary.ReplaceDicIDInCompStr(obj.Name)
    local itemCount = item.count
    local iconImg = obj.Icon
    if obj.GroupName ==  'Gem' or obj.GroupName ==  'Card' then
        itemCount = 'Lv' .. GET_ITEM_LEVEL(obj)
    end
    if obj.ItemType == 'Equip' and obj.ClassType == 'Outer' then
        local tempiconname = string.sub(obj.Icon, string.len(obj.Icon) - 1 );
        if tempiconname ~= "_m" and tempiconname ~= "_f" then
            if gender == nil then
                gender = GetMyPCObject().Gender;
            end
            if gender == 1 then
                iconImg =iconImg.."_m"
            else
                iconImg = iconImg.."_f"
            end
        end
    end
    return {itemName,itemCount,iconImg}
end

function GetObjBySlot(slot)
    local icon = slot:GetIcon()
    if not icon then return end
    local info = icon:GetInfo()
    local IESID = info:GetIESID()
    return GetObjectByGuid(IESID) ,info ,IESID
end

function BARRACKITEMLIST_CREATE_SETTINGMENU()
    local frame = ui.GetFrame('barrackitemlist')
    local settingGbox = frame:GetChild('settingGbox')
    local hideNodeGbox = settingGbox:GetChild('hideNodeGbox')

    -- create slotsize droplist
    local droplist = tolua.cast(settingGbox:GetChild("slotColDList"), "ui::CDropList");
    droplist:ClearItems()
    for i = 7, 14  do
        droplist:AddItem(i,"{s20}"..i.."{/}");
    end
    droplist:SelectItemByKey(g.setting.col)

    --create hide node list
    local checkbox
    for i = 1 ,#g.nodeList do
        checkbox = hideNodeGbox:CreateOrGetControl('checkbox','checkbox'..i,30,i*30,200,30)
        tolua.cast(checkbox,'ui::CCheckBox')
        checkbox:SetText('{s30}{#000000}'..BARRACKITEMLIST_TR(g.nodeList[i][2]))
        if not g.setting.hideNode[i] then 
            checkbox:SetCheck(1)
        end
    end
    checkbox = tolua.cast(settingGbox:GetChild('openNodeChbox'),'ui::CCheckBox')
    if g.setting.OpenNodeAll then
        checkbox:SetCheck(1)
    end
end

function BARRACKITEMLIST_SAVE_SETTINGMENU() 
    local frame = ui.GetFrame('barrackitemlist')
    local settingGbox = frame:GetChild('settingGbox')
    local hideNodeGbox = settingGbox:GetChild('hideNodeGbox')
    -- save slotsize droplist
    local droplist = tolua.cast(settingGbox:GetChild("slotColDList"), "ui::CDropList");
    g.setting.col = droplist:GetSelItemKey()
    --save hide node list
    local checkbox
    for i = 1 ,#g.nodeList do
        checkbox = tolua.cast(hideNodeGbox:GetChild('checkbox'..i),'ui::CCheckBox')
        if checkbox:IsChecked() ~= 1 then 
            g.setting.hideNode[i] = true
        else
            g.setting.hideNode[i] = false
        end
    end

    checkbox = tolua.cast(settingGbox:GetChild('openNodeChbox'),'ui::CCheckBox')
    if checkbox:IsChecked() == 1 then 
        g.setting.OpenNodeAll = true
    else
        g.setting.OpenNodeAll = false
    end
    acutil.saveJSON(g.settingPath..'setting.json',g.setting)
end

function BARRACKITEMLIST_CREATE_VAR_ICONS()
    local frame = ui.GetFrame("sysmenu");
    if false == VARICON_VISIBLE_STATE_CHANTED(frame, "necronomicon", "necronomicon")
    and false == VARICON_VISIBLE_STATE_CHANTED(frame, "grimoire", "grimoire")
    and false == VARICON_VISIBLE_STATE_CHANTED(frame, "guild", "guild")
    and false == VARICON_VISIBLE_STATE_CHANTED(frame, "poisonpot", "poisonpot")
    then
        return;
    end

    DESTROY_CHILD_BY_USERVALUE(frame, "IS_VAR_ICON", "YES");

    local extraBag = frame:GetChild('extraBag');
    local status = frame:GetChild("status");
    local offsetX = status:GetX() - extraBag:GetX();
    local rightMargin = extraBag:GetMargin().right + offsetX;

    rightMargin = SYSMENU_CREATE_VARICON(frame, extraBag, "guild", "guild", "sysmenu_guild", rightMargin, offsetX, "Guild");
    rightMargin = SYSMENU_CREATE_VARICON(frame, extraBag, "necronomicon", "necronomicon", "sysmenu_card", rightMargin, offsetX);
    rightMargin = SYSMENU_CREATE_VARICON(frame, extraBag, "grimoire", "grimoire", "sysmenu_neacro", rightMargin, offsetX);
    rightMargin = SYSMENU_CREATE_VARICON(frame, extraBag, "poisonpot", "poisonpot", "sysmenu_wugushi", rightMargin, offsetX);	
    if _G["EXPCARDCALCULATOR"] then
        rightMargin = SYSMENU_CREATE_VARICON(frame, status, "expcardcalculator", "expcardcalculator", "addonmenu_expcard", rightMargin, offsetX, "Experience Card Calculator") or rightMargin
    end
    rightMargin = SYSMENU_CREATE_VARICON(frame, status, "barrackitemlist", "barrackitemlist", "sysmenu_inv", rightMargin, offsetX, "barrack item list");

    local expcardcalculatorButton = GET_CHILD(frame, "expcardcalculator", "ui::CButton");
    if expcardcalculatorButton ~= nil then
        expcardcalculatorButton:SetTextTooltip("{@st59}expcardcalculator");
    end

    local barrackitemlistButton = GET_CHILD(frame, "barrackitemlist", "ui::CButton");
    if barrackitemlistButton ~= nil then
        barrackitemlistButton:SetTextTooltip("{@st59}barrackitemlist");
    end

    BARRACKITEMLIST_TRANSLATE_UI();
end
