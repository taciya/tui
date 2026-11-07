
SlashCmdList["TUI"]=function(msg)
	if TUI and TUI.Print then TUI:Print(msg) end
end
SLASH_TUI1="/TUI";
SLASH_TUI2="/tui";


SlashCmdList["TUIRELOADUI"]=function(msg)
	ReloadUI();
end
SLASH_TUIRELOADUI1="/TUIRELOADUI";
SLASH_TUIRELOADUI2="/tuireload";

--清理多余的碎片
function TUI_DC(msg)
	local idx=0;
	for bag=4, 0, -1 do
		for slot=1, C_Container.GetContainerNumSlots(bag) do
			local itemLink=C_Container.GetContainerItemLink(bag, slot);
			if (itemLink ~=nil and string.find(itemLink,"灵魂碎片")) then
				idx=idx+1;
				if (idx>(tonumber(msg) or 16)) then
					C_Container.PickupContainerItem(bag,slot);
					DeleteCursorItem();
					TUI_Print(" 清理物品 | "..itemLink);
				end
			end
		end
	end
end
SlashCmdList["DC"] = TUI_DC
SLASH_DC1="/DC";
SLASH_DC2="/dc";

--清理垃圾
function TUI_DR()
	TUI_Print(" 清理物品 | ------------------------");
	for bag=4, 0, -1 do
		for slot=1, C_Container.GetContainerNumSlots(bag) do
			local itemLink=C_Container.GetContainerItemLink(bag, slot);
			local id=getID(itemLink);
			if (itemLink and id and TUI_Rubbish[UnitName("player")] and TUI_Rubbish[UnitName("player")][id..""]) then
				C_Container.PickupContainerItem(bag,slot);
				DeleteCursorItem();
				TUI_Print(" 清理物品 | "..itemLink);
			end
		end
	end
	TUI_Print(" 清理物品 | ------------------------");
end
SlashCmdList["DR"] = TUI_DR
SLASH_DR1="/DR";
SLASH_DR2="/dr";

--打印当前职业技能信息
TUI_SpellInfo = TUI_SpellInfo or {};
function print_spell()
	local className = UnitClass("player")
	TUI_SpellInfo[className] = TUI_SpellInfo[className] or {}
	if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookSkillLineInfo and C_SpellBook.GetSpellBookItemName then
		local bank = Enum.SpellBookSpellBank.Player
		for lineIndex = 1, C_SpellBook.GetNumSpellBookSkillLines() do
			local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(lineIndex)
			if lineInfo then
				for slot = (lineInfo.itemIndexOffset or 0) + 1, (lineInfo.itemIndexOffset or 0) + (lineInfo.numSpellBookItems or 0) do
					local spellName = C_SpellBook.GetSpellBookItemName(slot, bank)
					local _, _, spellID = C_SpellBook.GetSpellBookItemType(slot, bank)
					local link = spellID and TUI_Compat.GetSpellLink(spellID)
					if spellID and link then TUI_SpellInfo[className][tostring(spellID)] = link end
				end
			end
		end
	else
		TUI_Print("当前客户端未提供可用的法术书 API")
	end
end
SlashCmdList["PS"] = print_spell
SLASH_PS1="/printspell";
SLASH_PS2="/ps";
--获取物品ID
function getID(link)
	--"(item[%-%d:]+):%d+|"; >> item:25600:0:0:0:0:0:0:768677774
	local ItemStringMatch = "item:(%d+):";
	return string.match(link or "", ItemStringMatch);
end
--获取技能ID
function getSpellID(link)
	--spellID, spellName = link:match("|c%x+|Hspell:(%d+)|h%[(.*)%]|h|r") For example: |cff71d5ff|Hspell:8131|h[Mana Burn]|h|r
	local ItemStringMatch = "Hspell:(%d+)";
	return string.match(link or "", ItemStringMatch);
end
--根据职业自动选择谜语内容
--DRUID,HUNTER,MAGE,PALADIN,PRIEST,ROGUE,SHAMAN,WARLOCK
TUI_SendMessages={
	PRIEST="给个耐力，谢谢。。",
	MAGE="给做点吃喝吧，谢谢。。",
	DRUID="给个爪子，谢谢。。",
	WARLOCK="拉个糖吧，谢谢。。",
	ROGUE="帮忙给开锁吧，谢谢。。",
}
--BATTLEGROUND,CHANNEL,DND,EMOTE,GUILD,OFFICER,PARTY,RAID,RAID_WARNING,SAY,WHISPER,YELL
--SendChatMessage("text" [, "chatType" [, "language" [, "channel"]]])

