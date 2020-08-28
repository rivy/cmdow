# Makefile (C/C++; OOS-build support; gmake-form/style)
# Cross-platform (bash/sh + CMD/PowerShell)
# `bcc32`, `cl`, `clang`, `embcc32`, and `gcc` (defaults to `CC=gcc`)
# GNU make (gmake) compatible; ref: <https://www.gnu.org/software/make/manual>
# Copyright (C) 2020 ~ Roy Ivy III <rivy.dev@gmail.com>; MIT+Apache-2.0 license

# NOTE: * requires `make` version 4.0+ (minimum needed for correct path functions)
# NOTE: `make` doesn't handle spaces within file names without gyrations (see <https://stackoverflow.com/questions/9838384/can-gnu-make-handle-filenames-with-spaces>@@<https://archive.is/PYKKq>)

# `make`

NAME := cmdow ## empty/null => autoset to name of containing folder

####

# spell-checker:ignore () brac cmdbuf forwback funcs ifile lessecho lesskey linenum lsystem optfunc opttbl scrsize ttyin

# spell-checker:ignore (targets) realclean vclean veryclean
# spell-checker:ignore (make) CURDIR MAKEFLAGS SHELLSTATUS TERMERR TERMOUT abspath addprefix addsuffix endef eval findstring firstword gmake ifeq ifneq lastword notdir patsubst prepend undefine wordlist
#
# spell-checker:ignore (CC) DDEBUG DNDEBUG NDEBUG Ofast Werror Wextra Xclang Xlinker bcc dumpmachine embcc flto flto-visibility-public-std fpie nodefaultlib nologo nothrow psdk
# spell-checker:ignore (abbrev/acronyms) LLVM MSVC MinGW POSIX VCvars
# spell-checker:ignore (jargon) autoset deps delims executables maint multilib
# spell-checker:ignore (libraries) libcmt libgcc libstdc lmsvcrt lstdc stdext
# spell-checker:ignore (names) benhoyt rivy Borland
# spell-checker:ignore (shell/nix) mkdir printf rmdir uname
# spell-checker:ignore (shell/win) COMSPEC SystemDrive SystemRoot findstr findstring mkdir windir
# spell-checker:ignore (utils) goawk ilink
# spell-checker:ignore (vars) CFLAGS CPPFLAGS CXXFLAGS DEFINETYPE EXEEXT LDFLAGS LIBPATH LIBs MAKEDIR OBJ_deps OBJs OSID PAREN devnull falsey fileset globset globsets punct truthy

####

OSID := $(or $(and $(filter .exe,$(patsubst %.exe,.exe,$(subst $() $(),_,${SHELL}))),$(filter win,${OS:Windows_NT=win})),nix)## OSID == [nix,win]
# for Windows OS, set SHELL to `%ComSpec%` or `cmd` (note: environment/${OS}=="Windows_NT" for XP, 2000, Vista, 7, 10 ...)
# * `make` may otherwise use an incorrect shell (eg, `bash`), if found; "syntax error: unexpected end of file" error output is indicative
ifeq (${OSID},win)
# use case and location fallbacks; note: assumes *no spaces* within the path values specified by ${ComSpec}, ${SystemRoot}, or ${windir}
COMSPEC := $(or ${ComSpec},${COMSPEC},${comspec})
SystemRoot := $(or ${SystemRoot},${SYSTEMROOT},${systemroot},${windir})
SHELL := $(firstword $(wildcard ${COMSPEC} ${SystemRoot}/System32/cmd.exe) cmd)
endif

#### Start of system configuration section. ####

# * default to `clang` (fallback to `gcc`; via a portable shell test)
CC := $(and $(filter-out default,$(origin CC)),${CC})## use any non-make defined value as default ## note: used to avoid a recursive definition of ${CC} within the the shell ${CC} presence check when determining default ${CC}
# CC := $(or ${CC},$(subst -FOUND,,$(filter clang-FOUND,$(shell clang --version 2>&1 && echo clang-FOUND || echo))),gcc)
CC := $(or ${CC},gcc)

CC_ID := $(lastword $(subst -,$() $(),${CC}))

#### * Compiler configuration

