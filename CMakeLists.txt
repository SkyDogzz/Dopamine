cmake_minimum_required(VERSION 3.21)
project(dopamine_survivor LANGUAGES CXX)

include(CTest)

include(FetchContent)

set(GODOTCPP_API_VERSION "4.7" CACHE STRING "Godot API version" FORCE)
set(GODOTCPP_TARGET "template_debug" CACHE STRING "godot-cpp target" FORCE)

FetchContent_Declare(
    godot-cpp
    GIT_REPOSITORY https://github.com/godotengine/godot-cpp.git
    GIT_TAG b8530af7546a3fcae80cef2477526569fd42ffc2
    GIT_SHALLOW TRUE
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

    add_executable(simulation_benchmark native/benchmarks/simulation_benchmark.cpp)
    target_link_libraries(simulation_benchmark PRIVATE dopamine_simulation)

    find_program(DOPAMINE_GODOT_EXECUTABLE NAMES godot godot4 Godot)
    if(DOPAMINE_GODOT_EXECUTABLE)
        add_test(NAME godot_project_import
            COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --editor --path "${PROJECT_SOURCE_DIR}/game" --quit)
        set_tests_properties(godot_project_import PROPERTIES FIXTURES_SETUP godot_project_ready)

        foreach(script_name IN ITEMS sandbox_smoke sandbox_ui_smoke sandbox_combat_smoke render_batching_smoke player_controller_smoke survival_entry_smoke survival_steering_smoke survival_weapon_smoke survival_weapon_catalog_smoke survival_starting_weapon_smoke survival_run_result_smoke survival_final_boss_loot_smoke survival_contact_damage_smoke survival_lifesteal_smoke survival_wave_director_smoke survival_wave_duration_smoke chest_choice_smoke survival_chest_director_smoke survival_loadout_smoke survival_chest_smoke)
            add_test(NAME ${script_name}
                COMMAND "${DOPAMINE_GODOT_EXECUTABLE}" --headless --path "${PROJECT_SOURCE_DIR}/game" --script "res://tests/${script_name}.gd")
            set_tests_properties(${script_name} PROPERTIES FIXTURES_REQUIRED godot_project_ready TIMEOUT 15)
        endforeach()
        if(UNIX AND NOT APPLE)
            set_tests_properties(sandbox_ui_smoke PROPERTIES
                ENVIRONMENT "XDG_DATA_HOME=${CMAKE_CURRENT_BINARY_DIR}/sandbox_ui_test_data")
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
