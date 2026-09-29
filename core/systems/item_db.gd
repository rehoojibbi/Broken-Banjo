class_name ItemDB
extends RefCounted
## Every inventory item lives here: its name, placeholder colour and look text.
## To add an item: add an entry to ITEMS, then give it to the player with
## GameState.add_item("my_item") (or a pickup Hotspot).

const ITEMS: Dictionary = {
	"postcard": {
		"name": "Postcard",
		"color": Color(0.85, 0.72, 0.42),
		"look": "'Greetings from Reykjavik!' Viktor's handwriting. Viktor has never been to Reykjavik. Viktor hates the cold.",
	},
	"uv_torch": {
		"name": "UV torch",
		"color": Color(0.55, 0.35, 0.85),
		"look": "My old ultraviolet torch. Standard issue, 1987. Still finds invisible ink and hotel-room crimes.",
	},
	"decoded_postcard": {
		"name": "Decoded postcard",
		"color": Color(0.95, 0.55, 0.3),
		"look": "Under UV: 'HAVANA. EL MALECON. SATURDAY 06:00. COME ALONE.' The front still says Reykjavik. A perfect decoy.",
	},
	"passport": {
		"name": "Passport",
		"color": Color(0.2, 0.35, 0.65),
		"look": "My real passport. The photo is from when I still had opinions about hair.",
	},
	"boarding_pass": {
		"name": "Dropped boarding pass",
		"color": Color(0.35, 0.7, 0.75),
		"look": "Aurora Air STANDBY pass: today, any destination. Passenger: H. GRAU. Someone plans to follow somebody, wherever they go.",
	},
	"ticket": {
		"name": "Plane ticket",
		"color": Color(0.9, 0.9, 0.9),
		"look": "One seat to Havana. 14C: aisle, near the exit, back to the wall. Old habits.",
	},
}

## Item + item = new item (order doesn't matter).
## "remove" lists items that get used up, "flags" are set when it works.
const COMBINATIONS: Array[Dictionary] = [
	{
		"items": ["uv_torch", "postcard"],
		"result": "decoded_postcard",
		"remove": ["postcard"],
		"flags": ["postcard_decoded"],
		"text": "Invisible ink! 'HAVANA. EL MALECON. SATURDAY 06:00. COME ALONE.' Oh, Viktor. You old show-off.",
	},
]

const FAIL_LINES: Array[String] = [
	"That doesn't work.",
	"I don't think so.",
	"Creative. Useless, but creative.",
	"Even in 1987 that wouldn't have worked.",
]


static func has(item_id: String) -> bool:
	return ITEMS.has(item_id)


static func get_item_name(item_id: String) -> String:
	return ITEMS.get(item_id, {}).get("name", item_id)


static func get_color(item_id: String) -> Color:
	return ITEMS.get(item_id, {}).get("color", Color.GRAY)


static func get_look_text(item_id: String) -> String:
	return ITEMS.get(item_id, {}).get("look", "It's a thing.")


## Returns the matching combination entry, or {} if these two don't combine.
static func find_combination(item_a: String, item_b: String) -> Dictionary:
	for combo: Dictionary in COMBINATIONS:
		var pair: Array = combo["items"]
		if (pair[0] == item_a and pair[1] == item_b) or (pair[0] == item_b and pair[1] == item_a):
			return combo
	return {}


static func random_fail_line() -> String:
	return FAIL_LINES.pick_random()