ifeq (,$(filter-out clang gcc,${CC_ID}))
## `clang` or `gcc`
CXX := ${CC:gcc=g}++
LD := ${CXX}
%link = ${LD} ${LDFLAGS} ${LD_o}${1} ${2} ${3}## $(call %link,EXE,OBJs,LIBs); requires delayed expansion
STRIP_CC_clang_OSID_nix := strip
STRIP_CC_clang_OSID_win := llvm-strip
STRIP_CC_gcc := strip
## -g :: produce debugging information
## -v :: verbose output (shows command lines used during run)
## -O<n> :: <n> == [0 .. 3], increasing level of optimization (see <https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html> @@ <https://archive.vn/7YtdI>)
## -pedantic-errors :: error on use of compiler language extensions
## -Werror :: warnings treated as errors
## -Wall :: enable all (usual) warnings
## -Wextra :: enable extra warnings
## -Wno-comment :: suppress warnings about trailing comments on directive lines
## -Wno-deprecated-declarations :: suppress deprecation warnings
## -Wno-int-to-void-pointer-cast :: suppress cast to void from int warnings; ref: <https://stackoverflow.com/questions/22751762/how-to-make-compiler-not-show-int-to-void-pointer-cast-warnings>
## -D_CRT_SECURE_NO_WARNINGS :: compiler directive == suppress "unsafe function" compiler warning
## note: CFLAGS == C flags; CPPFLAGS == C PreProcessor flags; CXXFLAGS := C++ flags; ref: <https://stackoverflow.com/questions/495598/difference-between-cppflags-and-cxxflags-in-gnu-make>
CFLAGS := -I. -pedantic-errors -Werror -Wall -Wno-comment -Wno-deprecated-declarations -D_CRT_SECURE_NO_WARNINGS
CFLAGS_COMPILE_ONLY := -c
CFLAGS_ARCH_32 := -m32
CFLAGS_ARCH_64 := -m64
CFLAGS_DEBUG_true := -DDEBUG -O0 -g
CFLAGS_DEBUG_false := -DNDEBUG -O3
# CFLAGS_STATIC_false := -shared
# CFLAGS_STATIC_true := -static
CFLAGS_VERBOSE_true := -v
CFLAGS_check := -v
CFLAGS_machine := -dumpmachine
CFLAGS_v := --version
CPPFLAGS := $()
## see <https://stackoverflow.com/questions/42545078/clang-version-5-and-lnk4217-warning/42752769#42752769>@@<https://archive.is/bK4Di>
## see <http://clang-developers.42468.n3.nabble.com/MinGW-Clang-issues-with-static-libstdc-td4056214.html>
## see <https://clang.llvm.org/docs/LTOVisibility.html>
## -Xclang <arg> :: pass <arg> to clang compiler
## -flto-visibility-public-std :: use public LTO visibility for classes in std and stdext namespaces
CXXFLAGS := $()
CXXFLAGS_clang := -Xclang -flto-visibility-public-std
## -Xlinker <arg> :: pass <arg> to linker
## --strip-all :: strip all symbols
LDFLAGS := $()
LDFLAGS_ARCH_32 := -m32
LDFLAGS_ARCH_64 := -m64
LDFLAGS_DEBUG_false := -Xlinker --strip-all
# LDFLAGS_STATIC_false := -pie
# LDFLAGS_STATIC_false := -shared
# LDFLAGS_STATIC_true := -static -static-libgcc -static-libstdc++
LDFLAGS_STATIC_true := -static
LDFLAGS_clang_nix := -lstdc++
LDFLAGS_gcc := -lstdc++

LIBS := $()

# ifeq ($(CC),clang)
# LDFLAGS_dynamic := -Wl,-nodefaultlib:libcmt -lmsvcrt # only works for MSVC targets
# endif
# ifeq ($(CC),gcc)
# # CFLAGS_dynamic := -fpie
# # LDFLAGS_dynamic := -fpie
# endif
endif ## `clang` or `gcc`

ifeq (cl,${CC_ID})
## `cl` (MSVC)
CXX := ${CC}
LD := link
%link = ${LD} ${LDFLAGS} ${LD_o}${1} ${2} ${3}## $(call %link,EXE,OBJs,LIBs); requires delayed expansion
STRIP := $()
## ref: <https://docs.microsoft.com/en-us/cpp/build/reference/compiler-options-listed-by-category> @@ <https://archive.is/PTPDN>
## /nologo :: startup without logo display
## /W3 :: set warning level to 3 [1..4, all; increasing level of warning scrutiny]
## /WX :: treat warnings as errors
## /wd4996 :: suppress POSIX function name deprecation warning (#C4996)
## /EHsc :: enable C++ EH (no SEH exceptions) + extern "C" defaults to nothrow (replaces deprecated /GX)
## /D "_CRT_SECURE_NO_WARNING" :: compiler directive == suppress "unsafe function" compiler warning
## /Od :: disable optimization
## /Ox :: maximum optimizations
## /O2 :: maximize speed
## /D "WIN32" :: old/extraneous define
## /D "_CONSOLE" :: old/extraneous define
## /D "DEBUG" :: activate DEBUG changes
## /D "NDEBUG" :: deactivate assert()
## /D "_CRT_SECURE_NO_WARNING" :: compiler directive == suppress "unsafe function" compiler warning
## /MT :: static linking
## /MTd :: static debug linking
## /Fd:... :: program database file name
## /Zi :: generate complete debug information (as a *.PDB file)
## /Z7 :: generate complete debug information within each object file (no *.PDB file)
## * `link`
## ref: <https://docs.microsoft.com/en-us/cpp/build/reference/linker-options> @@ <https://archive.is/wip/61bbL>
## /incremental:no :: disable incremental linking (avoids size increase, useless for cold builds, with minimal time cost)
## /machine:I386 :: specify the target machine platform
## /subsystem:console,4.00 :: generate "Win32 character-mode" console application; 4.00 => minimum supported system is Win9x/NT; supported only by MSVC 9 (`cl` version "15xx") or less
## /subsystem:console,5.01 :: generate "Win32 character-mode" console application; 5.01 => minimum supported system is XP; supported by MSVC 10 (`cl` version "16xx") or later
CFLAGS := /nologo /W3 /WX /EHsc /I "." /D "WIN32" /D "_CONSOLE" /D "_CRT_SECURE_NO_WARNINGS"
CFLAGS_COMPILE_ONLY := -c
# CFLAGS_DEBUG_true = /D "DEBUG" /D "_DEBUG" /Od /Zi /Fd"${OUT_DIR_obj}/"
CFLAGS_DEBUG_true := /D "DEBUG" /D "_DEBUG" /Od /Z7
CFLAGS_DEBUG_false := /D "NDEBUG" /Ox /O2
CFLAGS_DEBUG_true_STATIC_false := /MDd ## debug + dynamic
CFLAGS_DEBUG_false_STATIC_false := /MD ## release + dynamic
CFLAGS_DEBUG_true_STATIC_true := /MTd ## debug + static
CFLAGS_DEBUG_false_STATIC_true := /MT ## release + static
CFLAGS_VERBOSE_true := $()
CPPFLAGS := $()
CXXFLAGS := $()
LDFLAGS := /nologo /incremental:no
LDFLAGS_ARCH_32 := /machine:I386
# CL version specific flags
LDFLAGS_CL1600+_false := /subsystem:console,4.00
LDFLAGS_CL1600+_true := /subsystem:console,5.01
# VC6-specific flags
## /ignore:4254 :: suppress "merging sections with different attributes" warning (LNK4254)
LDFLAGS_VC6_true := /ignore:4254

