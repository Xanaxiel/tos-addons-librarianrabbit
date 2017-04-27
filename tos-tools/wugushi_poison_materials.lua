local clsList, cnt = GetClassList("item_poisonpot");

for i = 0, cnt - 1 do
	local cls = GetClassByIndexFromList(clsList, i);
	print(GetClass("Item", cls.ClassName).Name .. " : " .. cls.PoisonAmount)
end
