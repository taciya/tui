
local function gn(id,id1,id2,id3)
	local name=select(1, TUI_Compat.GetSpellNameByID(id));	
	if(name ) then
		return name
	end
	
	name=select(1, TUI_Compat.GetSpellNameByID(id1));
	if(name ) then
		return name
	end	
	
	name=select(1, TUI_Compat.GetSpellNameByID(id2));	
	if(name ) then
		return name
	end
	
	name=select(1, TUI_Compat.GetSpellNameByID(id3));	
	if(name ) then
		return name
	end
	return "";
end
local function GetSpellID(spell, rank)
	if not spell then return nil end
	if C_SpellBook and C_SpellBook.FindSpellBookSlotForSpell and C_SpellBook.GetSpellBookItemType and Enum and Enum.SpellBookSpellBank then
		local slot, bank = C_SpellBook.FindSpellBookSlotForSpell(spell)
		if slot then
			local _, actionID, spellID = C_SpellBook.GetSpellBookItemType(slot, bank or Enum.SpellBookSpellBank.Player)
			return spellID or actionID
		end
	end
	if GetSpellName then
		for i = 1, 500 do
			local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL or "spell")
			if not spellName then break end
			if spellName == spell and (not rank or spellRank == rank) then return i, spellRank end
		end
	end
