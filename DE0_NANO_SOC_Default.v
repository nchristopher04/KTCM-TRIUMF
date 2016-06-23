//--==========---=========---==========---==--------==---====--------====---==========--
//------==-------==-----==-------==-------==--------==---==-==------==-==---==----------
//------==-------==----==--------==-------==--------==---==--==----==--==---==----------
//------==-------======----------==-------==--------==---==---==--==---==---=======-----
//------==-------==---==---------==-------==--------==---==----====----==---==----------
//------==-------==----==--------==--------==------==----==-----==-----==---==----------
//------==-------==-----==---==========------======------==-----==-----==---==----------

//This program was created in June 2016 By Nicholas Christopher - UCN group
//
//The Function of this program is to create a trigger signal to send to UCN's Kicker Power Supply
//
//It requires as inputs:
//-beam intensity signal from 1VM4, and a pulse signal from the cyclotron.
//-a Safety interrupt signal.
//-signals defining the ratio of kicker on vs off, and a signal to say when to run the kicker.
//
//It outputs the trigger signal.
//
//
//This program was intended for use with a DE0 nano board from Terasic.com

//=======================================================
//  PIN declarations
//=======================================================

//`define ENABLE_HPS
module DE0_NANO_SOC_Default(

	//////////// ADC //////////
	output		          		ADC_CONVST,
	output		          		ADC_SCK,
	output		          		ADC_SDI,
	input 		          		ADC_SDO,
	//////////// CLOCK //////////
	input 		          		FPGA_CLK1_50,
	input 		          		FPGA_CLK2_50,
	input 		          		FPGA_CLK3_50,
	
`ifdef ENABLE_HPS
	//////////// HPS //////////
	inout 		          		HPS_CONV_USB_N,
	output		    [14:0]		HPS_DDR3_ADDR,
	output		     [2:0]		HPS_DDR3_BA,
	output		          		HPS_DDR3_CAS_N,
	output		          		HPS_DDR3_CK_N,
	output		          		HPS_DDR3_CK_P,
	output		          		HPS_DDR3_CKE,
	output		          		HPS_DDR3_CS_N,
	output		     [3:0]		HPS_DDR3_DM,
	inout 		    [31:0]		HPS_DDR3_DQ,
	inout 		     [3:0]		HPS_DDR3_DQS_N,
	inout 		     [3:0]		HPS_DDR3_DQS_P,
	output		          		HPS_DDR3_ODT,
	output		          		HPS_DDR3_RAS_N,
	output		          		HPS_DDR3_RESET_N,
	input 		          		HPS_DDR3_RZQ,
	output		          		HPS_DDR3_WE_N,
	output		          		HPS_ENET_GTX_CLK,
	inout 		          		HPS_ENET_INT_N,
	output		          		HPS_ENET_MDC,
	inout 		          		HPS_ENET_MDIO,
	input 		          		HPS_ENET_RX_CLK,
	input 		     [3:0]		HPS_ENET_RX_DATA,
	input 		          		HPS_ENET_RX_DV,
	output		     [3:0]		HPS_ENET_TX_DATA,
	output		          		HPS_ENET_TX_EN,
	inout 		          		HPS_GSENSOR_INT,
	inout 		          		HPS_I2C0_SCLK,
	inout 		          		HPS_I2C0_SDAT,
	inout 		          		HPS_I2C1_SCLK,
	inout 		          		HPS_I2C1_SDAT,
	inout 		          		HPS_KEY,
	inout 		          		HPS_LED,
	inout 		          		HPS_LTC_GPIO,
	output		          		HPS_SD_CLK,
	inout 		          		HPS_SD_CMD,
	inout 		     [3:0]		HPS_SD_DATA,
	output		          		HPS_SPIM_CLK,
	input 		          		HPS_SPIM_MISO,
	output		          		HPS_SPIM_MOSI,
	inout 		          		HPS_SPIM_SS,
	input 		          		HPS_UART_RX,
	output		          		HPS_UART_TX,
	input 		          		HPS_USB_CLKOUT,
	inout 		     [7:0]		HPS_USB_DATA,
	input 		          		HPS_USB_DIR,
	input 		          		HPS_USB_NXT,
	output		          		HPS_USB_STP,
`endif /*ENABLE_HPS*/

	//////////// KEY //////////
	input 		     [1:0]		KEY,

	//////////// LED //////////
	output		     [7:0]		LED,

	//////////// SW //////////
	input 		     [3:0]		SW,

	//////////// GPIO_0, GPIO connect to GPIO Default //////////
	inout 		    [35:0]		GPIO_0,

	//////////// GPIO_1, GPIO connect to GPIO Default //////////
	output 		    [35:0]		GPIO_1
);

