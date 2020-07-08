extends Node

# Note: bt is short for Bluetooth.
#######################################
# Group "FreecoiL" methods start with "fi_" which
# stands for FreecoiLInterface.
# Add your listening nodes to group "FreecoiL"
# Then implement the methods below for them to be called.
# To call FreecoiL methods you will use the Singleton name
# of "FreecoiLInterface", ie: FreecoiLInterface.connect_to_laser_gun()
# fi_bt_connection_timed_out
# fi_bt_connect_timeout
# fi_gun_connected
# fi_trigger_btn_pushed
# fi_reload_btn_pushed
# fi_thumb_btn_pushed
# fi_power_btn_pushed
# fi_got_shot(shooter_id)

# The FreecoiL Singleton
var FreecoiL = null

# State vars below.
var auto_reconnect_laser
var laser_gun_id
var shot_mode
# Permission related vars below.
var bt_on
var bt_scanning
var fine_access_location
# Various timer vars below.
var bt_connect_timeout = Timer.new()
var bt_connection_timed_out = Timer.new()

# Various counters below.
var reload_btn_counter = 0
var thumb_btn_counter = 0
var power_btn_counter = 0

var battery_lvl_avg = null
var prev_battery_lvl_avg = null
var battery_lvl_array = []

var command_id
var recoil_enabled

# Shot Details:
var shot_by_id_1 = null
var shot_by_id_2 = null
var shot_counter_1 = null
var shot_counter_2 = null

#####################
# Public Godot API
#####################

func connect_to_laser_gun():
    Settings.Session.set_data("fi_laser_is_connected", 1)
    start_bt_scan()
    bt_connect_timeout.start()
    prev_battery_lvl_avg = null
    battery_lvl_array = []
    battery_lvl_avg = null
  
func start_bt_scan():
    if FreecoiL != null:
        FreecoiL.startBluetoothScan()

func stop_bt_scan():
    if FreecoiL != null:
        FreecoiL.stopBluetoothScan()

func vibrate(duration_millis):
    Input.vibrate_handheld(duration_millis)

func set_laser_id(new_id):
    if FreecoiL != null:
        if Settings.Session.get_data("fi_laser_is_connected") == 2:
            FreecoiL.setLaserId(new_id)

func reload_start():
    if FreecoiL != null:
        if Settings.Session.get_data("fi_laser_is_connected") == 2:
            FreecoiL.startReload()

func reload_finish(new_rounds):
    if FreecoiL != null:
        if Settings.Session.get_data("fi_laser_is_connected") == 2:
            FreecoiL.finishReload(new_rounds)

func set_shot_mode(shot_mode, indoor_outdoor_mode):
    # SHOT_MODE_FULL_AUTO = 1
    # SHOT_MODE_SINGLE = 2
    # SHOT_MODE_BURST = 4
    # FIRING_MODE_OUTDOOR_NO_CONE = 0;
    # FIRING_MODE_OUTDOOR_WITH_CONE = 1;
    # FIRING_MODE_INDOOR_NO_CONE = 2;
    if shot_mode == "single":
        shot_mode = 2
    elif shot_mode == "burst":
        shot_mode = 4
    else:  # shot_mode == "auto"
        shot_mode = 1
    if indoor_outdoor_mode == "outdoor_no_cone":
        indoor_outdoor_mode = 0
    elif indoor_outdoor_mode == "outdoor_with_cone":
        indoor_outdoor_mode = 1
    else:  # "indoor_no_cone"
        indoor_outdoor_mode = 2
    if FreecoiL != null:
        if Settings.Session.get_data("fi_laser_is_connected") == 2:
            FreecoiL.setShotMode(shot_mode, indoor_outdoor_mode)

func enable_recoil(enabled):
    if FreecoiL != null:
        recoil_enabled = enabled
        if Settings.Session.get_data("fi_laser_is_connected") == 2:
            FreecoiL.enableRecoil(recoil_enabled)   
            if recoil_enabled:
                Settings.Session.set_data("fi_laser_recoil", 1)
            else:
                Settings.Session.set_data("fi_laser_recoil", 2)  
        get_tree().call_group("FreecoiL", "fi_recoil_enabled_changed")
        
func toggle_recoil():
    var fi_laser_recoil = Settings.Session.get_data("fi_laser_recoil")
    if fi_laser_recoil != 0:
        if fi_laser_recoil == 1:
            FreecoiL.enableRecoil(false)
        else:
            FreecoiL.enableRecoil(true)
        