function TUI_SendMsg(msg)
	--if (MinimapZoneText:GetText() == "冰血要塞") then
	--	SendChatMessage("男人正常--男人正常--男人正常", "BATTLEGROUND") ;
	--else
	local _,uc=UnitClass("target");
	if (UnitExists("target") and UnitIsPlayer("target") and TUI_SendMessages[uc]) then
		SendChatMessage(TUI_SendMessages[uc], "WHISPER", self.language, UnitName("target")) ;
	elseif ( msg and (string.len(msg) > 0) )then
		SendChatMessage(msg,"CHANNEL",GetDefaultLanguage(),1);
		SendChatMessage(msg,"CHANNEL",GetDefaultLanguage(),2);
		SendChatMessage(msg,"CHANNEL",GetDefaultLanguage(),3);
		SendChatMessage(msg,"CHANNEL",GetDefaultLanguage(),4);
		SendChatMessage(msg,"CHANNEL",GetDefaultLanguage(),5);		
		SendChatMessage(msg,"CHANNEL",GetDefaultLanguage(),6);						
	end
end
SlashCmdList["TUIHANHUA"]=TUI_SendMsg;
SLASH_TUIHANHUA1="/TUIHANHUA";
SLASH_TUIHANHUA2="/th";


local _G = _G;

function trim (s)
	return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end 


function TUI_Print(msg)
	if(msg) then
		DEFAULT_CHAT_FRAME:AddMessage(msg);
	else
		DEFAULT_CHAT_FRAME:AddMessage("is nil");
	end
end
SlashCmdList["TUIPRINT"]=TUI_Print;
SLASH_TUIPRINT1="/TUIPRINT";
SLASH_TUIPRINT2="/tp";

function TUI_HP()
	if UnitExists("target") then
		local un,uh,uhm,ct=UnitName("target"),UnitHealth("target"),UnitHealthMax("target"),"RAID";
		SendChatMessage(un.."  "..uh.."/"..uhm.."  ("..math.floor(uh/uhm*100).."%)","RAID",GetDefaultLanguage());		
	end
end

--取得物品信息，包裹和人物装备
function TUI_ItemInfo(arg1,arg2)
	if (type(arg1)=="string") then
		if (arg1=="player") then
			if (not GetInventoryItemLink("player",arg2)) then
				return nil;
			end
			i,j, itemID, enchant, randomProp, uniqID, name=string.find(GetInventoryItemLink("player",arg2),".Hitem:(%d+):(%d+):(%d+):(%d+).h[[]([^]]+)[]].h")
			return tonumber(itemID or nil), tonumber(randomProp or nil), tonumber(enchant or nil), tonumber(uniqID or nil), name			
		else
			local i,j, itemID, enchant, randomProp, uniqID, name=string.find(arg1,".Hitem:(%d+):(%d+):(%d+):(%d+).h[[]([^]]+)[]].h")
			return tonumber(itemID or nil), tonumber(randomProp or nil), tonumber(enchant or nil), tonumber(uniqID or nil), name
		end
	else
		local ItemLink=TUI_Compat.ContainerItemLink(arg1, arg2);
		if (not ItemLink) then
			return nil,nil,nil,nil,nil;
		end
		local i,j, itemID, enchant, randomProp, uniqID, name=string.find(ItemLink,".Hitem:(%d+):(%d+):(%d+):(%d+).h[[]([^]]+)[]].h")
		return tonumber(itemID or nil), tonumber(randomProp or nil), tonumber(enchant or nil), tonumber(uniqID or nil), name ,ItemLink
	end
end

function TUI_tinsertLink(arg1,arg2,arg3)
	if not arg1 then
		arg1={};
	end
	
	if (not arg3) then
		table.insert(arg1,arg2);
		TUI_Print(arg2);
	else
		if (arg1[arg2]) then
			arg3=arg1[arg2].." "..arg3;
		end
		table.remove(arg1,arg2);
		table.insert(arg1,arg2,arg3);
		TUI_Print(arg3);
	end	
	
