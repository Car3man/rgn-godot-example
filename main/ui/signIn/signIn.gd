extends Control

onready var idTokenLabel: Label = get_node("VBoxContainer/IdTokenLabel") as Label
onready var currenciesLabel: Label = get_node("VBoxContainer/CurrenciesLabel") as Label

var godotIAC;
var idToken: String = ""

func _ready():
	connectToDeepLinks()
	
func _process(delta):
	if (OS.get_name() == "iOS"):
		while godotIAC.get_pending_event_count() > 0:
			var event = godotIAC.pop_pending_event()
			_on_deeplink_received(event.payload, "")
	pass
	
func _on_Button_pressed():
	OS.shell_open("https://development-oauth.ready.gg/?url_redirect=rgngodot://%2F&returnSecureToken=true&appId=io.getready.rgngodot&lang=ru")

# --- DeepLink Begin ---

func connectToDeepLinks():
	if (Engine.has_singleton("GodotIAC")):
		godotIAC = Engine.get_singleton("GodotIAC")
		if (OS.get_name() == "Android"):
			godotIAC.connect("deeplink_received", self, "_on_deeplink_received")

func _on_deeplink_received(payload, origin):
	idToken = parseIdToken(payload)
	idTokenLabel.text = idToken
	make_get_user_currencies_request()
	
# --- DeepLink End ---

# --- Http Begin ---

var getUserCurrenciesRequest: HTTPRequest = null

func make_get_user_currencies_request():
	getUserCurrenciesRequest = HTTPRequest.new()
	add_child(getUserCurrenciesRequest)
	getUserCurrenciesRequest.connect(
		"request_completed",
		self,
		"_on_get_user_currencies_request_completed"
	)
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + idToken
	]
	var data = JSON.print({
		"appPackageName": "io.getready.rgntest"
	})
	getUserCurrenciesRequest.request(
		"https://us-central1-readymaster-development.cloudfunctions.net/user-getUserCurrenciesV2",
		headers,
		true,
		HTTPClient.METHOD_POST,
		data
	)
	pass

func _on_get_user_currencies_request_completed(result, response_code, headers, body):
	if (result == HTTPRequest.RESULT_SUCCESS):
		currenciesLabel.text = body.get_string_from_utf8()
	getUserCurrenciesRequest.queue_free()
	
# --- Http End ---
	
# --- Parsing Begin ---
	
func parseIdToken(deepLinkUrl):
	var parsed = parseUrl(deepLinkUrl)
	return parsed.token
		
func parseUrl(url):
	var regex = RegEx.new()
	regex.compile("(\\?|\\&)(?<parameter>[^=]+)\\=(?<value>[^&]+)")
	var results = {}
	for result in regex.search_all(url):
		var parameter = result.strings[result.names["parameter"]]
		var value = result.strings[result.names["value"]]
		results[parameter] = value
	return results

# --- Parsing End ---