#####################
# Private Godot API
#####################
func _ready():
    bt_connect_timeout.one_shot = true
    bt_connection_timed_out.one_shot = true
    bt_connect_timeout.wait_time = 10
    bt_connection_timed_out.wait_time = 2  # Bumped this up because some phones are slower to load resources.
    bt_connect_timeout.connect("timeout", self, "_on_bt_connect_timeout")
    bt_connection_timed_out.connect("timeout", self, "_on_bt_connection_timed_out")
    add_child(bt_connect_timeout)
    add_child(bt_connection_timed_out)
    init_vars()
    # Delay the loading of FreecoiL, so as to not delay the UI.
    call_deferred('_on_delay_loading')
   
func _on_delay_loading():
    if Engine.has_singleton("FreecoiL"):
        FreecoiL = Engine.get_singleton("FreecoiL")
        print(" ************* " + str(FreecoiL.hello()))
        FreecoiL.init(get_instance_id())
    
func init_vars():
    # We initialize the vars here to allow loading from saved defaults but also to 
    # improve Godot error checking by removing the warnings about unused vars.
    # fi_laser_is_connected:
    # Pent state: 0=never connected, 1=trying, 2=connected, 3=disconnected, 4=retrying.
    Settings.Session.set_data("fi_laser_is_connected", 0)
    #fi_laser_recoil:
    # Tri state: 0=disconnected, 1=enabled, 2=disabled.
    Settings.Session.set_data("fi_laser_recoil", 0)
    auto_reconnect_laser = false
    laser_gun_id = 0
    shot_mode = 2
    recoil_enabled = true
    bt_on = null
    bt_scanning = false
    fine_access_location = null
    command_id = 0
        
func _bt_status():
    if FreecoiL != null:
        bt_on = FreecoiL.bluetoothStatus()
    
func _bt_on():
    if bt_on == 1:
        print('Bluetooth is on.')
        _fine_access_location_status()
        call_deferred('_fine_access_location_enabled')
    elif bt_on == 0:
        print('Bluetooth is off.')
        if FreecoiL != null:
            FreecoiL.enableBluetooth()
    else:  # = 2
        print('Bluetooth is NOT supported on this device.')
    
func _fine_access_location_status():
    print("Granted Permissions: " + str(OS.get_granted_permissions()))
    #fine_access_location = FreecoiL.fineAccessPermissionStatus()
        
func _fine_access_location_enabled():
    if fine_access_location == 1:
        print('Fine Access Enabled!')
    else:
        if FreecoiL != null:
            # TODO: detect if permissions were granted, should be in the returned bool below.
            var __ = OS.request_permissions()
            #FreecoiL.enableFineAccess()
        
func _on_bt_connect_timeout():
    if FreecoiL != null:
        FreecoiL.stopBluetoothScan()
    if Settings.Session.get_data("fi_laser_is_connected") == 1:
        Settings.Session.set_data("fi_laser_is_connected", 0)
    elif Settings.Session.get_data("fi_laser_is_connected") == 4:
        Settings.Session.set_data("fi_laser_is_connected", 3)
    get_tree().call_group("FreecoiL", "fi_bt_connect_timeout")
    
func _on_bt_connection_timed_out():
    bt_connection_timed_out.stop()
    get_tree().call_group("FreecoiL", "fi_bt_connection_timed_out")
    if Settings.Session.get_data("fi_laser_is_connected") == 2:
        _on_laser_gun_disconnected()
    if auto_reconnect_laser:
      pass  # TODO: generic connect to device, and delete from _on_laser_gun_disconnected()

func _on_laser_gun_connected():
    Settings.Session.set_data("fi_laser_is_connected", 2)
    Settings.Session.set_data("fi_laser_recoil", 1)
    bt_connect_timeout.stop()
    bt_connection_timed_out.start()

func _on_laser_gun_disconnected():
    Settings.Session.set_data("fi_laser_is_connected", 3)
    #get_tree().call_group("FreecoiL", "fi_laser_gun_disconnected")
    Settings.Session.set_data("fi_laser_battery_lvl", 0)
    Settings.Session.set_data("fi_laser_recoil", 0)
    bt_connection_timed_out.stop()
    if auto_reconnect_laser:
        connect_to_laser_gun()
# FreecoiL Callbacks
func _on_mod_init():
    _on_activity_result_bt_enable()
    
func _on_activity_result_bt_enable():
    _bt_status()
    call_deferred('_bt_on')

func _on_activity_result_fine_access():
    _fine_access_location_status()
    call_deferred('_fine_access_location_enabled')
    
func _on_laser_gun_still_connected():
    bt_connection_timed_out.start()  # resets the timer.

# NEW CHANGE ONLY Oriented Callbacks From Java.
func _changed_laser_telem_commandId(commandId):
    command_id = commandId
    get_tree().call_group("FreecoiL", "fi_command_accepted")

