//--==========---=========---==========---==--------==---====--------====---==========--
//------==-------==-----==-------==-------==--------==---==-==------==-==---==----------
//------==-------==----==--------==-------==--------==---==--==----==--==---==----------
//------==-------======----------==-------==--------==---==---==--==---==---=======-----
//------==-------==---==---------==-------==--------==---==----====----==---==----------
//------==-------==----==--------==--------==------==----==-----==-----==---==----------
//------==-------==-----==---==========------======------==-----==-----==---==----------

//This program was created in June 2016 By Nicholas Christopher - UCN group
//It is intended to record data from the 1VM4 Capacitive pickoff monitor. both beam intensity and timing with reference to the cyclotron pulser signal
//It also generates a Trigger signal that can be used to turn on and off the Kicker magnet.
//
//
//*********************READ ME!!!!!!!!!****************************
/*
There are 2 modes this program can operate in:

TEST MODE:
This mode is used in absence of the 1VM4 and pulser signals. 
To activate this mode , search for assign USE1VM4 and set to:

assign USE1VM4 = 1'b0;


REAL BEAM MODE:
This is used with the real signals from 1VM4 and the pulser.
To activate this mode , search for assign USE1VM4 and set to:

assign USE1VM4 = 1'b1;


Connections:
1VM4/ADC:
connect the two wires from the I signal to pins 2 and 3 of J15 ADC CON on the DE0 Nano board
connect the two wires from the Q signal to pins 4 and 5 of J15 ADC CON on the DE0 Nano board
Polarity is not important
the ADC inputs can take +-2V

Pulser signal:
Connect the signal (must be 3.3V LVTTL) to pin 1 of JP1 GPIO 0 on the DE0 Nano board 
Connect the gound of the signal to pin 12 (GND) of JP1 GPIO 0 on the DE0 Nano board 

Output trigger:
The signal is set on pin 6 of JP1 GPIO 0 on the DE0 Nano board.
it is a 3.3V LVTTL signal
you can use pin 12 or 30 as GND
*/

module KCM_LOGIC(
//DEFINE INPUTS AND OUTPUT names
input wire [1:0] KEY,

output wire	    [7:0]		LED,
//////////// SW //////////
input wire		 [3:0]		SW,
//////////// GPIO_0, GPIO connect to GPIO Default //////////
inout wire	    [35:0]		GPIO_0,
//////////// GPIO_1, GPIO connect to GPIO Default //////////
output wire	    [35:0]		GPIO_1,

output wire		          	ADC_CONVST,
output wire          		ADC_SCK,
output wire	          		ADC_SDI,
input wire	          		ADC_SDO,
//////////// CLOCK //////////
input wire	          		FPGA_CLK1_50,
input wire	          		FPGA_CLK2_50,
input wire	          		FPGA_CLK3_50,
/////////// COMMUNICATION WITH HPS ///////////////
output wire CLOCK_80MHZ,
output wire NewData,
output wire InValley,
output wire [11:0] ADCValue,
output wire [17:0] ADCTime,
output wire [17:0] currentTrigOffset,
output wire [11:0] highVoltage,
output wire [11:0] lowVoltage,
output wire [17:0] meanOffset,
output wire errorOut,
output wire [5:0]errorInfo,
input wire errorMessageComplete
);


//=======================================================
//  REG/WIRE declarations
//=======================================================

//For sending values to HPS*******************
reg [11:0] NEWADCVALUE [0:1];
wire done;
reg valleyRecord;
reg [17:0] ADCTimeR;
reg DataGo;
assign InValley = DataGo;
assign NewData = valleyRecord;

//For gathering ADC values and Determining IQ value************************
wire [23:0] RESULT_CHAN [0:1] ;
wire [23:0] I_PLUS_Q;
wire [12:0] IQRemainder;
wire [11:0] CHAN [0:7];
wire KEY_NOT;
wire RESET_80MHZ;
assign KEY_NOT = !KEY[0];
wire [11:0] IQvalue;
assign ADCValue = IQvalue;
//assign ADCValue = CHAN[0];

// FOR ADC SIGNAL analysis*****************************
reg [23:0] sumAveraging;
reg [18:0] meanPeriod;
reg [18:0] period;
reg [17:0] pulseSize;
reg [13:0] valleySize;
reg [17:0] pulseAveraging [0:31];
reg [13:0] valleyAveraging [0:31];
reg [13:0] countRealSwitch;
reg [13:0] switchOffsetValue;
reg switchStates;
reg [5:0] datanum;
reg countPulseStart;
reg countValleyStart;
reg countValley;
reg countPulse;
reg writeData,writeValleySum,writePulseSum;
reg dataReady;
reg [3:0] state;
reg [3:0] nextState;
reg ADCsignal;

//For calculating the beam-on Voltage
reg [11:0]meanHighVoltage;
reg [18:0]highVoltageSum;
reg [6:0]countHV;
assign highVoltage = meanHighVoltage;

//For calculating the residual beam Voltage
reg [18:0]lowVoltageSum;
reg [6:0]countLV;
reg [11:0]meanLowVoltage;
assign lowVoltage = meanLowVoltage;

// FOR PULSER SIGNAL analysis*************************
reg pulserSignal;
reg [23:0] PsumAveraging;
reg [18:0] PmeanPeriod;
reg [18:0] Pperiod;
reg [17:0] PpulseSize;
reg [13:0] PvalleySize;
reg [17:0] PpulseAveraging [0:31];
reg [13:0] PvalleyAveraging [0:31];
reg [5:0] Pdatanum;
reg PcountPulseStart;
reg PcountValleyStart;
reg PcountValley; // With P at the start denotes that they are for the pulser signal. follows same or similar logic to logic for 1VM4 signals.
reg PcountPulse;
reg PwriteData,PwriteValleySum,PwritePulseSum;
reg PdataReady;
reg [3:0] Pstate;
reg [3:0] PnextState;