wire [11:0] CHAN0 ;
wire [11:0] CHAN [0:7];
wire CLOCK_80MHZ;
wire KEY_NOT;
wire RESET_80MHZ;
assign KEY_NOT = !KEY[0];

	DE0_80MHZ u1 (
		.ref_clk_clk        (FPGA_CLK1_50),        //      ref_clk.clk
		.ref_reset_reset    (KEY_NOT),    //    ref_reset.reset
		.sys_clk_clk        (CLOCK_80MHZ),        //      sys_clk.clk
		.reset_source_reset (RESET_80MHZ)  // reset_source.reset
	);


    ADC_LTC u0 (
        .ADC_SCLK  (ADC_SCK),  // adc_signals.SCLK
        .ADC_CS_N  (ADC_CONVST),  //            .CS_N
        .ADC_SDAT  (ADC_SDO),  //            .SDAT
        .ADC_SADDR (ADC_SDI), //            .SADDR
        .CLOCK     (CLOCK_80MHZ),     //         clk.clk
        .CH0       (CHAN0),       //    readings.CH0
        .CH1       (CHAN[1]),       //            .CH1
        .CH2       (CHAN[2]),       //            .CH2
        .CH3       (CHAN[3]),       //            .CH3
        .CH4       (CHAN[4]),       //            .CH4
        .CH5       (CHAN[5]),       //            .CH5
        .CH6       (CHAN[6]),       //            .CH6
        .CH7       (CHAN[7]),       //            .CH7
        .RESET     (KEY_NOT)      //       reset.reset
    );
	 



//=======================================================
//  REG/WIRE declarations
//=======================================================
//reg  [31:0]	Cont;
//reg [11:0] COMPARE;
reg [7:0] LEDr;
reg GPIOr;

// FOR ADC SIGNAL*****************************
reg [23:0] sumAveraging;
reg [18:0] meanPeriod;
reg [17:0] pulseSize;
reg [13:0] valleySize;
reg [17:0] pulseAveraging [0:31];
reg [13:0] valleyAveraging [0:31];
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

// FOR PULSER SIGNAL*************************
reg pulserSignal;
reg [23:0] PsumAveraging;
reg [18:0] PmeanPeriod;
reg [17:0] PpulseSize;
reg [13:0] PvalleySize;
reg [17:0] PpulseAveraging [0:31];
reg [13:0] PvalleyAveraging [0:31];
reg [5:0] Pdatanum;
reg PcountPulseStart;
reg PcountValleyStart;
reg PcountValley; // With P denotes that they are for the pulser signal. follows same logic.
reg PcountPulse;
reg PwriteData,PwriteValleySum,PwritePulseSum;
reg PdataReady;
reg [3:0] Pstate;
reg [3:0] PnextState;

//etc*******************************
reg [17:0] triggerOffset [0:31];
reg [23:0] triggerSum;
reg [17:0] meanTriggerOffset;

//Triggering parameters
reg [3:0] Tstate;
reg [3:0] TnextState;
reg TriggerSignal;
reg BeamOn;
reg [6:0] OnRatio;
reg [6:0] OffRatio;
reg [6:0] switchCount;
reg turnON;
reg turnOFF;
reg resetButton;
reg [5:0]Tdatanum;
reg [17:0]TrigTime [0:1];
reg errorRamp;
reg resetPress;
//interger k;
//wire runTrigger;

parameter COMPARE = 12'b011111111111, resetState=4'd0, beginState=4'd1,record1State=4'd2,record2State=4'd3;

parameter KickerOnState=4'd2, KickerOffState=4'd3, errorState=4'd4;
//=======================================================
//  Intitial Values
//=======================================================
initial
begin
Pstate <= resetState;
state <= resetState;
Tstate <= resetState;
TnextState <= resetState;

resetButton <=1'b0;
OnRatio <= 7'd1;
OffRatio <= 7'd2;
//for (k = 6'd0; k < 6'd32 ; k = (k + 6'd1))
//begin
//pulseAveraging[k[4:0]] = 18'd0;
//valleyAveraging[k[4:0]] = 14'd0;
//end 
end
//assign GPIO_0  		=	36'hzzzzzzzz;
//assign GPIO_1  		=	36'hzzzzzzzz;