end
--[[


local function gn(id,id1,id2,id3)
	local name=select(1, TUI_Compat.GetSpellNameByID(id));	
	local spellID=GetSpellID(name) or 0;
	if(name and spellID>0) then
		return name
	end

	name=select(1, TUI_Compat.GetSpellNameByID(id1));	
	spellID=GetSpellID(name) or 0;
	if(name and spellID>0) then
		return name
	end

	name=select(1, TUI_Compat.GetSpellNameByID(id2));	
	spellID=GetSpellID(name) or 0;
	if(name and spellID>0) then
		return name
	end

	name=select(1, TUI_Compat.GetSpellNameByID(id3));	
	spellID=GetSpellID(name) or 0;
	if(name and spellID>0) then
		return name
	end

	return "";
end
--]]
TUIBinds={}
TUIBinds.Party={PartyMemberFrame1,PartyMemberFrame2,PartyMemberFrame3,PartyMemberFrame4,PlayerFrame,PartyMemberFrame1PetFrame,PartyMemberFrame2PetFrame,PartyMemberFrame3PetFrame,PartyMemberFrame4PetFrame,TargetFrameTargetFrame}
TUIBinds.Target = {TargetFrame}
TUIBinds.MouseButtons = {
	LeftButton = 1,
	RightButton = 2,
	MiddleButton = 3,
	Button4 = 4,
	Button5 = 5,
}
TUIBinds.Modifiers = {
	CTRL = true,
	SHIFT = true,
	ALT = true,
}
TUIBinds.common={
	{Key = "ESCAPE", Type = "command", Value = "TOGGLEGAMEMENU"},
	{Key = "W", Type = "command", Value = "MOVEFORWARD"},
	{Key = "S", Type = "command", Value = "MOVEBACKWARD"},
	{Key = "A", Type = "command", Value = "TURNLEFT"},
	{Key = "D", Type = "command", Value = "TURNRIGHT"},
	{Key="TAB", Type="command", Value="TARGETNEARESTFRIEND"},
	{Key="E", Type="command", Value="ATTACKTARGET"},
	{Key="`", Type="command", Value="ALLNAMEPLATES"},
	{Key="Q", Type="command", Value="TARGETNEARESTENEMY"},
	{Key="F1", Type="command", Value="RAIDTARGET1"},
	{Key="F2", Type="command", Value="RAIDTARGET2"},
	{Key="F3", Type="command", Value="RAIDTARGET3"},
	{Key="F4", Type="command", Value="RAIDTARGET4"},
	{Key="F5", Type="command", Value="RAIDTARGET5"},
	{Key="F6", Type="command", Value="RAIDTARGET6"},
	{Key="F7", Type="command", Value="RAIDTARGET7"},
	{Key="F8", Type="command", Value="RAIDTARGET8"},
	{Key="F9", Type="macro",Value="/script TUI_ItemRack_F9()"},
	{Key="F10",Type="macro",Value="/script TUI_ItemRack_F10()"},	
	{Key="F11",Type="macro",Value="/script TUI_ItemRack_F11()"},	
	{Key="F12",Type="macro",Value="/script TUI_ItemRack_F12()"},		
	{Key = "SPACE", Type = "command", Value = "JUMP", Comment = "跳跃"},
	{Key = "NUMLOCK", Type = "command", Value = "TOGGLEAUTORUN", Comment = "自动奔跑"},

	{Key = "1", Type = "command", Value = "ACTIONBUTTON1"},
	{Key = "2", Type = "command", Value = "ACTIONBUTTON2"},
	{Key = "3", Type = "command", Value = "ACTIONBUTTON3"},
	{Key = "4", Type = "command", Value = "ACTIONBUTTON4"},
	{Key = "SHIFT-C", Type = "command", Value = "ACTIONBUTTON5", Target = "target"},
	{Key = "SHIFT-V", Type = "command", Value = "ACTIONBUTTON6", Target = "target"},
	--{Key = "SHIFT-S", Type = "command", Value = "ACTIONBUTTON7",  Target = "target"},
	{Key = "SHIFT-D", Type = "command", Value = "ACTIONBUTTON8",  Target = "target"},
	{Key = "F", Type = "command", Value = "ACTIONBUTTON12"},

	{Key = "Z", Type = "command", Value = "MULTIACTIONBAR1BUTTON1", Target = "target"},
	{Key = "X", Type = "command", Value = "MULTIACTIONBAR1BUTTON2", Target = "target"},
	{Key = "C", Type = "command", Value = "MULTIACTIONBAR1BUTTON3", Target = "target"},
	{Key = "V", Type = "command", Value = "MULTIACTIONBAR1BUTTON4", Target = "target"},
	{Key = "SHIFT-W", Type = "command", Value = "MULTIACTIONBAR1BUTTON5", Target = "target"},
	{Key = "SHIFT-A", Type = "command", Value = "MULTIACTIONBAR1BUTTON6",  Target = "target"},
	{Key = "MiddleButton", Type = "command", Value = "MULTIACTIONBAR1BUTTON7", Target = "target"},
	{Key = "SHIFT-S", Type = "command", Value = "MULTIACTIONBAR1BUTTON8", Target = "target"},
	{Key = "SHIFT-E", Type = "command", Value = "MULTIACTIONBAR1BUTTON9", Target = "target"},
	{Key = "SHIFT-R", Type = "command", Value = "MULTIACTIONBAR1BUTTON10", Target = "target"},
	{Key = "SHIFT-Q", Type = "command", Value = "MULTIACTIONBAR1BUTTON11", Target = "target"},
	{Key = "SHIFT-F", Type = "command", Value = "MULTIACTIONBAR1BUTTON12", Target = "target"},


}
--[[
TUIBinds.MONK={
	{Key = "1", Type = "command", Value = "ACTIONBUTTON1"},
	{Key = "2", Type = "command", Value = "ACTIONBUTTON2"},
	{Key = "3", Type = "command", Value = "ACTIONBUTTON3"},
	{Key = "4", Type = "command", Value = "ACTIONBUTTON4"},

	{Key = "Z", Type = "command", Value = "MULTIACTIONBAR1BUTTON1", Target = "target"},
	{Key = "X", Type = "command", Value = "MULTIACTIONBAR1BUTTON2", Target = "target"},
	{Key = "C", Type = "command", Value = "MULTIACTIONBAR1BUTTON3", Target = "target"},
	{Key = "V", Type = "command", Value = "MULTIACTIONBAR1BUTTON4", Target = "target"},
	{Key = "F", Type = "command", Value = "ACTIONBUTTON12"},
	{Key = "SHIFT-C", Type = "command", Value = "ACTIONBUTTON6", Target = "target"},
	{Key = "SHIFT-V", Type = "command", Value = "ACTIONBUTTON7", Target = "target"},	
	{Key = "SHIFT-R", Type = "command", Value = "ACTIONBUTTON8", Target = "target"},
	{Key = "SHIFT-W", Type = "command", Value = "ACTIONBUTTON9", Target = "target"},
	{Key = "SHIFT-E", Type = "command", Value = "MULTIACTIONBAR1BUTTON8", Target = "target"},
	{Key = "SHIFT-Q", Type = "command", Value = "MULTIACTIONBAR1BUTTON9", Target = "target"},
	{Key = "SHIFT-F", Type = "command", Value = "MULTIACTIONBAR1BUTTON10", Target = "target"},
	

}
--]]
TUIBinds.PALADIN_bak={
	{Key = "1", Type = "command", Value = "ACTIONBUTTON1"},
	{Key = "2", Type = "command", Value = "ACTIONBUTTON2"},
	{Key = "3", Type = "command", Value = "ACTIONBUTTON3"},
	{Key = "4", Type = "command", Value = "ACTIONBUTTON4"},
	--{Key="3",Type="macro",Value="/castsequence reset=14 "..gn(5615)..","..gn(62124)},--驅邪術,清算聖禦
	--{Key="SHIFT-E",Type="macro",Value="/cast [help][target=player]"..gn(5599)},--保護聖禦
	{Key="SHIFT-E",Type="macro",Value="/castsequence reset=290 圣盾术,保护之手"},--聖盾術,保護聖禦
	{Key="SHIFT-V",Type="macro",Value="/cast [help][target=player]圣疗术"},--聖療術
	{Key="SHIFT-F",Type="macro",Value="/cast [help][target=player]自由之手"},--自由聖禦
	{Key="SHIFT-D",Type="macro",Value="/cast [help][target=targettarget,help]正义防护"},--正義防禦..gn(31789)
	{Key="SHIFT-R",Type="spell",Value="神圣愤怒"},--神聖憤怒
	{Key="SHIFT-Q",Type="spell",Value="神圣风暴"},--神性風暴	
	--{Key="V",Type="macro",Value="/cast [help][target=player]"..gn(1042)},--聖光術
	{Key="F",Type="macro",Value="/cast [help][target=player]净化术"},--4987,1152 淨化術,純淨術
	--{Key="C",Type="macro",Value="/cast [help][target=player]"..gn(19939)},--聖光閃現
	--{Key="SHIFT-C",Type="macro",Value="/castsequence reset=170 "..gn(498)..","..gn(642)},--聖佑術,聖盾術
	{Key="SHIFT-C",Type="spell",Value="圣佑术"},--聖佑術,聖盾術
	{Key="SHIFT-A",Type="spell",Value="奉献"},--奉獻
	--{Key="SHIFT-S",Type="spell",Value="神圣之盾"},--懺悔,神聖之盾,復仇聖印,{ {IF="懺悔",Value="懺悔"},{IF="神聖之盾",Value="神聖之盾"},{IF="復仇聖印",Value="復仇聖印"}}, Target = "target"},
	{Key="SHIFT-S",Type="spell",Value="炽热防御者"},
	{Key="Z",Type="command",Value="MULTIACTIONBAR1BUTTON1"},
	{Key="X",Type="command",Value="MULTIACTIONBAR1BUTTON2"},
	{Key="C",Type="command",Value="MULTIACTIONBAR1BUTTON3"},
	{Key="V",Type="command",Value="MULTIACTIONBAR1BUTTON4"},
	{Key="SHIFT-W",Type="command",Value="MULTIACTIONBAR1BUTTON5"},
