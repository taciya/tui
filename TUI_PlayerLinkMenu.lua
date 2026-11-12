--[[
功能说明：
			对聊天窗口链接的快捷操作。
			如果链接是玩家，那么对应不同组合快捷会直接调用不同的功能
			如果链接是聊天频道，那么直接切换到该频道。
使用说明：
			1代表是左键, 2代表右键
			SHIFT+1		邀请组队
			SHIFT+2		邀请入会
			ALT+1		查询玩家
			ALT+2		从屏蔽列表中移除
			CTRL+1		添加好友
			CTRL+2		添加到屏蔽列表中
			1				密语
			2				复制当前玩家姓名
命令说明：
			/tci 参数1 参数2
			没有参数 打印屏蔽列表明细
			参数1 为ADD，DEL，CLEAR  分别对应添加，删除，清空
			参数2 为玩家名
--]]
--获取物品ID
local function getID(link)
	return link and string.match(link, "item:(%d+)")
end
-- WHO search support for ALT-clicked player links.
-- WHO_LIST_UPDATE has no query identifier, so keep only one addon request
-- outstanding and apply a local cooldown to avoid overlapping results.
local TUI_WhoPending
local TUI_WhoLastRequest = 0
local TUI_WhoFrame = CreateFrame("Frame")
TUI_WhoFrame:RegisterEvent("WHO_LIST_UPDATE")

local function TUI_WhoPrint(message)
	if TUI_Print then
		TUI_Print(message)
	elseif DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(message)
	end
end

local function TUI_SetWhoToUi(enabled)
	if C_FriendList and C_FriendList.SetWhoToUi then
		C_FriendList.SetWhoToUi(enabled)
	elseif SetWhoToUI then
		SetWhoToUI(enabled and 1 or 0)
	end
end

local function TUI_GetWhoCount()
	if C_FriendList and C_FriendList.GetNumWhoResults then
		return C_FriendList.GetNumWhoResults()
	elseif GetNumWhoResults then
		return GetNumWhoResults()
	end
	return 0, 0
end

local function TUI_GetWhoEntry(index)
	if C_FriendList and C_FriendList.GetWhoInfo then
		local info = C_FriendList.GetWhoInfo(index)
		if type(info) == "table" then
			return info.fullName or info.name,
				info.fullGuildName or info.guild,
				info.level, info.raceStr or info.race,
				info.classStr or info.class, info.area or info.zone
		end
	end

	if GetWhoInfo then
		return GetWhoInfo(index)
	end
end

local function TUI_FinishWhoSearch()
	local pending = TUI_WhoPending
	if not pending then return end
	TUI_WhoPending = nil
	TUI_SetWhoToUi(false)

	local count, total = TUI_GetWhoCount()
	count = tonumber(count) or 0
	total = tonumber(total) or count
	TUI_WhoPrint(string.format("玩家查询「%s」：找到 %d 个玩家", pending.token, total))

	if count == 0 then
		TUI_WhoPrint("没有收到可显示的玩家资料；也可能是服务器 WHO 冷却导致请求未返回。")
		return
	end

	for index = 1, count do
		local playerName, guild, level, race, class, zone = TUI_GetWhoEntry(index)
		if playerName then
			local details = string.format("%s | %s级 %s %s | %s | 公会：%s",
				tostring(playerName),
				tostring(level or "?"),
				tostring(race or "?"),
				tostring(class or "?"),
				tostring(zone or "?"),
				(guild and guild ~= "") and guild or "无")
			TUI_WhoPrint(details)
		end
	end
end

TUI_WhoFrame:SetScript("OnEvent", function(_, event)
	if event == "WHO_LIST_UPDATE" and TUI_WhoPending then
		TUI_FinishWhoSearch()
	end
end)

function TUI_PlayerWhoSearch(fullName)
	local token = string.match(fullName or "", "([^%s]+)%s*$")
	if not token or token == "" then
		TUI_WhoPrint("无法从玩家链接中提取查询名称")
		return
	end
	if TUI_WhoPending then
		TUI_WhoPrint("上一次玩家查询尚未完成，请稍后再试")
		return
	end

	local now = GetTime and GetTime() or 0
	if now > 0 and now - TUI_WhoLastRequest < 5 then
		TUI_WhoPrint("WHO 查询间隔太短，请稍后再试")
		return
	end

	local sendWho = (C_FriendList and C_FriendList.SendWho) or SendWho
	if not sendWho then
		TUI_WhoPrint("当前客户端没有可用的玩家查询接口")
		return
	end

	TUI_WhoLastRequest = now
	local request = { token = token, fullName = fullName }
	TUI_WhoPending = request
	TUI_SetWhoToUi(true)

	-- WoW Infinite accepts the n- prefix with an unquoted partial surname.
	-- Call directly from the hyperlink click handler to preserve the
	-- hardware-event context required by SendWho on supported clients.
	sendWho("n-" .. token)

	TUI_WhoPrint("正在查询玩家「" .. token .. "」……")
	if C_Timer and C_Timer.After then
		C_Timer.After(8, function()
			if TUI_WhoPending == request then
				TUI_WhoPending = nil
				TUI_SetWhoToUi(false)
				TUI_WhoPrint("玩家查询暂时没有返回结果；可能是服务器 WHO 冷却，请稍后重试。")
			end
		end)
	end
