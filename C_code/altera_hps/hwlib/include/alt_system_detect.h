/******************************************************************************
*
* Copyright 2014 Altera Corporation. All Rights Reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice,
* this list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice,
* this list of conditions and the following disclaimer in the documentation
* and/or other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors
* may be used to endorse or promote products derived from this software without
* specific prior written permission.
* 
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
* ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
* LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
* SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
* INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
* CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*
******************************************************************************/

/*
 * $Id: //acds/rel/15.0/embedded/ip/hps/altera_hps/hwlib/include/alt_system_detect.h#3 $
 */

/*! \file
 *  Altera - System Detect API
 */



#ifndef __alt_sys_detect_H__
#define __alt_sys_detect_H__

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <soc_cv_av/socal/socal.h>
#include <soc_cv_av/socal/hps.h>
#include <hwlib.h>

#ifdef __cplusplus
extern "C"
{
#endif                          /* __cplusplus */

/*!
 * \addtogroup ALT_SYS_DETECT System Detect Common API Definitions
 *
 * This module contains the common definitions for the System Detect related
 * APIs.
 *
 * @{
 */

/*!
 * Detects if the SoCFPGA variant of the current HPS is a Cyclone 5 SoCFPGA.
 *
 * Internally it looks at the system manager silicon ID to determine the
 * current device is a generation 5 device. To differentiate between Cyclone 5
 * and Arria 5, it attempts to query the CAN reset bits.
 *
 * \retval      true            Current device is a Cyclone 5 SoCFPGA.
 * \retval      false           Current device is something else.
 */
bool alt_hps_detect_is_cyclone5(void);

/*!
 * Detects if the SoCFPGA variant of the current HPS is an Arria 5 SoCFPGA.
 *
 * For internal logic, see documentation for alt_hps_detect_is_cyclone5(). It is
 * changed slightly to detect the absense of the CAN interface.
 *
 * \retval      true            Current device is an Arria 5 SoCFPGA.
 * \retval      false           Current device is something else.
 */
bool alt_hps_detect_is_arria5(void);


/******************************************************************************/
/*!
 * Parse ID and write a text message to a string buffer. This function
 * checks that ID is a valid Altera Chip ID and decodes it
 * as a string.  The decoded silicon ID string is copied into the character
 * buffer pointed to by buff.  The maximum length of the buffer is set by 
 * max len.  Returns ALT_E_SUCCESS upon successful chip ID 
 * decode and returns ALT_E_ERROR if the ID is not a valid Altera chip ID. 
 *
 * \param       id 
 *              Altera Silicon ID fetched from scan manager by the 
 *              alt_sys_detect_silicon_id_get() function. 
 *
 * \param       buff
 *              [out] Pointer to the memory that stores the decoded string.  
 *
 * \param       max_len
 *              Length of the allocated string buffer.
 *
 * \retval      ALT_E_SUCCESS   The operation was succesful (if known or unknown ID).
 * \retval      ALT_E_ERROR     The operation failed (if not an Altera Silicon ID).
 */        
  ALT_STATUS_CODE alt_sys_detect_silicon_id_decode(uint32_t id, char *buff, uint32_t max_len);


/******************************************************************************/
/*!
 * Get the 32bit Altera Silicon ID read from the CPU via JTAG and the scan manager
 *
 * \retval      uint32_t     The Altera Silicon ID.
 */
    uint32_t alt_sys_detect_silicon_id_get(void);
/*!
 * @}
 */


#ifdef __cplusplus
}
#endif                          /* __cplusplus */

#endif                          /* __alt_sys_detect_H__ */
