# Fetch and build SQLite3 for rosbag2 storage support, or use a system-provided
# SQLite3 development package when USE_EXTERNAL_SQLITE3 is enabled.

set(SQLITE3_VERSION "3.49.1")
set(SQLITE3_DOWNLOAD_URL "https://sqlite.org/2025/sqlite-amalgamation-3490100.zip")

if(USE_EXTERNAL_SQLITE3)
    message(STATUS "Using external sqlite3 package")

    find_package(PkgConfig QUIET)
    if(PkgConfig_FOUND)
        pkg_check_modules(SQLITE3 QUIET IMPORTED_TARGET sqlite3)
    endif()

    if(TARGET PkgConfig::SQLITE3)
        add_library(sqlite3 INTERFACE)
        target_link_libraries(sqlite3 INTERFACE PkgConfig::SQLITE3)
    else()
        find_path(SQLITE3_INCLUDE_DIR sqlite3.h)
        find_library(SQLITE3_LIBRARY NAMES sqlite3)

        include(FindPackageHandleStandardArgs)
        find_package_handle_standard_args(SQLite3
            REQUIRED_VARS SQLITE3_INCLUDE_DIR SQLITE3_LIBRARY
        )

        add_library(sqlite3 INTERFACE)
        target_include_directories(sqlite3 INTERFACE ${SQLITE3_INCLUDE_DIR})
        target_link_libraries(sqlite3 INTERFACE ${SQLITE3_LIBRARY})
    endif()
else()
    if(POLICY CMP0135) # suppress warning for cmake 3.24+
        cmake_policy(SET CMP0135 NEW)
    endif()

    if(NOT TARGET sqlite3_external)
        include(ExternalProject)
        ExternalProject_Add(sqlite3_external
            URL ${SQLITE3_DOWNLOAD_URL}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND ""
            INSTALL_COMMAND ""
        )
    endif()

    ExternalProject_Get_Property(sqlite3_external SOURCE_DIR)
    set(sqlite3_SOURCE_DIR ${SOURCE_DIR})
    set(HEADER_DIR_SQLITE3 ${sqlite3_SOURCE_DIR})
    set(SQLITE3_SOURCES "${sqlite3_SOURCE_DIR}/sqlite3.c")

    add_library(sqlite3 STATIC ${SQLITE3_SOURCES})
    set_source_files_properties(${SQLITE3_SOURCES} PROPERTIES GENERATED TRUE)

    add_dependencies(sqlite3 sqlite3_external)

    target_include_directories(sqlite3 PUBLIC $<BUILD_INTERFACE:${sqlite3_SOURCE_DIR}>)

    if(UNIX)
        find_package(Threads REQUIRED)
        target_link_libraries(sqlite3 PRIVATE Threads::Threads ${CMAKE_DL_LIBS})
    endif()
endif()
