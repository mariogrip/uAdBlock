include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
)

set(
    UAdBlockbackend_SRCS
    modules/UAdBlock/backend.cpp
    modules/UAdBlock/cmd.cpp
)

# Make the unit test files visible on qtcreator
add_custom_target(UAdBlockbackend_UNITTEST_QML_FILES ALL SOURCES "tests/unit/tst_mytype.qml")

add_library(UAdBlockbackend MODULE
    ${UAdBlockbackend_SRCS}
)

set_target_properties(UAdBlockbackend PROPERTIES
         LIBRARY_OUTPUT_DIRECTORY UAdBlock)

qt5_use_modules(UAdBlockbackend Gui Qml Quick)

# Copy qmldir file to build dir for running in QtCreator
add_custom_target(UAdBlockbackend-qmldir ALL
    COMMAND cp ${CMAKE_CURRENT_SOURCE_DIR}/modules/UAdBlock/qmldir ${CMAKE_CURRENT_BINARY_DIR}/UAdBlock
    DEPENDS ${QMLFILES}
)

# Install plugin file
install(TARGETS UAdBlockbackend DESTINATION ${QT_IMPORTS_DIR}/UAdBlock/)
install(FILES   modules/UAdBlock/qmldir DESTINATION ${QT_IMPORTS_DIR}/UAdBlock/)
