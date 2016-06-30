#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <math.h>
#include "hwlib.h"
#include "soc_cv_av/socal/socal.h"
#include "soc_cv_av/socal/hps.h" 
#include "soc_cv_av/socal/alt_gpio.h"
#include "hps_0.h"

#define HW_REGS_BASE ( ALT_STM_OFST )
#define HW_REGS_SPAN ( 0x04000000 )
#define HW_REGS_MASK ( HW_REGS_SPAN - 1 )

int main() {
//FILE *f = fopen("KTM_data.txt", "w");
//if (f == NULL)
//{
//    printf("Error opening file!\n");
//    return(1);
//}

/* print some text */
printf("KTM DATA\nBEAM ON MEAN VOLTAGE (mv)\nTRIGGER OFFSET\nTIME KTM WOULD HAVE TRIGGERED\nINPUT, TIME SINCE LAST PULSER FALLING EDGE(us), VOLTAGE(mV)\n");

 


	void *virtual_base;
	int fd;
	unsigned int DataIn [61];
	unsigned int triggerOffset;
	unsigned int meanOffset;
	unsigned int highVoltage;
	unsigned int DataOut;
int i = 0;
	int loop_count;
	unsigned int voltage;
	unsigned int clocks;
	float time;
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

	while(i<30){
i++;
loop_count = 0;
	/**(uint32_t *)h2p_lw_IO = 0;*/
	while( loop_count < 25 ) {


		// control led
		DataOut = 3;
		*(uint32_t *)h2p_lw_led_addr = DataOut;
		DataIn[loop_count] = *(uint32_t *)h2p_lw_led_addr; 
		while(DataIn[loop_count]%2 == 0)
		{
			DataIn[loop_count] = *(uint32_t *)h2p_lw_led_addr; 
		}
		DataOut = 1;
		*(uint32_t *)h2p_lw_led_addr = DataOut;
//		printf("%u\n",DataIn);
//		clocks = DataIn/16384.0;
//		printf("%u 80MHZ clock cycles since pulser trigger\n",clocks);
//		time = clocks*12.5;
//		printf("%f time in ns since pulser trigger\n",time);
//		voltage = ((1.0*DataIn)/16384.0-clocks)*8192.0;
//		printf("%u mV\n",voltage);
//		fprintf(f, "%u",DataIn);
//		fprintf(f, "%u,%f,%u\n",DataIn,time,voltage);
		loop_count++;
	} // while

	DataOut = 8;
	*(uint32_t *)h2p_lw_led_addr = DataOut;
	highVoltage = *(uint32_t *)h2p_lw_led_addr; 
	while(highVoltage%2 == 0)
		{
			highVoltage = *(uint32_t *)h2p_lw_led_addr; 
		}
	printf("%u mV\n",highVoltage/2);

	DataOut = 4;
	*(uint32_t *)h2p_lw_led_addr = DataOut;
	triggerOffset = *(uint32_t *)h2p_lw_led_addr; 
	while(triggerOffset%2 == 0)
		{
			triggerOffset = *(uint32_t *)h2p_lw_led_addr; 
		}

	printf("%f us\n",0.0125*((triggerOffset*1.0)/2.0-0.5));
	
	DataOut = 16;

	*(uint32_t *)h2p_lw_led_addr = DataOut;
	meanOffset = *(uint32_t *)h2p_lw_led_addr; 
	while(meanOffset%2 == 0)
		{
			meanOffset = *(uint32_t *)h2p_lw_led_addr; 
		}

	printf("Mean: %3.4f us\n",0.0125*((meanOffset*1.0)/2.0-0.5));

loop_count=0;

	while( loop_count<25 ){
		clocks = DataIn[loop_count]/16384;
		time = 0.0125*clocks+0.00005;
		voltage = ((1.0*DataIn[loop_count])/16384.0-clocks)*8192.0;
		printf("%u,%3.4f,%u\n",DataIn[loop_count],time,voltage);
	loop_count++;
}
}

	// clean up our memory mapping and exit
	
	if( munmap( virtual_base, HW_REGS_SPAN ) != 0 ) {
		printf( "ERROR: munmap() failed...\n" );
		close( fd );
		return( 1 );
	}

//	fclose(f);
	close( fd );

	return( 0 );
}
