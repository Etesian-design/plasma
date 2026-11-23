# The Etesian widget style (a Qt style plugin over Breeze: buttons, fields, sliders, check boxes, radio buttons and progress bars
# as the Etesian Design Language draws them). Built by ./build.sh; installed by ../../install.sh into ~/.local/lib/qt6/plugins/styles.
cmake_minimum_required(VERSION 3.22)
project(etesian-style LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_AUTOMOC ON)
find_package(Qt6 6.6 REQUIRED COMPONENTS Core Gui Widgets)
add_library(etesian MODULE etesianstyle.cpp)
target_link_libraries(etesian PRIVATE Qt6::Core Qt6::Gui Qt6::Widgets)
set_target_properties(etesian PROPERTIES PREFIX "")
# test/scenarios/controls.sh: a window with every control the style draws (not installed)
add_executable(etesian-controls test/gallery.cpp)
target_link_libraries(etesian-controls PRIVATE Qt6::Widgets)
