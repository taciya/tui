
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

-- 背包物品操作统一检查战斗状态和鼠标光标，避免误删手持物品。
local function TUI_CanModifyInventory()
	if InCombatLockdown and InCombatLockdown() then
		TUI_Print("战斗中无法整理背包")
		return false
	end
	if not CursorHasItem then
		TUI_Print("当前客户端缺少 CursorHasItem，已取消背包操作")
		return false
	end
	if CursorHasItem() then
		TUI_Print("请先放下鼠标光标上的物品，再执行背包整理")
		return false
	end
	return true
end

local function TUI_DeleteBagItem(bag, slot, itemLink)
	if not TUI_CanModifyInventory() then return false end
	if not TUI_Compat or not TUI_Compat.PickupContainerItem then return false end
	TUI_Compat.PickupContainerItem(bag, slot)
	if CursorHasItem and CursorHasItem() then
		if DeleteCursorItem then
			DeleteCursorItem()
			TUI_Print(" 清理物品 | " .. tostring(itemLink))
			return true
		end
		TUI_Compat.PickupContainerItem(bag, slot)
		TUI_Print("当前客户端不支持删除光标物品，已尝试放回背包")
	end
	return false
end

-- 清理超过保留数量的灵魂碎片。
function TUI_DC(msg)
	if not TUI_CanModifyInventory() then return end
	local keepCount = math.max(0, tonumber(msg) or 16)
	local found = 0
	for bag = 4, 0, -1 do
		for slot = 1, TUI_Compat.ContainerNumSlots(bag) do
			local itemLink = TUI_Compat.ContainerItemLink(bag, slot)
			if itemLink and string.find(itemLink, "灵魂碎片", 1, true) then
				found = found + 1
				if found > keepCount then TUI_DeleteBagItem(bag, slot, itemLink) end
			end
		end
	end
end
SlashCmdList["DC"] = TUI_DC
SLASH_DC1="/DC";
SLASH_DC2="/dc";

-- 清理已标记的垃圾物品；只在安全、空光标状态下执行。
function TUI_DR()
	if not TUI_CanModifyInventory() then return end
	local playerName = UnitName("player")
	local rubbish = TUI_Rubbish and TUI_Rubbish[playerName]
	if not rubbish then
		TUI_Print("垃圾列表为空")
		return
	end
	local removed = 0
	for bag = 4, 0, -1 do
		for slot = 1, TUI_Compat.ContainerNumSlots(bag) do
			local itemLink = TUI_Compat.ContainerItemLink(bag, slot)
			local id = getID(itemLink)
			if id and rubbish[id] and TUI_DeleteBagItem(bag, slot, itemLink) then
				removed = removed + 1
			end
		end
	end
	TUI_Print("垃圾清理完成，共删除 " .. removed .. " 件物品")
end
SlashCmdList["DR"] = TUI_DR
SLASH_DR1="/DR";
SLASH_DR2="/dr";

--打印当前职业技能信息
TUI_SpellInfo = TUI_SpellInfo or {};
function print_spell()
	local localizedName, classFile = UnitClass("player")
	local classKey = classFile or localizedName or "UNKNOWN"
	TUI_SpellInfo[classKey] = TUI_SpellInfo[classKey] or {}
	if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookSkillLineInfo
			and C_SpellBook.GetSpellBookItemName and C_SpellBook.GetSpellBookItemType
			and Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) then
		TUI_Print("当前客户端未提供可用的法术书 API")
		return
	end

	local bank = Enum.SpellBookSpellBank.Player
	local printed = 0
	TUI_Print("===== " .. classKey .. " 技能列表 =====")
	for lineIndex = 1, C_SpellBook.GetNumSpellBookSkillLines() do
		local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(lineIndex)
		if lineInfo then
			local first = (lineInfo.itemIndexOffset or 0) + 1
			local last = (lineInfo.itemIndexOffset or 0) + (lineInfo.numSpellBookItems or 0)
			for slot = first, last do
				local spellName = C_SpellBook.GetSpellBookItemName(slot, bank)
				local _, _, spellID = C_SpellBook.GetSpellBookItemType(slot, bank)
				local link = spellID and TUI_Compat.GetSpellLink(spellID)
				if spellID then
					TUI_SpellInfo[classKey][tostring(spellID)] = link or spellName or tostring(spellID)
					TUI_Print((link or tostring(spellName or "未知技能")) .. "  ID:" .. tostring(spellID))
					printed = printed + 1
				end
			end
		end
	end
	TUI_Print("技能记录完成，共 " .. printed .. " 项")