# warning-ignore:unused_argument
func _changed_laser_telem_playerId(playerId):
    get_tree().call_group("FreecoiL", "fi_player_id_changed")
    # TODO: Set or update player id.
    laser_gun_id = playerId

func _changed_laser_telem_shotsRemaining(shotsRemaining):
    if Settings.Session.get_data("game_player_alive"):
        Settings.Session.set_data("game_weapon_magazine_ammo", shotsRemaining)
    else:
        reload_start()

func _changed_laser_telem_triggerBtnCounter(triggerBtnCounter):
    Settings.Session.set_data("fi_trigger_btn_pushed", triggerBtnCounter)

func _changed_laser_telem_reloadBtnCounter(reloadBtnCounter):
    reload_btn_counter = reloadBtnCounter
    get_tree().call_group("FreecoiL", "fi_reload_btn_pushed")

func _changed_laser_telem_thumbBtnCounter(thumbBtnCounter):
    thumb_btn_counter = thumbBtnCounter
    get_tree().call_group("FreecoiL", "fi_thumb_btn_pushed")

func _changed_laser_telem_powerBtnCounter(powerBtnCounter):
    power_btn_counter = powerBtnCounter
    get_tree().call_group("FreecoiL", "fi_power_btn_pushed")

func _laser_telem_batteryLvl(batteryLvl):
    # 0x10 = 00010000 = 16 = Brand New Alkalines
    # 0x0E = 00001110 = 14
    # 0x0D = 00001101 = 13
    # High order byte for battery level - RK-45, 10 is brand new 
    # alkalines, 0E for fully charged rechargables with 0D showing 
    # up pretty quick. The SR-12 uses 6 AA instead of 4 and the 
    # battery level value will be 50% higher than the RK-45 
    battery_lvl_array.append(batteryLvl)
    if battery_lvl_array.size() > 60:  # is 6 seconds of battery level.
        battery_lvl_array.pop_front()
    var battery_sum = 0
    for i in range(0, battery_lvl_array.size() - 1):
         battery_sum += battery_lvl_array[i]
    battery_lvl_avg = battery_sum / battery_lvl_array.size()
    if battery_lvl_avg != prev_battery_lvl_avg:
        var physical_laser_type = Settings.Session.get_data("physical_laser_type")
        if physical_laser_type == null:
            physical_laser_type = "RK-45"
        if physical_laser_type == "SR-12":
            Settings.Session.set_data("fi_laser_battery_lvl", battery_lvl_avg * 6.25 / 1.5)
            prev_battery_lvl_avg = battery_lvl_avg
        else:
            # If full batteries for a pistol are a charge of 16 then 100 / 16 == 6.25
            Settings.Session.set_data("fi_laser_battery_lvl", battery_lvl_avg * 6.25)
            prev_battery_lvl_avg = battery_lvl_avg
    
func _changed_laser_telem_shot_data(shotById1, shotCounter1, shotById2, shotCounter2, sensorsHit, sensorsHit2):
    if shotCounter1 != shot_counter_1:
        shot_counter_1 = shotCounter1
        shot_by_id_1 = shotById1
        get_tree().call_group("FreecoiL", "fi_got_shot", shotById1)
        print("sensorsHit = " + str(sensorsHit))
    if shotCounter2 != shot_counter_2:
        shot_counter_2 = shotCounter2
        shot_by_id_2 = shotById2
        get_tree().call_group("FreecoiL", "fi_got_shot", shotById2)
        print("sensorsHit2 = " + str(sensorsHit2))

# warning-ignore:unused_argument
func _changed_telem_button_pressed(powerBtnPressed, triggerBtnPressed, thumbBtnPressed, reloadBtnPressed):
    # buttonsPressed Values:
    #default = 0
    #trigger = 1
    #reload = 2
    #trigger + reload = 3
    #back = 4
    #trigger + back = 5
    #reload + back = 6
    #triger + reload + back = 7
    #power = 16
    #trigger + power = 17
    #reload + power = 18
    #trigger + reload + power = 19
    #back + power = 20
    #trigger + power + back = 21
    #reload + back + power = 22
    #triger + reload + back + power = 23
    get_tree().call_group("FreecoiL", "fi_buttons_pressed", powerBtnPressed, triggerBtnPressed, thumbBtnPressed, reloadBtnPressed)