--[[
	{Key = "SHIFT-LeftButton", Type = "spell", Value = gn(19939), TargetFrames = TUIBinds.Party},--聖光閃現
	{Key = "CTRL-LeftButton", Type = "spell", Value = gn(20217), TargetFrames = TUIBinds.Party},--"王者祝福"
	{Key = "ALT-LeftButton", Type = "spell", Value = gn(19853), TargetFrames = TUIBinds.Party},--智慧祝福
	{Key = "SHIFT-RightButton", Type = "spell", Value = gn(1042), TargetFrames = TUIBinds.Party},--聖光術
	{Key = "CTRL-RightButton", Type = "spell", Value = gn(19837), TargetFrames = TUIBinds.Party},--力量祝福
	{Key = "ALT-RightButton", Type = "spell", Value = gn(4987), TargetFrames = TUIBinds.Party},--淨化術,純淨術
	{Key = "SHIFT-LeftButton", Type = "macro", Value = "/focus target", TargetFrames = TUIBinds.Target},
--]]
}
TUIBinds.WARRIOR={
	{Key = "Z", Type = "command", Value = "MULTIACTIONBAR1BUTTON1"},
	{Key = "X", Type = "command", Value = "MULTIACTIONBAR1BUTTON2"},
	{Key = "C", Type = "command", Value = "MULTIACTIONBAR1BUTTON3"},
	{Key = "V", Type = "command", Value = "MULTIACTIONBAR1BUTTON4"},	
	{Key = "SHIFT-C", Type = "command", Value = "ACTIONBUTTON5"},
	--{Key = "SHIFT-V", Type = "macro", Value = "/cast [stance:1/3]"..gn(20662)..";冲击波", Target = "target"},--20662 斩杀
	{Key = "SHIFT-V", Type = "command", Value = "ACTIONBUTTON6"},
	--{Key = "MiddleButton", Type = "command", Value = "ACTIONBUTTON7"},
	{Key = "SHIFT-D", Type = "command", Value = "ACTIONBUTTON8"},
	{Key = "SHIFT-S", Type = "command", Value = "ACTIONBUTTON9"},
	{Key = "F", Type = "command", Value = "ACTIONBUTTON12"},

	--{Key = "MiddleButton", Type = "macro", Value = "/cancelaura 猝死\n/cast 斩杀"},--钓鱼
	--{Key = "1", Type = "spell", Value = gn(25286), Target = "target"},--25286 英勇打击
	--{Key = "4", Type = "spell", Value = gn(7386), Target = "target"},--7386 破甲攻击
	--{Key = "3", Type = "spell", Value = gn(11578), Target = "target"},--11578 冲锋	
	{Key = "1", Type = "command", Value = "ACTIONBUTTON1"},
	{Key = "2", Type = "command", Value = "ACTIONBUTTON2"},
	{Key = "3", Type = "command", Value = "ACTIONBUTTON3"},	
	{Key = "4", Type = "command", Value = "ACTIONBUTTON4"},
	--{Key = "2", Type = "spell", Value = gn(25241), Target = "target"},--25241 猛击

	{Key = "MiddleButton", Type = "command", Value = "MULTIACTIONBAR1BUTTON7"},
	{Key = "SHIFT-A", Type = "command", Value = "MULTIACTIONBAR1BUTTON6",  Target = "target"},
	--{Key = "SHIFT-S", Type = "command", Value = "MULTIACTIONBAR1BUTTON7",  Target = "target"},
	--{Key = "SHIFT-D", Type = "command", Value = "MULTIACTIONBAR1BUTTON8",  Target = "target"},
	{Key = "SHIFT-Q", Type = "command", Value = "MULTIACTIONBAR1BUTTON11",  Target = "target"},
	{Key = "SHIFT-E", Type = "command", Value = "MULTIACTIONBAR1BUTTON9",  Target = "target"},
	{Key = "SHIFT-R", Type = "command", Value = "MULTIACTIONBAR1BUTTON10",  Target = "target"},
	{Key = "SHIFT-W", Type = "command", Value = "MULTIACTIONBAR1BUTTON5",  Target = "target"},
	{Key = "SHIFT-F", Type = "command", Value = "MULTIACTIONBAR1BUTTON12",  Target = "target"},

--通过函数切换武器，适用于非战斗模式
	--{Key = "SHIFT-A", Type = "macro", Value = "/cast [stance:1/2]狂暴姿态;[stance:0]狂暴之怒"},
	--{Key = "SHIFT-S", Type = "macro", Value = "/cast [stance:1/0]战斗姿态;[stance:2,combat]反击风暴;"},
	--{Key = "SHIFT-D", Type = "macro", Value = "/cast [stance:2/0]!防御姿态;[stance:1,combat]破釜沉舟"},

--[[

--通过宏切换武器，适用于非战斗/战斗模式
--/script PickupContainerItem(1, 1) PickupInventoryItem(16) PickupContainerItem(1, 1) 
--/script PickupContainerItem(1, 2) PickupInventoryItem(17) PickupContainerItem(1, 2)
	--{Key = "SHIFT-A", Type = "macro", Value = "/cast [stance:1]"..gn(2458)..";[stance:3]狂暴之怒;[stance:2]"..gn(2458).."\n/stopcasting\n/script TUI_Equip_12()"},--2458 狂暴姿态  / 鲁莽
	--{Key = "SHIFT-S", Type = "macro", Value = "/cast [stance:2]"..gn(2457)..";[stance:1,combat]反击风暴;[stance:3]"..gn(2457).."\n/stopcasting\n/script TUI_Equip_12()"},--2457 战斗姿态
	--{Key = "SHIFT-D", Type = "macro", Value = "/cast [stance:1]"..gn(71)..";[stance:2,combat]盾墙;[stance:3]"..gn(71).."\n/stopcasting\n/script TUI_Equip_10()"},--71 防御姿态
	--/equipslot [equiped:多彩之剑] 16 毁灭之刃
	{Key = "SHIFT-A", Type = "macro", Value = "/cast [stance:1]"..gn(2458)..";[stance:3]狂暴之怒;[stance:2]"..gn(2458).."\n/stopcasting".."\n/equipslot 16 "..(GetItemInfo(TUI_ItemDB[UnitName("player")]["F12"]["16"]) or "").."\n/equipslot 17 "..(GetItemInfo(TUI_ItemDB[UnitName("player")]["F12"]["17"]) or "")},--2458 狂暴姿态  / 鲁莽
	{Key = "SHIFT-S", Type = "macro", Value = "/cast [stance:2]"..gn(2457)..";[stance:1,combat]反击风暴;[stance:3]"..gn(2457).."\n/stopcasting".."\n/equipslot 16 "..(GetItemInfo(TUI_ItemDB[UnitName("player")]["F12"]["16"]) or "").."\n/equipslot 17 "..(GetItemInfo(TUI_ItemDB[UnitName("player")]["F12"]["17"]) or "")},--2457 战斗姿态
	{Key = "SHIFT-D", Type = "macro", Value = "/cast [stance:1]"..gn(71)..";[stance:2,combat]盾墙;[stance:3]"..gn(71).."\n/stopcasting".."\n/equipslot 16 "..(GetItemInfo(TUI_ItemDB[UnitName("player")]["F10"]["16"]) or "").."\n/equipslot 17 "..(GetItemInfo(TUI_ItemDB[UnitName("player")]["F10"]["17"]) or "")},--71 防御姿态	

	--{Key = "SHIFT-F", Type = "macro", Value = "/castsequence reset=50 "..gn(2687)..","..gn(18499), Target = "player"},--2687 血性狂暴		18499 狂暴之怒
	{Key = "SHIFT-F", Type = "macro", Value = "/cast "..gn(2687), Target = "player"},--2687 血性狂暴		18499 狂暴之怒
	{Key = "SHIFT-E", Type = "macro", Value = "/stopattack\n/cast "..gn(5246), Target = "player"},--5246 破胆怒吼
	{Key = "SHIFT-R", Type = "command", Value = "ACTIONBUTTON8"},	
	{Key = "SHIFT-T", Type = "macro", Value = "/cast "..gn(23920), Target = "target"},--23920 法术反射
	--{Key = "SHIFT-Q", Type = "macro", Value = "/castsequence reset=4 "..gn(6343)..",挫志怒吼", Target = "target"},--6343 11556 雷霆一击 挫志怒吼
	--{Key = "SHIFT-Q", Type = "command", Value = "ACTIONBUTTON9"},
	{Key = "SHIFT-Q", Type = "macro", Value = "/cast [stance:1]"..gn(6343)..";[stance:2]"..gn(11556)..";[stance:3]"..gn(6343), Target = "target"},--6343 11556 雷霆一击 挫志怒吼\\


--]]
}

