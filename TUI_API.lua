--[[
-------------------------------- TBC宏 基础 --------------------------------
身上各个部位编号：
1：头
2：颈
3：肩
4：衬衣
5：胸
6：腰带
7：腿
8：脚
9：手腕
10：手套
11：手指1
12：手指2
13：饰品1
14：饰品2
15：背
16：主手
17：副手
18：远程武器

动作条名称及编号：
主动作条1： ActionButton
主动作条2：不知道。。。。。。。
主动作条3（右1）： MultiBarRightButton
主动作条4（右2）： MultiBarLeftButton
主动作条5（右下）： MultiBarBottomRightButton
主动作条6（左下）： MultiBarBottomLeftButton
每个动作条的按钮从左至右都是1~12。
背包及包裹格子编号：
背包从右到左的编号分别是：4、3、2、1、0~
包裹格子的编号是从左至右排列，一个包的第一行分别是：1、2、3、4~
然后是包裹第2行：5、6、7、8~下面几行依次类推。

姿态编号：
      | 战士 |   德鲁伊   |　 牧师 　|　 盗贼 　|　萨满祭祀
－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－
姿态 1 | 战斗 |　　熊　 | 暗影形态 |　   潜行 　|　幽魂之狼
姿态 2 | 防御 |　 海豹　|　　　　　|　　　　　|
姿态 3 | 狂暴 |　　猫　 |　　　　　|　　　　　|
姿态 4 |          |　旅行 　|　　　　　|　　　　　|
姿态 5 |          | 枭兽/树 |　　　　　|　　　　　|
姿态 6 |          |　 飞行　|　　　　　|　　　　　|

-------------------------------- TBC宏 条件--------------------------------
help---判断目标是否为友善；
harm---判断目标是否为敌对；
party---判断目标是否在本小队中；
raid---判断目标是否在团队中；
group---判断自己是否在一个队伍中（小队或团队）；
group:party/raid判断自己是否在一个指定的集体中：小队/团队；
combat---判断你是否在战斗中；
stance或stance:#---判断你是否在姿态中或是否在指定姿态中。#为数字，也就是姿态编号。
stealth---判断你是否在潜行；
modifier或modifier:x---x可为shift、ctrl、alt 或者是它们的组合，判断某个或某几个按键是否被按下。
equipped:<item>---判断某件物品是否在装备中。<item>可以是装备栏编号、装备分类（武器、副手。。。）、装备子类（双手剑、法仗等等。。。）
target=<unit>-- -可以把技能目标指定为任何有效的目标，并且可以另你不丢失当前目标！<unit>还可以为“none”，用来指定没有目标的时候。 “player”，用来指定只对自己施放。比如“/use [target=player] 厚符文布绷带”，无论任何时候都只对自己使用绷带。关于“self”，这个条件在使用时经多人测试都会报错，原因不明，所以暂时大家先不要用。
actionbar:<number>---判断当前动作条是否被列出。<number>可为1、2、3、4、5、6
pet:<pet type 或 pet name>---pet type为宠物类型；pet name为宠物名字。如果不填写宠物类型或名字则判断宠物是否存在。
mounted---判断是否在坐骑上。
swimming---判断是否在游泳。
flying---判断是否在飞行中。
outdoors---判断你是否在室外。
indoors---判断你是否在室内。
button:<#>---判断某个特定按钮是否被用来触发技能。<#>可为1（鼠标左键）、2（鼠标右键）、3（鼠标按键3，也就是鼠标滚轮向下按，不是向上滚也不是向下滚）、4（鼠标按键4，多键鼠标专用）、5（鼠标按键5，多键鼠标专用）。默认为1。
channeling或channeling:法术名称---判断你是否在引导法术或是否在引导指定的法术。
exists---判断特定目标是否存在。
dead---判断目标是否死亡。请注意，这个是判断目标是否死亡。如果你想判断你自己的宠物是否死亡就要写成这样“[target=pet,dead]”。
比如“/cast [target=pet,dead]复活宠物（猎人的复活宠物技能。。。）”。这个宏的意思就是如果你的宠物死亡了那么施放复活宠物。
equipped:装备名称/类型/子类型---判断某件装备是否在装备中。


/use [option]
使用物品或装备，不再需要像以前一样指定包裹或动作条编号了。比如“/use 厚符文布绷带”。
/userandom [option]
随即使用指定的几件物品。比如“/userandom [nomounted] 黑色作战科多兽,死亡军马的缰绳,霜狼嗥叫者的号角,迅捷绿色迅猛龙
/equip [option]
直接举例说明吧。“/equip [noequiped:复仇法袍]复仇法袍”，意思是如果没装备复仇法袍就把复仇法袍装备上。
/equipslot [option]
这个功能和上面那个类似。但是这个命令主要是为了武器、戒指等可以装备两件的装备而诞生的。
比如：
/equipslot [equiped:多彩之剑] 16 毁灭之刃
/equipslot [equiped:残忍利刃] 17 熔火犬牙
/equipslot [equiped:毁灭之刃] 16 多彩之剑
/equipslot [equiped:熔火犬牙] 17 残忍利刃
这个宏可以把多彩和毁灭、残忍和狗牙互换。“/equipslot”在这里主要就是区分主副手，让宏可以把装备穿到正确的位置。

/target [option]
/targetenemy [option]
/targetfriend [option]
/targetparty [option]
/targetraid [option]
/targetlasttarget [option]
/targetlastenemy [option]
/assist [option]
/focus [option]/clearfocus [option]

/petattack [option]让宠物开始攻击一个目标。
/petstay [option]让宠物停在原地。
/petfollow [option]让宠物跟随自己。
/petpassive [option]让宠物进入被动状态。
/petdefensive [option]让宠物进入防御状态。
/petaggressive [option]让宠物进入攻击状态。
/petautocaston [option] 法术名称 宠物法术自动施放开启。
/petautocastoff [option] 法术名称


/startattack
/stopattack
# show <法术名称/物品名称>
#showtooltip <法术名称/物品名称>
/cancelaura [option]
/cancleform. [option]
/stopmacro [option]
/click [option]
/stopcasting [option]
/dismount [option]
/run
/in N /频道 内容
/swapactionbar [option] <动作条编号> <动作条编号>
/changeactionbar [option] <动作条编号>
/script. SetCVar("targetNearestDistance",5)
--]]

	--{Key = "G", Type = "item", Value = "黑色战驹缰绳", Target = "player"},

	--鼠标滚轮上滑3次会依次对自己使用"心灵之火", "防护暗影", "真言术：韧", 3个法术, 当每个法术施放后5秒内没有任何动作将复位到开始
	--{Key = "MOUSEWHEELUP", Type = "spell", Value = {"心灵之火", "防护暗影", "真言术：韧"}, Target = "player", Smart = true},

	--在小队头像上按鼠标左键会为该小队成员施放"快速治疗"法术
	--{Key = "LeftButton", Type = "spell", Value = "快速治疗", Condition = "helpbutton", TargetFrames = ShortKey.ExtFrame.Party},
	--{Key = "ALT-LeftButton", Type = "spell", Value = "强效治疗术", Condition = "helpbutton", TargetFrames = ShortKey.ExtFrame.Party},
	--{Key = "CTRL-LeftButton", Type = "spell", Value = "真言术：韧", Condition = "helpbutton", TargetFrames = ShortKey.ExtFrame.Party},
	--在小队头像上按SHIFT+鼠标左键为选中该小队成员
	--{Key = "SHIFT-LeftButton", Type = "target", TargetFrames = ShortKey.ExtFrame.Party},
	--{Key = "RightButton", Type = "spell", Value = "真言术：盾", Condition = "helpbutton", TargetFrames = ShortKey.ExtFrame.Party},
	--{Key = "ALT-RightButton", Type = "spell", Value = "复活术", Condition = "helpbutton", TargetFrames = ShortKey.ExtFrame.Party},
	--{Key = "CTRL-RightButton", Type = "spell", Value = "防护暗影", Condition = "helpbutton", TargetFrames = ShortKey.ExtFrame.Party},
	--在小队头像上按SHIFT+鼠标右键为协助该小队成员
	--{Key = "SHIFT-LeftButton", Type = "assist", TargetFrames = ShortKey.ExtFrame.Party},
	--{Key = "MiddleButton", Type = "spell", Value = "恢复", Condition = "helpbutton", TargetFrames = ShortKey.ExtFrame.Party},

	--在目标头像上按鼠标左键如果他是友方目标则会为他施放"快速治疗"法术
	--{Key = "LeftButton", Type = "spell", Value = "快速治疗", Condition = "helpbutton", TargetFrames = ShortKey.ExtFrame.Target},
	--{Key = "RightButton", Type = "spell", Value = "真言术：盾", Condition = "helpbutton", TargetFrames = ShortKey.ExtFrame.Target},
	--{Key = "MiddleButton", Type = "spell", Value = "恢复", Condition = "helpbutton", TargetFrames = ShortKey.ExtFrame.Target},
	--在目标头像上按鼠标左键如果他是敌方目标则会为他施放"驱散魔法"法术
	--{Key = "LeftButton", Type = "spell", Value = "驱散魔法", Condition = "harmbutton", TargetFrames = ShortKey.ExtFrame.Target},
	--{Key = "RightButton", Type = "spell", Value = "沉默", Condition = "harmbutton", TargetFrames = ShortKey.ExtFrame.Target},
	--{Key = "MiddleButton", Type = "spell", Value = "精神控制", Condition = "harmbutton", TargetFrames = ShortKey.ExtFrame.Target},
	--在目标头像上按SHIFT+鼠标右键为调出改目标菜单
	--{Key = "SHIFT-RightButton", Type = "menu", TargetFrames = ShortKey.ExtFrame.Target},
