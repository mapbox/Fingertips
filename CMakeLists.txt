cmake_minimum_required(VERSION 3.31)

set(CMAKE_OSX_DEPLOYMENT_TARGET 11.0)
set(CMAKE_Swift_LANGUAGE_VERSION 5.9)
set(CMAKE_SYSTEM_NAME iOS)
set(BUILD_TYPE SHARED)

project(Fingertips LANGUAGES C CXX Swift)

add_library(Fingertips SHARED Sources/Fingertips/FingerTipWindow.swift)

set_target_properties(Fingertips
    PROPERTIES
        FRAMEWORK TRUE
        FRAMEWORK_VERSION A
        MACOSX_FRAMEWORK_IDENTIFIER com.example.fingertips
        MACOSX_FRAMEWORK_BUNDLE_VERSION 1.0.0
        MACOSX_FRAMEWORK_SHORT_VERSION_STRING 1.0
)

set_target_properties(Fingertips PROPERTIES
    XCODE_ATTRIBUTE_OTHER_SWIFT_FLAGS "-no-warnings-as-errors"
    XCODE_ATTRIBUTE_BUILD_LIBRARY_FOR_DISTRIBUTION YES
)

