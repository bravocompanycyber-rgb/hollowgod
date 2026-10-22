extends Node
# The Pantheon Ledger: remembers your choices between runs (saved on your PC).
# Save file lives in Godot's user folder (user://ledger.json).

const PATH = "user://ledger.json"

var data = {"runs": 0, "deaths": 0, "wins": 0, "warden": ""}

func _ready():
    var f = File.new()
    if f.file_exists(PATH):
        if f.open(PATH, File.READ) == OK:
            var r = JSON.parse(f.get_as_text())
            f.close()
            if r.error == OK and typeof(r.result) == TYPE_DICTIONARY:
                for k in r.result.keys():
                    data[k] = r.result[k]

func save():
    var f = File.new()
    if f.open(PATH, File.WRITE) == OK:
        f.store_string(JSON.print(data))
        f.close()