--[[

DEHHAN
GIMHAN JinHan7952
MAKOTO_WOW
TACIYA


local MACROS1 = {
	["1"] = {
		[""]		= "/script TUI_DR()",	
		["alt-"]	= gn(774),--"回春術",			
		["shift-"]	= gn(8936),--"癒合",
		["ctrl-"]	= gn(33763),--"生命之花",
	},
	["2"] = {
		[""]		= gn(2893),--"驅毒術",			
		["ctrl-"]	= gn(2782),--"解除詛咒",
		["shift-"]	= gn(5185),--"治療之觸",
		["alt-"]	= gn(18562),--"迅捷治愈",
	},
	["3"] = {
		[""]		= "/cast 自然迅捷\n/stopcasting\n/cast "..gn(5185),--治療之觸,
	},
}
local button, sets;
if(DefaultClickSets and DefaultClickSets[class]) then
	for button, sets in pairs(DefaultClickSets[class]) do
		for modifier, spell in pairs(sets) do
			if string.find(spell,"/") then
				frame:SetAttribute(modifier.."type"..button, "macro");
				frame:SetAttribute(modifier.."macrotext"..button, spell);
			else
				frame:SetAttribute(modifier.."type"..button, "spell");
				frame:SetAttribute(modifier.."spell"..button, spell);
			end
		end
	end
end

#showtooltip 顺劈斩 
/script SetCVar("targetNearestDistance",5) 
/targetenemy 
/cast 顺劈斩 
/startattack 
/script SetCVar("targetNearestDistance",41) 

--S-W 乘胜追击,援护
#showtooltip 援护 
/cast [target=exist]
/cast [help] 援护; [target=targettarget, help] 援护 
/startattack [target=harm]  

#showtooltip 灵魂箭雨
/cast 灵魂箭雨

#showtooltip 灵魂锁链
/cast 灵魂锁链

#showtooltip 灵魂长枪
/cleartarget
/targetenemy
/cast 灵魂长枪 

/script TUI_Equip_10()
/cast 盾击

/stopcasting

拥抱 痛 瘟疫 心灵 鞭挞

#showtooltip 精神鞭笞
/cast [nochanneling:精神鞭笞] 精神鞭笞

function CHANNELSWITCH_SetChatChannel(channel)
	channel = "/"..(channel or "s").." ";
	if not ChatFrameEditBox:IsVisible() then
 		ChatFrame_OpenChat(channel);
	else
		ChatFrameEditBox:SetText(channel);
	end;
	ChatEdit_ParseText(ChatFrame1.editBox, 0);
end



local function INIT_CODE()
	-- ========================= 顯示目標血量百分比 ===========================================================================================
	TargetFrameHealthBarText:SetFont(TargetFrameHealthBarText:GetFont(), 10, "OUTLINE")
	hooksecurefunc("TextStatusBar_UpdateTextString", function(textStatusBar)
		local textString = textStatusBar.TextString;
		if textString and textString:GetName() == "TargetFrameHealthBarText" then
			if UnitIsPlayer("target") then return end
			local value = textStatusBar:GetValue();
			local valueMin, valueMax = textStatusBar:GetMinMaxValues();

			if ( ( tonumber(valueMax) ~= valueMax or valueMax > 0 ) and not ( textStatusBar.pauseUpdates ) ) then
				if ( value and valueMax > 0 and not GetCVarBool("statusTextPercentage") ) then
					local pct = tostring(math.ceil((value / valueMax) * 100)) .. "%"
					if ( value > 0 and textString:GetText() and pct~="100%" ) then
						textString:SetText(pct .. " ".. textString:GetText() )
					end
				end
			end
		end
	end)


	-- ========================= 隱藏主動作條兩側材質 ===========================================================================================
	MainMenuBarLeftEndCap:Hide();
	MainMenuBarRightEndCap:Hide();

	-- ========================= 縮小默認動作條 ===========================================================================================
	local actionBarScale = 0.9
	MainMenuBar:SetScale(actionBarScale)
	MultiBarBottomLeft:SetScale(actionBarScale)
	MultiBarBottomRight:SetScale(actionBarScale)
	MultiBarLeft:SetScale(actionBarScale * 0.85)
	MultiBarRight:SetScale(actionBarScale * 0.85)

	-- ========================= 修改默認動作條佈局 ===========================================================================================
	MainMenuBar:ClearAllPoints();
	MainMenuBar:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 3, 0)
	MultiBarRight:ClearAllPoints();
	MultiBarRight:SetPoint("RIGHT",UIParent,"RIGHT", -3, 0);
	MultiBarRight:SetPoint("BOTTOM",MultiBarBottomRight,"TOP");

	MultiBarLeftButton7:ClearAllPoints();	MultiBarLeftButton7:SetPoint("RIGHT", MultiBarRightButton1, "LEFT", -6, 0)
	MultiBarLeftButton1:ClearAllPoints();	MultiBarLeftButton1:SetPoint("RIGHT", MultiBarLeftButton7, "LEFT", -6, 0)

	MultiBarRight:SetHeight( MultiBarRight:GetHeight() / 2);
	MultiBarRightButton7:ClearAllPoints();	MultiBarRightButton7:SetPoint("TOPRIGHT")
	MultiBarRightButton1:ClearAllPoints();	MultiBarRightButton1:SetPoint("RIGHT", MultiBarRightButton7, "LEFT", -6, 0)


	-- ========================= 按著功能鍵點擊天賦按鈕可以切換天賦 =============================================================================
	TalentMicroButton:SetScript("OnClick", function () 
		if  IsModifierKeyDown() then
			local activeTalentGroup = GetActiveTalentGroup() or 1;
			SetActiveTalentGroup(3-activeTalentGroup)
		else
			ToggleTalentFrame()
		end
	end)

end

local frame = CreateFrame("Frame");
frame:RegisterEvent("PLAYER_ENTERING_WORLD");
frame:SetScript("OnEvent", function(self,event) INIT_CODE(); self:UnregisterEvent("PLAYER_ENTERING_WORLD"); end)

/cast [exists] 驱散魔法;[target=player]驱散魔法
/cast 暗影恶魔 /petpassive




------------------------------------------------------------
-- 血条及名字按职业颜色
------------------------------------------------------------
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

