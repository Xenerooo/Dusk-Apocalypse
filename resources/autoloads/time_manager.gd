extends Node
class_name TimeManager

# ==============================
# Signals
# ==============================
signal second_changed
signal minute_changed
signal hour_changed
signal day_changed
signal month_changed
signal year_changed
signal cycle_changed(new_cycle)
signal time_synced


# ==============================
# Enums
# ==============================
enum CycleState { NIGHT, DAWN, DAY, DUSK }


# ==============================
# Constants
# ==============================
const SECONDS_IN_A_MINUTE: int = 60
const MINUTES_IN_AN_HOUR: int = 60
const HOURS_IN_A_DAY: int = 24
const DAYS_IN_A_MONTH: int = 30
const MONTHS_IN_A_YEAR: int = 12

const SECONDS_IN_AN_HOUR: int = SECONDS_IN_A_MINUTE * MINUTES_IN_AN_HOUR
const SECONDS_IN_A_DAY: int = SECONDS_IN_AN_HOUR * HOURS_IN_A_DAY


# ==============================
# Settings
# ==============================
## In-game speed (1 real second = 60 in-game seconds)
var IN_GAME_SECONDS_PER_REAL_SECOND: int = 60

## Starting time
var current_seconds: int = 0
var current_minutes: int = 0
var current_hours: int = 12
var current_day: int = 1
var current_month: int = 1
var current_year: int = 2021

## Cycle start hours
var state_dawn_start_hour: int = 5
var state_day_start_hour: int = 8
var state_dusk_start_hour: int = 16
var state_night_start_hour: int = 19

## Current cycle
var current_cycle: int = CycleState.NIGHT


# ==============================
# Internal State
# ==============================
var elapsed_seconds: float = 0.0
var freeze_time: bool = true


# ==============================
# Multiplayer
# ==============================
## Sync interval (in in-game minutes)
var sync_interval: int = 1
var last_synced_minute: int = -1


# ==============================
# Process
# ==============================
func _physics_process(delta: float) -> void:
	if freeze_time:
		return

	# Simulate locally for smoothness
	elapsed_seconds += delta * IN_GAME_SECONDS_PER_REAL_SECOND
	var seconds_to_add: int = int(elapsed_seconds)

	if seconds_to_add >= 1:
		elapsed_seconds -= seconds_to_add
		advance_time(seconds_to_add)

	# Server: send sync periodically
	if multiplayer.is_server():
		if current_minutes != last_synced_minute and current_seconds == 0:
			last_synced_minute = current_minutes
			rpc("sync_time", current_seconds, current_minutes, current_hours,
				current_day, current_month, current_year, current_cycle)


# ==============================
# Time Advancement
# ==============================
func advance_time(seconds: int) -> void:
	current_seconds += seconds

	# Seconds → Minutes
	while current_seconds >= SECONDS_IN_A_MINUTE:
		current_seconds -= SECONDS_IN_A_MINUTE
		current_minutes += 1
		emit_signal("minute_changed", current_minutes)

	# Minutes → Hours
	while current_minutes >= MINUTES_IN_AN_HOUR:
		current_minutes -= MINUTES_IN_AN_HOUR
		current_hours += 1
		emit_signal("hour_changed", current_hours)
		update_cycle()

	# Hours → Days
	while current_hours >= HOURS_IN_A_DAY:
		current_hours -= HOURS_IN_A_DAY
		current_day += 1
		emit_signal("day_changed", current_day)

		# Days → Months
		if current_day > DAYS_IN_A_MONTH:
			current_day = 1
			current_month += 1
			emit_signal("month_changed", current_month)

			# Months → Years
			if current_month > MONTHS_IN_A_YEAR:
				current_month = 1
				current_year += 1
				emit_signal("year_changed", current_year)


# ==============================
# Cycle Updates
# ==============================
func update_cycle() -> void:
	var new_cycle: int

	if current_hours >= state_night_start_hour or current_hours < state_dawn_start_hour:
		new_cycle = CycleState.NIGHT
	elif current_hours >= state_dawn_start_hour and current_hours < state_day_start_hour:
		new_cycle = CycleState.DAWN
	elif current_hours >= state_day_start_hour and current_hours < state_dusk_start_hour:
		new_cycle = CycleState.DAY
	elif current_hours >= state_dusk_start_hour and current_hours < state_night_start_hour:
		new_cycle = CycleState.DUSK
	else:
		new_cycle = CycleState.NIGHT  # Fallback

	if new_cycle != current_cycle:
		current_cycle = new_cycle
		emit_signal("cycle_changed", current_cycle_to_string())


func current_cycle_to_string() -> String:
	return CycleState.keys()[current_cycle]


# ==============================
# Multiplayer Sync
# ==============================
@rpc("any_peer", "call_local")
func sync_time(seconds:int, minutes:int, hours:int, day:int, month:int, year:int, cycle:int) -> void:
	current_seconds = seconds
	current_minutes = minutes
	current_hours = hours
	current_day = day
	current_month = month
	current_year = year
	current_cycle = cycle
	emit_signal("time_synced")


# ==============================
# Utilities
# ==============================
func get_current_time_string() -> String:
	return "%02d:%02d" % [current_hours, current_minutes]

func get_current_date_string() -> String:
	return "%02d/%02d/%04d" % [current_day, current_month, current_year]

func get_current_date_time_string() -> String:
	return get_current_date_string() + " " + get_current_time_string()

## Total seconds in the current day
func get_total_seconds_in_day() -> int:
	return (current_hours * SECONDS_IN_AN_HOUR) \
		+ (current_minutes * SECONDS_IN_A_MINUTE) \
		+ current_seconds

## Normalized progress of the day (0.0 → 1.0)
func get_day_progress() -> float:
	return float(get_total_seconds_in_day()) / float(SECONDS_IN_A_DAY)


# ==============================
# Save & Load
# ==============================
func get_default_data() -> Dictionary:
	return {
		"current_seconds": 0,
		"current_minutes": 30,
		"current_hours": 4,
		"current_day": 28,
		"current_month": 3,
		"current_year": 2025,
		"freeze_time": freeze_time,
		"current_cycle": current_cycle
	}

func reset_manager() -> void:
	freeze_time = true

func load_time(time_data: Dictionary) -> void:
	current_seconds = int(time_data.get("current_seconds", 0))
	current_minutes = int(time_data.get("current_minutes", 0))
	current_hours = int(time_data.get("current_hours", 12))
	current_day = int(time_data.get("current_day", 1))
	current_month = int(time_data.get("current_month", 1))
	current_year = int(time_data.get("current_year", 2021))
	current_cycle = int(time_data.get("current_cycle", CycleState.DAWN))
	freeze_time = false

func get_time_dict() -> Dictionary:
	return {
		"current_seconds": current_seconds,
		"current_minutes": current_minutes,
		"current_hours": current_hours,
		"current_day": current_day,
		"current_month": current_month,
		"current_year": current_year,
		"freeze_time": freeze_time,
		"current_cycle": current_cycle
	}
