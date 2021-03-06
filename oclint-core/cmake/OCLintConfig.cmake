SET(CMAKE_DISABLE_SOURCE_CHANGES ON)
SET(CMAKE_DISABLE_IN_SOURCE_BUILD ON)
SET(CMAKE_BUILD_TYPE None)
SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_LINKER_FLAGS} -O0 -g -fno-rtti -fcolor-diagnostics -Wno-c++11-extensions -fPIC")
SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_CXX_LINKER_FLAGS} -g -fno-rtti")
SET(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)

set(OCLINT_VERSION_MAJOR 0)
set(OCLINT_VERSION_MINOR 8)

set(OCLINT_VERSION_RELEASE "${OCLINT_VERSION_MAJOR}.${OCLINT_VERSION_MINOR}")

IF( NOT EXISTS ${LLVM_ROOT}/include/llvm )
    MESSAGE(FATAL_ERROR "LLVM_ROOT (${LLVM_ROOT}) is not a valid LLVM install")
ENDIF()

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${LLVM_ROOT}/share/llvm/cmake")
INCLUDE(LLVMConfig)

INCLUDE_DIRECTORIES( ${LLVM_INCLUDE_DIRS} )
LINK_DIRECTORIES( ${LLVM_LIBRARY_DIRS} )
ADD_DEFINITIONS( ${LLVM_DEFINITIONS} )

LLVM_MAP_COMPONENTS_TO_LIBRARIES(REQ_LLVM_LIBRARIES arminfo cppbackendinfo debuginfo hexagoninfo mblazeinfo mipsinfo msp430info nvptxinfo powerpcinfo sparcinfo x86info xcoreinfo armdesc hexagondesc mblazedesc mipsdesc msp430desc nvptxdesc powerpcdesc sparcdesc x86desc xcoredesc armasmparser asmparser bitreader mblazeasmparser mcparser mipsasmparser x86asmparser)

SET(CLANG_LIBRARIES
    clangTooling
    clangFrontend
    clangDriver
    clangSerialization
    clangParse
    clangSema
    clangAnalysis
    clangEdit
    clangASTMatchers
    clangAST
    clangLex
    clangBasic)

IF(TEST_BUILD)
    ENABLE_TESTING()
    ADD_DEFINITIONS(
        --coverage
        )
    INCLUDE_DIRECTORIES(
        ${GOOGLETEST_SRC}/include
        ${GOOGLETEST_SRC}/gtest/include
        )
    LINK_DIRECTORIES(${GOOGLETEST_BUILD})

    # Setup the path for profile_rt library
    SET(COMPILER_RT_VERSION "${LLVM_VERSION_MAJOR}.${LLVM_VERSION_MINOR}")
    STRING(TOLOWER ${CMAKE_SYSTEM_NAME} COMPILER_RT_SYSTEM_NAME)
    LINK_DIRECTORIES(${LLVM_LIBRARY_DIRS}/clang/${COMPILER_RT_VERSION}/lib/${COMPILER_RT_SYSTEM_NAME})
    IF(APPLE)
        SET(PROFILE_RT_LIBS clang_rt.profile_osx)
    ELSE()
        IF(CMAKE_SIZEOF_VOID_P EQUAL 8)
            SET(PROFILE_RT_LIBS clang_rt.profile-x86_64)
        ELSE()
            SET(PROFILE_RT_LIBS clang_rt.profile-i386)
        ENDIF()
    ENDIF()
ENDIF()