TUIBinds.HUNTER= {
	{Key = "SHIFT-A", Type = "macro", Value = "/petattack", Target = "target"},
	{Key = "SHIFT-S", Type = "macro", Value = "/petpassive", Target = "target"},
	{Key = "SHIFT-D", Type = "macro", Value = "/petstay", Target = "target"},
	{Key = "SHIFT-C", Type = "macro", Value = "/cast 假死\n/petpassive", Target = "target"},	
}

TUIBinds.WARLOCK= {

	{Key = "SHIFT-A", Type = "macro", Value = "/petattack", Target = "target"},
	{Key = "SHIFT-S", Type = "macro", Value = "/petfollow", Target = "target"},
	{Key = "SHIFT-D", Type = "macro", Value = "/petstay", Target = "target"},

}

--[[
TUIBinds.MAGE= {
	{Key = "1", Type = "command", Value = "ACTIONBUTTON1"},
	{Key = "2", Type = "command", Value = "ACTIONBUTTON2"},
	{Key = "3", Type = "command", Value = "ACTIONBUTTON3"},
	{Key = "4", Type = "command", Value = "ACTIONBUTTON4"},
	{Key = "F", Type = "command", Value = "ACTIONBUTTON12"},
	{Key = "Z", Type = "command", Value = "MULTIACTIONBAR1BUTTON1",  Target = "target"},
	{Key = "X", Type = "command", Value = "MULTIACTIONBAR1BUTTON2", Target = "target"},
	{Key = "C", Type = "command", Value = "MULTIACTIONBAR1BUTTON3",  Target = "target"},
	{Key = "V", Type = "command", Value = "MULTIACTIONBAR1BUTTON4",  Target = "target"},
	{Key = "SHIFT-C", Type = "command", Value = "MULTIACTIONBAR1BUTTON5",   Target = "player"},	
	{Key = "SHIFT-A", Type = "command", Value = "MULTIACTIONBAR1BUTTON6",  Target = "target"},
	--{Key = "SHIFT-S", Type = "command", Value = "MULTIACTIONBAR1BUTTON7",  Target = "target"},
	{Key = "SHIFT-D", Type = "command", Value = "MULTIACTIONBAR1BUTTON8",  Target = "target"},
	{Key = "SHIFT-W", Type = "command", Value = "ACTIONBUTTON5"},
	{Key = "SHIFT-S", Type = "command", Value = "ACTIONBUTTON7",  Target = "target"},
	{Key = "SHIFT-E", Type = "command", Value = "MULTIACTIONBAR1BUTTON9",  Target = "target"},
	{Key = "SHIFT-R", Type = "command", Value = "MULTIACTIONBAR1BUTTON10",  Target = "target"},
	{Key = "SHIFT-V", Type = "command", Value = "MULTIACTIONBAR1BUTTON11",  Target = "target"},
	{Key = "SHIFT-F", Type = "command", Value = "MULTIACTIONBAR1BUTTON12",  Target = "target"},
}
--]]
TUIBinds.SHAMAN= {
--[[
	{Key = "1", Type = "command", Value = "ACTIONBUTTON1"},
	{Key = "2", Type = "command", Value = "ACTIONBUTTON2"},
	{Key = "3", Type = "command", Value = "ACTIONBUTTON3"},
	{Key = "4", Type = "command", Value = "ACTIONBUTTON4"},

	{Key = "Z", Type = "command", Value = "MULTIACTIONBAR1BUTTON1",  Target = "target"},
	{Key = "X", Type = "command", Value = "MULTIACTIONBAR1BUTTON2", Target = "target"},
	{Key = "C", Type = "command", Value = "MULTIACTIONBAR1BUTTON3",  Target = "target"},
	{Key = "V", Type = "command", Value = "MULTIACTIONBAR1BUTTON4",  Target = "target"},
	{Key = "SHIFT-V", Type = "command", Value = "ACTIONBUTTON6",  Target = "target"},
	{Key = "SHIFT-C", Type = "command", Value = "ACTIONBUTTON5",  Target = "target"},

	{Key = "SHIFT-A", Type = "command", Value = "MULTIACTIONBAR1BUTTON6",  Target = "target"},
	{Key = "SHIFT-S", Type = "command", Value = "MULTIACTIONBAR1BUTTON7",  Target = "target"},
	{Key = "SHIFT-D", Type = "command", Value = "MULTIACTIONBAR1BUTTON8",  Target = "target"},
	{Key = "SHIFT-Q", Type = "command", Value = "MULTIACTIONBAR1BUTTON11",  Target = "target"},
	{Key = "SHIFT-E", Type = "command", Value = "MULTIACTIONBAR1BUTTON9",  Target = "target"},
	{Key = "SHIFT-R", Type = "command", Value = "MULTIACTIONBAR1BUTTON10",  Target = "target"},
	{Key = "SHIFT-W", Type = "command", Value = "MULTIACTIONBAR1BUTTON5",  Target = "target"},
	{Key = "SHIFT-F", Type = "command", Value = "MULTIACTIONBAR1BUTTON12",  Target = "target"},

	{Key = "F", Type = "command", Value = "ACTIONBUTTON11"},--精灵之火

	{Key = "SHIFT-LeftButton", Type = "spell", Value = gn(49276), TargetFrames = TUIBinds.Party},--次级治疗波
	{Key = "CTRL-LeftButton", Type = "spell", Value = gn(6077), TargetFrames = TUIBinds.Party},--恢复
	{Key = "ALT-LeftButton", Type = "spell", Value = gn(528), TargetFrames = TUIBinds.Party},--祛病术
	{Key = "SHIFT-RightButton", Type = "spell", Value = gn(49273), TargetFrames = TUIBinds.Party},--治疗波
	{Key = "CTRL-RightButton", Type = "spell", Value = gn(6065), TargetFrames = TUIBinds.Party},--真言术：盾
	{Key = "ALT-RightButton", Type = "spell", Value = gn(527), TargetFrames = TUIBinds.Party},--驱散魔法

	{Key = "SHIFT-LeftButton", Type = "macro", Value = "/focus target", TargetFrames = TUIBinds.Target},
--]]
}
--[[
TUIBinds.PRIEST= {

	{Key = "1", Type = "command", Value = "ACTIONBUTTON1"},
	{Key = "2", Type = "command", Value = "ACTIONBUTTON2"},
	{Key = "3", Type = "command", Value = "ACTIONBUTTON3"},
	{Key = "4", Type = "command", Value = "ACTIONBUTTON4"},
	{Key = "F", Type = "command", Value = "ACTIONBUTTON11"},
	{Key = "Z", Type = "command", Value = "MULTIACTIONBAR1BUTTON1",  Target = "target"},
	{Key = "X", Type = "command", Value = "MULTIACTIONBAR1BUTTON2", Target = "target"},
	{Key = "C", Type = "command", Value = "MULTIACTIONBAR1BUTTON3",  Target = "target"},
	{Key = "V", Type = "command", Value = "MULTIACTIONBAR1BUTTON4",  Target = "target"},
	{Key = "SHIFT-C", Type = "command", Value = "ACTIONBUTTON5",   Target = "target"},	
	{Key = "SHIFT-V", Type = "command", Value = "ACTIONBUTTON6",  Target = "target"},

	{Key = "SHIFT-A", Type = "spell", Value = "暗影形态"},
	{Key = "SHIFT-S", Type = "command", Value = "MULTIACTIONBAR1BUTTON7",  Target = "target"},
	{Key = "SHIFT-D", Type = "command", Value = "MULTIACTIONBAR1BUTTON8",  Target = "target"},
	{Key = "SHIFT-Q", Type = "command", Value = "MULTIACTIONBAR1BUTTON6",  Target = "target"},
	{Key = "SHIFT-E", Type = "command", Value = "MULTIACTIONBAR1BUTTON9",  Target = "target"},
	{Key = "SHIFT-R", Type = "command", Value = "MULTIACTIONBAR1BUTTON10",  Target = "target"},
	{Key = "SHIFT-W", Type = "command", Value = "MULTIACTIONBAR1BUTTON5",  Target = "target"},
	{Key = "SHIFT-F", Type = "command", Value = "MULTIACTIONBAR1BUTTON12",  Target = "target"},

	{Key = "MiddleButton", Type = "spell", Value = "治疗之环", TargetFrames = TUIBinds.Party},--	
	{Key = "SHIFT-MiddleButton", Type = "spell", Value = "治疗祷言", TargetFrames = TUIBinds.Party},	
	{Key = "CTRL-MiddleButton", Type = "spell", Value = "真言术：韧", TargetFrames = TUIBinds.Party},--gn(7731)钓鱼
	{Key = "ALT-MiddleButton", Type = "spell", Value = "驱散魔法", TargetFrames = TUIBinds.Party},--gn(527) 驱散魔法

	{Key = "SHIFT-LeftButton", Type = "spell", Value = gn(9473), TargetFrames = TUIBinds.Party},--次级治疗术 gn(9473) 快速治疗
	{Key = "CTRL-LeftButton", Type = "spell", Value = "愈合祷言", TargetFrames = TUIBinds.Party},
	{Key = "ALT-LeftButton", Type = "spell", Value = gn(6077), TargetFrames = TUIBinds.Party},--gn(6077) 恢复

	{Key = "RightButton", Type = "spell", Value = gn(527), TargetFrames = TUIBinds.Party},--gn(527) 驱散魔法
	{Key = "SHIFT-RightButton", Type = "spell", Value =  "治疗术", TargetFrames = TUIBinds.Party},--gn(2060,6064) 治疗术,强效治疗术
	{Key = "CTRL-RightButton", Type = "spell", Value = gn(6065), TargetFrames = TUIBinds.Party},--gn(6065) 真言术：盾
	{Key = "ALT-RightButton", Type = "spell", Value = "祛病术", TargetFrames = TUIBinds.Party},-- gn(552,528) 驱除疾病,祛病术
}

TUIBinds.DRUID={
	{Key = "1", Type = "command", Value = "ACTIONBUTTON1"},
	{Key = "2", Type = "command", Value = "ACTIONBUTTON2"},
	{Key = "3", Type = "command", Value = "ACTIONBUTTON3"},	
	{Key = "4", Type = "command", Value = "ACTIONBUTTON4"},
	{Key = "SHIFT-C", Type = "command", Value = "ACTIONBUTTON5"},
	{Key = "SHIFT-V", Type = "command", Value = "ACTIONBUTTON6"},
	{Key = "SHIFT-W", Type = "command", Value = "ACTIONBUTTON7"},
	{Key = "SHIFT-R", Type = "command", Value = "ACTIONBUTTON8"},
	{Key = "F", Type = "command", Value = "ACTIONBUTTON12"},	

	{Key = "MiddleButton", Type = "command", Value = "MULTIACTIONBAR1BUTTON7"},

	{Key = "Z", Type = "command", Value = "MULTIACTIONBAR1BUTTON1"},
	{Key = "X", Type = "command", Value = "MULTIACTIONBAR1BUTTON2"},
	{Key = "C", Type = "command", Value = "MULTIACTIONBAR1BUTTON3"},
	{Key = "V", Type = "command", Value = "MULTIACTIONBAR1BUTTON4"},	
	{Key = "SHIFT-F", Type = "command", Value = "MULTIACTIONBAR1BUTTON10"},
	{Key = "SHIFT-E", Type = "command", Value = "MULTIACTIONBAR1BUTTON9"},
	{Key = "SHIFT-Q", Type = "command", Value = "MULTIACTIONBAR1BUTTON8"},


	--{Key = "1", Type = "macro", Value = "/cast [stealth]突袭;[stance:1]重殴;[stance:3]爪击;愤怒",  Target = "target"},--裂伤 - 豹
	--{Key = "2", Type = "macro", Value = "/cast [stance:1]低吼;[stance:3]斜掠;月火术",  Target = "target"},
	--{Key = "3", Type = "macro", Value = "/cast [stealth]毁灭;[stance:1]横扫;[stance:3]撕碎;星火术",  Target = "target"},
	--{Key = "4", Type = "macro", Value = "/cast [stance:1]猛击;[stance:3]割裂;纠缠根须",  Target = "target"},	

}
--]]
--[[
TUIBinds.ROGUE= {
	{Key = "F", Type = "macro", Value = "/cast [stealth]搜索;脚踢",  Target = "target"},
	{Key = "Z", Type = "command", Value = "MULTIACTIONBAR1BUTTON1",  Target = "target"},
	{Key = "X", Type = "command", Value = "MULTIACTIONBAR1BUTTON2", Target = "target"},
	{Key = "C", Type = "macro", Value = "/cast [stealth]搜索\n/cast [nostealth]凿击;闷棍",  Target = "target"},
	{Key = "V", Type = "command", Value = "MULTIACTIONBAR1BUTTON3",  Target = "target"},

	{Key = "1", Type = "macro", Value = "/script TUI_Change(0)\n/cast [stealth]搜索\n/cast [nostealth]影袭;偷袭",  Target = "target"},
	{Key = "2", Type = "macro", Value = "/script TUI_Change(0)\n/cast [stealth]搜索\n/cast [nostealth]刺骨;锁喉",  Target = "target"},
	{Key = "3", Type = "macro", Value = "/script TUI_Change(3)\n/cast [stealth]搜索\n/cast [nostealth]背刺;伏击",  Target = "target"},
	{Key = "4", Type = "macro", Value = "/script TUI_Change(3)\n/cast [stealth]搜索\n/cast 破甲",  Target = "target"},

	{Key = "SHIFT-C", Type = "spell", Value = "暗影斗篷",   Target = "player"},	
	{Key = "SHIFT-A", Type = "command", Value = "MULTIACTIONBAR1BUTTON4",  Target = "target"},
	{Key = "SHIFT-S", Type = "spell", Value = "致盲",  Target = "target"},
	{Key = "SHIFT-D", Type = "spell", Value = "佯攻",  Target = "target"},		
	{Key = "SHIFT-E", Type = "spell", Value = "肾击",  Target = "target"},
	{Key = "SHIFT-R", Type = "command", Value = "ACTIONBUTTON6",  Target = "target"},
	{Key = "SHIFT-W", Type = "command", Value = "ACTIONBUTTON7",  Target = "target"},
	{Key = "SHIFT-V", Type = "command", Value = "MULTIACTIONBAR1BUTTON5",  Target = "target"},
	{Key = "SHIFT-F", Type = "macro", Value = "/cast [combat]消失;[nocombat,nostealth]潜行",  Target = "target"},
}

TUIBinds.DEATHKNIGHT= {
	{Key = "1", Type = "command", Value = "ACTIONBUTTON1"},
	{Key = "2", Type = "command", Value = "ACTIONBUTTON2"},
	{Key = "3", Type = "command", Value = "ACTIONBUTTON3"},
	{Key = "4", Type = "command", Value = "ACTIONBUTTON4"},
	{Key = "SHIFT-C", Type = "command", Value = "ACTIONBUTTON5"},
	{Key = "SHIFT-V", Type = "command", Value = "ACTIONBUTTON6"},
	{Key = "SHIFT-D", Type = "command", Value = "ACTIONBUTTON8"},
	{Key = "SHIFT-S", Type = "command", Value = "ACTIONBUTTON9"},
	{Key = "F", Type = "command", Value = "ACTIONBUTTON12"},

	{Key = "Z", Type = "command", Value = "MULTIACTIONBAR1BUTTON1",  Target = "target"},
	{Key = "X", Type = "command", Value = "MULTIACTIONBAR1BUTTON2", Target = "target"},
	{Key = "C", Type = "command", Value = "MULTIACTIONBAR1BUTTON3",  Target = "target"},
	{Key = "V", Type = "command", Value = "MULTIACTIONBAR1BUTTON4",  Target = "target"},
	{Key = "MiddleButton", Type = "command", Value = "MULTIACTIONBAR1BUTTON7"},
	{Key = "SHIFT-A", Type = "command", Value = "MULTIACTIONBAR1BUTTON6",  Target = "target"},
	{Key = "SHIFT-Q", Type = "command", Value = "MULTIACTIONBAR1BUTTON11",  Target = "target"},
	{Key = "SHIFT-E", Type = "command", Value = "MULTIACTIONBAR1BUTTON9",  Target = "target"},
	{Key = "SHIFT-R", Type = "command", Value = "MULTIACTIONBAR1BUTTON10",  Target = "target"},
	{Key = "SHIFT-W", Type = "command", Value = "MULTIACTIONBAR1BUTTON5",  Target = "target"},
	{Key = "SHIFT-F", Type = "command", Value = "MULTIACTIONBAR1BUTTON12",  Target = "target"},

}
--]]
TUIBinds.DEMONHUNTER= {
	{Key = "1", Type = "command", Value = "ACTIONBUTTON1"},
	{Key = "2", Type = "command", Value = "ACTIONBUTTON2"},
	{Key = "3", Type = "command", Value = "ACTIONBUTTON3"},
	{Key = "4", Type = "command", Value = "ACTIONBUTTON4"},
	{Key = "SHIFT-C", Type = "command", Value = "ACTIONBUTTON5"},
	{Key = "SHIFT-V", Type = "command", Value = "ACTIONBUTTON6"},
	{Key = "SHIFT-D", Type = "command", Value = "ACTIONBUTTON8"},
	{Key = "SHIFT-S", Type = "command", Value = "ACTIONBUTTON9"},
	{Key = "F", Type = "command", Value = "ACTIONBUTTON12"},

	{Key = "Z", Type = "command", Value = "MULTIACTIONBAR1BUTTON1",  Target = "target"},
	{Key = "X", Type = "command", Value = "MULTIACTIONBAR1BUTTON2", Target = "target"},
	{Key = "C", Type = "command", Value = "MULTIACTIONBAR1BUTTON3",  Target = "target"},
	{Key = "V", Type = "command", Value = "MULTIACTIONBAR1BUTTON4",  Target = "target"},
	{Key = "MiddleButton", Type = "command", Value = "MULTIACTIONBAR1BUTTON7"},
	{Key = "SHIFT-A", Type = "command", Value = "MULTIACTIONBAR1BUTTON6",  Target = "target"},
	{Key = "SHIFT-Q", Type = "command", Value = "MULTIACTIONBAR1BUTTON11",  Target = "target"},
	{Key = "SHIFT-E", Type = "command", Value = "MULTIACTIONBAR1BUTTON9",  Target = "target"},
	{Key = "SHIFT-R", Type = "command", Value = "MULTIACTIONBAR1BUTTON10",  Target = "target"},
	{Key = "SHIFT-W", Type = "command", Value = "MULTIACTIONBAR1BUTTON5",  Target = "target"},
	{Key = "SHIFT-F", Type = "command", Value = "MULTIACTIONBAR1BUTTON12",  Target = "target"},

}