end

function TUI_tinsertText(arg1,arg2,arg3)
	if not arg1 then
		arg1={};
	end
	
	if (not arg3) then
		local _,_,item=string.find(arg2,"([[][^]]+[]])");
		table.insert(arg1,UnitName("target").." "..item or arg2);
		TUI_Print(item or arg2);
		return ;
	end
	table.insert(arg1,arg2,arg3);
	TUI_Print(arg3);
end

function TUI_printTable(arg1,arg2)
	if not arg1 or not #arg1 then
		DEFAULT_CHAT_FRAME:AddMessage("table is nil。。");
		return;
	end
	if not arg2 then
		for i=1,#arg1,1 do
			DEFAULT_CHAT_FRAME:AddMessage(arg1[i]);			
		end
		return;
	end
	if tonumber(arg2) then
		for i=1,#arg1,1 do
			SendChatMessage(arg1[i],"CHANNEL",GetDefaultLanguage(),arg2)		
		end
	else
		for i=1,#arg1,1 do
			SendChatMessage(arg1[i],arg2,GetDefaultLanguage())		
		end
	end

end

function TUI_Text(str)
	DEFAULT_CHAT_FRAME:AddMessage("TUI:"..str);
end

function TUI_OnLoad()
	--self:RegisterEvent("VARIABLES_LOADED");
	--this:RegisterEvent("PLAYER_LOGIN")
	--this:RegisterEvent("UNIT_RAGE");
	--self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	--Load_TUI_Button_CMD();
end

function TUI_OnEvent(self, event, ...)

end
--[[
--根据怒气染色
local ActionButtons={
	"Action",
	"MultiBarBottomLeft",
	--"MultiBarBottomRight",
	--"MultiBarRight",
	--"MultiBarLeft"
}
local RageSpells={
	WARRIOR={
		gn(25286)=45,
		gn(30330)=50,		
	},
}
function TUI_UNIT_RAGE(unit)
	if (unit ~= "player") then
		return;
	end
	local _,uc=UnitClass("player");
	if (not RageSpells[uc]) then
		return ;
	end
	local actionButton,spellID,spellName,rage;
	for _,action in pairs(ActionButtons) do
		for slot=1,12 do
			spellID = GetActionInfo(slot);
			actionButton = _G(action.."Button"..slot);
			if (actionButton and spellID) then
				spellName=GetSpellInfo(spellID);
				if (spellName) then
					rage=RageSpells[uc][spellName];
					local player_rage=UnitMana("player");
					if (rage and rage >= player_rage) then
						
					end
				end
			end
		end		
	end
end
--]]

--自定义错误信息层
function TUI_ERRORS_OnLoad(self)
	local filename, fontHeight, flags = self:GetFont()
	self:SetFont(filename, 32, flags);
end

--聊天过滤
-- Use the supported chat message-filter API instead of replacing ChatFrame_OnEvent.
local TUI_CHAT_FILTER_EVENTS = {
	"CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
	"CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_CHANNEL", "CHAT_MSG_BATTLEGROUND",
	"CHAT_MSG_BATTLEGROUND_LEADER", "CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE",
}
local function TUI_ChatMessageFilter(_, event, message, sender)
	local ignored = TUI_IgnoreList or ","
	if sender and string.find(ignored, "," .. sender .. ",", 1, true) then return true end
	if message and string.find(message, "暗影新星", 1, true) then return true end
	return false
end
if ChatFrame_AddMessageEventFilter then
	for _, eventName in ipairs(TUI_CHAT_FILTER_EVENTS) do
		ChatFrame_AddMessageEventFilter(eventName, TUI_ChatMessageFilter)
	end
end

SLASH_TUICHATIGNORE1 = "/TUICHATIGNORE";
SLASH_TUICHATIGNORE2 = "/tci";
local function isNull(str)
	return (str == nil or string.gsub(str, "%s", "") == "")
