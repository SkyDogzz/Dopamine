cmake_minimum_required(VERSION 3.21)
project(dopamine_survivor LANGUAGES CXX)

include(CTest)

include(FetchContent)

set(GODOTCPP_API_VERSION "4.7" CACHE STRING "Godot API version" FORCE)
set(GODOTCPP_TARGET "template_debug" CACHE STRING "godot-cpp target")

FetchContent_Declare(
    godot-cpp
    GIT_REPOSITORY https://github.com/godotengine/godot-cpp.git
    # CMake only supports GIT_SHALLOW with branch and tag names, not commit hashes.
    GIT_TAG b8530af7546a3fcae80cef2477526569fd42ffc2
)
FetchContent_MakeAvailable(godot-cpp)

add_library(dopamine_simulation STATIC
    native/src/simulation_core.cpp
    native/src/simulation_worker.cpp
)
target_include_directories(dopamine_simulation PUBLIC native/include)
target_compile_features(dopamine_simulation PUBLIC cxx_std_23)
set_target_properties(dopamine_simulation PROPERTIES POSITION_INDEPENDENT_CODE ON)

if(BUILD_TESTING)
    find_package(Python3 COMPONENTS Interpreter QUIET)
    if(Python3_Interpreter_FOUND)
        add_test(NAME asset_integration_scope_smoke
            COMMAND "${Python3_EXECUTABLE}" "${PROJECT_SOURCE_DIR}/game/tools/asset_integration_scope_smoke.py")
        set_tests_properties(asset_integration_scope_smoke PROPERTIES TIMEOUT 10)
    endif()
    set(DOPAMINE_GAME_PROJECT_DIR "${PROJECT_SOURCE_DIR}/game" CACHE PATH "Godot project directory used by automated tests")
    add_executable(simulation_core_tests native/tests/simulation_core_test.cpp)
    target_link_libraries(simulation_core_tests PRIVATE dopamine_simulation)
    add_test(NAME simulation_core COMMAND simulation_core_tests)
    set_tests_properties(simulation_core PROPERTIES TIMEOUT 15)

    add_executable(simulation_worker_tests native/tests/simulation_worker_test.cpp)
    target_link_libraries(simulation_worker_tests PRIVATE dopamine_simulation)
    add_test(NAME simulation_worker COMMAND simulation_worker_tests)
    set_tests_properties(simulation_worker PROPERTIES TIMEOUT 10)

    add_executable(simulation_benchmark native/benchmarks/simulation_benchmark.cpp)
    target_link_libraries(simulation_benchmark PRIVATE dopamine_simulation)

    find_program(DOPAMINE_GODOT_EXECUTABLE NAMES godot godot4 Godot)
    if(DOPAMINE_GODOT_EXECUTABLE)
        function(dopamine_isolate_windows_test_data test_name)
            if(WIN32)
                file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/test_appdata/${test_name}")
                set_tests_properties(${test_name} PROPERTIES
                    ENVIRONMENT "APPDATA=${CMAKE_CURRENT_BINARY_DIR}/test_appdata/${test_name}")
            endif()
        endfunction()

        if(UNIX AND NOT APPLE)
            find_program(DOPAMINE_XVFB_RUN_EXECUTABLE NAMES xvfb-run)
            if(DOPAMINE_XVFB_RUN_EXECUTABLE)
                add_test(NAME render_visual_smoke
                    COMMAND "${DOPAMINE_XVFB_RUN_EXECUTABLE}" -a -s "-screen 0 1280x800x24"
                        "${CMAKE_COMMAND}" -E env LIBGL_ALWAYS_SOFTWARE=1
                        "${DOPAMINE_GODOT_EXECUTABLE}" --path "${DOPAMINE_GAME_PROJECT_DIR}"
                        --audio-driver Dummy --script res://tests/render_visual_smoke.gd)
                set_tests_properties(render_visual_smoke PROPERTIES FIXTURES_REQUIRED godot_project_ready TIMEOUT 45)
                add_test(NAME survival_combat_visual_smoke
                    COMMAND "${DOPAMINE_XVFB_RUN_EXECUTABLE}" -a -s "-screen 0 1280x800x24"
                        "${CMAKE_COMMAND}" -E env LIBGL_ALWAYS_SOFTWARE=1
                        "${DOPAMINE_GODOT_EXECUTABLE}" --path "${DOPAMINE_GAME_PROJECT_DIR}"
                        --audio-driver Dummy --script res://tests/survival_combat_visual_smoke.gd)
                set_tests_properties(survival_combat_visual_smoke PROPERTIES FIXTURES_REQUIRED godot_project_ready TIMEOUT 45)
                add_test(NAME pilot_scene_visual_smoke
                    COMMAND "${DOPAMINE_XVFB_RUN_EXECUTABLE}" -a -s "-screen 0 1280x800x24"
                        "${CMAKE_COMMAND}" -E env LIBGL_ALWAYS_SOFTWARE=1
                        "${DOPAMINE_GODOT_EXECUTABLE}" --path "${DOPAMINE_GAME_PROJECT_DIR}"
                        --audio-driver Dummy --script res://tests/pilot_scene_visual_smoke.gd)
                set_tests_properties(pilot_scene_visual_smoke PROPERTIES FIXTURES_REQUIRED godot_project_ready TIMEOUT 45)
                add_test(NAME survival_impact_status_visual_smoke
                    COMMAND "${DOPAMINE_XVFB_RUN_EXECUTABLE}" -a -s "-screen 0 1280x800x24"
                        "${CMAKE_COMMAND}" -E env LIBGL_ALWAYS_SOFTWARE=1
                        "${DOPAMINE_GODOT_EXECUTABLE}" --path "${DOPAMINE_GAME_PROJECT_DIR}"
                        --audio-driver Dummy --script res://tests/survival_visual_effects_smoke.gd -- --capture)
                set_tests_properties(survival_impact_status_visual_smoke PROPERTIES FIXTURES_REQUIRED godot_project_ready TIMEOUT 45)
            endif()
        endif()
        add_test(NAME godot_project_import
            COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --editor --path "${DOPAMINE_GAME_PROJECT_DIR}" --quit)
        set_tests_properties(godot_project_import PROPERTIES FIXTURES_SETUP godot_project_ready TIMEOUT 60)

        foreach(script_name IN ITEMS sandbox_smoke sandbox_ui_smoke sandbox_combat_smoke sandbox_preset_smoke sandbox_lab_smoke sandbox_lab_layout_smoke sandbox_snapshot_smoke sandbox_profile_build_smoke scenario_runner_validation_smoke sandbox_weapon_scenario_validation_smoke render_batching_smoke catalog_icon_assets_smoke art_bible_asset_audit original_roster_assets_smoke player_animation_assets_smoke signal_prism_asset_smoke pause_panel_visual_smoke survival_abandon_smoke survival_chest_choice_smoke survival_chest_layout_smoke survival_run_meta_access_smoke survival_speed_control_smoke ui_foundation_smoke ui_viewport_layout_smoke armorless_session_cycle_smoke player_controller_smoke survival_entry_smoke survival_steering_smoke survival_weapon_smoke survival_targeting_smoke survival_weapon_catalog_smoke survival_level_feedback_smoke survival_visual_effects_smoke combat_catalog_smoke survival_starting_weapon_smoke survival_run_stat_hub_smoke survival_xp_run_bonuses_smoke survival_hud_smoke survival_run_result_smoke survival_revive_smoke survival_final_boss_loot_smoke survival_contact_damage_smoke survival_idle_combat_smoke survival_shooter_smoke survival_support_enemy_smoke survival_elite_smoke survival_unique_effects_smoke survival_exploder_smoke survival_shielder_smoke survival_summoner_smoke survival_boss_attack_smoke survival_lifesteal_smoke survival_magnet_heart_synergy_smoke survival_damage_causality_smoke survival_wave_director_smoke survival_wave_spawn_smoke survival_wave_duration_smoke survival_pause_smoke survival_pause_inventory_smoke chest_choice_smoke free_chest_reroll_smoke survival_chest_director_smoke survival_loadout_smoke survival_chest_smoke save_service_smoke progression_service_smoke survival_progression_smoke survival_difficulty_profile_smoke survival_difficulty_unlock_smoke survival_difficulty_session_smoke survival_inventory_smoke equipment_slots_smoke equipment_rarity_smoke equipment_stats_smoke equipment_enhancement_smoke enhancement_probability_smoke equipment_economy_smoke armorless_run_state_smoke armorless_equipment_generator_smoke armorless_wave_director_smoke survival_armorless_mode_smoke armorless_records_smoke endless_standard_progression_smoke endless_standard_session_smoke settings_service_smoke ui_settings_smoke launch_navigation_smoke survival_hub_smoke survival_hub_layout_smoke skill_tree_panel_visual_smoke equipment_panel_visual_smoke run_result_panel_smoke)
            add_test(NAME ${script_name}
                COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --path "${DOPAMINE_GAME_PROJECT_DIR}" --script "res://tests/${script_name}.gd")
            set_tests_properties(${script_name} PROPERTIES FIXTURES_REQUIRED godot_project_ready TIMEOUT 15)
            dopamine_isolate_windows_test_data(${script_name})
        endforeach()
        if(UNIX AND NOT APPLE)
            set_tests_properties(sandbox_ui_smoke PROPERTIES
                ENVIRONMENT "XDG_DATA_HOME=${CMAKE_CURRENT_BINARY_DIR}/test_appdata/sandbox_ui_smoke")
        endif()
        add_test(NAME sfx_service_assets_smoke
            COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --audio-driver Dummy
                --path "${DOPAMINE_GAME_PROJECT_DIR}" --script res://tests/sfx_service_assets_smoke.gd)
        set_tests_properties(sfx_service_assets_smoke PROPERTIES
            FIXTURES_REQUIRED godot_project_ready TIMEOUT 15)
        dopamine_isolate_windows_test_data(sfx_service_assets_smoke)
        add_test(NAME sfx_specific_event_smoke
            COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --audio-driver Dummy
                --path "${DOPAMINE_GAME_PROJECT_DIR}" --script res://tests/sfx_specific_event_smoke.gd)
        set_tests_properties(sfx_specific_event_smoke PROPERTIES
            FIXTURES_REQUIRED godot_project_ready TIMEOUT 15)
        dopamine_isolate_windows_test_data(sfx_specific_event_smoke)
        add_test(NAME adaptive_survival_music_smoke
            COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --audio-driver Dummy
                --path "${DOPAMINE_GAME_PROJECT_DIR}" --script res://tests/adaptive_survival_music_smoke.gd)
        set_tests_properties(adaptive_survival_music_smoke PROPERTIES
            FIXTURES_REQUIRED godot_project_ready TIMEOUT 15)
        dopamine_isolate_windows_test_data(adaptive_survival_music_smoke)
        add_test(NAME keyboard_menu_journey_smoke
            COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --path "${DOPAMINE_GAME_PROJECT_DIR}"
                --script res://tests/keyboard_menu_journey_smoke.gd)
        add_test(NAME gamepad_menu_journey_smoke
            COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --path "${DOPAMINE_GAME_PROJECT_DIR}"
                --script res://tests/keyboard_menu_journey_smoke.gd -- --gamepad)
        set_tests_properties(keyboard_menu_journey_smoke gamepad_menu_journey_smoke PROPERTIES
            FIXTURES_REQUIRED godot_project_ready TIMEOUT 15)
        dopamine_isolate_windows_test_data(keyboard_menu_journey_smoke)
        dopamine_isolate_windows_test_data(gamepad_menu_journey_smoke)
        if(UNIX AND NOT APPLE)
            set_tests_properties(sandbox_lab_smoke PROPERTIES
                ENVIRONMENT "XDG_DATA_HOME=${CMAKE_CURRENT_BINARY_DIR}/sandbox_lab_test_data")
            set_tests_properties(sandbox_lab_layout_smoke PROPERTIES
                ENVIRONMENT "XDG_DATA_HOME=${CMAKE_CURRENT_BINARY_DIR}/sandbox_lab_layout_test_data")
            set_tests_properties(sandbox_snapshot_smoke PROPERTIES
                ENVIRONMENT "XDG_DATA_HOME=${CMAKE_CURRENT_BINARY_DIR}/sandbox_snapshot_test_data")
            set_tests_properties(sandbox_ui_smoke PROPERTIES
                ENVIRONMENT "XDG_DATA_HOME=${CMAKE_CURRENT_BINARY_DIR}/sandbox_ui_test_data")
            set_tests_properties(settings_service_smoke PROPERTIES
                ENVIRONMENT "XDG_DATA_HOME=${CMAKE_CURRENT_BINARY_DIR}/ui_settings_service_test_data")
            set_tests_properties(survival_hud_smoke PROPERTIES
                ENVIRONMENT "XDG_DATA_HOME=${CMAKE_CURRENT_BINARY_DIR}/survival_hud_test_data")
            set_tests_properties(survival_abandon_smoke PROPERTIES
                ENVIRONMENT "XDG_DATA_HOME=${CMAKE_CURRENT_BINARY_DIR}/survival_abandon_test_data")
            set_tests_properties(survival_speed_control_smoke PROPERTIES
                ENVIRONMENT "XDG_DATA_HOME=${CMAKE_CURRENT_BINARY_DIR}/survival_speed_test_data")
            set_tests_properties(ui_settings_smoke PROPERTIES
                ENVIRONMENT "XDG_DATA_HOME=${CMAKE_CURRENT_BINARY_DIR}/ui_settings_panel_test_data")
            set_tests_properties(keyboard_menu_journey_smoke PROPERTIES
                ENVIRONMENT "XDG_DATA_HOME=${CMAKE_CURRENT_BINARY_DIR}/keyboard_menu_journey_keyboard_test_data")
            set_tests_properties(gamepad_menu_journey_smoke PROPERTIES
                ENVIRONMENT "XDG_DATA_HOME=${CMAKE_CURRENT_BINARY_DIR}/keyboard_menu_journey_gamepad_test_data")
        endif()

        add_test(NAME sandbox_scenario
            COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --path "${DOPAMINE_GAME_PROJECT_DIR}"
                --script res://scripts/scenario_runner.gd --
                --scenario=res://scenarios/dev_sandbox.json
                "--output=${CMAKE_CURRENT_BINARY_DIR}/sandbox_scenario_result.json")
        set_tests_properties(sandbox_scenario PROPERTIES FIXTURES_REQUIRED godot_project_ready TIMEOUT 120)
        dopamine_isolate_windows_test_data(sandbox_scenario)

        add_test(NAME sandbox_steering_scenario
            COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --path "${DOPAMINE_GAME_PROJECT_DIR}"
                --script res://scripts/scenario_runner.gd --
                --scenario=res://scenarios/steering_smoke.json
                "--output=${CMAKE_CURRENT_BINARY_DIR}/sandbox_steering_result.json")
        set_tests_properties(sandbox_steering_scenario PROPERTIES FIXTURES_REQUIRED godot_project_ready TIMEOUT 120)
        dopamine_isolate_windows_test_data(sandbox_steering_scenario)

        add_test(NAME sandbox_projectile_scenario
            COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --path "${DOPAMINE_GAME_PROJECT_DIR}"
                --script res://scripts/scenario_runner.gd --
                --scenario=res://scenarios/projectile_swept_smoke.json
                "--output=${CMAKE_CURRENT_BINARY_DIR}/sandbox_projectile_result.json")
        set_tests_properties(sandbox_projectile_scenario PROPERTIES FIXTURES_REQUIRED godot_project_ready TIMEOUT 120)
        dopamine_isolate_windows_test_data(sandbox_projectile_scenario)

        add_test(NAME sandbox_enemy_profiles_scenario
            COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --path "${DOPAMINE_GAME_PROJECT_DIR}"
                --script res://scripts/scenario_runner.gd --
                --scenario=res://scenarios/enemy_profiles_smoke.json
                "--output=${CMAKE_CURRENT_BINARY_DIR}/sandbox_enemy_profiles_result.json")
        set_tests_properties(sandbox_enemy_profiles_scenario PROPERTIES FIXTURES_REQUIRED godot_project_ready TIMEOUT 120)
        dopamine_isolate_windows_test_data(sandbox_enemy_profiles_scenario)

        add_test(NAME sandbox_damage_over_time_scenario
            COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --path "${DOPAMINE_GAME_PROJECT_DIR}"
                --script res://scripts/scenario_runner.gd --
                --scenario=res://scenarios/damage_over_time_smoke.json
                "--output=${CMAKE_CURRENT_BINARY_DIR}/sandbox_damage_over_time_result.json")
        set_tests_properties(sandbox_damage_over_time_scenario PROPERTIES FIXTURES_REQUIRED godot_project_ready TIMEOUT 120)
        dopamine_isolate_windows_test_data(sandbox_damage_over_time_scenario)

        foreach(weapon_id IN ITEMS lightning_conductor inferno_sprayer crimson_daggers minigun toxic_cloud sawblades meteor_staff prism_laser void_orb frost_nova)
            add_test(NAME sandbox_weapon_${weapon_id}_scenario
                COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --path "${DOPAMINE_GAME_PROJECT_DIR}"
                    --script res://scripts/sandbox_weapon_scenario_runner.gd --
                    "--scenario=res://scenarios/weapons/${weapon_id}.json"
                    "--output=${CMAKE_CURRENT_BINARY_DIR}/sandbox_weapon_${weapon_id}_result.json")
            set_tests_properties(sandbox_weapon_${weapon_id}_scenario PROPERTIES
                FIXTURES_REQUIRED godot_project_ready TIMEOUT 15)
            dopamine_isolate_windows_test_data(sandbox_weapon_${weapon_id}_scenario)
        endforeach()

        add_custom_target(stability_soak
            COMMAND "${CMAKE_COMMAND}" -E env
                "XDG_DATA_HOME=${CMAKE_CURRENT_BINARY_DIR}/stability_soak_data"
                "${DOPAMINE_GODOT_EXECUTABLE}" --headless --audio-driver Dummy
                    --path "${DOPAMINE_GAME_PROJECT_DIR}"
                    --script res://tests/stability_soak_smoke.gd
            COMMENT "Running the opt-in multi-mode stability soak"
            USES_TERMINAL
            VERBATIM
        )
    endif()
endif()

add_library(dopamine SHARED
    native/src/register_types.cpp
    native/src/combat_simulation.cpp
)
target_compile_features(dopamine PRIVATE cxx_std_23)
target_link_libraries(dopamine PRIVATE dopamine_simulation godot-cpp)

get_target_property(GODOTCPP_SUFFIX godot::cpp GODOTCPP_SUFFIX)
get_target_property(GODOTCPP_PLATFORM godot::cpp GODOTCPP_PLATFORM)
set_target_properties(dopamine PROPERTIES
    PREFIX "lib"
    OUTPUT_NAME "dopamine${GODOTCPP_SUFFIX}"
    LIBRARY_OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/game/bin/${GODOTCPP_PLATFORM}"
    RUNTIME_OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/game/bin/${GODOTCPP_PLATFORM}"
)
foreach(configuration IN ITEMS Debug Release RelWithDebInfo MinSizeRel)
    set_target_properties(dopamine PROPERTIES
        "RUNTIME_OUTPUT_DIRECTORY_${configuration}" "${PROJECT_SOURCE_DIR}/game/bin/${GODOTCPP_PLATFORM}"
    )
endforeach()