func _processed_laser_telemetry2(array_of_args):
    print("Telemetry:  " + str(array_of_args))
    print("commandId = " + str(array_of_args[0]) + " | playerId = " + str(array_of_args[1]) + 
        " | buttonsPressed = " + str(array_of_args[2]) + " | triggerBtnCounter = " + str(array_of_args[3]) + 
        " | reloadBtnCounter = " + str(array_of_args[4]) + " | thumbBtnCounter = " + str(array_of_args[5]) + 
        " | powerBtnCounter = " + str(array_of_args[6]) + " | batteryLvlHigh = " + str(array_of_args[7]) + 
        " | batteryLvlLow = " + str(array_of_args[8]) + " | powerBtnPressed = " + str(array_of_args[9]) + 
        " | triggerBtnPressed = " + str(array_of_args[10]) + " | reloadBtnPressed = " + str(array_of_args[11]) + 
        " | thumbBtnPressed = " + str(array_of_args[12]) + " | shotsRemaining = " + str(array_of_args[13]) + 
        " | shooter1LaserId = " + str(array_of_args[14]) + 
        " | shooter2LaserId = " + str(array_of_args[15]) + " | shooter1WpnProfile = " + str(array_of_args[16]) + 
        " | shooter2WpnProfile = " + str(array_of_args[17]) + " | shooter1charge = " + str(array_of_args[18]) + 
        " | shooter1check = " + str(array_of_args[19]) + " | shooter2charge = " + str(array_of_args[20]) + 
        " | shooter2check = " + str(array_of_args[21]) + " | shotCounter1 = " + str(array_of_args[22]) + 
        " | shotCounter2 = " + str(array_of_args[23]) + " | sensorsHit1 = " + str(array_of_args[24]) + 
        " | sensorsHit2 = " + str(array_of_args[25]) + " | clipSensor1 = " + str(array_of_args[26]) + 
        " | frontSensor1 = " + str(array_of_args[27]) + " | leftSensor1 = " + str(array_of_args[28]) + 
        " | rightSensor1 = " + str(array_of_args[29]) + " | clipSensor2 = " + str(array_of_args[30]) + 
        " | frontSensor2 = " + str(array_of_args[31]) + " | leftSensor2 = " + str(array_of_args[32]) + 
        " | rightSensor2 = " + str(array_of_args[33]) + 
        " | status = " + str(array_of_args[34]) + 
        " | PlayerIdAccepted = " + str(array_of_args[35]) + " | wpnProfileAgain = " + str(array_of_args[36]))
    _on_laser_gun_still_connected()

#func _processed_laser_telemetry(commandId, playerId, buttonsPressed, triggerBtnCounter, reloadBtnCounter,
#                thumbBtnCounter, powerBtnCounter, batteryLvlHigh, batteryLvlLow, powerBtnPressed,
#                triggerBtnPressed, reloadBtnPressed, thumbBtnPressed, shotsRemaining, shooter1LaserId,
#                shooter2LaserId, shooter1WpnProfile, shooter2WpnProfile, shooter1charge, shooter1check,
#                shooter2charge, shooter2check, shotCounter1, shotCounter2, sensorsHit1, sensorsHit2,
#                clipSensor1, frontSensor1, leftSensor1, rightSensor1, clipSensor2, frontSensor2, leftSensor2,
#                rightSensor2, status, playerIdAccepted, wpnProfileAgain):
#    print("Telemetry: " + str(commandId) + " | " + str(playerId) + " | " + str(triggerBtnCounter) 
#        + " | " + str(reloadBtnCounter) + " | " + str(thumbBtnCounter) + " | " + str(powerBtnCounter) + " | " + str(batteryLvlHigh) + " | " + 
#        str(batteryLvlLow) + " | " + str(powerBtnPressed) + " | " + str(triggerBtnPressed) + " | " + str(reloadBtnPressed) + " | " + 
#        str(thumbBtnPressed) + " | " + str(shooter1LaserId) + " | " + str(shooter2LaserId) + " | " + str(shooter1WpnProfile) + " | " + 
#        str(shooter2WpnProfile) + " | " + str(shooter1charge) + " | " + str(shooter2charge) + " | " + 
#        str(shotCounter1) + " | " + str(shotCounter2) + " | " + str(sensorsHit1) + " | " + str(sensorsHit2))
#    _laser_telem_batteryLvl(batteryLvlHigh)
#    _changed_telem_button_pressed(powerBtnPressed, triggerBtnPressed, reloadBtnPressed, thumbBtnPressed)
#    _on_laser_gun_still_connected()

func _new_status(status, level):
    # Debug Levels:
    #     0 = debug
    #     1 = info
    #     2 = warning
    #     3 = error
    #     4 = critical
    #     5 = exception
    Settings.Log('FreecoiL Java: DEBUG: ' + status) # debug level always print
    if "Pistol detected." in status:
        Settings.Session.set_data("physical_laser_type", "RK-45")
    elif "Riffle detected." in status:
        Settings.Session.set_data("physical_laser_type", "SR-12")
    
