extends Label

var player : Player

func _ready():
	player = owner

func _physics_process(_delta):
	text = str(floor(player.vel.length()))
