set_global_assignment -entity "mhz23" -library "lib_mhz23" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "mhz23" -library "lib_mhz23" -name IP_TOOL_VERSION "15.1"
set_global_assignment -entity "mhz23" -library "lib_mhz23" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_mhz23" -name SPD_FILE [file join $::quartus(sip_path) "mhz23.spd"]

set_global_assignment -library "lib_mhz23" -name MISC_FILE [file join $::quartus(sip_path) "mhz23_sim/mhz23.vo"]
