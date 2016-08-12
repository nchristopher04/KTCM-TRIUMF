set_global_assignment -entity "RFx8_2" -library "lib_RFx8_2" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "RFx8_2" -library "lib_RFx8_2" -name IP_TOOL_VERSION "15.1"
set_global_assignment -entity "RFx8_2" -library "lib_RFx8_2" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_RFx8_2" -name SPD_FILE [file join $::quartus(sip_path) "RFx8_2.spd"]

set_global_assignment -library "lib_RFx8_2" -name MISC_FILE [file join $::quartus(sip_path) "RFx8_2_sim/RFx8_2.vo"]
