local NakedObj_NoDur = {[2] = true, [4] = true, [11] = true, [12] = true, [13] = true, 
[14] = true, [15] = true, [19] = true}
NakedObj_Nakie = false;
function TUI_Nakedize()
	NakedObj_Nakie = true;
	local e = {};
	NakedObj_NakedInv = {};
	for o=0,4 do
		e[o] = 0;
		for p=1,C_Container.GetContainerNumSlots(o) do
			if (not C_Container.GetContainerItemInfo(o,p)) then
				e[o] = e[o]+1;
			end; 
		end;
	end;
	for i=19,1,-1 do
		if (not NakedObj_NoDur[i]) then
			PickupInventoryItem(i);
			if (CursorHasItem()) then
				d = false;
				for o=0,4 do
					if (e[o] > 0) then
						local _,a = string.find(GetInventoryItemLink("player",i),"|h",3);
						local b = string.find(GetInventoryItemLink("player",i),"|h",a);
						local name = string.sub(GetInventoryItemLink("player",i),a+2,b-2);
						NakedObj_NakedInv[name] = 1;
						if (o==0) then
							PutItemInBackpack(); 
						else
							PutItemInBag(19+o);
						end;
						e[o] = e[o] - 1;
						d = true;
						break;
					end;
				end;
				if (not d) then AutoEquipCursorItem(); break; end;
			end;
		end;
	end;
end;
function TUI_Dressing()
	NakedObj_Nakie = false;
	for o=0,4 do
		for p=1,C_Container.GetContainerNumSlots(o) do
			if (C_Container.GetContainerItemLink(o,p)) then
				local _,a = string.find(C_Container.GetContainerItemLink(o,p),"|h",3);
				local b = string.find(C_Container.GetContainerItemLink(o,p),"|h",a);
				local name = string.sub(C_Container.GetContainerItemLink(o,p),a+2,b-2);
				if (NakedObj_NakedInv[name] == 1) then
					C_Container.PickupContainerItem(o,p);
					AutoEquipCursorItem();
				end;
			end;
		end;
	end;
end;
function TUI_ItemRack_F9()
	if (NakedObj_Nakie == true) then
		TUI_Dressing();
	else
		TUI_Nakedize();
	end;
end;

TUI_ItemDB = TUI_ItemDB or {};
local function TUI_ItemChange(k)

	local playerDB = TUI_ItemDB[UnitName("player")]
	if not playerDB or not playerDB[k] then return end
	local db = playerDB[k];
	for i=1,18 do
		if db[i..""] ~= "null" and (getID(GetInventoryItemLink("player",i)) ~= getID(db[i..""]))then
			local flag = true;
			for o=0,4 do
				for p=1,C_Container.GetContainerNumSlots(o) do
					if (getID(C_Container.GetContainerItemLink(o,p)) == getID(db[i..""])) then
						if GetInventoryItemLink("player",i) and string.find(GetInventoryItemLink("player",i),"|h") then
							PickupInventoryItem(i);
							C_Container.PickupContainerItem(o,p);
						else
							C_Container.PickupContainerItem(o,p);
							AutoEquipCursorItem();
						end
						flag = nil;					
					end;
				end;
			end;
			if flag then
				TUI_Print("not found item "..db[i..""]);
			end
		end
	end
end
function TUI_ItemRack_F10()
	TUI_ItemChange("F10");
end;
function TUI_ItemRack_F11()
	TUI_ItemChange("F11");
end;
function TUI_ItemRack_F12()
	TUI_ItemChange("F12");
end;

SlashCmdList["TUIITEMRACK"]=function(msg)
	if tonumber(msg)<10 or tonumber(msg)>12 then
		return;
	end
	if (TUI_ItemDB[UnitName("player")] == nil ) then
		TUI_ItemDB[UnitName("player")] = {}
	end	
	TUI_ItemDB[UnitName("player")]["F"..msg] = {}
	for i=18,1,-1 do
		if GetInventoryItemLink("player",i) and string.find(GetInventoryItemLink("player",i),"|h") then
			TUI_ItemDB[UnitName("player")]["F"..msg][i..""] = GetInventoryItemLink("player",i)
		else
			TUI_ItemDB[UnitName("player")]["F"..msg][i..""] = "null"
		end
	end
	--ReloadUI();
end
SLASH_TUIITEMRACK1="/TUIITEMRACK";
SLASH_TUIITEMRACK2="/ti";

SlashCmdList["TUIH3"]=function(msg)
	if (TUI_ItemDB[UnitName("player")] == nil ) then
		TUI_ItemDB[UnitName("player")] = {}
	end	
	TUI_ItemDB[UnitName("player")]["H3"] = GetItemInfo(msg)
end
SLASH_TUIH31="/TUIH3";
SLASH_TUIH32="/t3";
SlashCmdList["TUIH0"]=function(msg)
	if (TUI_ItemDB[UnitName("player")] == nil ) then
		TUI_ItemDB[UnitName("player")] = {}
	end	
	TUI_ItemDB[UnitName("player")]["H0"] = GetItemInfo(msg)
end
SLASH_TUIH01="/TUIH0";
SLASH_TUIH02="/t0";

function TUI_Change(msg)
	if (TUI_ItemDB[UnitName("player")] == nil ) then
		TUI_ItemDB[UnitName("player")] = {}
	end		
	
	local h = TUI_ItemDB[UnitName("player")]["H"..msg];
	local h16 = GetInventoryItemLink("player",16);
	if (IsEquippedItem(h)) then
		if (h16 and GetItemInfo(h16) ~= h) then
			
			PickupInventoryItem(16);
			PickupInventoryItem(17);
		end
	else
		EquipItemByName(h);
	end
end

function TUI_Equip_10()
	if (TUI_ItemDB[UnitName("player")] == nil ) then
		return
	end		
	local db = TUI_ItemDB[UnitName("player")]["F10"];
	if (db == nil ) then
		return
	end
	local db16 = db["16"];
	local db17 = db["17"];
	if ( (db16 == nil or db16 =="null") and (db17 == nil or db17 =="null")) then
		return
	end
	local id16=getID(db16);
	local id17=getID(db17);
	if id16 and getID(GetInventoryItemLink("player",16)) ~= id16 then
		EquipItemByName(id16);
	end
	if id17 and getID(GetInventoryItemLink("player",17)) ~= id17 then
		EquipItemByName(id17);
	end
end
function TUI_Equip_12()
	if (TUI_ItemDB[UnitName("player")] == nil ) then
		return
	end		
	local db = TUI_ItemDB[UnitName("player")]["F12"];
	if (db == nil ) then
		return
	end
	local db16 = db["16"];
	if (db16 == nil or db16 =="null") then
		return
	end
	local id16=getID(db16);
	if id16 and getID(GetInventoryItemLink("player",16)) ~= id16 then
		EquipItemByName(id16);
	end

	local db17 = db["17"];
	if (db17 == nil or db17 =="null") then
		return
	end
	local id17=getID(db17);
	if id17 and getID(GetInventoryItemLink("player",17)) ~= id17 then		
		PickupInventoryItem(17);
		PutItemInBackpack(); 
		EquipItemByName(id17);
	end
end