end
function TUI_CHAT_IGNORE(str)
	local cmd, name = string.match(str or "", "(%S+)%s*(%S+)")
	if isNull(cmd) then
		TUI_Print(TUI_IgnoreList or ",")
	elseif string.upper(cmd) == "ADD" and not isNull(name) then
		if string.find(TUI_IgnoreList or ",", "," .. name .. ",", 1, true) then
			TUI_Print(name .. "已经存在于屏蔽列表中")
		else
			TUI_IgnoreList = (TUI_IgnoreList or ",") .. name .. ","
			TUI_Print(name .. " 已经添加到屏蔽列表中")
		end
	elseif string.upper(cmd) == "DEL" and not isNull(name) then
		TUI_IgnoreList = string.gsub(TUI_IgnoreList or ",", "," .. name .. ",", ",")
		TUI_Print(name .. " 已经从屏蔽列表中删除")
	elseif string.upper(cmd) == "CLEAR" then
		TUI_IgnoreList = ","
		TUI_Print("屏蔽列表已清空")
	else
		TUI_Print("用法: /tci ADD|DEL <玩家名> 或 /tci CLEAR")
	end
end
SlashCmdList["TUICHATIGNORE"] = TUI_CHAT_IGNORE

--TAB频道切换
function ChatEdit_CustomTabPressed(self)
   --if strsub(tostring(self:GetText()), 1, 1) == "/" then return end
   
   if  (self:GetAttribute("chatType") == "SAY")  then
      --if (GetNumPartyMembers()>0) then
      if UnitExists("party1") then
         self:SetAttribute("chatType", "PARTY");
         ChatEdit_UpdateHeader(self);
      --elseif (GetNumRaidMembers()>0) then
      elseif IsInRaid and IsInRaid() then
         self:SetAttribute("chatType", "RAID");
         ChatEdit_UpdateHeader(self);
      elseif (GetNumBattlefieldScores()>0) then
         self:SetAttribute("chatType", "BATTLEGROUND");
         ChatEdit_UpdateHeader(self);
      elseif (IsInGuild()) then
         self:SetAttribute("chatType", "GUILD");
         ChatEdit_UpdateHeader(self);
      else
         return;
      end
   elseif (self:GetAttribute("chatType") == "PARTY") then
      --if (GetNumRaidMembers()>0) then
      if IsInRaid and IsInRaid() then
         self:SetAttribute("chatType", "RAID");
         ChatEdit_UpdateHeader(self);
      elseif (GetNumBattlefieldScores()>0) then
         self:SetAttribute("chatType", "BATTLEGROUND");
         ChatEdit_UpdateHeader(self);
      elseif (IsInGuild()) then
         self:SetAttribute("chatType", "GUILD");
         ChatEdit_UpdateHeader(self);
      else
         self:SetAttribute("chatType", "SAY");
         ChatEdit_UpdateHeader(self);
      end         
   elseif (self:GetAttribute("chatType") == "RAID") then
      if (GetNumBattlefieldScores()>0) then
         self:SetAttribute("chatType", "BATTLEGROUND");
         ChatEdit_UpdateHeader(self);
      elseif (IsInGuild()) then
         self:SetAttribute("chatType", "GUILD");
         ChatEdit_UpdateHeader(self);
      else
         self:SetAttribute("chatType", "SAY");
         ChatEdit_UpdateHeader(self);
      end
   elseif (self:GetAttribute("chatType") == "BATTLEGROUND") then
      if (IsInGuild and IsInGuild()) then
         self:SetAttribute("chatType", "GUILD");
         ChatEdit_UpdateHeader(self);
      else
         self:SetAttribute("chatType", "SAY");
         ChatEdit_UpdateHeader(self);
      end
   elseif (self:GetAttribute("chatType") == "GUILD") then
      self:SetAttribute("chatType", "SAY");
      ChatEdit_UpdateHeader(self);
   end
end 
--释放技能时,自动喊话

if type(UseAction) == "function" then
hooksecurefunc("UseAction", function (slot)
	local _, _, _, spellID = GetActionInfo(slot);
	local fuhuo=",复活术,先祖之魂,救赎,"
	local yishi=",召唤仪式,灵魂仪式,"
	if (not spellID) then
		return;
	end
	local spellName = TUI_Compat.GetSpellNameByID(spellID);
	if (not spellName) then
		return;
	end
	if (UnitName("target") and string.find(fuhuo,spellName) and UnitIsDead("target")) then
		SendChatMessage(">> "..UnitName("target").." << 复活ing..........","EMOTE",GetDefaultLanguage());		
	end
	if string.find(yishi,spellName) then
		SendChatMessage(">>>>点点点点点点点点点点点点点点点<<<<","SAY",GetDefaultLanguage());		
	end
end);
end


