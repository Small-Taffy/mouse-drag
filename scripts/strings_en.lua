STRINGS.MOUSE_DRAG = {
	CONTROLS = {
		DRAG = "Drag",
		COLLECT = "Collect",
		COLLECT_MORE = "Collect More",
	},
	RECIPES = {
		NOT_RECNAME = "No last recipe record",
		NOT_KNOWSRECIPE = "Technology not unlocked",
		NOT_CANBUILD = "Not enough materials",
	},
	BUTTONS = {
		RANGE = "Scan Range",
		SPACING = "Point Spacing",
		REMODE = "Repeat Mode",
		PTMODE = "Point Mode",
		PICKUP = "Auto Pick-up",
		LINKED = "Linked Action",
		FORCE = "Force Action",
		REMOTE = "Remote Action",
	},
	OPTIONS = {
		FALSE = "Disabled",
		TRUE = "Enabled",
		ONCE = "Once",
		DEFEAULT = "Default",
		REPEAT = "Repeat",
		SQUARE = "Square",
		HEXAGON = "Hexagon",
	},
	INTRODUCTION = {
		RANGE = "Radius of the scan range. Covers quick, double-click and special queues; the quick queue is centered on the player, while double-click and special queues are centered on the mouse cursor.",
		SPACING = "Spacing between adjacent points when performing area planting/building.",
		REMODE = "Once: all entity actions are executed only once.\nDefault: default logic; repeats based on preset rules.\nRepeat: all entity actions repeat until they can no longer be performed.",
		PTMODE = "Square points and hexagonal points. For hexagonal points during batch planting/building, each drag must start from the same origin or horizontal axis, otherwise coordinates will not align with previous batches.",
		PICKUP = "After all entity actions and turf digging are completed, automatically pick up drops within a certain range.",
		LINKED = "Currently includes auto-equipping a shovel and digging the corresponding stump after chopping; auto-tracking dirt piles/bubbles works without enabling this.",
		FORCE = "Pushed actions ignore the player's current state. Actions can interrupt the after-cast of previous actions (faster execution) and break frozen/stuck states (crowd-control removal). However, it will also interrupt Woodie's transformation when chopping, so disable it in that case.",
		REMOTE = "Perform actions remotely without approaching the entity or location, executing all actions in place.",
	}
}