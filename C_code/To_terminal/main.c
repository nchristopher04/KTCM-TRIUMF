#include <stdio.h>
#include <time.h>
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
/* print some text */
printf("NUMBER TRIGGER_OFFSET(us) TIME_KTM_WOULD_HAVE_TRIGGERED(us) BEAM_ON_MEAN_VOLTAGE(mv) RESIDUAL_BEAM_MEAN_VOLTAGE(mv) TIME_SINCE_LAST_PULSER_FALLING_EDGE(us) VOLTAGE(mV)");

time_t rawtime;
struct tm * timeinfo;

time ( &rawtime );
timeinfo = localtime ( &rawtime );
printf ( "Current local time and date: %s\n", asctime (timeinfo) );

 


	void *virtual_base;
	int fd;
	unsigned int DataIn [100];
	unsigned int triggerOffset;
	unsigned int meanOffset;
	unsigned int highVoltage;
	unsigned int lowVoltage;
	unsigned int DataOut;
	unsigned int errorType;
	unsigned int errorDone;
	long int i = 0;
	int loop_count;
	int loop_count2;
	unsigned int voltage;
	unsigned int clocks;
	float time;
	void *h2p_lw_led_addr;
//	void *h2p_lw_IO;

	// map the address space for the AXI BRIDGE registers into user space so we can interact with them.
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
	
//	h2p_lw_IO=virtual_base + ( ( unsigned long  )( ALT_LWFPGASLVS_OFST + HPS_DATA_BASE + 0x01 ) & ( unsigned long)( HW_REGS_MASK ) );
	while(i>-1&&i<10000000){
if(i==3600000)
{
	timeinfo = localtime ( &rawtime );
	printf ( "Current local time and date: %s\n", asctime (timeinfo) );
	i=0;
}

i++;
loop_count = 0;
	/**(uint32_t *)h2p_lw_IO = 0;*/
	do{

		// control led
		DataOut = 3;
		*(uint32_t *)h2p_lw_led_addr = DataOut;
		DataIn[loop_count] = *(uint32_t *)h2p_lw_led_addr; 
		while(DataIn[loop_count]%2 == 0 && (DataIn[loop_count] != 2 || loop_count==0))
		{
			DataIn[loop_count] = *(uint32_t *)h2p_lw_led_addr; 
		}
		DataOut = 1;
		*(uint32_t *)h2p_lw_led_addr = DataOut;
		loop_count++;
	} while( DataIn[loop_count-1] != 2 && DataIn[loop_count-1]!=3 && loop_count<99);

	if(DataIn[loop_count-1]==3)
	{	
		DataOut = 64;
		*(uint32_t *)h2p_lw_led_addr = DataOut;
		DataIn[loop_count]= *(uint32_t *)h2p_lw_led_addr; 
		while(DataIn[loop_count]%2 == 0)
		{
			DataIn[loop_count]= *(uint32_t *)h2p_lw_led_addr; 
		}
		errorType = (DataIn[loop_count]-1)/2;
		printf("!!!!!!!!!!!!!!!!!!!!\n\n\nERROR NUMBER %u\n",errorType);
		timeinfo = localtime ( &rawtime );
		printf ( "Current local time and date: %s\n", asctime (timeinfo) );
		switch(errorType)
		{
			case 1:
	    			printf("Kicker Trigger signal in on state longer than it should be\n");
	    		break; 
			case 2:
	    			printf("ratio of beam on vs off is too large\n");
	    		break; 
			case 3:
	    			printf("Pulser valley is smaller than 48.75us\n");
	    		break; 
			case 4:
	    			printf("Pulser mean period is larger than 1.4ms\n");
	    		break; 
			case 5:
	    			printf("Pulser last period was larger than 1.4ms\n");
	    		break; 
			case 6:
	    			printf("Pulser mean period is smaller than 0.8ms\n");
	    		break; 
			case 7:
	    			printf("Pulser last period was smaller than 0.8ms\n");
	    		break; 
			case 8:
	    			printf("1VM4 valley is smaller than 37.5us\n");
	    		break; 
			case 9:
	    			printf("1VM4 last period was smaller than 0.8ms\n");
	    		break; 
			case 10:
	    			printf("1VM4 last period was larger than 1.4ms\n");
	    		break; 
			case 11:
	    			printf("1VM4 valley is larger than 150us\n");
	    		break; 
			case 12:
	    			printf("1VM4 signal is high for longer than 1.25ms\n");
	    		break; 
			case 13:
	    			printf("Pulser valley is larger than 150us\n");
	    		break; 
			case 14:
	    			printf("Pulser signal is high for longer than 1.25ms\n");
	    		break; 	
			case 15:
	    			printf("1VM4 and pulser signal are not in sync. Common reasons would be a connectivity problem, or a logic issue.\n");
	    		break; 			
	 		default:
	 			printf("Could not Identify error type. For more info, go to https://github.com/nchristopher04/KTCM-TRIUMF and search for 'conditions that cause an error' In KCM_LOGIC.v\n");
		}
		DataOut = 128;
		*(uint32_t *)h2p_lw_led_addr = DataOut;
		errorDone = *(uint32_t *)h2p_lw_led_addr;
		while(errorDone != 2)
		{
			errorDone = *(uint32_t *)h2p_lw_led_addr; 
		}
	}
	else
	{
		DataOut = 4;
		*(uint32_t *)h2p_lw_led_addr = DataOut;
		triggerOffset = *(uint32_t *)h2p_lw_led_addr; 
		while(triggerOffset%2 == 0)
		{
			triggerOffset = *(uint32_t *)h2p_lw_led_addr; 
		}

		printf("\n%ld %4.4f ",i,0.0125*((triggerOffset*1.0)/2.0-0.5));
	
		DataOut = 16;

		*(uint32_t *)h2p_lw_led_addr = DataOut;
		meanOffset = *(uint32_t *)h2p_lw_led_addr; 
		while(meanOffset%2 == 0)
		{
			meanOffset = *(uint32_t *)h2p_lw_led_addr; 
		}

		printf("%4.4f ",0.0125*((meanOffset*1.0)/2.0-0.5));

		DataOut = 8;
		*(uint32_t *)h2p_lw_led_addr = DataOut;
		highVoltage = *(uint32_t *)h2p_lw_led_addr; 
		while(highVoltage%2 == 0)
		{
			highVoltage = *(uint32_t *)h2p_lw_led_addr; 
		}
		printf("%u ",highVoltage/2);

		DataOut = 32;

		*(uint32_t *)h2p_lw_led_addr = DataOut;
		lowVoltage = *(uint32_t *)h2p_lw_led_addr; 
		while(lowVoltage%2 == 0)
		{
			lowVoltage = *(uint32_t *)h2p_lw_led_addr; 
		}
		printf("%u ",lowVoltage/2);

		loop_count2=0;

		while( loop_count2<(loop_count-1) ){
			clocks = DataIn[loop_count2]/16384;
			time = 0.0125*clocks+0.00005;
			voltage = ((1.0*DataIn[loop_count2])/16384.0-clocks)*4096.0;
			//printf("%u,%3.4f,%u\n",DataIn[loop_count2],time,voltage);
			printf("%3.4f %u ",time,voltage);
			loop_count2++;
		}
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
