set_global_assignment -entity "RFx8" -library "lib_RFx8" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "RFx8" -library "lib_RFx8" -name IP_TOOL_VERSION "15.1"
set_global_assignment -entity "RFx8" -library "lib_RFx8" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_RFx8" -name SPD_FILE [file join $::quartus(sip_path) "RFx8.spd"]

set_global_assignment -library "lib_RFx8" -name MISC_FILE [file join $::quartus(sip_path) "RFx8_sim/RFx8.vo"]