--[[
hooksecurefunc("TextStatusBar_UpdateTextString", function(textStatusBar)

	--血量百分比显示到上边
	local textString = textStatusBar.TextString;
	if (not textString) then
		return 
	end
	if textString:GetName() == "TargetFrameHealthBarText" then
		if (TUI_TargetFrameHealthBarText) then
			if UnitIsPlayer("target") or textStatusBar.pauseUpdates or UnitHealthMax("target") < 1 then return end	
			TUI_TargetFrameHealthBarText:SetText(math.ceil(UnitHealth("target")/UnitHealthMax("target")*100).."%");			
		else
			textStatusBar:CreateFontString("TUI_TargetFrameHealthBarText", "ARTWORK", "GameFontNormal");	
			TUI_TargetFrameHealthBarText:SetPoint("RIGHT", textStatusBar, "LEFT", -5, 0);
			TUI_TargetFrameHealthBarText:SetJustifyH("RIGHT");
			TUI_TargetFrameHealthBarText:SetWidth(50);
		end
	end

	--血量警报
	if textString:GetName() == "PlayerFrameHealthBarText" then
		local uh,uhm=UnitHealth("player"),UnitHealthMax("player");
		local uhp=math.ceil(uh/uhm*100);
		if (uhp <50) then
			TUI_ERRORS:AddMessage("自救,自救,自救  >>"..uhp.."%<<", 1.0, 0, 0, 3.0)
		end
	end

end)
--]]
-- 背包按钮快捷操作。延迟到 PLAYER_LOGIN，避免按钮尚未创建；
-- 使用 HookScript 保留客户端原有的 OnMouseDown 处理逻辑。
local function TUI_HookBackpackButton()
	local button = _G.MainMenuBarBackpackButton
	if not button then
		TUI_Print("TUI: 找不到 MainMenuBarBackpackButton，跳过背包快捷操作")
		return
	end
	if button.TUI_MouseDownHooked then return end
	button.TUI_MouseDownHooked = true

	button:HookScript("OnMouseDown", function(self, mouseButton)
		if IsControlKeyDown() then
			if TUI_DR then TUI_DR() end
			if TUI_DC then TUI_DC(16) end
		elseif IsAltKeyDown() and mouseButton == "RightButton" then
			ReloadUI()
		end
	end)
end

local TUI_BackpackHookFrame = CreateFrame("Frame")
TUI_BackpackHookFrame:RegisterEvent("PLAYER_LOGIN")
TUI_BackpackHookFrame:SetScript("OnEvent", function(self)
	TUI_HookBackpackButton()
	self:UnregisterEvent("PLAYER_LOGIN")
end)

-- 某些客户端在插件载入时按钮已存在；仍通过同一个幂等函数处理。
if _G.MainMenuBarBackpackButton then
	TUI_HookBackpackButton()
end

------------------------------------------------------------
-- 血条及名字按职业颜色
------------------------------------------------------------
--[[
local   UnitIsPlayer, UnitIsConnected, UnitClass, RAID_CLASS_COLORS =
        UnitIsPlayer, UnitIsConnected, UnitClass, RAID_CLASS_COLORS
local _, class, c

local function colour(statusbar, unit)
    if UnitIsPlayer(unit) and UnitIsConnected(unit) and unit == statusbar.unit and UnitClass(unit) then
        _, class = UnitClass(unit)
        c = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
        statusbar:SetStatusBarColor(c.r, c.g, c.b)
    end
end

hooksecurefunc("UnitFrameHealthBar_Update", colour)
hooksecurefunc("HealthBar_OnValueChanged", function(self)
  colour(self, self.unit)
end)

local sb = _G.GameTooltipStatusBar
local addon = CreateFrame("Frame", "StatusColour")
addon:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
addon:SetScript("OnEvent", function()
  colour(sb, "mouseover")
end)

hooksecurefunc("UnitFrame_Update", function(self)
        if UnitClass(self.unit) then
        local c = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[select(2,UnitClass(self.unit))]
              self.name:SetTextColor(c.r,c.g,c.b,1)
    end
end)
--]]

