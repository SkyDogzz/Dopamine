cmake_minimum_required(VERSION 3.21)
project(dopamine_survivor LANGUAGES CXX)

include(CTest)

include(FetchContent)

set(GODOTCPP_API_VERSION "4.7" CACHE STRING "Godot API version" FORCE)
set(GODOTCPP_TARGET "template_debug" CACHE STRING "godot-cpp target" FORCE)

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
    add_executable(simulation_core_tests native/tests/simulation_core_test.cpp)
    target_link_libraries(simulation_core_tests PRIVATE dopamine_simulation)
    add_test(NAME simulation_core COMMAND simulation_core_tests)

    add_executable(simulation_worker_tests native/tests/simulation_worker_test.cpp)
    target_link_libraries(simulation_worker_tests PRIVATE dopamine_simulation)
    add_test(NAME simulation_worker COMMAND simulation_worker_tests)
    set_tests_properties(simulation_worker PROPERTIES TIMEOUT 10)

    add_executable(simulation_benchmark native/benchmarks/simulation_benchmark.cpp)
    target_link_libraries(simulation_benchmark PRIVATE dopamine_simulation)

    find_program(DOPAMINE_GODOT_EXECUTABLE NAMES godot godot4 Godot)
    if(DOPAMINE_GODOT_EXECUTABLE)
        if(UNIX AND NOT APPLE)
            find_program(DOPAMINE_XVFB_RUN_EXECUTABLE NAMES xvfb-run)
            if(DOPAMINE_XVFB_RUN_EXECUTABLE)
                add_test(NAME render_visual_smoke
                    COMMAND "${DOPAMINE_XVFB_RUN_EXECUTABLE}" -a -s "-screen 0 1280x800x24"
                        "${CMAKE_COMMAND}" -E env LIBGL_ALWAYS_SOFTWARE=1
                        "${DOPAMINE_GODOT_EXECUTABLE}" --path "${PROJECT_SOURCE_DIR}/game"
                        --audio-driver Dummy --script res://tests/render_visual_smoke.gd)
                set_tests_properties(render_visual_smoke PROPERTIES FIXTURES_REQUIRED godot_project_ready TIMEOUT 45)
                add_test(NAME survival_combat_visual_smoke
                    COMMAND "${DOPAMINE_XVFB_RUN_EXECUTABLE}" -a -s "-screen 0 1280x800x24"
                        "${CMAKE_COMMAND}" -E env LIBGL_ALWAYS_SOFTWARE=1
                        "${DOPAMINE_GODOT_EXECUTABLE}" --path "${PROJECT_SOURCE_DIR}/game"
                        --audio-driver Dummy --script res://tests/survival_combat_visual_smoke.gd)
                set_tests_properties(survival_combat_visual_smoke PROPERTIES FIXTURES_REQUIRED godot_project_ready TIMEOUT 45)
            endif()
        endif()
        add_test(NAME godot_project_import
            COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --editor --path "${PROJECT_SOURCE_DIR}/game" --quit)
        set_tests_properties(godot_project_import PROPERTIES FIXTURES_SETUP godot_project_ready)

        foreach(script_name IN ITEMS sandbox_smoke sandbox_ui_smoke sandbox_combat_smoke sandbox_preset_smoke sandbox_lab_smoke scenario_runner_validation_smoke sandbox_weapon_scenario_validation_smoke render_batching_smoke player_controller_smoke survival_entry_smoke survival_steering_smoke survival_weapon_smoke survival_targeting_smoke survival_weapon_catalog_smoke survival_level_feedback_smoke combat_catalog_smoke survival_starting_weapon_smoke survival_run_stat_hub_smoke survival_run_result_smoke survival_run_restart_smoke survival_final_boss_loot_smoke survival_contact_damage_smoke survival_idle_combat_smoke survival_shooter_smoke survival_support_enemy_smoke survival_elite_smoke survival_unique_effects_smoke survival_exploder_smoke survival_shielder_smoke survival_summoner_smoke survival_boss_attack_smoke survival_lifesteal_smoke survival_damage_causality_smoke survival_wave_director_smoke survival_wave_spawn_smoke survival_wave_duration_smoke survival_pause_smoke chest_choice_smoke free_chest_reroll_smoke survival_chest_director_smoke survival_loadout_smoke survival_chest_smoke save_service_smoke progression_service_smoke survival_progression_smoke survival_difficulty_profile_smoke survival_difficulty_unlock_smoke survival_difficulty_session_smoke survival_inventory_smoke equipment_slots_smoke equipment_rarity_smoke equipment_stats_smoke equipment_enhancement_smoke equipment_economy_smoke armorless_run_state_smoke armorless_equipment_generator_smoke armorless_wave_director_smoke survival_armorless_mode_smoke settings_service_smoke ui_settings_smoke launch_navigation_smoke)
            add_test(NAME ${script_name}
                COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --path "${PROJECT_SOURCE_DIR}/game" --script "res://tests/${script_name}.gd")
            set_tests_properties(${script_name} PROPERTIES FIXTURES_REQUIRED godot_project_ready TIMEOUT 15)
        endforeach()
        if(UNIX AND NOT APPLE)
            set_tests_properties(sandbox_lab_smoke PROPERTIES
                ENVIRONMENT "XDG_DATA_HOME=${CMAKE_CURRENT_BINARY_DIR}/sandbox_lab_test_data")
            set_tests_properties(sandbox_ui_smoke PROPERTIES
                ENVIRONMENT "XDG_DATA_HOME=${CMAKE_CURRENT_BINARY_DIR}/sandbox_ui_test_data")
            set_tests_properties(settings_service_smoke PROPERTIES
                ENVIRONMENT "XDG_DATA_HOME=${CMAKE_CURRENT_BINARY_DIR}/ui_settings_service_test_data")
            set_tests_properties(ui_settings_smoke PROPERTIES
                ENVIRONMENT "XDG_DATA_HOME=${CMAKE_CURRENT_BINARY_DIR}/ui_settings_panel_test_data")
        endif()

        add_test(NAME sandbox_scenario
            COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --path "${PROJECT_SOURCE_DIR}/game"
                --script res://scripts/scenario_runner.gd --
                --scenario=res://scenarios/dev_sandbox.json
                "--output=${CMAKE_CURRENT_BINARY_DIR}/sandbox_scenario_result.json")
        set_tests_properties(sandbox_scenario PROPERTIES FIXTURES_REQUIRED godot_project_ready)

        add_test(NAME sandbox_steering_scenario
            COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --path "${PROJECT_SOURCE_DIR}/game"
                --script res://scripts/scenario_runner.gd --
                --scenario=res://scenarios/steering_smoke.json
                "--output=${CMAKE_CURRENT_BINARY_DIR}/sandbox_steering_result.json")
        set_tests_properties(sandbox_steering_scenario PROPERTIES FIXTURES_REQUIRED godot_project_ready)

        add_test(NAME sandbox_projectile_scenario
            COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --path "${PROJECT_SOURCE_DIR}/game"
                --script res://scripts/scenario_runner.gd --
                --scenario=res://scenarios/projectile_swept_smoke.json
                "--output=${CMAKE_CURRENT_BINARY_DIR}/sandbox_projectile_result.json")
        set_tests_properties(sandbox_projectile_scenario PROPERTIES FIXTURES_REQUIRED godot_project_ready)

        add_test(NAME sandbox_enemy_profiles_scenario
            COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --path "${PROJECT_SOURCE_DIR}/game"
                --script res://scripts/scenario_runner.gd --
                --scenario=res://scenarios/enemy_profiles_smoke.json
                "--output=${CMAKE_CURRENT_BINARY_DIR}/sandbox_enemy_profiles_result.json")
        set_tests_properties(sandbox_enemy_profiles_scenario PROPERTIES FIXTURES_REQUIRED godot_project_ready)

        add_test(NAME sandbox_damage_over_time_scenario
            COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --path "${PROJECT_SOURCE_DIR}/game"
                --script res://scripts/scenario_runner.gd --
                --scenario=res://scenarios/damage_over_time_smoke.json
                "--output=${CMAKE_CURRENT_BINARY_DIR}/sandbox_damage_over_time_result.json")
        set_tests_properties(sandbox_damage_over_time_scenario PROPERTIES FIXTURES_REQUIRED godot_project_ready)

        foreach(weapon_id IN ITEMS lightning_conductor inferno_sprayer crimson_daggers minigun toxic_cloud sawblades meteor_staff prism_laser void_orb frost_nova)
            add_test(NAME sandbox_weapon_${weapon_id}_scenario
                COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --path "${PROJECT_SOURCE_DIR}/game"
                    --script res://scripts/sandbox_weapon_scenario_runner.gd --
                    "--scenario=res://scenarios/weapons/${weapon_id}.json"
                    "--output=${CMAKE_CURRENT_BINARY_DIR}/sandbox_weapon_${weapon_id}_result.json")
            set_tests_properties(sandbox_weapon_${weapon_id}_scenario PROPERTIES
                FIXTURES_REQUIRED godot_project_ready TIMEOUT 15)
        endforeach()
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
)