//For Triggering Offset analysis*******************************
reg [17:0] triggerOffset [0:31];
reg [23:0] triggerSum;
reg [17:0] meanTriggerOffset;
reg [17:0] wouldHaveTriggeredAt;
assign meanOffset = wouldHaveTriggeredAt;

//Triggering parameters
reg [3:0] Tstate;
reg [3:0] TnextState;
reg TriggerSignal;
reg TriggerOut;
reg BeamOn;
reg [6:0] OnRatio;
reg [6:0] OffRatio;
reg [6:0] switchCount;
reg turnON;
reg turnOFF;
reg [5:0]Tdatanum;
reg [17:0]TrigTime;

//For when errors occur**********************
reg [17:0] errorClockSize;
reg errorReset;
reg error;
assign errorOut = error;
reg [5:0]errorType;
assign errorInfo = errorType;
reg [19:0]KickerOnCounter;
reg errorSwitch;
reg [18:0]errorCounter1;
reg [18:0]errorCounter2;
reg errorFlag;

//Test signal***************************
//reg signal1,signal2;
//wire signalW1,signalW2;
wire USE1VM4;
assign USE1VM4 = 1'b0;
wire PulsarInput;


//etc..****************
reg [7:0] LEDr;

parameter COMPARE = 12'b011111111111,resetState=4'd0,beginState=4'd1,record1State=4'd2,record2State=4'd3,beginHighState=4'd6,beginLowState=4'd7;

parameter KickerOnState=4'd2, KickerOffState=4'd3, errorLowState=4'd4, errorHighState=4'd5;


//=======================================================
//  Intitial Values
//=======================================================
initial
begin
//datanum <= 6'd32; 
//Tdatanum <= 6'd4;
//dataReady <= 1'b0;
//sumAveraging <= 24'd0;
//Pdatanum <= 6'd32; 
//PdataReady <= 1'b0;
//PsumAveraging <= 24'd0;
error <= 1'b0;

Pstate <= resetState;
state <= resetState;
Tstate <= resetState;
TnextState <= resetState;

pulse2state <= beginState;
pulse1state <= record2State;
pulse1 <= record2State;
pulse2 <= beginState;

OnRatio <= 7'd1;
OffRatio <= 7'd2;

highVoltageSum<=12'd0;
end


//assign GPIO_0  		=	36'hzzzzzzzz;
//assign GPIO_1  		=	36'hzzzzzzzz;



DE0_80MHZ u1 (//generates the 80Mhz clock signal used in the program
	.ref_clk_clk        (FPGA_CLK1_50),        //      ref_clk.clk
	.ref_reset_reset    (KEY_NOT),    //    ref_reset.reset
	.sys_clk_clk        (CLOCK_80MHZ),        //      sys_clk.clk
	.reset_source_reset (RESET_80MHZ)  // reset_source.reset
);


//=======================================================
//collect the ADC values on the desired channels. We are using CH0 and CH1
//======================================================= 
ADC_LTC u0 (
	 .ADC_SCLK  (ADC_SCK),  // adc_signals.SCLK
	 .ADC_CS_N  (ADC_CONVST),  //            .CS_N
	 .ADC_SDAT  (ADC_SDO),  //            .SDAT
	 .ADC_SADDR (ADC_SDI), //            .SADDR
	 .CLOCK     (CLOCK_80MHZ),     //         clk.clk
	 .CH0       (CHAN[0]),       //    readings.CH0
	 .CH1       (CHAN[1]),       //            .CH1
	 .CH2       (CHAN[2]),       //            .CH2
	 .CH3       (CHAN[3]),       //            .CH3
	 .CH4       (CHAN[4]),       //            .CH4
	 .CH5       (CHAN[5]),       //            .CH5
	 .CH6       (CHAN[6]),       //            .CH6
	 .CH7       (CHAN[7]),		  //            .CH7
	 .done      (done),
	 .RESET     (KEY_NOT)      //       reset.reset
);

//=======================================================
// Determine The Envelope from Demodulated I and Q values
//======================================================= 
SQUARER	SQUARER_inst1 (//Square I value
	.dataa ( CHAN[0]),
	.result ( RESULT_CHAN[0] )
	);
	
SQUARER SQUARER_inst2(//Square Q value
	.dataa ( CHAN[1] ),
	.result ( RESULT_CHAN[1] )
	);
	
assign I_PLUS_Q = RESULT_CHAN[0] + RESULT_CHAN[1];

SQRT	SQRT_inst (//determines the sum of the two phases. Envelope= sqrt(I^2+Q^2)
	.radical ( I_PLUS_Q ),
	.q ( IQvalue ),
	.remainder ( IQRemainder )
	);

	
//=======================================================
// For sending Values to HPS 
//=======================================================
always@(posedge CLOCK_80MHZ)
begin
	if(TrigTime> (meanTriggerOffset - 18'd1600) && TrigTime<(meanTriggerOffset + PvalleyAveraging [Pdatanum] + 18'd1600) && dataReady)
		DataGo =1;//In region where we want to record ADC values
	else
		DataGo =0;//In region where we dont want to record ADC values

	if(done)
	begin
		ADCTimeR <= TrigTime;
		if(TrigTime> (meanTriggerOffset - 18'd1600) && TrigTime<(meanTriggerOffset +  PvalleyAveraging [Pdatanum] + 18'd1600) && dataReady)
			valleyRecord = 1;
		else
			valleyRecord = 0;
	end
	else
		valleyRecord = 0;
