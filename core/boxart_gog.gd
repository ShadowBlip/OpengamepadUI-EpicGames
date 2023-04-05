extends BoxArtProvider

const _boxart_dir = "user://boxart/gog"
const _supported_ext = [".jpg", ".png", ".jpeg"]

@export var use_caching: bool = true

# Maps the layout to a file suffix for caching
var layout_map: Dictionary = {
	LAYOUT.GRID_PORTRAIT: "-portrait",
	LAYOUT.GRID_LANDSCAPE: "-landscape",
	LAYOUT.BANNER: "-banner",
	LAYOUT.LOGO: "-logo",
}

# Maps the layout to the Steam CDN url
var layout_url_map: Dictionary = {
	LAYOUT.GRID_PORTRAIT: "",
	LAYOUT.GRID_LANDSCAPE: "",
	LAYOUT.BANNER: "",
	LAYOUT.LOGO: "",
}


func _init() -> void:
	super()
	# Create the data directory if it doesn't exist
	DirAccess.make_dir_recursive_absolute(_boxart_dir)
	provider_id = "gog"
	logger_name = "BoxArtGOG"


func _ready() -> void:
	super()
	logger.info("GOG BoxArt provider loaded")
	logger._level = Log.LEVEL.INFO


# Looks for boxart in the local user directory based on the app name
func get_boxart(item: LibraryItem, kind: LAYOUT) -> Texture2D:
	var texture: Texture2D 
	return texture