CC_${CC_ID}_e := /Fe
CC_${CC_ID}_o := /Fo
LD_${CC_ID}_o := /out:

O_${CC_ID} := obj

LIBS := $()
endif ## `cl` (MSVC)

ifeq (bcc32,${CC_ID})
## `bcc32` (Borland C++ 5.5.1 free command line tools)
CXX := ${CC}
LD := ilink32
%link = ${LD} ${LDFLAGS} $(subst /,\,${2}), $(subst /,\,${1}),,$(subst /,\,${3})## $(call %link,EXE,OBJs,LIBs); requires delayed expansion
STRIP := $()

# * find CC base directory (for include and library directories plus initialization code, as needed); note: CMD/PowerShell is assumed as `bcc32` is DOS/Windows-only
CC_BASEDIR := $(subst /,\,$(abspath $(firstword $(shell scoop which ${CC} 2>NUL) $(shell which ${CC} 2>NUL) $(shell where ${CC} 2>NUL))\..\..))
LIB_DIRS := "${CC_BASEDIR}\lib"
LD_INIT_OBJ := "${CC_BASEDIR}\lib\c0x32.obj"

CFLAGS := -q -O2 -TWC -P-c -v- -d -f- -ff- -vi -w-pro -I. -I"${CC_BASEDIR}\include"
CFLAGS_COMPILE_ONLY := -c
CPPFLAGS := $()
CXXFLAGS := $()
LDFLAGS := -q -Tpe -v- -ap -c -x -V4.0 -GF:AGGRESSIVE -L${LIB_DIRS} ${LD_INIT_OBJ}

CC_${CC_ID}_e := -e
CC_${CC_ID}_o := -o
LD_${CC_ID}_o := $()

O_${CC_ID} := obj

LIBS := import32.lib cw32.lib
endif ## `bcc32` (Borland)

ifeq (embcc32,${CC_ID})
## `embcc32` (Embarcadero Borland C++ free command line tools)
CXX := ${CC}
LD := ilink32
%link = ${LD} ${LDFLAGS} $(subst /,\,${2}), $(subst /,\,${1}),,$(subst /,\,${3})## $(call %link,EXE,OBJs,LIBs); requires delayed expansion
STRIP := $()

# * find CC base directory (for include and library directories plus initialization code, as needed); note: CMD/PowerShell is assumed as `bcc32` is DOS/Windows-only
CC_BASEDIR := $(subst /,\,$(abspath $(firstword $(shell scoop which ${CC} 2>NUL) $(shell which ${CC} 2>NUL) $(shell where ${CC} 2>NUL))\..\..))
LIB_DIRS := "${CC_BASEDIR}\lib\win32c\release";"${CC_BASEDIR}\lib\win32c\release\psdk"
LD_INIT_OBJ := "${CC_BASEDIR}\lib\c0x32.obj"

CFLAGS := -q -O2 -TWC -P-c -v- -d -f- -vi -I.
CFLAGS_COMPILE_ONLY := -c
CFLAGS_check := --version
CFLAGS_v := --version
CPPFLAGS := $()
CXXFLAGS := $()
LDFLAGS := -q -Tpe -v- -ap -c -x -V4.0 -GF:AGGRESSIVE -L${LIB_DIRS} ${LD_INIT_OBJ}

CC_${CC_ID}_e := -e
CC_${CC_ID}_o := -o
LD_${CC_ID}_o := $()

O_${CC_ID} := obj

LIBS := import32.lib cw32.lib
endif ## `embcc32` (Borland)

# `make` command line flags/options
ARCH := 32## [$(),...]; default ARCH for compilation; $() => use CC default ARCH
CC_DEFINES := false## provide compiler info (as `CC_...` defines) to compiling targets ('truthy'-type)
COLOR := $(if $(or ${MAKE_TERMOUT},${MAKE_TERMERR}),true,false)## enable colorized output ('truthy'-type)
DEBUG := false## enable compiler debug flags/options ('truthy'-type; default == false)
STATIC := true## compile to statically linked executable ('truthy'-type; default == true)
VERBOSE := false## verbose `make` output ('truthy'-type; default == false)
MAKEFLAGS_debug := $(if $(findstring d,${MAKEFLAGS}),true,false)## Makefile debug output ('truthy'-type; default == false) ## NOTE: use `-d` or `MAKEFLAGS_debug=1`, `--debug[=FLAGS]` does not set MAKEFLAGS correctly (see <https://savannah.gnu.org/bugs/?func=detailitem&item_id=58341>)

#### End of system configuration section. ####

falsey := false 0 f n no off
false := $()
true := true
truthy := ${true}

devnull := $(if $(filter win,${OSID}),NUL,/dev/null)
int_max := 2147483647## largest signed 32-bit integer; used as arbitrary max expected list length

NULL := $()
BACKSLASH := $()\$()
COMMA := ,
DOT := .
ESC := $()$()## literal ANSI escape character (required for ANSI color display output; also used for some string matching)
HASH := \#
PAREN_OPEN := $()($()
PAREN_CLOSE := $())$()
SLASH := /
SPACE := $() $()

