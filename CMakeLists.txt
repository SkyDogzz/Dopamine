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
endif()

add_library(dopamine SHARED
    native/src/register_types.cpp
    native/src/simulation_probe.cpp
)
target_compile_features(dopamine PRIVATE cxx_std_23)
target_link_libraries(dopamine PRIVATE godot-cpp)

get_target_property(GODOTCPP_SUFFIX godot::cpp GODOTCPP_SUFFIX)
get_target_property(GODOTCPP_PLATFORM godot::cpp GODOTCPP_PLATFORM)
set_target_properties(dopamine PROPERTIES
    PREFIX "lib"
    OUTPUT_NAME "dopamine${GODOTCPP_SUFFIX}"
    LIBRARY_OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/game/bin/${GODOTCPP_PLATFORM}"
)