//=======================================================
//  conditions for different outputs. Mainly for FPGA program analysis
//=======================================================
always@(posedge CLOCK_80MHZ)
    begin
      case (SW)
		0:LEDr =	KEY[1]? {CHAN0[11:4]}:8'hff;
		1:LEDr = KEY[1]? {(CHAN0>COMPARE),(CHAN0<COMPARE),6'd0}:8'hff;
		2:GPIOr = CHAN0>COMPARE;
		3:begin
		GPIOr = CHAN0>COMPARE;
		LEDr = KEY[1]? {(CHAN0>COMPARE),(CHAN0<COMPARE),6'd0}:8'hff;
		end
		4:LEDr =	KEY[1]? {CHAN0[7:0]}:8'hff;
		//5:
		//6:
		//7:
		8:begin
		//	runTrigger =1'b1;
			LEDr= KEY[1]? {pulseSize[17:10]}:8'hff;
		end
		default:begin
		GPIOr = 1'hz;
		LEDr = 8'hff;
		end
		endcase
    end
	 
assign LED = LEDr;
assign GPIO_0[0] = GPIOr;
//assign GPIO_0[2] = CLOCK_80MHZ;
assign GPIO_0[35:4] = 34'hzzzzzzzz;

always@(posedge CLOCK_80MHZ)
begin
	if(( (datanum + 6'd1 == Pdatanum) || (datanum == Pdatanum) || ((datanum == 6'd31 || datanum == 6'd32) && Pdatanum==6'd0) ) && resetButton == 1'b0)
	begin
		state <= nextState;
		Pstate <= PnextState;
		Tstate <= TnextState;
		errorRamp = 1'b0;
	end
	else
	begin
		state <= errorState;
		Pstate <= errorState;
		Tstate <= errorState;
		if(TriggerSignal)
			begin
			errorRamp = 1'b1;
			end
		else
			begin
			errorRamp = 1'b0;
			end
	end
end

//***********************ADC SIGNAL ANALYSIS**********************

//=======================================================
// State conditions for the measurment of the ADC pulse signal.
// Determines if ADC value is above a threshold, and sets the state accordingly.
//=======================================================
always @(*)
begin
		ADCsignal <= GPIO_0[2];
		case(state)
		resetState:begin
			countValley=0;
			countPulse=0;
			countValleyStart=0;
			countPulseStart=0;
				if(ADCsignal==1'b0 && (Pstate==record1State||Pstate==record2State))//if(CHAN0<COMPARE)
				nextState = beginState;
			else
				nextState = resetState;
		end
		beginState:begin
			countValley=0;
			countPulse=0;
			countValleyStart=0;
			if(ADCsignal && (Pstate==record1State||Pstate==record2State))//if(CHAN0>COMPARE && (Pstate==record1State||Pstate==record2State))
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
		record1State:begin
			countValley=0;
			countPulse=1;
			countPulseStart=0;
			if(ADCsignal==1'b0)//if(CHAN0<COMPARE)
			begin
				nextState = record2State; 
				countValleyStart=1;
			end
			else
			begin
				nextState = record1State;
				countValleyStart=0;
			end
		end
		record2State:begin
			countValley=1;
			countPulse=0;
			countValleyStart=0;
			if(ADCsignal)//if(CHAN0>COMPARE)
			begin
				nextState = record1State;
				countPulseStart=1;
			end
			else
			begin
				nextState = record2State;
				countPulseStart=0;
			end
		end
		errorState:begin
		
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
	if(countValleyStart==1)
		valleySize <= 14'd1;
	else if(countValley==1)
		valleySize <= valleySize + 14'd1;
end

//=======================================================
//counter for the pulse time interval of the ADC signal(beam ON)
//=======================================================

always@(posedge CLOCK_80MHZ)
begin
	if(countPulseStart==1)
		pulseSize <= 18'd1;
	else if(countPulse==1)
		pulseSize <= pulseSize + 18'd1;
end

//=======================================================
//gathering data for creating a moving average of last 32 values
//=======================================================
always@(posedge CLOCK_80MHZ)
begin
	//=======================================================
	//for writing to array of time values
	//=======================================================
	if(state == resetState)
		pulseAveraging[31] <= 18'd0;
	else if(writeValleySum) 
		begin
			valleyAveraging [datanum] <= valleySize - 14'd1;
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
				triggerOffset [datanum] <= PpulseSize - 18'd1 + PvalleyAveraging[Pdatanum];
			else
				triggerOffset [datanum] <= PvalleySize - 18'd1;
		end
		
	//=======================================================
	//Determine if all parts of the array are non-zero
	//=======================================================	
	if(state == resetState)
		dataReady <= 1'b0;
	else if(pulseAveraging[31] > 18'd10)
		dataReady <= 1'b1;//All parts of the array have a value. can begin the mean calulation
	else
		dataReady <= 1'b0;
		
	//=======================================================
	//Calculate the mean Period
	//=======================================================	
	if(dataReady && writePulseSum)
	begin 
		meanPeriod <= sumAveraging[23:5];//because there are 2^5 data points, the mean Period is just this value, truncated to nearest pulse.
	end
		
	if(dataReady && PdataReady && writePulseSum)
	begin
		meanTriggerOffset <= triggerSum[22:5];
	end
	//=======================================================
	//for incrementing array of time values
	//=======================================================
	if(state == resetState)
	begin
		datanum <= 6'd32;
	end
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
		triggerSum   <= 24'd0;
	end
	else if(countPulseStart && (datanum < 6'd32))// for simplicity, the number of data points is 2^5. This way shift register can be used instead of a divide circuit
	begin
		writeValleySum <= 1'b1;
		if(dataReady)
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
				triggerSum <= triggerSum + PpulseSize + PvalleyAveraging[Pdatanum] - triggerOffset[6'd0];
			end
			else
			begin
				triggerSum <= triggerSum + PvalleySize - triggerOffset[6'd0];
			end
		end
		else if (dataReady)
		begin
			if(PcountPulse)
			begin
				triggerSum <= triggerSum + PpulseSize + PvalleyAveraging[Pdatanum] - triggerOffset[datanum + 6'd1];
			end
			else
			begin
				triggerSum <= triggerSum + PvalleySize - triggerOffset[datanum + 6'd1];
			end
		end
		else
		begin
			if(PcountPulse)
			begin
				triggerSum <= triggerSum + PpulseSize + PvalleyAveraging[Pdatanum];
			end
			else
			begin
				triggerSum <= triggerSum  + PvalleySize;
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

//***********************PULSER SIGNAL ANALYSIS****************************


//=========================================================
// State conditions for Pulser signal.
//=========================================================

always @(*)
begin
		pulserSignal <= GPIO_0[1];
		case(Pstate)
		resetState:begin
			PcountValley=0;
			PcountPulse=0;
			PcountPulseStart=0;
			PcountValleyStart=0;
			if(pulserSignal)
				PnextState = resetState;
			else
				PnextState = beginState;
		end
		beginState:begin
			PcountValley=0;
			PcountPulse=0;
			PcountValleyStart=0;
			if(pulserSignal)
				begin
				PnextState = record1State;
				PcountPulseStart=1;
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
				PnextState = record2State; 
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
				PnextState = record1State;
				PcountPulseStart=1;
			end
			else
			begin
				PnextState = record2State;
				PcountPulseStart=0;
			end
		end
		errorState:begin
		
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
	if(PcountValleyStart==1)
		PvalleySize <= 14'd1;
	else if(PcountValley==1)
		PvalleySize <= PvalleySize + 14'd1;
end


//=======================================================
//counter for the pulse time interval of the Pulser signal(beam ON)
//=======================================================

always@(posedge CLOCK_80MHZ)
begin
	if(PcountPulseStart==1)
		PpulseSize <= 18'd1;
	else if(PcountPulse==1)
		PpulseSize <= PpulseSize + 18'd1;
end

//

//=======================================================
//gathering data for creating a moving average of last 32 values
//=======================================================
always@(posedge CLOCK_80MHZ)
begin
	//=======================================================
	//for writing to array of time values
	//=======================================================
	if(Pstate == resetState)
		PpulseAveraging[31] <= 18'd0;
	else if(PwriteValleySum) 
		begin
			PvalleyAveraging [Pdatanum] <= PvalleySize - 14'd1;
			PwriteValleySum <= 1'b0; 
		end
//	else if(writePulseSum && datanum==6'd0)
//		begin
//			pulseAveraging [31] <= pulseSize - 18'd1;
//			writePulseSum <= 1'b0;
//		end
	else if(PwritePulseSum)
		begin
			PpulseAveraging [Pdatanum] <= PpulseSize - 18'd1;
			PwritePulseSum <= 1'b0;
		end
		
	//=======================================================
	//Determine if all parts of the array are non-zero
	//=======================================================	
	if (Pstate == resetState)
		PdataReady <= 1'b0;
	else if(PpulseAveraging[31] > 18'd1)
		PdataReady <= 1'b1;//All parts of the array have a value. can begin the mean calulation
	else
		PdataReady <= 1'b0;
		
	//=======================================================
	//Calculate the mean Period
	//=======================================================	
	if(PdataReady && PwritePulseSum)
	begin
		PmeanPeriod <= PsumAveraging[23:5];//because there are 2^5 data points, the mean Period is just this value, truncated to nearest pulse.
	end
		
	//=======================================================
	//for incrementing array of time values
	//=======================================================
	if(Pstate == resetState)
	begin
		Pdatanum <= 6'd32;
	end
	else if((Pdatanum==6'd31 || Pdatanum==6'd32) && PcountValleyStart)
	begin
		Pdatanum <= 6'd0;
	end
	else if (PcountValleyStart)
		Pdatanum <= Pdatanum + 6'd1;
		
	//=======================================================
	//for calculating the sum of the last 32 cycles 
	//=======================================================
	if(Pstate == resetState)
	begin
	PsumAveraging <= 24'd0;	
	end
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


//***********************Trigger output logic****************************


//=========================================================
// State conditions for Trigger signal.
//=========================================================

always @(*)
begin
	BeamOn <= GPIO_0[3];
	case(Tstate)
	resetState:begin
		TriggerSignal=0;
		resetPress=0;
		if(resetButton)
			TnextState=resetState;
		else
			TnextState=beginState;
	end
	
	beginState:begin
		TriggerSignal=0;
		if(dataReady && PdataReady)
		begin
			TnextState=KickerOffState;
		end	
		else
			TnextState=beginState;
	end
	
	KickerOnState:begin
		TriggerSignal=1;
		//turnON=0;
		if(turnOFF)
		begin
			TnextState=KickerOffState;
		end
		else
			TnextState=KickerOnState;
	end
	
	KickerOffState:begin
		TriggerSignal=0;
	//	turnOFF=0;
		if(BeamOn && turnON)
		begin
				TnextState=KickerOnState;
		end
		else
			TnextState=KickerOffState;
	end
	errorState:begin
	
	if(errorRamp)
	begin
	TnextState = errorState;
	
	end
	
	else
	begin
		if (resetPress==0)
		begin
			TnextState = errorState;
			if (resetButton==1)
				resetPress = 1;
			else
				resetPress = 0;
		end
		else
		begin
			if (resetButton==1)
				TnextState = resetState;
			else
				TnextState = errorState;
		end
	end
	
	
	end
	default:begin
			TriggerSignal=0;
			TnextState = resetState;
	end
	endcase
end

always@(posedge CLOCK_80MHZ)
begin
	TrigTime[0] <= PvalleyAveraging [Pdatanum] + PpulseSize;
	TrigTime[1] <= PvalleySize;
	if(Tstate == resetState)
	begin
		switchCount<=7'd1;
		turnOFF <= 1'b0;
		turnON <= 1'b0;
		Tdatanum <= 6'd4;
	end
	else if((( TrigTime[0] == meanTriggerOffset) ||(TrigTime[1] == meanTriggerOffset)) && dataReady && PdataReady && ((Tdatanum == 6'd32 && Pdatanum == 6'd0)||((Tdatanum + 6'd1) == Pdatanum)))
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
		if(Tdatanum == 6'd32)
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

//always@(posedge CLOCK_80MHZ)//cal averaging
//begin
//	if(dataReady)
//	begin
//		
//	end
//end

//always@(posedge countValley)//
//begin
//	pulseAveraging [datanum] <= pulseSize;
//end
//
//always@(posedge countPulse)//
//begin
//	valleyAveraging [datanum] <= valleySize;
//end

assign GPIO_1 = {datanum,Pdatanum,Tdatanum,TriggerSignal};
	 //assign LED[0]=(CHAN[0]>COMPARE);Tstate

//assign LED[1]=(CHAN[0]<COMPARE);

//assign LED[2] = SW[0];
//assign LED = KEY[1]? {(CHAN0>COMPARE),(CHAN0<COMPARE),6'd0}:8'hff

//	begin
//			LEDr =	KEY[1]? {CHAN0[11:4]}:8'hff;
//		end
//      else
//		begin
//			LEDr[0]=(CHAN0>COMPARE);
//			LEDr[1]=(CHAN0<COMPARE);
//			LEDr[7:2]=6'd0;
//		end

//======================================================================================
//----------------------------------THINGS TO DO----------------------------------------
//======================================================================================
//Right now it is just averaging the time between triggers for 1vm4 signal. 
//I need to add another reading for the pulser signal and figure out the offset average from 1vm4
//then I need to turn that into the 1:2 ratio and figure out how we are going to edit that. (maybe through gpio and another board)
//then I need to add all the failsafes. valley too small, pulse signal doesn't make sense. etc..
//then I need to figure out how to calculate the pulse on value, and what % of that determines a kick start.

//also I should test the IQ and this program to see the performance

endmodule