end
assign ADCTime = ADCTimeR;
assign currentTrigOffset = triggerOffset[datanum];

//=======================================================
//  conditions for different outputs. Mainly for FPGA program analysis
//=======================================================
always@(posedge CLOCK_80MHZ)
    begin
      case (SW)
		0:LEDr =	KEY[1]? {CHAN[0][11:4]}:8'hff;
		1:LEDr = KEY[1]? {CHAN[1][11:4]}:8'hff;
		2:LEDr = KEY[1]? {IQvalue[11:4]}:8'hff;
		3:LEDr =	KEY[1]? {IQvalue[7:0]}:8'hff;
		4:LEDr =	KEY[1]? {CHAN[0][7:0]}:8'hff;
		5:LEDr =	KEY[1]? {Tstate}:8'hff;//If LED's show 4 or 5 (0100 or 0101), the system is in an error state
		6:LEDr =	KEY[1]? {Pstate}:8'hff;
		7:LEDr =	KEY[1]? {state}:8'hff;
		8:begin
		//	runTrigger =1'b1;
		LEDr= KEY[1]? {DataGo}:8'hff;
		end
		9:LEDr =	KEY[1]? {error}:8'hff;
		default:begin
		LEDr = 8'hff;
		end
		endcase
    end
	 
assign LED = LEDr;
//assign GPIO_0[2] = CLOCK_80MHZ;



always@(posedge CLOCK_80MHZ)//state change logic for state conditions
begin
	if(errorReset)//If an error has been cleared, reset
	begin
		state <= resetState;
		Pstate <= resetState;
		Tstate <= resetState;
	end
	else
	begin
		state <= nextState;
		Pstate <= PnextState;
		Tstate <= TnextState;
	end
end




//***********************PULSER SIGNAL ANALYSIS****************************


//=========================================================
// State conditions for Pulser signal.
//=========================================================