function TUIBinds_GetFrame(frame)
	local button
	if (not frame) then
		return
	end

	if (type(frame) == "string") then
		button = _G and _G[frame] or (getglobal and getglobal(frame))
	elseif (type(frame) == "table") then
		local objType = frame:GetObjectType()
		if (objType == "Button" or objType == "CheckButton") then
			button = frame
		end
	end

	return button
end
function TUIBinds_GetMouseButton(key)
	local modifier, dash, button = string.match(key, "(%a*)(-?)(.*Button.?)")

	if (dash ~= "-") then
		dash = nil
	end

	if (not dash and button == "Button") then
		button = key
	end

	if (not TUIBinds.Modifiers[modifier]) then
		modifier = nil
	end

	if (not TUIBinds.MouseButtons[button]) then
		button = nil
	end

	if (not modifier and not dash and button) then
		return true, "", TUIBinds.MouseButtons[button]
	elseif (modifier and dash and button) then
		return true, string.lower(modifier).."-", TUIBinds.MouseButtons[button]
	end
end
function TUIBinds_GetTypeValue(item)
	if (item.Type=="actionbar" or item.Type=="pet" or item.Type=="maintank" or item.Type=="mainassist") then
		return "action"
	end
	if (item.Type=="click") then
		return "clickbutton"
	end
	if (item.Type=="macro") then
		return "macrotext"
	end
	return item.Type
