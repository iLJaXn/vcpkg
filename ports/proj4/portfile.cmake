vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO OSGeo/PROJ
    REF 8.1.1
    SHA512 1f18ad83bae40c6c910900a062bd41c331838add6eebb7e83b4784e4e06fbf48706cee24aadbefe0f138f081ecc02e93a2b6fd45a84806e1372bf2997dafa852
    HEAD_REF master
    PATCHES
        fix-filemanager-uwp.patch
        fix-win-output-name.patch
        fix-proj4-targets-cmake.patch
        tools-cmake.patch
        pkgconfig.patch
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        net   ENABLE_CURL
        tiff  ENABLE_TIFF
        tools BUILD_CCT
        tools BUILD_CS2CS
        tools BUILD_GEOD
        tools BUILD_GIE
        tools BUILD_PROJ
        tools BUILD_PROJINFO
        # BUILD_PROJSYNC handled below
)

vcpkg_list(SET TOOL_NAMES cct cs2cs geod gie proj projinfo)
if("net" IN_LIST FEATURES AND "tools" IN_LIST FEATURES)
    set(BUILD_PROJSYNC TRUE)
    vcpkg_list(APPEND TOOL_NAMES projsync)
else()
    set(BUILD_PROJSYNC FALSE)
endif()
vcpkg_list(APPEND FEATURE_OPTIONS -DBUILD_PROJSYNC=${BUILD_PROJSYNC})

find_program(EXE_SQLITE3 NAMES "sqlite3" PATHS "${CURRENT_HOST_INSTALLED_DIR}/tools" NO_DEFAULT_PATH REQUIRED)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS ${FEATURE_OPTIONS}
    -DPROJ_LIB_SUBDIR=lib
    -DPROJ_INCLUDE_SUBDIR=include
    -DPROJ_DATA_SUBDIR=share/${PORT}
    -DBUILD_TESTING=OFF
    "-DEXE_SQLITE3=${EXE_SQLITE3}"
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(PACKAGE_NAME PROJ CONFIG_PATH lib/cmake/proj DO_NOT_DELETE_PARENT_CONFIG_PATH)
vcpkg_cmake_config_fixup(PACKAGE_NAME PROJ4 CONFIG_PATH lib/cmake/proj4)

if ("tools" IN_LIST FEATURES)
    vcpkg_copy_tools(TOOL_NAMES ${TOOL_NAMES} AUTO_CLEAN)
endif ()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

vcpkg_copy_pdbs()

vcpkg_fixup_pkgconfig()
if(NOT DEFINED VCPKG_BUILD_TYPE AND VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_MINGW)
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/proj.pc" " -lproj" " -lproj_d")
endif()

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(INSTALL "${SOURCE_PATH}/COPYING" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
