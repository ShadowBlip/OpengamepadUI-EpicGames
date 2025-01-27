extends Control

const EGClient := preload("res://plugins/template/core/eg_client.gd")
const SettingsManager := preload("res://core/global/settings_manager.tres")
const NotificationManager := preload("res://core/global/notification_manager.tres")
const icon := preload("res://plugins/template/assets/epic-games.svg")

@onready var status := $%Status
@onready var connected_status := $%ConnectedStatus
@onready var logged_in_status := $%LoggedInStatus
@onready var user_box := $%UsernameTextInput as ComponentTextInput
@onready var pass_box := $%PasswordTextInput
@onready var tfa_box := $%TFATextInput
@onready var login_button := $%LoginButton

@onready var gog: EGClient = get_tree().get_first_node_in_group("eg_client")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# If we have logged in before, populate the username box
	var user := SettingsManager.get_value("plugin.eg", "user", "") as String
	user_box.text = user

	# Set the status label based on the gog client status
	status.status = status.STATUS.CANCELLED
	status.color = "red"
	var set_running := func():
		if not gog.client_started:
			return
		status.status = status.STATUS.ACTIVE
		status.color = "green"
	if gog.client_started:
		set_running.call()
	gog.bootstrap_finished.connect(set_running)
	
	# Set the connection label based on the gog client status
	connected_status.status = connected_status.STATUS.ACTIVE
	if gog.state != gog.STATE.BOOT:
		_on_client_ready()
	gog.client_ready.connect(_on_client_ready)
	
	# Set our label if we log in
	var update_login_status := func(eg_status: EGClient.LOGIN_STATUS):
		if eg_status != EGClient.LOGIN_STATUS.OK:
			logged_in_status.status = logged_in_status.STATUS.ACTIVE
			logged_in_status.color = "gray"
			return
		logged_in_status.status = logged_in_status.STATUS.CLOSED
		logged_in_status.color = "green"
	gog.logged_in.connect(update_login_status)
	gog.logged_in.connect(_on_login)

	# Connect the login button
	login_button.pressed.connect(_on_login_button)

	# Focus on the next input when username or password is submitted 
	var on_user_submitted := func():
		pass_box.grab_focus.call_deferred()
	user_box.keyboard_context.submitted.connect(on_user_submitted)
	var on_pass_submitted := func():
		if tfa_box.visible:
			tfa_box.grab_focus.call_deferred()
			return
		login_button.grab_focus.call_deferred()
	pass_box.keyboard_context.submitted.connect(on_pass_submitted)


func _on_client_ready() -> void:
	connected_status.color = "green"


func _on_login(login_status: EGClient.LOGIN_STATUS) -> void:
	# Un-hide the 2fa box if we require two-factor auth
	if login_status == EGClient.LOGIN_STATUS.TFA_REQUIRED:
		tfa_box.visible = true
		tfa_box.grab_focus.call_deferred()
		return

	# If we logged, woo!
	if login_status == EGClient.LOGIN_STATUS.OK:
		logged_in_status.status = logged_in_status.STATUS.CLOSED
		logged_in_status.color = "green"
		return


# Called when the login button is pressed
func _on_login_button() -> void:
	var username: String = user_box.text
	var password: String = pass_box.text
	var tfa_code: String = tfa_box.text
	SettingsManager.set_value("plugin.gog", "user", username)
	gog.login(username, password, tfa_code)