------------------------------------------------------------
-- TUI命令按钮
------------------------------------------------------------
function Load_TUI_Button_CMD()
	local TUI_Button_CMD ={
		["SPELLS"]={
			["TextName"]="法",
			["TextMacro1"]="/script TUI_PS();",
			["TextTooltip"]="打印【当前角色】技能一览信息",
			["Idx"]=0,
		},
		["ITEMS"]={
			["TextName"]="物",
			["TextMacro1"]="/script TUI_PI();",
			["TextTooltip"]="打印【所有角色】物品一览信息",
			["Idx"]=1
		},
		["RELOAD"]={
			["TextName"]="重",
			["TextMacro1"]="/script ReloadUI();",
			["TextTooltip"]="重新载入游戏",
			["Idx"]=2
		}
		,
		["TEST"]={
			["TextName"]="T",
			["TextMacro1"]="/ti 12",
			["TextMacro2"]="/ti 10",
			["TextMacro3"]="/script Join_DJSJPD()",
			["TextTooltip"]="保存装备快捷信息",
			["Idx"]=3
		}
	}
	for key, value in pairs(TUI_Button_CMD) do
		local TUI_BUTTON_CMD = CreateFrame("Button", 'TUI_BUTTON_CMD'..key, nil, "UIPanelButtonTemplate,SecureActionButtonTemplate")
		TUI_BUTTON_CMD:RegisterForClicks("LeftButtonUp","RightButtonUp","MiddleButtonUp")
		TUI_BUTTON_CMD:SetAttribute("type1", "macro")
		TUI_BUTTON_CMD:SetAttribute("macrotext1",value.TextMacro1)
		if value.TextMacro2 then
			TUI_BUTTON_CMD:SetAttribute("type2", "macro")
			TUI_BUTTON_CMD:SetAttribute("macrotext2",value.TextMacro2)
		end
		if value.TextMacro3 then
			TUI_BUTTON_CMD:SetAttribute("type3", "macro")
			TUI_BUTTON_CMD:SetAttribute("macrotext3",value.TextMacro3)
		end

		TUI_BUTTON_CMD:SetPoint("BOTTOMLEFT",31*value.Idx+4,0)
		TUI_BUTTON_CMD:SetWidth(26)
		TUI_BUTTON_CMD:SetHeight(26)
		TUI_BUTTON_CMD:SetText(value.TextName)
		TUI_BUTTON_CMD:Show()

	end
end 
-- 自动加入 大脚世界频道
function Join_DJSJPD()
	local idxChatFrame = 0 
	local vChatFrame = SELECTED_CHAT_FRAME

	for idx = 1, 9 do
		local chatName = GetChatWindowInfo(idx)
		if chatName == "组队" then
			idxChatFrame = idx
			break
		end
	end
	vChatFrame = _G("ChatFrame"..idxChatFrame)

	local _, channelName, _ = GetChannelName("大脚世界频道")
	if channelName == nil then
		JoinChannelByName("大脚世界频道", nil, vChatFrame:GetID(), 1)
		ChatFrame_AddChannel(vChatFrame, "大脚世界频道")
		print("|cff00d200已加入大脚世界频道|r")
	else
		LeaveChannelByName("大脚世界频道")
		print("|cffd20000已离开大脚世界频道|r")
	end

end