end

local TUI_PLM={
	["LEFT"]={
		["SHIFT"]=function(name)
			-- Modern clients expose the invite API through C_PartyInfo.
			local invite = (C_PartyInfo and C_PartyInfo.InviteUnit) or InviteUnit or InviteByName
			if invite then
				invite(name)
			elseif DEFAULT_CHAT_FRAME then
				DEFAULT_CHAT_FRAME:AddMessage("当前客户端没有可用的组队邀请接口")
			end
		end,
		["ALT"]=function(name)
			TUI_PlayerWhoSearch(name)
		end,
		["CTRL"]=function(name)
			if C_FriendList and C_FriendList.AddFriend then C_FriendList.AddFriend(name) elseif AddFriend then AddFriend(name) end;
		end,
		["NONE"]=function(name)
			ChatFrame_SendTell(name);
		end,
	},
	["RIGHT"]={
		["SHIFT"]=function(name)
			GuildInvite(name);
		end,
		["ALT"]=function(name)
			if not name then return end
			local kept, removed = {}, false
			for entry in string.gmatch(TUI_IgnoreList or ",", "[^,]+") do
				if entry == name then removed = true else kept[#kept + 1] = entry end
			end
			TUI_IgnoreList = "," .. table.concat(kept, ",") .. ","
			if DEFAULT_CHAT_FRAME then
				DEFAULT_CHAT_FRAME:AddMessage(removed and (name .. " 已从屏蔽列表中删除") or (name .. " 不在屏蔽列表中"))
			end
		end,
		["CTRL"]=function(name)
			if not name then return end
			for entry in string.gmatch(TUI_IgnoreList or ",", "[^,]+") do
				if entry == name then
					if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(name .. " 已存在于屏蔽列表中") end
					return
				end
			end
			TUI_IgnoreList = (TUI_IgnoreList or ",") .. name .. ","
			if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(name .. " 已添加到屏蔽列表中") end
		end,
		["NONE"]=function(name)
			local editBox = ChatEdit_ChooseBoxForSend and ChatEdit_ChooseBoxForSend()
			if not editBox then
				ChatFrame_OpenChat("", DEFAULT_CHAT_FRAME)
				editBox = ChatEdit_ChooseBoxForSend and ChatEdit_ChooseBoxForSend()
			end
			if editBox and editBox.Insert then
				editBox:Insert(name)
			elseif DEFAULT_CHAT_FRAME then
				DEFAULT_CHAT_FRAME:AddMessage("无法打开聊天输入框")
			end
		end,
	},
};
TUI_Rubbish = TUI_Rubbish or {};
TUI_IgnoreList = TUI_IgnoreList or ",";
local TUI_OriginalSetItemRef = SetItemRef
local function TUI_SetItemRef(link, text, button)
	link = link or ""
	text = text or link
	if string.sub(link, 1, 7) == "player:" then
		local name = string.match(link, "^player:([^:]+)")
		if name and name ~= "" then
			local usedButton = button == "RightButton" and "RIGHT" or "LEFT"
			local key = IsShiftKeyDown() and "SHIFT"
				or (IsControlKeyDown() and "CTRL")
				or (IsAltKeyDown() and "ALT") or "NONE"
			local action = TUI_PLM[usedButton][key]
			if action then return action(name) end
		end
		return
	end

	if IsControlKeyDown() then
		if DressUpItemLink then DressUpItemLink(text) end
	elseif IsShiftKeyDown() then
		local editBox = ChatEdit_ChooseBoxForSend and ChatEdit_ChooseBoxForSend()
		if editBox and editBox:IsShown() then
			editBox:Insert(text)
		else
			if TUI_OriginalSetItemRef then return TUI_OriginalSetItemRef(link, text, button) end
		end
	elseif ( IsAltKeyDown() ) then
		local itemID = getID(link)
		if not itemID then
			if TUI_OriginalSetItemRef then return TUI_OriginalSetItemRef(link, text, button) end
			return
		end
		local playerName = UnitName("player")
		TUI_Rubbish[playerName] = TUI_Rubbish[playerName] or {}
		if button == "RightButton" then
			TUI_Rubbish[playerName][itemID] = nil
			if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(text .. " 已从垃圾列表中移除") end
		else
			if TUI_Rubbish[playerName][itemID] then
				if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(text .. " 已在垃圾列表中") end
			else
				TUI_Rubbish[playerName][itemID] = text
				if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(text .. " 已添加到垃圾列表中") end
			end
		end
	elseif (string.sub(link, 1, 7) == "channel") then
	--[[
		ShowUIPanel(ItemRefTooltip);
		if ( not ItemRefTooltip:IsShown() ) then
			ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE");
		end
		ItemRefTooltip:SetHyperlink(link);
	--]]
		ChatBar_UseChatType(string.sub(link, 9, 15),string.sub(link, 17));
	else
		if TUI_OriginalSetItemRef then
			return TUI_OriginalSetItemRef(link, text, button)
		end
		if ItemRefTooltip then
			ShowUIPanel(ItemRefTooltip)
			if not ItemRefTooltip:IsShown() then ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE") end
			ItemRefTooltip:SetHyperlink(link)
		end
	end
end

-- Keep the Blizzard handler available for every link type we do not own.
if not _G.TUI_PlayerLinkMenuInstalled then
	SetItemRef = TUI_SetItemRef
	_G.TUI_PlayerLinkMenuInstalled = true
end

function ChatBar_UseChatType(chatType, target)
	if type(chatType) ~= "string" or not ChatEdit_ChooseBoxForSend then return end
	local editBox = ChatEdit_ChooseBoxForSend()
	if not editBox then return end
	local chatFrame = editBox.chatFrame or DEFAULT_CHAT_FRAME
	local parsedType, channelIndex = string.match(chatType, "([^%d]*)([%d]*)$")
	chatType = parsedType or chatType

	if chatType == "WHISPER" or chatType == "BN_WHISPER" then
		target = (ChatEdit_GetLastToldTarget and ChatEdit_GetLastToldTarget()) or ""
		if target == "" then
			target = (ChatEdit_GetLastTellTarget and ChatEdit_GetLastTellTarget()) or ""
		end
		if target == "" then
			--start new (bn) whisper
			ChatFrame_OpenChat("/w ", chatFrame);
			ChatEdit_UpdateHeader(editBox);
		else
			ChatEdit_ActivateChat(editBox);
			editBox:SetAttribute("chatType", chatType);
			editBox:SetAttribute("tellTarget", target);
			ChatEdit_UpdateHeader(editBox);
		end
		
	elseif chatType == "BN_CONVERSATION" then
		target = (ChatBar_GetLastBNConversationInTarget and ChatBar_GetLastBNConversationInTarget()) or ""
		if target == "" then
			target = (ChatBar_GetLastBNConversationOutTarget and ChatBar_GetLastBNConversationOutTarget()) or ""
		end
		if target == "" then
			target = (GetFirstBNConversation and GetFirstBNConversation()) or "";
		end
		if target == "" then
			if BNConversationInvite_NewConversation then BNConversationInvite_NewConversation() end
		else
			--target = target + MAX_WOW_CHAT_CHANNELS;
			ChatEdit_ActivateChat(editBox);
			editBox:SetAttribute("channelTarget", target);
			editBox:SetAttribute("chatType", chatType);
			ChatEdit_UpdateHeader(editBox);
		end
		
	elseif string.upper(chatType) == "CHANNEL" then
		if target then
			if type(target) == "string" then
				if not GetChannelName then return end
				target = GetChannelName(target)
			end
		elseif channelIndex and channelIndex ~= "" then
			target = tonumber(channelIndex)
		else
			return
		end
		if not target or target == 0 then return end
		ChatEdit_ActivateChat(editBox);
		editBox:SetAttribute("channelTarget", target);
		editBox:SetAttribute("chatType", "CHANNEL");
		ChatEdit_UpdateHeader(editBox);
		
	elseif chatType then
		ChatEdit_ActivateChat(editBox);
		editBox:SetAttribute("chatType", chatType);
		ChatEdit_UpdateHeader(editBox);
	end
	
	local text = (editBox:GetText() or "");
	
	if (not ChatEdit_GetLastTellTarget or ChatEdit_GetLastTellTarget() == "") and chatType ~= "WHISPER" and chatType ~= "BN_WHISPER"
			and string.sub(text, 1, 3) == "/w " then
		ChatFrame_OpenChat("", chatFrame);
	end
end