end
TUI_PS = print_spell
SlashCmdList["PS"] = print_spell
SLASH_PS1 = "/printspell"
SLASH_PS2 = "/ps"

-- 输出背包和装备栏物品，包含可直接用于宏的物品 ID。
function print_items()
	local count = 0
	TUI_Print("===== 当前角色物品列表 =====")
	for bag = 0, 4 do
		for slot = 1, TUI_Compat.ContainerNumSlots(bag) do
			local link = TUI_Compat.ContainerItemLink(bag, slot)
			if link then
				TUI_Print(string.format("背包 %d/%d  ID:%s  %s", bag, slot, tostring(getID(link) or "?"), link))
				count = count + 1
			end
		end
	end
	for slot = 1, 19 do
		local link = GetInventoryItemLink("player", slot)
		if link then
			TUI_Print(string.format("装备栏 %d  ID:%s  %s", slot, tostring(getID(link) or "?"), link))
			count = count + 1
		end
	end
	TUI_Print("物品记录完成，共 " .. count .. " 项")
end
TUI_PI = print_items
SlashCmdList["TUIITEMS"] = print_items
SLASH_TUIITEMS1 = "/tuiitems"
SLASH_TUIITEMS2 = "/pi"
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
	local _, class = UnitClass("target")
	if UnitExists("target") and UnitIsPlayer("target") and TUI_SendMessages[class] then
		SendChatMessage(TUI_SendMessages[class], "WHISPER", GetDefaultLanguage(), UnitName("target"))
		return
	end
	msg = trim and trim(msg or "") or (msg or "")
	if msg == "" then return end
	-- 只发送到实际加入的频道，频道编号以客户端返回值为准。
	if not GetChannelName then
		TUI_Print("当前客户端不支持频道查询 API")
		return
	end
	for index = 1, 6 do
		local channelID = GetChannelName(index)
		if type(channelID) == "number" and channelID > 0 then
			SendChatMessage(msg, "CHANNEL", GetDefaultLanguage(), channelID)
		end
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
	local frame = DEFAULT_CHAT_FRAME
	if frame and frame.AddMessage then
		frame:AddMessage(tostring(msg == nil and "is nil" or msg))
	end
end
SlashCmdList["TUIPRINT"]=TUI_Print;
SLASH_TUIPRINT1="/TUIPRINT";
SLASH_TUIPRINT2="/tp";

function TUI_HP()
	if not UnitExists("target") then return end
	local name = UnitName("target") or "目标"
	local health, maxHealth = UnitHealth("target"), UnitHealthMax("target")
	if type(health) ~= "number" or type(maxHealth) ~= "number" or maxHealth <= 0 then
		TUI_Print("当前目标血量数据不可用")
		return
	end
	local ok, message = pcall(function()
		local percent = math.floor(health / maxHealth * 100 + 0.5)
		return string.format("%s  %d/%d  (%d%%)", name, health, maxHealth, percent)
	end)
	if not ok then
		TUI_Print("当前客户端限制读取目标血量数据")
		return
	end
	SendChatMessage(message, "RAID", GetDefaultLanguage())
end

--取得物品信息，包裹和人物装备
function TUI_ItemInfo(arg1, arg2)
	local itemLink
	if type(arg1) == "string" then
		if arg1 == "player" then
			itemLink = GetInventoryItemLink("player", arg2)
		else
			itemLink = arg1
		end
	elseif type(arg1) == "number" then
		itemLink = TUI_Compat.ContainerItemLink(arg1, arg2)
	end
	if not itemLink then return nil, nil, nil, nil, nil end

	local itemID, enchant, randomProp, uniqueID, itemName =
		string.match(itemLink, "Hitem:(%d+):(%d+):(%d+):(%d+).*|h%[([^]]+)%]|h")
	return tonumber(itemID), tonumber(randomProp), tonumber(enchant),
		tonumber(uniqueID), itemName, itemLink
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
		local _, _, item = string.find(arg2 or "", "([[][^]]+[]])");
		local targetName = UnitName("target") or ""
		local value = item and (targetName .. " " .. item) or arg2
		table.insert(arg1, value);
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

function TUI_OnLoad(self)
	if self and self.RegisterEvent then
		self:RegisterEvent("PLAYER_LOGIN")
	end
