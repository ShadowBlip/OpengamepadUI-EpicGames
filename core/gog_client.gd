extends NodeThread

## Godot interface for wyvern
##
## Provides a Godot interface to the wyvern command. This class relies on 
## [InteractiveProcess] to spawn wyvern in a psuedo terminal to read and write 
## to its stdout/stdin.

const wyvern_url := "https://git.sr.ht/%7Enicohman/wyvern/archive/1.4.1.tar.gz"
const wyvern_dir := "user://plugins/gog-library/assets"
const CACHE_DIR := "gog"

enum STATE {
	BOOT,
	PROMPT,
	EXECUTING,
}

enum LOGIN_STATUS {
	OK,
	FAILED,
	INVALID_PASSWORD,
	TFA_REQUIRED,
}

# gog thread signals
signal command_finished(cmd: String, output: Array[String])
signal command_progressed(cmd: String, output: Array[String], finished: bool)
signal prompt_available

# Main thread signals
signal bootstrap_finished
signal client_ready
signal logged_in(status: LOGIN_STATUS)
signal app_installed(app_id: String, success: bool)
signal app_updated(app_id: String, success: bool)
signal app_uninstalled(app_id: String, success: bool)
signal install_progressed(app_id: String, current: int, total: int)

var proc: InteractiveProcess
var state: STATE = STATE.BOOT
var is_logged_in := false
var client_started := false 

var logger := Log.get_logger("GOGClient", Log.LEVEL.INFO)


func _ready() -> void:
	add_to_group("gog_client")
	thread_group = SharedThread.new()
	thread_group.name = "gogClient"


## Download wyvern to the user directory
func install_wyvern() -> bool:
	# Build the request
	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)
	if http.request(wyvern_url) != OK:
		logger.error("Error downloading wyvern: " + wyvern_url)
		remove_child(http)
		http.queue_free()
		return false
		
	# Wait for the request signal to complete
	# result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray
	var args: Array = await http.request_completed
	var result: int = args[0]
	var response_code: int = args[1]
	var body: PackedByteArray = args[3]
	remove_child(http)
	http.queue_free()
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		logger.error("wyvern couldn't be downloaded: " + wyvern_url)
		return false
	
	# Save the archive
	var file := FileAccess.open("/tmp/wyvern_linux.tar.gz", FileAccess.WRITE_READ)
	file.store_buffer(body)

	# Extract the archive
	DirAccess.make_dir_recursive_absolute(wyvern_dir)
	var out := []
	OS.execute("tar", ["xvfz", "/tmp/wyvern_linux.tar.gz", "-C", wyvern_dir], out)

	return true


## Log in to gog. This method will fire the 'logged_in' signal with the login 
## status. This should be called again if TFA is required.
func login(user: String, password := "", tfa := "") -> void:
	await thread_group.exec(_login.bind(user, password, tfa))


func _login(user: String, password := "", tfa := "") -> void:
	pass


## Log the user out of gog
func logout() -> void:
	await thread_group.exec(_logout)


func _logout() -> void:
	is_logged_in = false


## Returns an array of installed apps
## E.g. [{"id": "1779200", "name": "Thrive", "path": "~/.local/share/gog/gogapps/common/Thrive"}]
#wyvern +login <user> +apps_installed +quit
func get_installed_apps() -> Array[Dictionary]:
	return await thread_group.exec(_get_installed_apps)


func _get_installed_apps() -> Array[Dictionary]:
	var apps: Array[Dictionary] = []
	return apps


## Returns an array of app ids available to the user
func get_available_apps() -> Array:
	return await thread_group.exec(_get_available_apps)


func _get_available_apps() -> Array:
	var app_ids := []
	return app_ids


## Returns the app info for the given app
func get_app_info(app_id: String, cache_flags: int = Cache.FLAGS.LOAD | Cache.FLAGS.SAVE) -> Dictionary:
	return await thread_group.exec(_get_app_info.bind(app_id, cache_flags))


func _get_app_info(app_id: String, cache_flags: int = Cache.FLAGS.LOAD | Cache.FLAGS.SAVE) -> Dictionary:
	return {}


## Install the given app. This will emit the 'install_progressed' signal to 
## show install progress and emit the 'app_installed' signal with the status 
## of the installation.
func install(app_id: String) -> void:
	await thread_group.exec(_install.bind(app_id))


func _install(app_id: String) -> void:
	var success := await _install_update(app_id)
	#app_installed.emit(app_id, success)
	emit_signal.call_deferred("app_installed", app_id, success)


## Install the given app. This will emit the 'install_progressed' signal to 
## show install progress and emit the 'app_updated' signal with the status 
## of the installation.
func update(app_id: String) -> void:
	await thread_group.exec(_update.bind(app_id))


func _update(app_id: String) -> void:
	var success := await _install_update(app_id)
	#app_updated.emit(app_id, success)
	emit_signal.call_deferred("app_updated", app_id, success)


# Shared functionality between app install and app update
func _install_update(app_id: String) -> bool:
	return false


## Uninstalls the given app. Will emit the 'app_uninstalled' signal when 
## completed.
func uninstall(app_id: String) -> void:
	await thread_group.exec(_uninstall.bind(app_id))


func _uninstall(app_id: String) -> void:
	pass
