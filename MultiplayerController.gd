extends Control

@export var Address = "127.0.0.1"
@export var port = 8910
var peer

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	
	if "--server" in OS.get_cmdline_args():
		HostGame()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func peer_connected(id):
	print("Player connected: " + str(id))
	
func peer_disconnected(id):
	print("Player disconnected: " + str(id))
	GameManager.Players.erase(id)
	var players = get_tree().get_nodes_in_group("Player")
	for i in players:
		if i.name == str(id):
			i.queue_free()
	
func connected_to_server():
	print("Connected to server")
	SendPlayerInformation.rpc_id(1, $LineEdit.text, multiplayer.get_unique_id())
	
func connection_failed():
	print("Couldn't connect")
	
@rpc("any_peer")
func SendPlayerInformation(name, id):
	if !GameManager.Players.has(id):
		GameManager.Players[id] = {
			"name": name,
			"id": id,
			"score": 0
		}
	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInformation.rpc(GameManager.Players[i].name, i)
	
@rpc("any_peer", "call_local")
func StartGame():
	var scene = load("res://testScene.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()
	
func HostGame():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 2)
	if error != OK:
		print("cannot host: " + error)
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)

	multiplayer.set_multiplayer_peer(peer)
	print("Waiting For Players")

func _on_host_button_down():
	HostGame()
	SendPlayerInformation($LineEdit.text, multiplayer.get_unique_id())

func _on_join_button_down():
	peer = ENetMultiplayerPeer.new()
	peer.create_client(Address, port)
	
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)


func _on_start_game_button_down():
	StartGame.rpc()