end

function TUI_OnEvent(self, event, ...)
	if event == "PLAYER_LOGIN" then
		if Load_TUI_Button_ByClass then
			local ok, err = pcall(Load_TUI_Button_ByClass)
			if not ok then TUI_Print("职业功能初始化失败：" .. tostring(err)) end
		end
		if Load_TUI_Button_CMD then
			local ok, err = pcall(Load_TUI_Button_CMD)
			if not ok then TUI_Print("命令按钮初始化失败：" .. tostring(err)) end
		end
		if self and self.UnregisterEvent then self:UnregisterEvent("PLAYER_LOGIN") end
	end
end


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
	local cmd, name = string.match(str or "", "^(%S+)%s*(.-)%s*$")
	cmd = string.upper(cmd or "")
	name = trim(name or "")
	if cmd == "" then
		TUI_Print(TUI_IgnoreList or ",")
		return
	end
	if cmd == "CLEAR" then
		TUI_IgnoreList = ","
		TUI_Print("屏蔽列表已清空")
		return
	end
	if name == "" or (cmd ~= "ADD" and cmd ~= "DEL") then
		TUI_Print("用法: /tci ADD|DEL <玩家名> 或 /tci CLEAR")
		return
	end

	local entries, found = {}, false
	for entry in string.gmatch(TUI_IgnoreList or ",", "[^,]+") do
		if entry == name then
			found = true
			if cmd == "ADD" then entries[#entries + 1] = entry end
		else
			entries[#entries + 1] = entry
		end
	end
	if cmd == "ADD" and not found then
		entries[#entries + 1] = name
	end
	TUI_IgnoreList = "," .. table.concat(entries, ",") .. ","

	if cmd == "ADD" then
		TUI_Print(found and (name .. " 已存在于屏蔽列表中") or (name .. " 已添加到屏蔽列表中"))
	else
		TUI_Print(found and (name .. " 已从屏蔽列表中删除") or (name .. " 不在屏蔽列表中"))
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
	local definitions = {
		{ key = "SPELLS", text = "法", macro = "/ps", tooltip = "打印当前角色技能及 ID", index = 0 },
		{ key = "ITEMS", text = "物", macro = "/tuiitems", tooltip = "打印背包及装备物品 ID", index = 1 },
		{ key = "RELOAD", text = "重", macro = "/reload", tooltip = "重新载入游戏", index = 2 },
		{ key = "TEST", text = "T", macro = "/ti 12", rightMacro = "/ti 10", middleMacro = "/tuiworldchannel", tooltip = "左键保存 F12，右键保存 F10，中键切换世界频道", index = 3 },
	}
	table.sort(definitions, function(a, b) return a.index < b.index end)

	for _, data in ipairs(definitions) do
		local buttonData = data -- copy the loop value for Lua 5.1 closures
		local name = "TUI_BUTTON_CMD" .. buttonData.key
		local button = _G[name] or CreateFrame("Button", name, UIParent, "UIPanelButtonTemplate,SecureActionButtonTemplate")
		button:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
		button:SetAttribute("type1", "macro")
		button:SetAttribute("macrotext1", buttonData.macro)
		button:SetAttribute("type2", buttonData.rightMacro and "macro" or nil)
		button:SetAttribute("macrotext2", buttonData.rightMacro)
		button:SetAttribute("type3", buttonData.middleMacro and "macro" or nil)
		button:SetAttribute("macrotext3", buttonData.middleMacro)
		button:ClearAllPoints()
		button:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 4 + 31 * buttonData.index, 4)
		button:SetSize(26, 26)
		button:SetText(buttonData.text)
		button:SetScript("OnEnter", function(self)
			if not GameTooltip then return end
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText(buttonData.tooltip or buttonData.text)
			GameTooltip:Show()
		end)
		button:SetScript("OnLeave", function()
			if GameTooltip then GameTooltip:Hide() end
		end)
		button:Show()
	end
end

SlashCmdList["TUIWORLDCHANNEL"] = function() Join_DJSJPD() end
SLASH_TUIWORLDCHANNEL1 = "/tuiworldchannel"
SLASH_TUIWORLDCHANNEL2 = "/twc"

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
	if idxChatFrame > 0 then
		vChatFrame = _G["ChatFrame" .. idxChatFrame]
	end
	vChatFrame = vChatFrame or SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME
	if not vChatFrame then
		TUI_Print("找不到可用的聊天窗口")
		return
	end

	local channelID = GetChannelName("大脚世界频道")
	if not channelID or channelID == 0 then
		JoinChannelByName("大脚世界频道", nil, vChatFrame:GetID(), 1)
		if ChatFrame_AddChannel then ChatFrame_AddChannel(vChatFrame, "大脚世界频道") end
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
	if _G.TUI_ClassButtonsLoaded then return end
	local _,clazz=UnitClass("player")
	if clazz=="HUNTER" then
		--自动喂食
		local itemInfo = C_Container and C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(1, 1)
		local itemID = itemInfo and itemInfo.itemID
		local itemCount = itemInfo and itemInfo.stackCount or 0
		local itemTexture = itemInfo and itemInfo.iconFileID
		if itemID and not _G.TUI_Button_Food then
			local sMacroText = "/cast 喂养宠物\n/use item:" .. itemID
			local TUI_Button_Food = CreateFrame("Button", "TUI_Button_Food", UIParent, "UIPanelButtonTemplate,SecureActionButtonTemplate")
			TUI_Button_Food:SetAttribute("type", "macro")
			TUI_Button_Food:SetAttribute("macrotext",sMacroText )
			TUI_Button_Food:RegisterForClicks("LeftButtonUp")
			--TUI_Button_Food:SetPoint("CENTER",100,-100)
			TUI_Button_Food:SetPoint("RIGHT", _G.PetFrame or UIParent, "RIGHT", 50, -2)
			TUI_Button_Food:SetWidth(32)
			TUI_Button_Food:SetHeight(32)
			if itemTexture then TUI_Button_Food:SetNormalTexture(itemTexture) end
			TUI_Button_Food:SetText(itemCount)
			local function updateFoodButton(self)
				local info = C_Container and C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(1, 1)
				self:SetText(info and info.stackCount or 0)
				self:SetAlpha(UnitExists("pet") and 1 or 0)
			end
			TUI_Button_Food:RegisterEvent("BAG_UPDATE_DELAYED")
			TUI_Button_Food:RegisterEvent("UNIT_PET")
			TUI_Button_Food:RegisterEvent("PLAYER_ENTERING_WORLD")
			TUI_Button_Food:SetScript("OnEvent", updateFoodButton)
			updateFoodButton(TUI_Button_Food)
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
			local buttonName = "TUI_BUTTON_TRACK" .. key
			local TUI_BUTTON_TRACK = _G[buttonName] or CreateFrame("Button", buttonName, UIParent, "UIPanelButtonTemplate,SecureActionButtonTemplate")
			TUI_BUTTON_TRACK:SetAttribute("type", "macro")
			TUI_BUTTON_TRACK:SetAttribute("macrotext","/cast "..value )
			TUI_BUTTON_TRACK:RegisterForClicks("LeftButtonUp")
			TUI_BUTTON_TRACK:SetPoint("TOP",28*iIdx+5,0)
			TUI_BUTTON_TRACK:SetWidth(20)
			TUI_BUTTON_TRACK:SetHeight(20)
			local texture = TUI_Compat.GetSpellTextureByID(key)
			if texture then TUI_BUTTON_TRACK:SetNormalTexture(texture) end
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
			local buttonName = "TUI_BUTTON_BUSINESS" .. key
			local TUI_BUTTON_BUSINESS = _G[buttonName] or CreateFrame("Button", buttonName, UIParent, "UIPanelButtonTemplate,SecureActionButtonTemplate")
			TUI_BUTTON_BUSINESS:SetAttribute("type", "macro")
			TUI_BUTTON_BUSINESS:SetAttribute("macrotext","/cast "..value )
			TUI_BUTTON_BUSINESS:RegisterForClicks("LeftButtonUp")
			TUI_BUTTON_BUSINESS:SetPoint("TOP",-28*iIdx-5,0)
			TUI_BUTTON_BUSINESS:SetWidth(20)
			TUI_BUTTON_BUSINESS:SetHeight(20)
			local texture = TUI_Compat.GetSpellTextureByID(key)
			if texture then TUI_BUTTON_BUSINESS:SetNormalTexture(texture) end
			TUI_BUTTON_BUSINESS:Show()
			iIdx = iIdx + 1
		end

	end
	_G.TUI_ClassButtonsLoaded = true
end