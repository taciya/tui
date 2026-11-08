-- TUI Macro templates. Edit this text to maintain your own macro pack.
-- Format: VER 3 <source-id> "<name>" "<icon-file-id>" ... END
TUI_MACRO_SOURCE = [=[
VER 3 0000000000000042 "-找-" "134400"
#showtooltip 乌尔图斯
/target 鲁伯斯
/target 乌尔图斯
END
VER 3 000000000000004A "11" "132089"
/跟随 疯狂的胡老师
END
VER 3 000000000000004B "shi" "136012"
/cast 上古德莱尼作战咒符
/cast 刃拳的宽容
/cast 嗜血
END
VER 3 000000000000002D "T10" "132360"
/run if IsAltKeyDown() then SlashCmdList["TUIITEMRACK"]("10") else TUI_ItemRack_F10() end
END
VER 3 000000000000002E "T11" "135769"
/run if IsAltKeyDown() then SlashCmdList["TUIITEMRACK"]("11") else TUI_ItemRack_F11() end
END
VER 3 000000000000002F "T12" "132147"
/run if IsAltKeyDown() then SlashCmdList["TUIITEMRACK"]("12") else TUI_ItemRack_F12() end
END
VER 3 000000000000003D "传送" "134400"
#showtooltip
/cast [mod:Alt]叶基亚的卷轴;[mod:Ctrl]锻造;[mod]熔炼;[nomod]塞雷布拉斯节杖
END
VER 3 0000000000000009 "副业" "134400"
#showtooltip
/cast [mod:Alt]急救;[mod]烹饪;[nomod]钓鱼
END
VER 3 0000000000000007 "商-分" "134400"
#showtooltip
/cast [mod:Alt]附魔;[mod]裁缝;[nomod]分解
END
VER 3 0000000000000029 "商-矿" "134400"
#showtooltip
/cast [mod:Alt]工程学;[mod:Ctrl]锻造;[mod]熔炼;[nomod]寻找矿物
END
VER 3 000000000000002A "商-药" "134400"
#showtooltip
/cast [mod:Alt]炼金术;[mod]锻造;[nomod]寻找草药
END
VER 3 0000000000000001 "喊话" "134400"
/喊 >>>死亡矿井<<<  来T  4=1
END
VER 3 000000000000001C "图腾" "134400"
#showtooltip
/cast [mod:Alt]地缚图腾;[mod:Ctrl]石爪图腾;[mod]战栗图腾;[nomod]石肤图腾
END
VER 3 000000000000001E "德-1" "134400"
#showtooltip [stealth]突袭;[stance:1]重殴;[stance:3]爪击;愤怒
/cast [stealth]突袭;[stance:1]重殴;[stance:3]爪击;愤怒
END
VER 3 000000000000001F "德-2" "134400"
#showtooltip [stance:1]低吼;[stance:3]斜掠;月火术
/cast [stance:1]低吼;[stance:3]斜掠;月火术
END
VER 3 0000000000000020 "德-3" "134400"
#showtooltip [stealth]撕碎;[stance:1]横扫;[stance:3]撕碎;星火术
/cast [stealth]撕碎;[stance:1]横扫;[stance:3]撕碎;星火术
END
VER 3 0000000000000021 "德-4" "134400"
#showtooltip [stance:1]猛击;[stance:3]割裂;纠缠根须
/cast [stance:1]猛击;[stance:3]割裂;纠缠根须
END
VER 3 0000000000000026 "德-A" "134400"
#showtooltip [stance:3]猛虎之怒;[stance:1]激怒
/cast [stance:3]猛虎之怒;[stance:1]激怒
END
VER 3 0000000000000022 "德-D" "134400"
#showtooltip [stance:1]挫志咆哮;熊形态
/cast [stance:1]挫志咆哮;熊形态
END
VER 3 0000000000000044 "德-F" "134400"
#showtooltip [stance:1/3]精灵之火（野性）;精灵之火
/cast [stance:1/3]精灵之火（野性）;精灵之火
END
VER 3 0000000000000023 "德-F" "134400"
#showtooltip [stance:3]潜行;猎豹形态
/cast [stance:3]潜行;猎豹形态
END
VER 3 0000000000000024 "德-S" "136047"
/cancelform
END
VER 3 0000000000000008 "德-中" "134400"
#showtooltip
/cast [mod:Alt,stance:3]野性印记;[mod:Shift]急奔;[mod]休眠;[nomod]荆棘术
END
VER 3 000000000000000C "战-1" "134400"
#showtooltip
/cast 英勇打击
/startattack
END
VER 3 0000000000000027 "战-A" "134400"
#showtooltip [stance:2/1]狂暴姿态;[stance:3]暴怒
/equipslot 16 雷德的神圣控诉者
/equipslot 17 克罗之刃
/cast [stance:2/1]狂暴姿态;[stance:3,combat]暴怒
--死亡之愿
END
VER 3 000000000000000D "战-C" "134400"
#showtooltip
/cast [stance:2]嘲讽;[stance:1/3]断筋
END
VER 3 000000000000000E "战-D" "134400"
#showtooltip  [stance:1/3]防御姿态;[stance:2]盾墙
/equipslot 16 雷德的神圣控诉者
/equipslot 17 龙人之盾
/cast [stance:1/3]防御姿态;[stance:2,combat]盾墙
END
VER 3 0000000000000039 "战-F" "134400"
#showtooltip
/castsequence reset=60 血性狂暴,鲁莽
END
VER 3 0000000000000011 "战-Q" "134400"
#showtooltip
/castsequence [stance:1]reset=4 雷霆一击,挫志怒吼;[stance:2/3]reset=combat 挫志怒吼
END
VER 3 000000000000000F "战-S" "134400"
#showtooltip [stance:2/3]战斗姿态;[stance:1]反击风暴
/equipslot 16 克罗之刃
/cast [stance:2/3]战斗姿态;[stance:1,combat]反击风暴
END
VER 3 0000000000000010 "战-V" "134400"
#showtooltip
/cast [stance:1]压制;[stance:2]复仇;旋风斩
END
VER 3 0000000000000014 "战-X" "134400"
#showtooltip
/cast [stance:2]盾牌格挡;[stance:1]惩戒痛击;拦截
END
VER 3 0000000000000028 "战-Z" "134400"
#showtooltip [stance:2/1]撕裂;[stance:3]狂暴之怒
/cast [stance:2/1]撕裂;[stance:3,combat]狂暴之怒
END
VER 3 0000000000000016 "战-中" "134400"
#showtooltip
/cast [mod:Alt]战斗怒吼;[mod:Ctrl]破釜沉舟;[mod]暴怒;[nomod]横扫攻击
END
VER 3 000000000000002B "战-持" "134400"
--#showtooltip 16
--/equipslot [equiped:多彩之剑] 16 毁灭之刃
--/equipslot 17
/equipslot 16 雷德的神圣控诉者
/equipslot 17 克罗之刃
END
VER 3 000000000000002C "战-盾" "134400"
#showtooltip 龙人之盾
--/equipslot [equiped:多彩之剑] 16 毁灭之刃
/equipslot 16 雷德的神圣控诉者
/equipslot 17 龙人之盾
END
VER 3 0000000000000015 "抓" "134328"
/target 扎克乌尔
/cast 冲锋
/startattack
END
VER 3 0000000000000041 "术-V" "134400"
#showtooltip [pet:虚空行者]牺牲;[pet:魅魔]诱惑;[pet:地狱猎犬]法术封锁;[pet:小鬼]火焰之盾
/cast [pet:虚空行者]牺牲;[pet:魅魔]诱惑;[pet:地狱猎犬]法术封锁;[pet:小鬼]火焰之盾
END
VER 3 0000000000000040 "术-碎" "134400"
#showtooltip 灵魂碎片
/run TUI_DC(7)
END
VER 3 000000000000003E "术-自" "134400"
#showtooltip
/petattack
/castsequence reset=target 痛苦诅咒,腐蚀术
/cast 射击
END
VER 3 000000000000001D "水水" "134400"
#showtooltip
/cast [mod:Alt]清毒图腾;[mod]雄鹰守护;[nomod]治疗之泉图腾(等级 1)
END
VER 3 0000000000000043 "法-F" "134400"
#showtooltip
/castsequence reset=15 闪现术,逃命专家
/cast 冰霜新星
END
VER 3 000000000000003A "法-Z" "134400"
/script SetRaidTarget("target", 1)
/cast 变形术
END
VER 3 000000000000003B "法-中" "134400"
#showtooltip
/cast [mod:Alt]暴风雪(等级 1);[mod:Ctrl];[mod];[nomod]暴风雪
END
VER 3 0000000000000038 "法-印" "134400"
#showtooltip
/cast [mod:Alt]冰甲术;[mod:Ctrl];[mod];[nomod]奥术智慧
END
VER 3 000000000000003C "法-门" "134400"
#showtooltip
/cast [mod:Alt]传送：铁炉堡;[mod:Ctrl];[mod]传送：达纳苏斯;[nomod]传送：暴风城
END
VER 3 0000000000000031 "牧-1" "134400"
#showtooltip
/startattack
/cast 惩击
END
VER 3 0000000000000030 "牧-4" "134400"
#showtooltip
/stopcasting
/startattack
/cast 暗言术：痛
/cast 射击
END
VER 3 0000000000000035 "牧-C" "134400"
#showtooltip
/stopcasting
/cast 真言术：盾
END
VER 3 0000000000000036 "牧-Z" "134400"
#showtooltip
/stopcasting
/cast 恢复
END
VER 3 0000000000000037 "牧-中" "134400"
#showtooltip
/cast [mod:Alt]心灵之火;[mod:Ctrl];[mod]防护暗影;[nomod]真言术：韧
END
VER 3 000000000000003F "猎-V" "134400"
#showtooltip
/cast 猫鼬撕咬
/cast 多重射击
END
VER 3 0000000000000045 "猎-X" "134400"
#showtooltip
/cast [combat]毒蝎钉刺;冰冻陷阱
END
VER 3 0000000000000018 "猎-中" "134400"
#showtooltip
/cast [mod:Alt]猎豹守护;[mod]雄鹰守护;[nomod]灵猴守护
END
VER 3 0000000000000017 "猎-商" "134400"
#showtooltip
/cast [mod:Alt]制皮;[mod:Ctrl]锻造;[mod]熔炼;[nomod]寻找财宝
END
VER 3 000000000000001B "猎-喂" "134400"
#showtooltip 0 1
/cast 喂养宠物
/use 0 1
END
VER 3 0000000000000019 "猎-宠" "134400"
#showtooltip
/cast [mod:Alt]复活宠物;[mod:Shift]驯服野兽;[mod]野兽知识;[nomod]召唤宠物
END
VER 3 000000000000001A "猎-踪" "134400"
#showtooltip
/cast [mod:Alt]追踪野兽;[mod:Shift]追踪隐藏生物;[mod:Ctrl]追踪亡灵;[nomod]追踪人型生物
END
VER 3 0000000000000047 "绷带" "134400"
/run TUI_BD()
END
VER 3 0000000000000046 "萨-4" "134400"
#showtooltip
/cast 烈焰震击
/startattack
END
VER 3 0000000000000004 "贼-1" "134400"
#showtooltip [nostealth]邪恶攻击;偷袭
/equipslot 16 翼刃
/equipslot 17 力量之战斗小刀
/cast [stealth]搜索
/cast [nostealth]邪恶攻击;偷袭
END
VER 3 0000000000000005 "贼-2" "134400"
#showtooltip [nostealth]刺骨;绞喉
/cast [stealth]搜索
/cast [nostealth]刺骨;绞喉
END
VER 3 0000000000000006 "贼-3" "134400"
#showtooltip [nostealth]背刺;伏击
/equipslot 16 奥格瑞玛之剑
/equipslot 17 力量之战斗小刀
/cast [stealth]搜索
/cast [nostealth]背刺;伏击
END
VER 3 0000000000000025 "贼-C" "134400"
#showtooltip [stealth]闷棍;凿击
/cast [stealth]搜索
/cast [stealth]闷棍;凿击
END
VER 3 0000000000000032 "贼-F" "134400"
#showtooltip
/cast [stealth]搜索;脚踢
END
VER 3 000000000000000B "贼-中" "134400"
#showtooltip
/cast [mod:Alt]疾跑;[mod]开锁;扰乱
END
VER 3 0000000000000003 "贼-消" "134400"
#showtooltip
/cast [combat]消失;[nocombat]潜行
END
VER 3 0000000000000033 "骑-D" "134400"
#showtooltip
/castsequence reset=300 圣盾术,圣佑术
END
VER 3 0000000000000048 "骑-S" "134400"
#showtooltip
/castsequence reset=120 神恩术,神启
END
VER 3 0000000000000034 "骑-中" "134400"
#showtooltip
/cast [mod:Alt]智慧祝福;[mod:Shift,known:庇护祝福]庇护祝福;[mod:Shift,noknown:庇护祝福]光明祝福;[mod]拯救祝福;[nomod]力量祝福
END
VER 3 0000000000000049 "骑-强" "134400"
#showtooltip
/cast [mod:Alt]强效智慧祝福;[mod:Shift,known:强效庇护祝福]强效庇护祝福;[mod:Shift,noknown:强效庇护祝福]强效光明祝福;[mod]强效拯救祝福;[nomod]强效力量祝福
END
]=]
