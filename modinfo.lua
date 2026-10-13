name = "  Mouse Drag"
version = "4.1.0"
description = ChooseTranslationTable({
	en = "Mouse Drag "..version.."\nShift+LMB/RMB=Action Queue\nShift+Craft Key= Craft  Queue\nShift+  LMB  = Special  Queue\nCtrl+Alt+RMB to read/eat=Read/Eat Queue",
	zh = "Mouse Drag "..version.."\nShift+左/右键=动作队列\nShift+ 制作键=制作队列\nShift+  左键  =特殊队列\nCtrl+Alt+右键阅读/吃=阅读/吃队列"
})
author = "Taffy"
forumthread = ""
api_version = 6
priority = 1000

dont_starve_compatible = true
reign_of_giants_compatible = true
shipwrecked_compatible = true
hamlet_compatible = true
dst_compatible = false

icon_atlas = "modicon.xml"
icon = "modicon.tex"

local options_key = {
	{description = "F1", data = 282},
	{description = "F2", data = 283},
	{description = "F3", data = 284},
	{description = "F4", data = 285},
	{description = "F5", data = 286},
	{description = "F6", data = 287},
	{description = "F7", data = 288},
	{description = "F8", data = 289},
	{description = "F9", data = 290},
	{description = "F10", data = 291},
	{description = "F11", data = 292},
	{description = "F12", data = 293},
	{description = "Z", data = 122},
	{description = "X", data = 120},
	{description = "C", data = 99},
	{description = "V", data = 118},
	{description = "B", data = 98},
	{description = "N", data = 110},
	{description = "M", data = 109},
	{description = "G", data = 103},
	{description = "H", data = 104},
	{description = "J", data = 106},
	{description = "K", data = 107},
	{description = "L", data = 108},
	{description = "R", data = 114},
	{description = "T", data = 116},
	{description = "Y", data = 121},
	{description = "U", data = 117},
	{description = "I", data = 105},
	{description = "O", data = 111},
	{description = "P", data = 112},
	{description = "1", data = 49},
	{description = "2", data = 50},
	{description = "3", data = 51},
	{description = "4", data = 52},
	{description = "5", data = 53},
	{description = "6", data = 54},
	{description = "7", data = 55},
	{description = "8", data = 56},
	{description = "9", data = 57},
	{description = "0", data = 48},
	{description = "/ ?", data = 47},
	{description = "\\ |", data = 92},
	{description = "Capslock", data = 301},
}
configuration_options = {
	{
		name = "Grid",
		label = ChooseTranslationTable({en = "Ground Grid Key", zh = "地皮网格键位"}),
		hover = ChooseTranslationTable({en = "Show 21×21 turf grids around the player", zh = "显示人物周围21×21的地皮网格"}),
		options = options_key,
		default = 283,
	},
	{
		name = "Action",
		label = ChooseTranslationTable({en = "Quick-Queue Key", zh = "快速队列键位"}),
		hover = ChooseTranslationTable({en = "Fast push left-click actions, Ctrl+key combo for right-click actions", zh = "快速左键动作，Ctrl组合键右键动作"}),
		options = options_key,
		default = 99,
	},
	{
		name = "Recipe",
		label = ChooseTranslationTable({en = "Craft/Build Key", zh = "制作建造键位"}),
		hover = ChooseTranslationTable({en = "Craft/Build the last item/structure, Shift + key combo for craft queue", zh = "制作/建造上一个物品/建筑，Shift组合键制作队列"}),
		options = options_key,
		default = 120,
	},
	{
		name = "Colour",
		label = ChooseTranslationTable({en = "Selected Entity Tint", zh = "选中实体颜色"}),
		hover = ChooseTranslationTable({en = "Change the additive tint of selected entities", zh = "调整选中实体的添加色"}),
		options =
		{
			{description = ChooseTranslationTable({en = "Red", zh = "红色"}), data = "C1"},
			{description = ChooseTranslationTable({en = "Green", zh = "绿色"}), data = "C2"},
			{description = ChooseTranslationTable({en = "Blue", zh = "蓝色"}), data = "C3"},
			{description = ChooseTranslationTable({en = "Pink", zh = "粉色"}), data = "C4"},
			{description = ChooseTranslationTable({en = "Orange", zh = "橙色"}), data = "C5"},
			{description = ChooseTranslationTable({en = "Cyan", zh = "青色"}), data = "C6"},
			{description = ChooseTranslationTable({en = "Purple", zh = "紫色"}), data = "C7"},
		},
		default = "C1",
	},
	{
		name = "Finder",
		label = ChooseTranslationTable({en = "Item Finder Toggle", zh = "物品查找开关"}),
		hover = ChooseTranslationTable({en = "Mark containers holding the selected item; right-click to collect crafting materials", zh = "标记存有所选物品的容器，右键收集制作材料"}),
		options =
		{
			{description = ChooseTranslationTable({en = "Disabled", zh = "禁用"}), data = false},
			{description = ChooseTranslationTable({en = "Enabled", zh = "启用"}), data = true},
		},
		default = false,
	},
	{
		name = "Range",
		label = ChooseTranslationTable({en = "Range Display Toggle", zh = "范围显示开关"}),
		hover = ChooseTranslationTable({en = "Show item range, hold Alt and left-click to show structure range", zh = "显示物品的作用范围；按住Alt并左键目标建筑，显示建筑的作用范围"}),
		options =
		{
			{description = ChooseTranslationTable({en = "Disabled", zh = "禁用"}), data = false},
			{description = ChooseTranslationTable({en = "Enabled", zh = "启用"}), data = true},
		},
		default = false,
	},
	{
		name = "Short",
		label = ChooseTranslationTable({en = "Quick Action Toggle", zh = "快速动作开关"}),
		hover = ChooseTranslationTable({en = "Convert most long actions to short", zh = "改多数长动作为短动作"}),
		options =
		{
			{description = ChooseTranslationTable({en = "Disabled", zh = "禁用"}), data = false},
			{description = ChooseTranslationTable({en = "Enabled", zh = "启用"}), data = true},
		},
		default = false,
	},
	{
		name = "Ignorance",
		label = ChooseTranslationTable({en = "Ignore Spacing Toggle", zh = "无视间距开关"}),
		hover = ChooseTranslationTable({en = "Adjust spacing requirements for planting and building", zh = "调整种植和建造时的间距要求"}),
		options =
		{
			{description = ChooseTranslationTable({en = "Disabled", zh = "禁用"}), data = 0},
			{description = ChooseTranslationTable({en = "Ignore Item", zh = "无视物品"}), data = 1},
			{description = ChooseTranslationTable({en = "Ignore All", zh = "无视全部"}), data = 2},
		},
		default = 0,
	},
	{
		name = "range_default",
		label = ChooseTranslationTable({en = "Default Scan Range", zh = "默认扫描范围"}),
		hover = ChooseTranslationTable({en = "Default value of scan range at first load ", zh = "扫描范围的初次加载默认值"}),
		options =
		{
			{description = "5", data = 5},
			{description = "10", data = 10},
			{description = "15", data = 15},
			{description = "20", data = 20},
			{description = "25", data = 25},
			{description = "30", data = 30},
			{description = "35", data = 35},
			{description = "40", data = 40},
			{description = "45", data = 45},
			{description = "50", data = 50},
		},
		default = 20,
	},
	{
		name = "remode_default",
		label = ChooseTranslationTable({en = "Default Repeat Mode", zh = "默认重复模式"}),
		hover = ChooseTranslationTable({en = "Default value of repeat mode at first load ", zh = "重复模式的初次加载默认值"}),
		options =
		{
			{description = ChooseTranslationTable({en = "Once", zh = "单次"}), data = 0},
			{description = ChooseTranslationTable({en = "Default", zh = "默认"}), data = 1},
			{description = ChooseTranslationTable({en = "Repeat", zh = "重复"}), data = 2},
		},
		default = 1,
	},
	{
		name = "pickup_default",
		label = ChooseTranslationTable({en = "Default Auto Pick-up", zh = "默认自动拾取"}),
		hover = ChooseTranslationTable({en = "Default value of auto pick-up at first load ", zh = "自动拾取的初次加载默认值"}),
		options =
		{
			{description = ChooseTranslationTable({en = "Disabled", zh = "禁用"}), data = false},
			{description = ChooseTranslationTable({en = "Enabled", zh = "启用"}), data = true},
		},
		default = false,
	},
	{
		name = "linked_default",
		label = ChooseTranslationTable({en = "Default Linked Action", zh = "默认链接动作"}),
		hover = ChooseTranslationTable({en = "Default value of linked action at first load ", zh = "链接动作的初次加载默认值"}),
		options =
		{
			{description = ChooseTranslationTable({en = "Disabled", zh = "禁用"}), data = false},
			{description = ChooseTranslationTable({en = "Enabled", zh = "启用"}), data = true},
		},
		default = false,
	},
	{
		name = "force_default",
		label = ChooseTranslationTable({en = "Default Force Action", zh = "默认强制动作"}),
		hover = ChooseTranslationTable({en = "Default value of force action at first load ", zh = "强制动作的初次加载默认值"}),
		options =
		{
			{description = ChooseTranslationTable({en = "Disabled", zh = "禁用"}), data = false},
			{description = ChooseTranslationTable({en = "Enabled", zh = "启用"}), data = true},
		},
		default = false,
	},
	{
		name = "remote_default",
		label = ChooseTranslationTable({en = "Default Remote Action", zh = "默认远程动作"}),
		hover = ChooseTranslationTable({en = "Default value of remote action at first load ", zh = "远程动作的初次加载默认值"}),
		options =
		{
			{description = ChooseTranslationTable({en = "Disabled", zh = "禁用"}), data = false},
			{description = ChooseTranslationTable({en = "Enabled", zh = "启用"}), data = true},
		},
		default = false,
	},
}