end
function TUIBinds_GetValueValue(item)
	if type(item.Value)=="table" then
		for _,t in pairs(item.Value) do
			if TUI_Compat.GetSpellNameByID(t.IF) then
				return t.Value	
			end
		end
	end
	return item.Value
end
function TUIBinds_SetButtonUnit(self, unit, vbutton)
	if (self and not self:GetAttribute("unit") and unit) then
		if (vbutton) then
			self:SetAttribute("unit-"..vbutton, unit)
		else
			self:SetAttribute("unit", unit)
		end
	end
end

function TUIBinds_OnEvent()
	local buttonName,button,item
	for i,item in pairs(TUIBinds["common"]) do
		if item.Key then
			buttonName="TUIBinds"..UnitName("player")..GetRealmName().."common"..i
			button=CreateFrame("Button",buttonName,nil,"SecureActionButtonTemplate")
			button:SetAttribute("type",item.Type)
			button:SetAttribute(TUIBinds_GetTypeValue(item),TUIBinds_GetValueValue(item))
			if item.Type=="command" then
				SetBinding(item.Key, item.Value)
			else
				SetBindingClick(item.Key,buttonName)
			end			
		end
	end
	local _,clazz=UnitClass("player");
	if TUIBinds[clazz] then
		local buttonName,button,item
		for i,item in pairs(TUIBinds[clazz]) do
			if item.Key then
				if (item.TargetFrames) then
					for _,f in pairs(item.TargetFrames) do
						button=TUIBinds_GetFrame(f)
						if (button) then
							button:RegisterForClicks('LeftButtonUp','RightButtonUp','MiddleButtonUp');--,'Button4Up','Button5Up');
							local ismouse, modifier, mousebutton = TUIBinds_GetMouseButton(item.Key)
--TUI_Print(modifier.."type"..mousebutton.."==="..item.Type.."      "..modifier..TUIBinds_GetTypeValue(item)..mousebutton.."="..TUIBinds_GetValueValue(item))
							button:SetAttribute(modifier.."type"..mousebutton, item.Type)
							button:SetAttribute(modifier..TUIBinds_GetTypeValue(item)..mousebutton, TUIBinds_GetValueValue(item))						
						end						
					end					
				else
					buttonName="TUIBinds"..UnitName("player")..GetRealmName()..UnitClass("player")..i
					button=CreateFrame("Button",buttonName,nil,"SecureActionButtonTemplate")
					button:SetAttribute("type",item.Type)
					button:SetAttribute(TUIBinds_GetTypeValue(item),TUIBinds_GetValueValue(item))
					if item.Type=="command" then
						SetBinding(item.Key, item.Value)
					else
						SetBindingClick(item.Key,buttonName)
					end
				end
			
			end
		end
	end
	SaveBindings(GetCurrentBindingSet())
	DEFAULT_CHAT_FRAME:AddMessage("Binds is loaded")
end