[lower] := a b c d e f g h i j k l m n o p q r s t u v w x y z
[upper] := A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
[alpha] := ${[lower]} ${[upper]}
[digit] := 1 2 3 4 5 6 7 8 9 0
[punct] := ~ ` ! @ ${HASH} ${DOLLAR} % ^ & * ${PAREN_OPEN} ${PAREN_CLOSE} _ - + = { } [ ] | ${BACKSLASH} : ; " ' < > ${COMMA} ? ${SLASH} ${DOT}

%not = $(if ${1},${false},$(or ${1},${true}))
%eq = $(or $(and $(findstring ${1},${2}),$(findstring ${2},${1})),$(if ${1}${2},${false},${true}))# note: `call %eq,$(),$()` => ${true}
%neq = $(if $(call %eq,${1},${2}),${false},$(or ${1},${2},${true}))# note: ${1} != ${2} => ${false}; ${1} == ${2} => first non-empty value (or ${true})

%falsey = $(firstword ${falsey})
%truthy = $(firstword ${truthy})

%as_truthy = $(if $(call %is_truthy,${1}),$(call %truthy),$(call %falsey))
%is_truthy = $(if $(filter-out ${falsey},$(call %lc,${1})),${true},${false})
%is_falsey = $(call %not,$(call %is_truthy,${1}))

%range = $(if $(word ${1},${2}),$(wordlist 1,${1},${2}),$(call %range,${1},${2} $(words _ ${2})))
%repeat = $(if $(word ${2},${1}),$(wordlist 1,${2},${1}),$(call %repeat,${1} ${1},${2}))

%head = $(firstword ${1})
%tail = $(words 2,${int_max},${1})
%chop = $(wordlist 2,$(words ${1}),_ ${1})
%append = ${2} ${1}
%prepend = ${1} ${2}
%length = $(words ${1})

%filter_map = $(strip $(foreach elem,${2},$(call ${1},${elem})))
%uniq = $(if ${1},$(firstword ${1}) $(call %uniq,$(filter-out $(firstword ${1}),${1})))

%tr = $(strip $(if ${1},$(call %tr,$(wordlist 2,$(words ${1}),${1}),$(wordlist 2,$(words ${2}),${2}),$(subst $(firstword ${1}),$(firstword ${2}),${3})),${3}))
%lc = $(call %tr,${[upper]},${[lower]},${1})
%uc = $(call %tr,${[lower]},${[upper]},${1})

ifeq (${OSID},win)
%rm_dir = $(shell if EXIST "${1}" ${RMDIR} "${1}" && ${ECHO} ${true})
%rm_file = $(shell if EXIST "${1}" ${RM} "${1}" && ${ECHO} ${true})
%rm_file_globset = $(shell for %%G in (${1}) do ${RM} "%%G" >${devnull} && ${ECHO} ${true})
else
%rm_dir = $(shell ls -d "${1}" >${devnull} 2>&1 && { ${RMDIR} "${1}" && ${ECHO} ${true}; } || true)
%rm_file = $(shell ls -d "${1}" >${devnull} 2>&1 && { ${RM} "${1}" && ${ECHO} ${true}; } || true)
%rm_file_globset = $(shell for file in ${1}; do ls -d "$${file}" >${devnull} 2>&1 && ${RM} "$${file}"; done && ${ECHO} "${true}")
endif
%rm_dirs = $(call %filter_map,%rm_dir,${1})
%rm_dirs_verbose = $(call %filter_map,$(eval %f=$$(if $$(call %rm_dir,$${1}),$$(call %info,"$${1}" removed),))%f,${1})
%rm_files = $(call %filter_map,%rm_file,${1})
%rm_files_verbose = $(call %filter_map,$(eval %f=$$(if $$(call %rm_file,$${1}),$$(call %info,"$${1}" removed),))%f,${1})
%rm_file_globsets = $(call %filter_map,%rm_file_globset,${1})
%rm_file_globsets_verbose = $(call %filter_map,$(eval %f=$$(if $$(call %rm_file_globset,$${1}),$$(call %info,"$${1}" removed),))%f,${1})

ifeq (${OSID},win)
%shell_quote = $(call %tr,^ | < > %,^^ ^| ^< ^> ^%,${1})
else
%shell_quote = '$(call %tr,','"'"',${1})'
endif

@mkdir_rule = ${1} : ${2} ; ${MKDIR} "$$@"

!shell_noop = ${ECHO} >${devnull}

####

color_black := $(if $(call %is_truthy,${COLOR}),${ESC}[0;30m,)
color_blue := $(if $(call %is_truthy,${COLOR}),${ESC}[0;34m,)
color_cyan := $(if $(call %is_truthy,${COLOR}),${ESC}[0;36m,)
color_green := $(if $(call %is_truthy,${COLOR}),${ESC}[0;32m,)
color_magenta := $(if $(call %is_truthy,${COLOR}),${ESC}[0;35m,)
color_red := $(if $(call %is_truthy,${COLOR}),${ESC}[0;31m,)
color_yellow := $(if $(call %is_truthy,${COLOR}),${ESC}[0;33m,)
color_white := $(if $(call %is_truthy,${COLOR}),${ESC}[0;37m,)
color_reset := $(if $(call %is_truthy,${COLOR}),${ESC}[0m,)
#
color_success := ${color_green}
color_debug := ${color_cyan}
color_info := ${color_blue}
color_warning := ${color_yellow}
color_error := ${color_red}

%error_text = ${color_error}ERR!:${color_reset} ${1}
%debug_text = ${color_debug}debug:${color_reset} ${1}
%info_text = ${color_info}info:${color_reset} ${1}
%success_text = ${color_success}SUCCESS:${color_reset} ${1}
%warning_text = ${color_warning}WARN:${color_reset} ${1}
%error = $(error $(call %error_text,${1}))
%debug = $(if $(call %is_truthy,${MAKEFLAGS_debug}),$(info $(call %debug_text,${1})),)
%info = $(info $(call %info_text,${1}))
%success = $(info $(call %success_text,${1}))
%warning = $(warning $(call %warning_text,${1}))

%debug_var = $(call %debug,${1}="${${1}}")

####

override COLOR := $(call %as_truthy,${COLOR})
override DEBUG := $(call %as_truthy,${DEBUG})
override STATIC := $(call %as_truthy,${STATIC})
override VERBOSE := $(call %as_truthy,${VERBOSE})

override MAKEFLAGS_debug := $(call %as_truthy,$(or $(call %is_truthy,${MAKEFLAGS_debug}),$(call %is_truthy,${MAKEFILE_debug})))

$(call %debug_var,OSID)
$(call %debug_var,SHELL)

$(call %debug_var,CC)
$(call %debug_var,CXX)
$(call %debug_var,LD)
$(call %debug_var,CFLAGS)
$(call %debug_var,CPPFLAGS)
$(call %debug_var,CXXFLAGS)
$(call %debug_var,LDFLAGS)

CC_e := $(or ${CC_${CC_ID}_e},-o${SPACE})
CC_o := $(or ${CC_${CC_ID}_o},-o${SPACE})
LD_o := $(or ${LD_${CC_ID}_o},-o${SPACE})

$(call %debug_var,CC_e)
$(call %debug_var,CC_o)
$(call %debug_var,LD_o)

O := $(or ${O_${CC_ID}},o)

$(call %debug_var,O)

$(call %debug_var,COLOR)
$(call %debug_var,DEBUG)
$(call %debug_var,STATIC)
$(call %debug_var,VERBOSE)

$(call %debug_var,MAKEFLAGS_debug)

####

# require at least `make` v4.0 (minimum needed for correct path functions)
MAKE_VERSION_major := $(word 1,$(subst ., ,${MAKE_VERSION}))
MAKE_VERSION_minor := $(word 2,$(subst ., ,${MAKE_VERSION}))
MAKE_VERSION_fail := $(filter ${MAKE_VERSION_major},3 2 1 0)
ifeq (${MAKE_VERSION_major},4)
MAKE_VERSION_fail := $(filter ${MAKE_VERSION_minor},)
endif
$(call %debug_var,MAKE_VERSION)
$(call %debug_var,MAKE_VERSION_major)
$(call %debug_var,MAKE_VERSION_minor)
$(call %debug_var,MAKE_VERSION_fail)
ifneq (${MAKE_VERSION_fail},)
$(call %error,`make` v4.0+ required (currently using v${MAKE_VERSION}))
endif

####

# NOTE: early configuration; must be done before ${CC_ID} (`clang`) is used as a linker (eg, during configuration)
ifeq (${OSID},win)
ifeq (${CC_ID},clang)
# prior LIB definition may interfere with clang builds when using MSVC
undefine LIB # no 'override' to allow definition on command line
endif
endif
$(call %debug_var,LIB)

####

# detect ${CC}
ifeq (,$(shell "${CC}" ${CFLAGS_check} >${devnull} 2>&1 && echo ${CC} present))
$(call %error,Missing required compiler (`${CC}`))
endif

ifeq (${SPACE},$(findstring ${SPACE},${makefile_abs_path}))
$(call %error,<SPACE>'s within project directory may cause issues)
endif

# Since we rely on paths relative to the makefile location, abort if make isn't being run from there.
ifneq (${makefile_dir},${current_dir})
$(call %error,Invalid current directory; this makefile must be invoked from the directory it resides in)
endif

####

OS_PREFIX=
ifeq (${OSID},win)
OSID_name  := windows
OS_PREFIX  := win.
EXEEXT     := .exe
#
AWK        := gawk ## from `scoop install gawk`; or "goawk" from `go get github.com/benhoyt/goawk`
CAT        := "${SystemRoot}\System32\findstr" /r .*
CP         := copy /y
ECHO       := echo
GREP       := grep ## from `scoop install grep`
MKDIR      := mkdir
RM         := del
RM_r       := $(RM) /s
RMDIR      := rmdir /s/q
FIND       := "${SystemRoot}\System32\find"
FINDSTR    := "${SystemRoot}\System32\findstr"
MORE       := "${SystemRoot}\System32\more"
SORT       := "${SystemRoot}\System32\sort"
WHICH      := where
#
ECHO_newline := echo.
else
OSID_name  ?= $(shell uname | tr '[:upper:]' '[:lower:]')
OS_PREFIX  := ${OSID_name}.
EXEEXT     := $()
#
AWK        := awk
CAT        := cat
CP         := cp
ECHO       := echo
GREP       := grep
MKDIR      := mkdir -p
RM         := rm
RM_r       := ${RM} -r
RMDIR      := ${RM} -r
SORT       := sort
WHICH      := which
#
ECHO_newline := echo
endif

# find/calculate best available `strip`
STRIP_check_flags := --version
# * calculate `strip`; general overrides for ${CC_ID} and ${OSID}
STRIP := $(or ${STRIP_CC_${CC_ID}_OSID_${OSID}},${STRIP_CC_${CC_ID}},${STRIP})
# $(call %debug_var,STRIP)
# * available as ${CC}-prefixed variant?
STRIP_CC_${CC}_name := $(call %neq,${CC:-${CC_ID}=-strip},${CC})
$(call %debug_var,STRIP_CC_${CC}_name)
STRIP_CC_${CC} := $(or ${STRIP_CC_${CC}},$(and ${STRIP_CC_${CC}_name},$(shell "${STRIP_CC_${CC}_name}" ${STRIP_check_flags} >${devnull} 2>&1 && echo ${STRIP_CC_${CC}_name})))
$(call %debug_var,STRIP_CC_${CC})
# * calculate `strip`; specific overrides for ${CC}
STRIP := $(or ${STRIP_CC_${CC}},${STRIP})
# $(call %debug_var,STRIP)
# * and... ${STRIP} available? (missing in some distributions)
STRIP := $(shell "${STRIP}" ${STRIP_check_flags} >${devnull} 2>&1 && echo ${STRIP})
$(call %debug_var,STRIP)

####

makefile_path := $(lastword ${MAKEFILE_LIST})
makefile_abs_path := $(abspath ${makefile_path})
makefile_dir := $(abspath $(dir ${makefile_abs_path}))
current_dir := ${CURDIR}
make_invoke_alias ?= $(if $(call %eq,Makefile,${makefile_path}),make,make -f "${makefile_path}")

$(call %debug_var,makefile_path)
$(call %debug_var,makefile_abs_path)
$(call %debug_var,makefile_dir)
$(call %debug_var,current_dir)
$(call %debug_var,current_dir)

####

NAME := $(strip ${NAME})
ifeq (${NAME},)
override NAME := $(notdir ${makefile_dir})
endif

####

ARCH_default := i686
ARCH_x86 := i386 i586 i686 x86
ARCH_x86_64 := amd64 x64 x86_64 x86_amd64
ARCH_allowed := $(sort 32 x32 ${ARCH_x86} 64 ${ARCH_x86_64})
ifneq (${ARCH},$(filter ${ARCH},${ARCH_allowed}))
$(call %error,Unknown architecture "$(ARCH)"; valid values are [""$(subst $(SPACE),$(),$(addprefix ${COMMA}",$(addsuffix ",${ARCH_allowed})))])
endif

ifeq (${OSID},win)
CC_machine_raw := $(shell ${CC} ${CFLAGS_machine} 2>&1 | ${FINDSTR} /n /r .* | ${FINDSTR} /b /r "1:")
else ## nix
CC_machine_raw := $(shell ${CC} ${CFLAGS_machine} 2>&1 | ${GREP} -n ".*" | ${GREP} "^1:" )
endif
CC_machine_raw := $(subst ${ESC}1:,$(),${ESC}${CC_machine_raw})
CC_ARCH := $(or $(filter $(subst -, ,${CC_machine_raw}),${ARCH_x86} ${ARCH_x86_64}),${ARCH_default})
CC_machine := $(or $(and $(filter cl bcc32,${CC_ID}),${CC_ARCH}),${CC_machine_raw})
CC_ARCH_ID := $(if $(filter ${CC_ARCH},32 x32 ${ARCH_x86}),32,64)
override ARCH := $(or ${ARCH},${CC_ARCH})
ARCH_ID := $(if $(filter ${ARCH},32 x32 ${ARCH_x86}),32,64)

$(call %debug_var,CC_machine_raw)
$(call %debug_var,CC_machine)
$(call %debug_var,CC_ARCH)
$(call %debug_var,CC_ARCH_ID)

$(call %debug_var,ARCH)
$(call %debug_var,ARCH_ID)

####

# "version heuristic" => parse first line of ${CC} version output, remove all non-version-compatible characters, take first word that starts with number and contains a ${DOT}
# maint; [2020-05-14;rivy] heuristic is dependant on version output of various compilers; works for all known versions as of

ifeq (${OSID},win)
CC_version_raw := $(shell ${CC} ${CFLAGS_v} 2>&1 | ${FINDSTR} /n /r .* | ${FINDSTR} /b /r "1:")
else ## nix
CC_version_raw := $(shell ${CC} ${CFLAGS_v} 2>&1 | ${GREP} -n ".*" | ${GREP} "^1:" )
endif
$(call %debug_var,CC_version_raw)

s := ${CC_version_raw}

# remove "1:" leader
s := $(subst ${ESC}1:,$(),${ESC}${s})
# $(call %debug_var,s)
# remove all non-version-compatible characters (leaving common version characters [${BACKSLASH} ${SLASH} ${DOT} _ - +])
s := $(call %tr,$(filter-out ${SLASH} ${BACKSLASH} ${DOT} _ - +,${[punct]}),$(),${s})
# $(call %debug_var,s)
# filter_map ${DOT}-containing words
%f = $(and $(findstring ${DOT},${1}),${1})
s := $(call %filter_map,%f,${s})
$(call %debug_var,s)
# filter_map all words with leading digits
%f = $(and $(findstring ${ESC}_,${ESC}$(call %tr,${[digit]} ${ESC},$(call %repeat,_,$(words ${[digit]})),${1})),${1})
s := $(call %filter_map,%f,${s})
# $(call %debug_var,s)

# take first word as full version
CC_version := $(firstword ${s})
CC_version_parts := $(strip $(subst ${DOT},${SPACE},${CC_version}))
CC_version_M := $(strip $(word 1,${CC_version_parts}))
CC_version_m := $(strip $(word 2,${CC_version_parts}))
CC_version_r := $(strip $(word 3,${CC_version_parts}))
CC_version_Mm := $(strip ${CC_version_M}.${CC_version_m})

is_CL1600+ := $(call %as_truthy,$(and $(call %eq,cl,${CC}),$(call %not,$(filter ${CC_version_M},0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15)),${true}))
is_VC6 := $(call %as_truthy,$(and $(call %eq,cl,${CC}),$(call %eq,12,${CC_version_M}),${true}))

$(call %debug_var,CC_version)
$(call %debug_var,CC_version_parts)
$(call %debug_var,CC_version_M)
$(call %debug_var,CC_version_m)
$(call %debug_var,CC_version_r)
$(call %debug_var,CC_version_Mm)
$(call %debug_var,is_CL1600+)
$(call %debug_var,is_VC6)

####

OUT_DIR_EXT := $(if $(call %is_truthy,${STATIC}),,.dynamic)

ifeq (,${TARGET})
OUT_DIR_EXT :=-x${ARCH_ID}
else
CFLAGS_TARGET := --target=${TARGET}
LDFLAGS_TARGET := --target=${TARGET}
OUT_DIR_EXT := ${OUT_DIR_EXT}.${TARGET}
endif

$(call %debug_var,CFLAGS_TARGET)
$(call %debug_var,CXXFLAGS_TARGET)
$(call %debug_var,LDFLAGS_TARGET)

$(call %debug_var,ARCH_ID)
$(call %debug_var,TARGET)

$(call %debug_var,OUT_DIR_EXT)

####

CFLAGS += ${CFLAGS_ARCH_${ARCH_ID}}
CFLAGS += ${CFLAGS_TARGET}
CFLAGS += ${CFLAGS_DEBUG_${DEBUG}}
CFLAGS += ${CFLAGS_STATIC_${STATIC}}
CFLAGS += ${CFLAGS_DEBUG_${DEBUG}_STATIC_${STATIC}}
CFLAGS += ${CFLAGS_VERBOSE_${VERBOSE}}

CPPFLAGS += $(if $(call %is_truthy,${CC_DEFINES}),-D_CC="${CC}" -D_CC_ID="${CC_ID}" -D_CC_version="${CC_version}" -D_CC_machine="${CC_machine}" -D_CC_target="${TARGET}" -D_CC_target_arch="${ARCH_ID}",$())

CXXFLAGS += ${CXXFLAGS_${CC_ID}}

LDFLAGS += ${LDFLAGS_ARCH_${ARCH_ID}}
LDFLAGS += ${LDFLAGS_TARGET}
LDFLAGS += ${LDFLAGS_STATIC_${STATIC}}
LDFLAGS += ${LDFLAGS_CL1600+_${is_CL1600+}}
LDFLAGS += ${LDFLAGS_VC6_${is_VC6}}
LDFLAGS += ${LDFLAGS_${CC_ID}}
LDFLAGS += ${LDFLAGS_${CC_ID}_${OSID}}

CFLAGS := $(strip ${CFLAGS})
CPPFLAGS := $(strip ${CPPFLAGS})
CXXFLAGS := $(strip ${CXXFLAGS})
LDFLAGS := $(strip ${LDFLAGS})

$(call %debug_var,CFLAGS)
$(call %debug_var,CPPFLAGS)
$(call %debug_var,CXXFLAGS)
$(call %debug_var,LDFLAGS)

####

# note: work within ${CURDIR} (build directories may not yet be created)
# note: set LIB as `make` doesn't export the LIB change into `$(shell ...)` invocations
test_file_stem := $(subst ${SPACE},_,__MAKE__${CC}_${ARCH}_${TARGET}_test__)
test_file_cc_string := ${CC_e}${test_file_stem}${EXEEXT}
test_success_text := ..TEST-COMPILE-SUCCESSFUL..
$(call %debug_var,test_file_stem)
$(call %debug_var,test_file_cc_string)
ifeq (${OSID},win)
# erase the LIB environment variable for non-`cl` compilers (specifically `clang` has issues)
test_lib_setting_win := $(if $(call %neq,cl,${CC}),set "LIB=${LIB}",set "LIB=%LIB%")
$(call %debug_var,test_lib_setting_win)
# test_output := $(shell ${test_lib_setting_win} && ${ECHO} ${HASH}include ^<stdio.h^> > ${test_file_stem}.c && ${ECHO} int main(void){printf("${test_file_stem}");return 0;} >> ${test_file_stem}.c && ${CC} $(filter-out ${CFLAGS_VERBOSE_true},${CFLAGS}) ${test_file_stem}.c ${test_file_cc_string} 2>&1 && ${ECHO} ${test_success_text})
test_output := $(shell ${test_lib_setting_win} && ${ECHO} ${HASH}include ^<stdio.h^> > ${test_file_stem}.c && ${ECHO} int main(void){printf("${test_file_stem}");return 0;} >> ${test_file_stem}.c && ${CC} $(filter-out ${CFLAGS_VERBOSE_true},${CFLAGS}) ${test_file_stem}.c ${test_file_cc_string} 2>&1 && ${ECHO} ${test_success_text}& ${RM} ${test_file_stem}${EXEEXT} ${test_file_stem}.*)
else
test_output := $(shell LIB='${LIB}' && ${ECHO} '${HASH}include <stdio.h>' > ${test_file_stem}.c && ${ECHO} 'int main(void){printf("${test_file_stem}");return 0;}' >> ${test_file_stem}.c && ${CC} $(filter-out ${CFLAGS_VERBOSE_true},${CFLAGS}) ${test_file_stem}.c ${test_file_cc_string} 2>&1 && ${ECHO} ${test_success_text}; ${RM} -f ${test_file_stem}${EXEEXT} ${test_file_stem}.*)
endif
ARCH_available := $(call %is_truthy,$(findstring ${test_success_text},${test_output}))
$(call %debug_var,.SHELLSTATUS)
$(call %debug_var,test_output)
$(call %debug_var,ARCH_available)

$(call %debug_var,ARCH_ID)
$(call %debug_var,CC_ARCH_ID)

ifeq (${false},$(and ${ARCH_available},$(or $(call %eq,${ARCH_ID},${CC_ARCH_ID}),$(call %neq,cl,${CC}))))
$(call %error,$(if ${TARGET},Architecture/Target "${ARCH}/${TARGET}",Architecture "${ARCH}") is unavailable/unimplemented for this version of `${CC}` (v${CC_version}/${CC_machine}))
endif

####

BUILD_DIR := ${HASH}build
CONFIG    := $(if $(call %is_truthy,${DEBUG}),debug,release)

SRC_DIR := src
OUT_DIR := ${BUILD_DIR}/${OS_PREFIX}${CONFIG}$(if $(call %is_truthy,${STATIC}),,.dynamic).(${CC}@${CC_version_Mm})${OUT_DIR_EXT}
OUT_DIR_bin := ${OUT_DIR}/bin
OUT_DIR_obj := ${OUT_DIR}/obj
out_dirs := $(strip $(call %uniq,${OUT_DIR} ${OUT_DIR_bin} ${OUT_DIR_obj}))
out_dirs_for_rules := $(strip $(subst ${HASH},${BACKSLASH}${HASH},${out_dirs}))

$(call %debug_var,out_dirs)
$(call %debug_var,out_dirs_for_rules)

SRC_files := $(wildcard ${SRC_DIR}/*.c ${SRC_DIR}/*.cpp ${SRC_DIR}/*.cxx)
OBJ_files := $(SRC_files)
OBJ_files := $(OBJ_files:${SRC_DIR}/%.c=${OUT_DIR_obj}/%.${O})
OBJ_files := $(OBJ_files:${SRC_DIR}/%.cpp=${OUT_DIR_obj}/%.${O})
OBJ_files := $(OBJ_files:${SRC_DIR}/%.cxx=${OUT_DIR_obj}/%.${O})

$(call %debug_var,SRC_DIR)
$(call %debug_var,SRC_files)
$(call %debug_var,OBJ_files)

####

PROJECT_TARGET := ${OUT_DIR_bin}/${NAME}${EXEEXT}
${PROJECT_TARGET}: # *default* target (see recipe/rule below)

####

.PHONY: help
help: ## Display help
	@${ECHO} $(call %shell_quote,`${make_invoke_alias}`)
	@${ECHO} $(call %shell_quote,Usage: `${make_invoke_alias} [ARCH=..] [CC_DEFINES=..] [COLOR=..] [DEBUG=..] [STATIC=..] [TARGET=..] [VERBOSE=..] [MAKE_TARGET...]`)
	@${ECHO} $(call %shell_quote,Builds '${PROJECT_TARGET}' within "$(current_dir)")
	@${ECHO_newline}
	@${ECHO} $(call %shell_quote,MAKE_TARGETs:)
	@${ECHO_newline}
ifeq (${OSID},win)
	@${FINDSTR} "^[a-zA-Z-]*:.*${HASH}${HASH}" "${makefile_path}" | ${SORT} | for /f "tokens=1-2,* delims=:${HASH}" %%g in ('${MORE}') do @(@call set "t=%%g                " & @call echo ${color_success}%%t:~0,15%%${color_reset} ${color_info}%%i${color_reset})
else
	@${GREP} -P "(?i)^[[:alpha:]-]+:" "${makefile_path}" | ${SORT} | ${AWK} 'match($$0,"^([[:alpha:]]+):.*?${HASH}${HASH}\\s*(.*)$$",m){ printf "${color_success}%-10s${color_reset}\t${color_info}%s${color_reset}\n", m[1], m[2] }END{printf "\n"}'
endif

.PHONY: run
run: ${PROJECT_TARGET} ## Build/execute project executable
	@"$^"

####

.PHONY: clean
clean: ## Remove build artifacts (including intermediate files)
	@$(call !shell_noop,$(call %rm_dirs_verbose,${out_dirs}))

.PHONY: realclean
realclean: clean ## Remove *all* build artifacts (including all configurations and the build directory)
	@$(call !shell_noop,$(call %rm_dirs_verbose,${BUILD_DIR}))

####

.PHONY: all build compile rebuild veryclean
all: build ## Build all project targets
build: ${PROJECT_TARGET} ## Build project
compile: ${OBJ_files} ## Build intermediate files
rebuild: clean build ## Clean and rebuild project
vclean: veryclean
veryclean: realclean

####

# ref: [`make` default rules]<https://www.gnu.org/software/make/manual/html_node/Catalogue-of-Rules.html> @@ <https://archive.is/KDNbA>
# ref: [make ~ `eval()`](http://make.mad-scientist.net/the-eval-function) @ <https://archive.is/rpUfG>

${PROJECT_TARGET}: ${OBJ_files} ${makefile_abs_path} | ${OUT_DIR_bin}
	$(call %link,"$@",$(addprefix ",$(addsuffix ",${OBJ_files})),${LIBS})
	$(if $(and ${STRIP},$(call %is_falsey,${DEBUG})),${STRIP} "$@",)
	@${ECHO} $(call %shell_quote,$(call %success_text,made '$@'.))

${OUT_DIR_obj}/%.${O}: ${SRC_DIR}/%.c ${makefile_abs_path} | ${OUT_DIR_obj}
	${CC} ${CFLAGS_COMPILE_ONLY} ${CPPFLAGS} ${CFLAGS} ${CC_o}"$@" "$<"

${OUT_DIR_obj}/%.${O}: ${SRC_DIR}/%.cpp ${makefile_abs_path} | ${OUT_DIR_obj}
	${CXX} ${CFLAGS_COMPILE_ONLY} ${CPPFLAGS} ${CXXFLAGS} ${CC_o}"$@" ${CFLAGS} "$<"

${OUT_DIR_obj}/%.${O}: ${SRC_DIR}/%.cxx ${makefile_abs_path} | ${OUT_DIR_obj}
	${CXX} ${CFLAGS_COMPILE_ONLY} ${CPPFLAGS} ${CXXFLAGS} ${CC_o}"$@" ${CFLAGS} "$<"
#or ${CC} ${CFLAGS_COMPILE_ONLY} ${CPPFLAGS} ${CFLAGS} ${CC_o}"$@" "$<"

####

$(foreach dir,$(filter-out . ..,${out_dirs_for_rules}),$(eval $(call @mkdir_rule,${dir})))
