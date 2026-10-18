# A minimal QML runner for checking the patched files on a device or the
# emulator, which ship no qmlscene. Development only, not packaged.
TEMPLATE = app
TARGET = qmlrun
QT += quick qml
CONFIG += c++11
SOURCES += main.cpp