------------------------------------------------------------
-- 猎人
--自动喂食
--冰冻陷阱
------------------------------------------------------------
function Load_TUI_Button_ByClass()
	local _,clazz=UnitClass("player")
	if clazz=="HUNTER" then
		--自动喂食
		local itemInfo = C_Container and C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(1, 1)
		local itemID = itemInfo and itemInfo.itemID
		local itemCount = itemInfo and itemInfo.stackCount or 0
		local itemTexture = itemInfo and itemInfo.iconFileID
		if itemID then
			local itemName, _, _, _, _, itemType, itemSubType, _, _, fallbackTexture = GetItemInfo(itemID)
			itemTexture = itemTexture or fallbackTexture
			local sMacroText=""
			sMacroText = sMacroText.."/cast 喂养宠物\n"
			sMacroText = sMacroText.."/use "..itemName.."\n"
			local TUI_Button_Food = CreateFrame("Button", 'TUI_Button_Food', nil, "UIPanelButtonTemplate,SecureActionButtonTemplate")
			TUI_Button_Food:SetAttribute("type", "macro")
			TUI_Button_Food:SetAttribute("macrotext",sMacroText )
			TUI_Button_Food:RegisterForClicks("LeftButtonUp")
			--TUI_Button_Food:SetPoint("CENTER",100,-100)
			TUI_Button_Food:SetPoint("RIGHT","PetFrame",50,-2)
			TUI_Button_Food:SetWidth(32)
			TUI_Button_Food:SetHeight(32)
			TUI_Button_Food:SetNormalTexture(itemTexture);--GetSpellTexture(6991)
			TUI_Button_Food:SetText(itemCount)
			TUI_Button_Food:RegisterEvent("SPELL_UPDATE_COOLDOWN")
			TUI_Button_Food:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
			TUI_Button_Food:SetScript('OnEvent', function(self, event, ...)
				local info = C_Container and C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(1, 1)
			self:SetText(info and info.stackCount or 0)
				if UnitExists("pet") then
					TUI_Button_Food:SetAlpha(1)
				else
					TUI_Button_Food:SetAlpha(0)
				end
				--GetPetFoodTypes()
			end)
			TUI_Button_Food:Show()
		else
			print("宠物食物未设定<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
		end


	--追踪按钮
		local TUI_TRACK={
			[19882] = "追踪巨人",
			[19878] = "追踪恶魔",
			[19883] = "追踪人型生物",
			[19885] = "追踪隐藏生物",
			[1494] = "追踪野兽",
			[19880] = "追踪元素生物",
			[19884] = "追踪亡灵",
			[2580] = "寻找矿物",
			[2481] = "寻找财宝",
			[19879] = "追踪龙类",
		}
		local iIdx = 0
		for key, value in pairs(TUI_TRACK) do
			local TUI_BUTTON_TRACK = CreateFrame("Button", 'TUI_BUTTON_TRACK'..key, nil, "UIPanelButtonTemplate,SecureActionButtonTemplate")
			TUI_BUTTON_TRACK:SetAttribute("type", "macro")
			TUI_BUTTON_TRACK:SetAttribute("macrotext","/cast "..value )
			TUI_BUTTON_TRACK:RegisterForClicks("LeftButtonUp")
			TUI_BUTTON_TRACK:SetPoint("TOP",28*iIdx+5,0)
			TUI_BUTTON_TRACK:SetWidth(20)
			TUI_BUTTON_TRACK:SetHeight(20)
			TUI_BUTTON_TRACK:SetNormalTexture(TUI_Compat.GetSpellTextureByID(key));
			TUI_BUTTON_TRACK:Show()
			iIdx = iIdx + 1
		end

		local TUI_BUSINESS={
			[3413] = "烹饪",
			[7620] = "钓鱼",
			[2656] = "熔炼",
			[4038] = "工程学",
			[7924] = "急救",
			[818] = "基础营火",
			[5149] = "训练野兽",
		}
		iIdx = 1
		for key, value in pairs(TUI_BUSINESS) do
			local TUI_BUTTON_BUSINESS = CreateFrame("Button", 'TUI_BUTTON_BUSINESS'..key, nil, "UIPanelButtonTemplate,SecureActionButtonTemplate")
			TUI_BUTTON_BUSINESS:SetAttribute("type", "macro")
			TUI_BUTTON_BUSINESS:SetAttribute("macrotext","/cast "..value )
			TUI_BUTTON_BUSINESS:RegisterForClicks("LeftButtonUp")
			TUI_BUTTON_BUSINESS:SetPoint("TOP",-28*iIdx-5,0)
			TUI_BUTTON_BUSINESS:SetWidth(20)
			TUI_BUTTON_BUSINESS:SetHeight(20)
			TUI_BUTTON_BUSINESS:SetNormalTexture(TUI_Compat.GetSpellTextureByID(key));
			TUI_BUTTON_BUSINESS:Show()
			iIdx = iIdx + 1
		end

	end
end