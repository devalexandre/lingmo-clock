cmake_minimum_required(VERSION 3.16)
project(lingmo-clock LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Sql DBus)

set(PROJECT_SOURCES
    src/main.cpp
    src/alarmmanager.cpp
    src/alarmmanager.h
    src/clockservice.cpp
    src/clockservice.h
    qml.qrc
)

add_executable(lingmo-clock ${PROJECT_SOURCES})

target_link_libraries(lingmo-clock
  PRIVATE
  Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::QuickControls2 Qt6::Sql Qt6::DBus
)

install(TARGETS lingmo-clock RUNTIME DESTINATION bin)
install(FILES lingmo-clock.desktop DESTINATION share/applications)
# com.lingmo.Clock: started on demand (lingmo-clock --background) by D-Bus activation
install(FILES data/com.lingmo.Clock.service DESTINATION share/dbus-1/services)
# alarms ring after login even if the clock was never opened
install(FILES data/lingmo-clock-background.desktop DESTINATION /etc/xdg/autostart)
