DISABLE_TUI := DISABLE
ENABLE_CUSTOM_UI := ENABLE

# Sets the build type; defaults to Debug. Valid values:
#
# - Debug:          Disables optimizations (-O0), enables debug information and logging.
#
# - Dev:            Enables all optimizations that do not interfere with
#                   debugging (-Og if available, -O2 and -g if not).
#                   Enables debug information and logging.
#
# - RelWithDebInfo: Enables optimizations (-O2) and debug information.
#                   Disables logging.
#
# - MinSizeRel:     Enables all -O2 optimization that do not typically
#                   increase code size, and performs further optimizations
#                   designed to reduce code size (-Os).
#                   Disables debug information and logging.
#
# - Release:        Same as RelWithDebInfo, but disables debug information.
#CMAKE_BUILD_TYPE := Dev
CMAKE_BUILD_TYPE := Release

# The log level must be a number DEBUG (0), INFO (1), WARNING (2) or ERROR (3).
#CMAKE_EXTRA_FLAGS += -DMIN_LOG_LEVEL=0
