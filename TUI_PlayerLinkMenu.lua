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
function getID(link)
	--"(item[%-%d:]+):%d+|"; >> item:25600:0:0:0:0:0:0:768677774
	local ItemStringMatch = "item:(%d+):";
	return string.match(link or "", ItemStringMatch);
end
local TUI_PLM={
	["LEFT"]={
		["SHIFT"]=function(name)
			InviteUnit(name);
		end,
		["ALT"]=function(name)
			if C_FriendList and C_FriendList.SendWho then C_FriendList.SendWho("n-"..name) elseif SendWho then SendWho("n-"..name) end;
			
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
		["ALT"]=function(name,connected,lineID)
		--[[
			local dialog = StaticPopup_Show("CONFIRM_REPORT_SPAM_CHAT", name);
			if (dialog) then
				dialog.data = lineID;
			end
			return lineID and CanComplainChat(lineID)
		--]]

			if (name and string.find(TUI_IgnoreList, "," .. name .. ",", 1, true)) then
				TUI_IgnoreList=string.gsub(TUI_IgnoreList,","..name..",",",")
				DEFAULT_CHAT_FRAME:AddMessage(name.." 已经从屏蔽列表中删除")
			end

		end,
		["CTRL"]=function(name)
		--[[
			AddIgnore(name);
		--]]

			if (not name or string.find(TUI_IgnoreList, "," .. name .. ",", 1, true)) then
				DEFAULT_CHAT_FRAME:AddMessage((name or "nil").."已经存在于屏蔽列表中")
			else
				TUI_IgnoreList=TUI_IgnoreList..name..","
				DEFAULT_CHAT_FRAME:AddMessage(name.." 已经添加到屏蔽列表中")
			end

		end,
		["NONE"]=function(name)
			if (not DEFAULT_CHAT_FRAME.editBox:IsShown()) then
				ChatFrame_OpenChat(name, DEFAULT_CHAT_FRAME);
			end
			DEFAULT_CHAT_FRAME.editBox:Insert(name);
		end,
	},
};
TUI_Rubbish = TUI_Rubbish or {};
TUI_IgnoreList = TUI_IgnoreList or ",";
local TUI_OriginalSetItemRef = SetItemRef
function SetItemRef(link, text, button)
	link = link or ""
	text = text or link
	if (string.sub(link, 1, 6) == "player") then
		local namelink = string.sub(link, 8);
		local name, lineid = string.match(namelink, "([^:]+):?(.*)");
		if (name and (string.len(name) > 0)) then
		  name = string.gsub(name, "([^%s]*)%s+([^%s]*)%s+([^%s]*)", "%3");
		  name = string.gsub(name, "([^%s]*)%s+([^%s]*)", "%2");
		  local doAction;
		  local usedButton = "LEFT";
		  local key = "NONE";
		  if (button == "RightButton") then
			usedButton = "RIGHT";
		  end
		  if (IsShiftKeyDown()) then
			key = "SHIFT";
		  elseif (IsControlKeyDown()) then
			key = "CTRL";
		  elseif (IsAltKeyDown()) then
			key = "ALT";
		  end
		  local TUI_Action=TUI_PLM[usedButton][key];
		  if TUI_Action then
			return TUI_Action(name);
		  end
		end
		return;
--[[
	elseif (string.sub(link, 1, 7) == "channel") then
		local channel=string.sub(link, 9);

		if (channel) then
			if (not DEFAULT_CHAT_FRAME.editBox:IsShown()) then
				ChatFrame_OpenChat(" ", DEFAULT_CHAT_FRAME);				
			end
			if (tonumber(channel)) then
				DEFAULT_CHAT_FRAME.editBox:SetAttribute("chatType", "CHANNEL");
				DEFAULT_CHAT_FRAME.editBox:SetAttribute("channelTarget", channel);
			else
				DEFAULT_CHAT_FRAME.editBox:SetAttribute("chatType", string.upper(channel));
			end
			DEFAULT_CHAT_FRAME.editBox.info=" "	
			ChatEdit_UpdateHeader(DEFAULT_CHAT_FRAME.editBox);
			return;
		end
--]]
	end
	if ( IsControlKeyDown() ) then
		DressUpItemLink(text);
	elseif ( IsShiftKeyDown() ) then
		if ( ChatFrameEditBox:IsVisible() ) then
			ChatFrameEditBox:Insert(text);
		end
	elseif ( IsAltKeyDown() ) then
		local itemID = getID(link)
		if not itemID then
			if TUI_OriginalSetItemRef and TUI_OriginalSetItemRef ~= SetItemRef then
				return TUI_OriginalSetItemRef(link, text, button)
			end
			return
		end
		if (TUI_Rubbish[UnitName("player")] == nil ) then
			TUI_Rubbish[UnitName("player")] = {}
		end
		if (button == "RightButton") then
			TUI_Rubbish[UnitName("player")][itemID..""]=nil;
			DEFAULT_CHAT_FRAME:AddMessage(text.."已经从垃圾列表中移处！");
		else
			if(TUI_Rubbish[UnitName("player")][itemID..""]) then
				DEFAULT_CHAT_FRAME:AddMessage(text.."已经存在于垃圾列表中=======");
			else
				TUI_Rubbish[UnitName("player")][itemID..""]=text;
				DEFAULT_CHAT_FRAME:AddMessage(text.."已经添加到垃圾列表中！");
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
		if TUI_OriginalSetItemRef and TUI_OriginalSetItemRef ~= SetItemRef then
			return TUI_OriginalSetItemRef(link, text, button)
		end
		if ItemRefTooltip then
			ShowUIPanel(ItemRefTooltip)
			if not ItemRefTooltip:IsShown() then ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE") end
			ItemRefTooltip:SetHyperlink(link)
		end
	end
end

function ChatBar_UseChatType(chatType, target)
	--local chatFrame = SELECTED_DOCK_FRAME or DEFAULT_CHAT_FRAME;
	--local editBox = chatFrame.editBox;
	local editBox = ChatEdit_ChooseBoxForSend();
	local chatFrame = editBox.chatFrame;
	
	local chatType, channelIndex = string.gmatch(chatType, "([^%d]*)([%d]*)$")();
	
	if chatType == "WHISPER" or chatType == "BN_WHISPER" then
		target = ChatEdit_GetLastToldTarget();
		if target == "" then
			target = ChatEdit_GetLastTellTarget();
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
		target = ChatBar_GetLastBNConversationInTarget();
		if target == "" then
			target = ChatBar_GetLastBNConversationOutTarget();
		end
		if target == "" then
			target = (GetFirstBNConversation and GetFirstBNConversation()) or "";
		end
		if target == "" then
			--start new bn conversation
			BNConversationInvite_NewConversation();
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
				target = GetChannelName(target);
			end
		elseif channelIndex then
			target = tonumber(channelIndex);
		else
			return
		end
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
	
	if ChatEdit_GetLastTellTarget() == "" and chatType ~= "WHISPER" and chatType ~= "BN_WHISPER"
			and string.sub(text, 1, 3) == "/w " then
		ChatFrame_OpenChat("", chatFrame);
	end
end