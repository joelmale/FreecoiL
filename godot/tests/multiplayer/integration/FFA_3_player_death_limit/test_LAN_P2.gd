extends "res://addons/gut/test.gd"

var Obj
var _obj
var _map_maker
var time_started
var new_player_name = "Player 2"

onready var OvertimeTimer = Timer.new()

func _ready():
    add_child(OvertimeTimer)
    OvertimeTimer.connect("timeout", self, "overtime_exit")
    OvertimeTimer.wait_time = 60
    OvertimeTimer.start()
    
func overtime_exit():
    get_tree().quit(1)

func do_a_left_click(position:Vector2):
    var evt = InputEventMouseButton.new()
    evt.button_index = BUTTON_LEFT
    evt.position = position
    evt.pressed = true
    get_tree().input_event(evt)
    yield(yield_for(0.1), YIELD)
    evt.pressed = false
    get_tree().input_event(evt)
    yield(yield_for(0.15), YIELD)

func before_all():
    time_started = OS.get_unix_time()
    Settings.Testing.register_data("testing", true, false)
    Obj = load("res://scenes/Container/Container.tscn")
    _obj = Obj.instance()
    add_child(_obj)

func before_each():
    pass

func after_each():
    pass

func after_all():
    remove_child(_obj)
    _obj.queue_free()
    var time_now = OS.get_unix_time()
    var elapsed = time_now - time_started
    var minutes = elapsed / 60
    var seconds = elapsed % 60
    var str_elapsed = "%02d : %02d" % [minutes, seconds]
    print("Elapsed Time = ", str_elapsed)

func test_p2_loads_to_main_menu():
    while _obj.current_scene.name != "MainMenu":
        yield(get_tree(), 'idle_frame')
    assert_eq(_obj.current_scene.name, "MainMenu")
    while _obj.loading_state != "idle":
        yield(get_tree(), 'idle_frame')
        
func test_p2_can_change_player_name():
    var line_edit = _obj.get_node("Scene1/MainMenu/2,-1-Preferences/CenterContainer/VBoxContainer/HBoxContainer/PlayerName")
    line_edit.text = new_player_name
    line_edit.emit_signal("text_entered", new_player_name)
    yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Preferences.get_data("player_name"), new_player_name)
        
func test_p2_can_click_start_a_networked_game():
    var btn = _obj.get_node("Scene1/MainMenu/0,0-Game Options/CenterContainer/VBoxContainer/VBoxContainer/Button2")
    btn.emit_signal("pressed")
    yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("current_menu"), "0,1")

func test_p2_can_click_client():
    var btn = _obj.get_node("Scene1/MainMenu/0,1-Networked Game 1/CenterContainer/VBoxContainer/HBoxContainer/Button")
    btn.emit_signal("pressed")
    yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("current_menu"), "4,1")

func test_p2_can_press_ready():
    while _obj.current_scene.name != "Lobbies":
        yield(get_tree(), 'idle_frame')
    assert_eq(_obj.current_scene.name, "Lobbies")
    while _obj.loading_state != "idle":
        yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("player_team"), 0)
    var tmp = _obj.get_node("Scene0/Lobbies/0,0-Game Lobby/CenterContainer/VBoxContainer/HBoxContainer/VBoxContainer/ScrollContainer/TeamContainer")
    yield(yield_for(0.5), YIELD)
    var name = tmp.get_child(1).get_child(0)
    var btn = tmp.get_child(1).get_child(1)
    if name.text == new_player_name:
        btn.emit_signal("pressed")
    else:
        assert_eq(false, true)
    yield(get_tree(), 'idle_frame')

func test_p2_can_start_a_match():
    while Settings.Session.get_data("game_started") != 1:
        yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("game_started"), 1)
    
    
func test_p2_can_disconnect_from_game():
    get_tree().call_group("Network", "client_disconnect", true)
    yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("connection_status"), "do_not_connect")
    
func test_p2_can_log_offline_events():
    yield(get_tree().create_timer(1.0), "timeout")
    FreecoiLInterface._changed_laser_telem_triggerBtnCounter(1)
    yield(get_tree(), 'idle_frame')
    FreecoiLInterface._changed_laser_telem_shotsRemaining(0)
    yield(get_tree().create_timer(0.1), "timeout")
    FreecoiLInterface._changed_laser_telem_triggerBtnCounter(2)
    yield(get_tree().create_timer(2.0), "timeout")
    FreecoiLInterface._changed_laser_telem_reloadBtnCounter(1)
    yield(get_tree().create_timer(10.0), "timeout")
    
func test_p2_can_reconnect_to_game():
    Settings.Session.set_data("connection_status", "disconnected")
    yield(get_tree(), 'idle_frame')
    get_tree().call_group("auto_reconnect", "disconnected")
    
func test_p2_game_history_size_is_correct_after_rejoin():
    var all_players_have_rejoined = false
    while all_players_have_rejoined == false:
        var mups_status = Settings.Network.get_data("mups_status")
        var missing_a_player = false
        for mup in mups_status:
            if mups_status[mup] != "reconnected":
                if mups_status[mup] != "connected":
                    missing_a_player = true
        if missing_a_player == false:
            all_players_have_rejoined = true
        yield(get_tree(), 'idle_frame')
    # Give time to resync.
    yield(get_tree().create_timer(2.0), "timeout")
    assert_eq(_obj.current_scene.game_history.size(), 39)
    yield(get_tree(), 'idle_frame')
    
func test_p2_has_1_death_for_player_1():
    assert_eq(Settings.InGame.get_data("player_deaths_by_id")["1"], 1)
    yield(get_tree(), 'idle_frame')

func test_p2_has_2_kills_for_player_2():
    assert_eq(Settings.InGame.get_data("player_kills_by_id")["2"], 2)
    yield(get_tree(), 'idle_frame')

func test_p2_session_game_player_kills_is_2():
    assert_eq(Settings.Session.get_data("game_player_kills"), 2)
    yield(get_tree(), 'idle_frame')

func test_p2_yield_to_show_result():
    yield(get_tree(), 'idle_frame')
    print("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^")
    print("Signals Used = " + str(Settings.__signals_used))
    print("Memory Useage = " + str(OS.get_static_memory_peak_usage()))
    print("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^")
    print("Player 2 (Client) Game History:")
    print(_obj.current_scene.game_history.size())
    print(_obj.current_scene.game_history)
    print("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^")
    yield(get_tree(), 'idle_frame')
    
func test_p2_wait_for_coordinated_exit():
    while Settings.InGame.get_data("Testing_Complete") == null:
        yield(get_tree(), 'idle_frame')
    yield(get_tree(), 'idle_frame')
