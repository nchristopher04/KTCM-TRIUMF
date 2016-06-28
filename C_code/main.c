#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include "hwlib.h"
#include "soc_cv_av/socal/socal.h"
#include "soc_cv_av/socal/hps.h" 
#include "soc_cv_av/socal/alt_gpio.h"
#include "hps_0.h"

#define HW_REGS_BASE ( ALT_STM_OFST )
#define HW_REGS_SPAN ( 0x04000000 )
#define HW_REGS_MASK ( HW_REGS_SPAN - 1 )

int main() {

	void *virtual_base;
	int fd;
	int DataIn;
	int loop_count =0;
	void *h2p_lw_led_addr;
	void *h2p_lw_IO;

	// map the address space for the LED registers into user space so we can interact with them.
	// we'll actually map in the entire CSR span of the HPS since we want to access various registers within that span

	if( ( fd = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) {
		printf( "ERROR: could not open \"/dev/mem\"...\n" );
		return( 1 );
	}

	virtual_base = mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE );

	if( virtual_base == MAP_FAILED ) {
		printf( "ERROR: mmap() failed...\n" );
		close( fd );
		return( 1 );
	}
	
	h2p_lw_led_addr=virtual_base + ( ( unsigned long  )( ALT_LWFPGASLVS_OFST + HPS_DATA_BASE ) & ( unsigned long)( HW_REGS_MASK ) );
	
	h2p_lw_IO=virtual_base + ( ( unsigned long  )( ALT_LWFPGASLVS_OFST + HPS_DATA_BASE + 0x01 ) & ( unsigned long)( HW_REGS_MASK ) );

	// toggle the LEDs a bit
	
	/**(uint32_t *)h2p_lw_IO = 0;*/
	while( loop_count < 60 ) {


		// control led
		DataIn = *(uint32_t *)h2p_lw_led_addr; 

		printf("%u\n",DataIn);

		loop_count++;
	} // while
	

	// clean up our memory mapping and exit
	
	if( munmap( virtual_base, HW_REGS_SPAN ) != 0 ) {
		printf( "ERROR: munmap() failed...\n" );
		close( fd );
		return( 1 );
	}

	close( fd );

	return( 0 );
}
