extends Control

@onready var _primary_button: Button = %PrimaryButton
@onready var _secondary_button: Button = $Content/PreviewCenter/SamplePanel/SampleContent/Actions/SecondaryButton
@onready var _status: Label = $Content/PreviewCenter/SamplePanel/SampleContent/Status
@onready var _sample_option: OptionButton = $Content/PreviewCenter/SamplePanel/SampleContent/Fields/SampleOptionButton
@onready var _sample_spin: SpinBox = $Content/PreviewCenter/SamplePanel/SampleContent/Fields/SampleSpinBox

func _ready() -> void:
	_sample_option.add_item("CYAN / DEFAULT")
	_sample_option.add_item("AMBER / ALERT")
	_sample_spin.min_value = 1
	_sample_spin.max_value = 5
	_sample_spin.value = 3
	_primary_button.pressed.connect(_on_primary_pressed)
	_secondary_button.pressed.connect(_on_secondary_pressed)
	_primary_button.grab_focus()

func _on_primary_pressed() -> void:
	_status.text = "PRIMARY ACTION ACTIVATED  •  LEVEL %d" % int(_sample_spin.value)

func _on_secondary_pressed() -> void:
	_status.text = "LOADOUT ACTION ACTIVATED"
