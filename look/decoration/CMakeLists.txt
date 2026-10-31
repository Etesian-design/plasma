# The Etesian window decoration (KDecoration3): the 44 px N9 header bar, with a KDE app's toolbar actions moved into it.
# Built by ./build.sh (here or in a Kubuntu container); installed by ../../install.sh into ~/.local/lib/qt6/plugins.
cmake_minimum_required(VERSION 3.22)
project(etesian-decoration LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_AUTOMOC ON)
find_package(Qt6 6.6 REQUIRED COMPONENTS Core Gui DBus)
find_package(KDecoration3 REQUIRED)
find_package(KF6CoreAddons REQUIRED)
add_library(org.etesian.decoration MODULE decoration.cpp appactions.cpp)
target_link_libraries(org.etesian.decoration PRIVATE Qt6::Core Qt6::Gui Qt6::DBus KDecoration3::KDecoration KF6::CoreAddons)
set_target_properties(org.etesian.decoration PROPERTIES PREFIX "")
# The KDecoration version it is built against: the login script (env.sh) falls back to Aurorae when Plasma moves on.
file(WRITE "${CMAKE_BINARY_DIR}/kdecoration-version" "${KDecoration3_VERSION}\n")