always @(*)
begin
		if(USE1VM4)
		pulserSignal <= GPIO_0[0];
		else
		pulserSignal <= signal1;// for testing in absence of real pulser signal
		
		case(Pstate)
		resetState:begin
			PcountValley=0;
			PcountPulse=0;
			PcountPulseStart=0;
			PcountValleyStart=0;
			if(pulserSignal)
				PnextState = beginHighState;
			else
				PnextState = resetState;
		end
		beginHighState:begin
			PcountValley=0;
			PcountPulse=0;
			PcountPulseStart=0;
			PcountValleyStart=0;
			if(pulserSignal)
				PnextState = beginHighState;
			else if(state == beginHighState)
				PnextState = beginState;
			else
				PnextState = beginHighState;
		end
		beginState:begin//the reason for this state is to have the signal go from low to high before beginning the recording
			PcountValley=0;
			PcountPulse=0;
			PcountValleyStart=0;
			if(pulserSignal)
				begin
				PnextState = record1State;
				PcountPulseStart=1;//if pulser signal goes high, begin recording the pulse (aka beam on)
				end
			else
			begin
				PcountPulseStart=0;
				PnextState = beginState;
			end
		end
		record1State:begin
			PcountValley=0;
			PcountPulse=1;
			PcountPulseStart=0;
			if(pulserSignal==1'b0)
			begin
				PnextState = record2State; //if pulser signal goes low, switch to recording the valley
				PcountValleyStart=1;
			end
			else
			begin
				PnextState = record1State;
				PcountValleyStart=0;
			end
		end
		record2State:begin
			PcountValley=1;
			PcountPulse=0;
			PcountValleyStart=0;
			if(pulserSignal)
			begin
				PnextState = record1State;//if pulser signal goes high, switch to recording the pulse (aka beam on)
				PcountPulseStart=1;
			end
			else
			begin
				PnextState = record2State;
				PcountPulseStart=0;
			end
		end
		default:begin
			PcountValley=0;
			PcountPulse=0;
			PnextState = resetState;
		end
		endcase
end



//=======================================================
//counter for the valley time interval of the Pulser signal(beam OFF)
//=======================================================
always@(posedge CLOCK_80MHZ)
begin
	if(PcountValleyStart==1||(Pstate == resetState))
		PvalleySize <= 14'd1;
	else if(PcountValley==1)
		PvalleySize <= PvalleySize + 14'd1;
end


//=======================================================
//counter for the pulse time interval of the Pulser signal(beam ON)
//=======================================================

always@(posedge CLOCK_80MHZ)
begin
	if(PcountPulseStart==1||(Pstate == resetState))
		PpulseSize <= 18'd1;
	else if(PcountPulse==1)
		PpulseSize <= PpulseSize + 18'd1;
end

//

//=======================================================
//gathering data for creating a moving average of last 32 values
//=======================================================

 integer i;
always@(posedge CLOCK_80MHZ)
begin
	//=======================================================
	//for writing to array of time values
	//=======================================================
	if(state == resetState)
	begin
		for (i=0; i<32; i=i+1) 
		begin
			PvalleyAveraging[i] <= 14'd0;
			PpulseAveraging[i] <= 18'd0;
		end
		Pperiod <= 0;
	end
	else if(PwriteValleySum) 
		begin
			PvalleyAveraging [Pdatanum] <= PvalleySize - 14'd1;
			Pperiod <= PpulseAveraging [Pdatanum] + PvalleySize - 14'd1;
			PwriteValleySum <= 1'b0; 
		end
	else if(PwritePulseSum)
		begin
			PpulseAveraging [Pdatanum] <= PpulseSize - 18'd1;
			PwritePulseSum <= 1'b0;
		end
		
	//=======================================================
	//Determine if all parts of the array are non-zero
	//=======================================================	
	if((PvalleyAveraging[31] > 18'd10)&& Pstate != resetState)
		PdataReady <= 1'b1;//All parts of the array have a value. can begin the mean calulation
	else
		PdataReady <= 1'b0;
		
	//=======================================================
	//Calculate the mean Period
	//=======================================================	
	if(PwritePulseSum && error == 0)
	begin
		PmeanPeriod <= PsumAveraging[23:5];//because there are 2^5 data points, the mean Period is just this value, truncated to nearest pulse.
	end
		
	//=======================================================
	//for incrementing array of time values
	//=======================================================
	if(Pstate == resetState)
		Pdatanum <= 6'd32;
	else if((Pdatanum==6'd31 || Pdatanum==6'd32) && PcountValleyStart)
	begin
		Pdatanum <= 6'd0;
	end
	else if (PcountValleyStart)
		Pdatanum <= Pdatanum + 6'd1;
		
	//=======================================================
	//for calculating the sum of the last 32 cycles 
	//=======================================================	
	if (Pstate == resetState)
		PsumAveraging <=24'd0;
	else if(PcountPulseStart && (Pdatanum < 6'd32))// for simplicity, the number of data points is 2^5. This way shift register can be used instead of a divide circuit
	begin
		PwriteValleySum <= 1'b1;
		if(PdataReady)
			PsumAveraging <= PsumAveraging + PvalleySize - PvalleyAveraging [Pdatanum];
		else
			PsumAveraging <= PsumAveraging + PvalleySize;
	end
	else if(PcountValleyStart && (Pdatanum < 6'd32))
	begin
		PwritePulseSum <= 1'b1;
		if(PdataReady && Pdatanum==6'd31)
		begin
			PsumAveraging <= PsumAveraging + PpulseSize - PpulseAveraging [6'd0];
		end
		else if(PdataReady)
		begin
			PsumAveraging <= PsumAveraging + PpulseSize - PpulseAveraging [(Pdatanum + 6'd1)];
		end
		else
			PsumAveraging <= PsumAveraging + PpulseSize;
	end
end

//***********************ADC SIGNAL ANALYSIS**********************

// This section is very similar to pulser analysis, but is a bit more complex. It is better to understand the pulser logic before reading this section
//It also includes some of the logic for calculating the trigger offset

//=======================================================
// State conditions for the measurment of the ADC pulse signal.
// Determines if ADC value is above a threshold, and sets the state accordingly.
//=======================================================
always @(*)
begin
		ADCsignal <= signal2;//This assignment is for testing only.
		
		case(state)
		resetState:begin
			countValley=0;
			countPulse=0;
			countValleyStart=0;
			switchStates=0;
			countPulseStart=0;
			if(((USE1VM4==0 && ADCsignal==0)||(USE1VM4 && IQvalue<meanHighVoltage[11:2])))
			begin
				switchStates=1;
				if(countRealSwitch == 14'd500)
				begin
					nextState = beginLowState;
				end
				else
				begin
					nextState = resetState;
				end
			end
			else
			begin
				nextState = resetState;
				switchStates=0;
			end
		end
		beginLowState:begin
			countValley=0;
			countPulse=0;
			countPulseStart=0;
			countValleyStart=0;
			if((USE1VM4==0 && ADCsignal)||(USE1VM4 && IQvalue>meanHighVoltage[11:2]))
			begin
			switchStates=1;
				if(countRealSwitch == 14'd500)
				begin
					nextState = beginHighState;
				end
				else
				begin
					nextState = beginLowState;
				end
			end
			else
			begin
				nextState = beginLowState;
				switchStates=0;
			end
		end
		beginHighState:begin
			countValley=0;
			countPulse=0;
			countPulseStart=0;
			countValleyStart=0;
			if((USE1VM4==0 && ADCsignal==0)||(USE1VM4 && IQvalue<meanHighVoltage[11:2]))
			begin
				switchStates=1;
				if(countRealSwitch == 14'd500)
				begin
					if(Pstate == record1State)
					nextState = beginState;
				end
				else
				begin
					nextState = beginHighState;
				end
			end
			else
			begin
				nextState = beginHighState;
				switchStates=0;
			end
		end
		beginState:begin//the reason for this state is to have the signal go from low to high before beginning the recording
			countValley=0;
			countPulse=0;
			countValleyStart=0;
			if(((USE1VM4==0 && ADCsignal)||(USE1VM4 && IQvalue>meanHighVoltage[11:2])) && (Pstate==record1State))// if beam is above a certain threshold, start counting the beam on time. Also wait until the pulsar signal has begun counting
			begin
				switchStates=1;
				if(countRealSwitch == 14'd500)//buffer to make sure there was an actual switch occuring
				begin
					nextState = record1State;
					countPulseStart=1;
				end
				else
				begin
					nextState = beginState;
					countPulseStart=0;
				end
			end
			else
			begin
				switchStates=0;
				nextState = beginState;
				countPulseStart=0;
			end
		end
		record1State:begin
			countValley=0;
			countPulse=1;
			countPulseStart=0;
			if((USE1VM4==0 && ADCsignal==0)||(USE1VM4 && IQvalue<meanHighVoltage[11:2]))//if IQ value falls below certain threshold, switch to recording the valley
			begin
				switchStates=1;
				if(countRealSwitch == 14'd500)
				begin
				nextState = record2State; //if IQ value goes below certain threshold (1/4 full beam) for more than 6.25us, switch to recording valley
				countValleyStart=1;
				end
				else
				begin
					nextState = record1State;
					countValleyStart=0;
				end
			end
			else
			begin
				switchStates=0;
				nextState = record1State;
				countValleyStart=0;
			end
		end
		record2State:begin
			countValley=1;
			countPulse=0;
			countValleyStart=0;
			if((USE1VM4==0 && ADCsignal)||(USE1VM4 && IQvalue>meanHighVoltage[11:2]))
			begin
				switchStates=1;
				if(countRealSwitch == 14'd500)//buffer to make sure there was an actual switch occuring
				begin
				nextState = record1State;
				countPulseStart=1;//if IQ value goes above certain threshold, switch to recording pulse
				end
				else
				begin
					nextState = record2State;
					countPulseStart=0;
				end
			end
			else
			begin
				switchStates=0;
				nextState = record2State;
				countPulseStart=0;
			end
		end
		default:begin
			countValley=0;
			countPulse=0;
			nextState = resetState;
		end
		endcase
end

//=======================================================
//counter for the valley time interval of the ADC signal(beam OFF)
//=======================================================
always@(posedge CLOCK_80MHZ)
begin
	if(countValleyStart==1||(state == resetState))
		valleySize <= 14'd1;//reset the Valley counter
	else if(countValley==1)
		valleySize <= valleySize + 14'd1;//increment valley counter every clock cycle
end

//=======================================================
//counter for the pulse time interval of the ADC signal(beam ON)
//=======================================================

always@(posedge CLOCK_80MHZ)
begin
	if(countPulseStart==1||(state == resetState))
		pulseSize <= 18'd1;//reset the pulser counter
	else if(countPulse==1)
		pulseSize <= pulseSize + 18'd1;//increment pulser counter every clock cycle
end

always@(posedge CLOCK_80MHZ)//buffer so system doesnt detect a false pulse if ADC spikes for a short time
begin
	if(errorReset||switchStates==0)
		countRealSwitch <= 14'd0;
	else if(switchStates==1)
		countRealSwitch <= countRealSwitch + 14'd1;
end

//=======================================================
//gathering data for creating a moving average of last 32 values
//=======================================================
integer j;

always@(posedge CLOCK_80MHZ)
begin
	//=======================================================
	//for writing to array of time values
	//=======================================================
	if(state == resetState)
	begin
		for (j=0; j<32; j=j+1) 
		begin
			valleyAveraging[j] <= 14'd0;
			pulseAveraging[j] <= 18'd0;
			triggerOffset[j] <= 18'd0;
		end
		period <= 0;
	end
	else if(writeValleySum) 
		begin
			valleyAveraging [datanum] <= valleySize - 14'd1;
			period <= pulseAveraging [datanum] + valleySize - 14'd1;
			writeValleySum <= 1'b0; 
		end
//	else if(writePulseSum && datanum==6'd0)
//		begin
//			pulseAveraging [31] <= pulseSize - 18'd1;
//			writePulseSum <= 1'b0;
//		end
	else if(writePulseSum)
		begin
			pulseAveraging [datanum] <= pulseSize - 18'd1;
			writePulseSum <= 1'b0;
			if(PcountPulse)
				triggerOffset [datanum] <= PpulseSize - 18'd501 + PvalleyAveraging[Pdatanum];
			else
				triggerOffset [datanum] <= PvalleySize - 18'd501;
		end
		
	//=======================================================
	//Determine if all parts of the array are non-zero
	//=======================================================
	if(valleyAveraging[31] > 18'd100 && state != resetState)
		dataReady <= 1'b1;//All parts of the array have a value. can begin the mean calulation
	else
		dataReady <= 1'b0;
		
	//=======================================================
	//Calculate the mean Period from pulser signal
	//=======================================================	
	if(writePulseSum && error == 0)
	begin
		meanPeriod <= sumAveraging[23:5];//because there are 2^5 data points, the mean Period is just this value, truncated to nearest pulse.
	end
	
	//=======================================================
	//Calculate the mean trigger offset
	//=======================================================	
	if(dataReady && PdataReady && writeValleySum && error == 0)
	begin 
		meanTriggerOffset <= triggerSum[22:5];//if enough data has been gathered, output the mean trigger offset value
	end
	
	if(dataReady && PdataReady && writePulseSum)//for gathering data about when the KTM would have triggered
		wouldHaveTriggeredAt <= meanTriggerOffset;
	
	//=======================================================
	//for incrementing array of time values. cycles through from 0 to 31
	//=======================================================
	if(state == resetState)
		datanum <= 6'd32;
	else if((datanum==6'd31 || datanum==6'd32) && countValleyStart)
	begin
		datanum <= 6'd0;
	end
	else if (countValleyStart)
		datanum <= datanum + 6'd1;
		
	//=======================================================
	//for calculating the sum of the last 32 cycles 
	//=======================================================
	if(state == resetState)
	begin
		sumAveraging <= 24'd0;
		triggerSum <= 24'd0;
	end
	else if(countPulseStart && (datanum < 6'd32))// for simplicity, the number of data points is 2^5. This way shift register can be used instead of a divide circuit
	begin
		writeValleySum <= 1'b1;
		if(dataReady)// if sum averaging allready has 32 values, subtract oldest value and add new value
			sumAveraging <= sumAveraging + valleySize - valleyAveraging [datanum];
		else
			sumAveraging <= sumAveraging + valleySize;
	end
	else if(countValleyStart && (datanum < 6'd32))
	begin
		writePulseSum <= 1'b1;
		if(dataReady && datanum==6'd31)
		begin
			if(PcountPulse)
			begin
				triggerSum <= triggerSum + PpulseSize + PvalleyAveraging[Pdatanum] - triggerOffset[6'd0] - 24'd500;
			end
			else
			begin
				triggerSum <= triggerSum + PvalleySize - triggerOffset[6'd0] - 24'd500;
			end
		end
		else if (dataReady)
		begin
			if(PcountPulse)
			begin
				triggerSum <= triggerSum + PpulseSize + PvalleyAveraging[Pdatanum] - triggerOffset[datanum + 6'd1] - 24'd500;
			end
			else
			begin
				triggerSum <= triggerSum + PvalleySize - triggerOffset[datanum + 6'd1] - 24'd500;
			end
		end
		else
		begin
			if(PcountPulse)
			begin
				triggerSum <= triggerSum + PpulseSize + PvalleyAveraging[Pdatanum] - 24'd500;
			end
			else
			begin
				triggerSum <= triggerSum  + PvalleySize - 24'd500;
			end
		end
		
		
		if(dataReady && datanum==6'd31)
		begin
			sumAveraging <= sumAveraging + pulseSize - pulseAveraging [6'd0];
		end
		else if(dataReady)
		begin
			sumAveraging <= sumAveraging + pulseSize - pulseAveraging [(datanum + 6'd1)];
		end
		else
		begin
			sumAveraging <= sumAveraging + pulseSize;
		end
	end
end




//***********************Trigger output logic****************************


//=========================================================
// State conditions for Trigger signal.
//=========================================================

always @(*)
begin
	case(Tstate)
	resetState:begin
		errorReset=0;
		TriggerSignal=1'b0;
		TnextState=beginState;
	end
	
	beginState:begin
		TriggerSignal=1'b0;
		if(error)
		begin
			TnextState=errorLowState;
		end
		else if(dataReady && PdataReady)
		begin
			TnextState=KickerOffState;
		end	
		else
			TnextState=beginState;
	end
	
	KickerOnState:begin
		TriggerSignal=1'b1;
		//turnON=0;
		if(error)
			TnextState=errorHighState;
		else if(turnOFF)
		begin
			TnextState=KickerOffState;
		end
		else
			TnextState=KickerOnState;
	end
	
	KickerOffState:begin
		TriggerSignal=1'b0;
	//	turnOFF=0;
		if(error)
			TnextState=errorLowState;
		else if(turnON)//if(BeamOn && turnON)
		begin
				TnextState=KickerOnState;
		end
		else
			TnextState=KickerOffState;
	end
	errorLowState:begin
		TriggerSignal=1'b0;
		if(errorMessageComplete)
		begin
			TnextState = resetState;
			errorReset=1;
		end
		else
		begin
			TnextState = errorLowState;
			errorReset=0;
		end
		
	end
	errorHighState:begin
	TriggerSignal=1'b1;	
	if(errorClockSize >= 18'd160000)//wait for 2ms. If no ramp down time can be determined in that time, ramp down.
		TnextState = errorLowState;
	else if(errorSwitch==0 && errorCounter1 == (meanTriggerOffset + PmeanPeriod))
		TnextState = errorLowState;
	else if(errorSwitch==1 && errorCounter2 == (meanTriggerOffset + PmeanPeriod))
		TnextState = errorLowState;
	else
		TnextState = errorHighState;
	end
	default:begin
			TriggerSignal=1'b0;
			TnextState = resetState;
	end
	endcase
end

always@(posedge CLOCK_80MHZ)
begin
	if(Tstate == errorHighState)
		errorClockSize <= errorClockSize + 18'd1;
	else 
		errorClockSize <= 18'd0;
end

//=========================================================
// determining the switiching for ratio of pulses ON vs OFF
//=========================================================

always@(posedge CLOCK_80MHZ)
begin
	if(PcountPulse)//calculates time since last trigger
	TrigTime <= PvalleyAveraging [Pdatanum] + PpulseSize;
	else if(PcountValley)
	TrigTime <= PvalleySize;
	
	if(state==resetState)
	begin
		switchCount<=7'd1;
		turnOFF <= 1'b0;
		turnON <= 1'b0;
		Tdatanum <= 6'd4;
	end
	else if(( TrigTime == meanTriggerOffset) && dataReady && PdataReady && ((Tdatanum == 6'd31 && Pdatanum == 6'd0)||((Tdatanum + 6'd1) == Pdatanum)))
	begin
		if((switchCount == OffRatio) && (Tstate == KickerOffState))
		begin
			switchCount <= 7'd1;
			turnON <= 1'b1;
		end
		else if((switchCount == OnRatio) && (Tstate == KickerOnState))
		begin
			switchCount <= 7'd1;
			turnOFF <= 1'b1;
		end
		else
		begin
			switchCount <= switchCount + 7'd1;
			turnOFF <= 1'b0;
			turnON <= 1'b0;
		end
		if(Tdatanum == 6'd31)
			Tdatanum <= 6'd0;
		else
			Tdatanum <= Tdatanum + 6'd1;
		
	end
	else
	begin
		turnOFF <= 1'b0;
		turnON <= 1'b0;
	end
end



//=========================================================
// determining the average voltage value when beam is high
//=========================================================

always@(posedge CLOCK_80MHZ)
begin
	if(errorReset)
		highVoltageSum <= 12'd0;
	else
	begin
		if(dataReady==0)
		begin
			if (done && countHV<80 && IQvalue>meanHighVoltage[11:2])
			begin
				if(countHV<16)
					countHV <= countHV + 7'b1;
				else
				begin
					highVoltageSum <= highVoltageSum + IQvalue;
					countHV <= countHV + 7'b1;
				end
			end
			else if(IQvalue<meanHighVoltage[11:2])
			begin
				countHV <= 7'b0;	
				highVoltageSum <= 19'd0;
			end
			else if(countHV==80)
			begin
				meanHighVoltage <= highVoltageSum [17:6];
			end
		end
		
		else if(dataReady)
		begin
			if(TrigTime> (meanTriggerOffset + 18'd30000) && done)
			begin
				if(countHV<16)
				begin
					countHV <= countHV + 7'd1;
					highVoltageSum <= 18'd0;
				end
				else if(countHV==80)
				begin
					meanHighVoltage <= highVoltageSum [17:6];
					countHV <= 7'd0;
				end
				else
				begin
					highVoltageSum <= highVoltageSum + IQvalue;
					countHV <= countHV + 7'd1;
				end	
			end
		end
	end
end

//=========================================================
// determining the average voltage value when beam is low, during a specific intreval
//=========================================================

always@(posedge CLOCK_80MHZ)
begin
	if(dataReady)
	begin
		if(TrigTime> (meanTriggerOffset + 18'd1000) && TrigTime<(meanTriggerOffset + 18'd3000))
		begin
			if(done)
			begin
				lowVoltageSum <= lowVoltageSum + IQvalue;
				countLV <= countLV + 7'd1;
			end
		end
		else if(TrigTime == (meanTriggerOffset + 18'd3000))
			meanLowVoltage <= lowVoltageSum/countLV;//this will cause remainders that might make this value not as accurate. should cross check with HPS data
		else
		begin
			lowVoltageSum <= 12'd0;
			countLV <= 7'd0;
		end
	end
end

//=========================================================
// conditions that cause an error
//=========================================================

always@(posedge CLOCK_80MHZ)
begin
	
	if(KickerOnCounter>(20'd100000*OnRatio))
	begin//if the kicker is on for longer than it should be, give an error
		error <= 1'b1;
		errorType <=6'd1;
	end
	else if((OffRatio/OnRatio)<7'd2)
	begin//if ratio of beam on vs off is too large, give an error
		error <= 1'b1;
		errorType <=6'd2;
	end
	else if(PdataReady && (PvalleyAveraging [Pdatanum] < 14'd3900))
	begin//If valley is smaller than 48.75us, give an error
		error <= 1'b1;
		errorType <=6'd3;
	end
	else if(PdataReady && (PmeanPeriod > 19'd112000))
	begin//If mean period is larger than 1.4ms, give an error
		error <= 1'b1;
		errorType <=6'd4;
	end
	else if(PdataReady && (Pperiod > 19'd112000))
	begin//If last period was larger than 1.4ms, give an error
		error <= 1'b1;
		errorType <=6'd5;
	end
	else if(PdataReady && (PmeanPeriod < 19'd64000))
	begin//If mean period is smaller than 0.8ms, give an error
		error <= 1'b1;
		errorType <=6'd6;
	end
	else if(PdataReady && (Pperiod < 19'd64000))
	begin//If last period was smaller than 0.8ms, give an error
		error <= 1'b1;
		errorType <=6'd7;
	end
	else if(dataReady && valleyAveraging [datanum] < 14'd3000)
	begin//If valley is smaller than 37.5us, give an error
		error <= 1'b1;
		errorType <=6'd8;
	end
	else if(dataReady && (period < 19'd64000))
	begin//If last period was smaller than 0.8ms, give an error
		error <= 1'b1;
		errorType <=6'd9;
	end
	else if(dataReady && (period > 19'd112000))
	begin//If last period was larger than 1.4ms, give an error
		error <= 1'b1;
		errorType <=6'd10;
	end
	else if(valleySize > 14'd12000)
	begin//if valley is larger than 150us, give an error
		error <= 1'b1;
		errorType <=6'd11;
	end
	else if(pulseSize > 18'd100000)
	begin//if pulse is larger than 1.25ms,give an error
		error <= 1'b1;
		errorType <=6'd12;
	end
	else if(PvalleySize > 14'd12000)
	begin//if valley is larger than 150us, give an error
		error <= 1'b1;
		errorType <=6'd13;
	end
	else if(PpulseSize > 18'd100000)
	begin//if pulse is larger than 1.25ms,give an error
		error <= 1'b1;
		errorType <=6'd14;
	end
	else if((datanum + 6'd1 != Pdatanum) && (datanum != Pdatanum) && ((datanum == 6'd32 || datanum == 6'd31) && (Pdatanum != 6'd0)))
	begin//if tigger pulses are misaligned
		error <= 1'b1;
		errorType <=6'd15;
	end
	else if(errorFlag)
	begin
		error <= 1'b1;
		errorType <=6'd16;
	end
	else if(errorReset == 1 || state==resetState)
	begin
		error <= 1'b0; 
		errorType <=6'd0;
	end
end

always@(posedge CLOCK_80MHZ)
begin
	if (Tstate==KickerOnState)//failsafe counter so the kicker doesn't remain on for too long
		KickerOnCounter <= KickerOnCounter + 20'd0;
	else
		KickerOnCounter <= 20'd0;
end

always@(posedge CLOCK_80MHZ)
begin//these counters are allways running so that if there is an error, the program can look at the last good pulser falling edge and base its decision off of that
	if(PcountValleyStart == 1 && error == 0)
	begin
		if(errorSwitch==0)
		begin
			errorCounter1 <= 19'd1;
			errorSwitch=1;
		end
		else
		begin
			errorCounter2 <= 19'd1;
			errorSwitch=0;
		end
	end
	else
	begin
		errorCounter1 <= errorCounter1 + 19'd1;
		errorCounter2 <= errorCounter2 + 19'd1;
	end
end


//TEST!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//This section generates Signals to act as the 1VM4 and pulser signals in absence of them. It is used to test the programming logic
//To use these signals, 'assign USE1VM4 = 1'b0;'
//To use the real signals, 'assign USE1VM4 = 1'b1;'
reg signal1,signal2;
reg [3:0] pulse1state;
reg [3:0] pulse2state;
reg [3:0] pulse1;
reg [3:0] pulse2;
reg resetsig1,resetsig2;
reg [16:0] counter1;
reg [16:0] counter2;
always @(*)
begin
	case(pulse1)
	record1State:begin
		signal1 = 0;
		if (counter1 == 17'd80000)
		begin
			resetsig1 = 1;
			pulse1state = record2State;
		end
		else
		begin
			pulse1state = record1State;
			resetsig1 = 0;
		end
	end
	record2State:begin
		signal1 = 1;
		resetsig1 = 0;
		if(counter1 == 17'd72000)
		begin
			pulse1state = record1State;
		end
		else
			pulse1state = record2State;
	end
	default:begin
		pulse1state = record2State;
	end
	endcase
end
always @(*)
begin
	case(pulse2)
	beginState:begin
	signal2 = 0;
	if( counter1 == 17'd16000)
	begin
	resetsig2 = 1;
	pulse2state = record2State;
	end
	
	else
	begin
	pulse2state = beginState;
	resetsig2 = 0;
	end
	
	end
	record1State:begin
	signal2 = 0;
	if (counter2 == 17'd80000)
	begin
	resetsig2 = 1;
	pulse2state = record2State;
	end
	else
	begin
	pulse2state = record1State;
	resetsig2 = 0;
	end
	end
	record2State:begin
	signal2 = 1;
	resetsig2 = 0;
	if(counter2 == 17'd72000)
	begin
	pulse2state = record1State;
	end
	else
	pulse2state = record2State;
	end
	default:begin
	pulse2state = beginState;
	end
	endcase
end

always@(posedge CLOCK_80MHZ)
begin
pulse1 <= pulse1state;
pulse2 <= pulse2state;

if(resetsig1)
counter1 <= 17'd0;
else
counter1 <= counter1 + 17'd1;

if(resetsig2)
counter2 <= 17'd0;
else
counter2 <= counter2 + 17'd1;
end

//testSignals testSignals_inst (//generates singals to act as 1VM4 and pulser signals. For testing the program only.
// .signalW1 (signalW1),
// .signalW2 (signalW2),
// .USE1VM4 (USE1VM4),//to use these test signals instead of real signals, set "USE1VM4 <= 1'b0;" in the initial block of this file
// .CLOCK_80MHZ (CLOCK_80MHZ)
//);

//always@(posedge CLOCK_80MHZ)
//    begin
//	 signal1 <= signalW1;
//	 signal2 <= signalW2;
//	 end


//TEST END!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

always@(*)
begin
	if(RESET_80MHZ)
	begin
		TriggerOut = 0;
		errorFlag = 1;
	end
	else if(error && errorType == 6'd16)
	begin
		errorFlag = 0;
		TriggerOut = 0;
	end
	else if(USE1VM4)
	begin
		TriggerOut = TriggerSignal;
	end
	else
	begin
		TriggerOut = 0;
	end
 end
 

assign GPIO_1 = {error,3'b000,RESET_80MHZ,3'b000,signal1,3'b000,signal2,3'b000,TriggerSignal,1'b0};//for probing the program functionality
assign GPIO_0[35:1] = {30'hzzzzzzzzz,TriggerOut,4'hzzzz};
//assign LED[0]=(CHAN[0]>COMPARE);Tstate

//assign LED[1]=(CHAN[0]<COMPARE);

//assign LED[2] = SW[0];
//assign LED = KEY[1]? {(CHAN0>COMPARE),(CHAN0<COMPARE),6'd0}:8'hff

//======================================================================================
//----------------------------------THINGS TO DO----------------------------------------
//======================================================================================
//I need to change the ADC implementation to take in a differential signal.

//then I need to figure out how to determine what % of the puse on determines a kick start.

//also I should test the IQ and this program to see the performance
//I need to verify that the buffer on ADC switching states doesnt cause issues.

//**For making into a trigger generator**
//I need figure out how we are going to edit the ratio of on vs off. (maybe through gpio and another board, or with the HPS


//could edit error ramping
	//some conditions would include: 
	// - the pulse cycle perviously did not make sense, so start a counter based off the clock cycle before that one and ramp accordingly.
	// - the pulse previously did make sense, but now there is no signal. example is maybe the cyclotron turned off? so count based off of the last pulse falling edge.
	// - the 1VM4 signal is messed up, but the pulser signal is fine. This could be an demoulator issue, or adc issue. So just base the ramp down off the pulse signal with a preset offset.	



endmodule