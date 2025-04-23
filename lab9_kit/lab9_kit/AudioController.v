//module AudioController(
//    input        clk,        // System Clock Input 100 MHz
//    input  [3:0] tone,       // 4-bit input to select tone (16 options)
//    input        ena,        // Enable signal
//    output       audioOut,   // PWM signal to the audio jack
//    output       audioEn     // Audio Enable
//);

//    localparam MHz = 1000000;
//    localparam SYSTEM_FREQ = 100 * MHz; // System clock frequency

//    assign audioEn = ena;  // Enable Audio Output

//    // Initialize the frequency array. FREQs[0] = 261
//    reg [10:0] FREQs[0:15];
//    initial begin
//        $readmemh("FREQs.mem", FREQs);
//    end

//    // Generate square wave using counter
//    reg [31:0] counter = 0;
//    reg waveState = 0;
//    wire [31:0] toggleThreshold;

//    // Compute counter threshold based on selected frequency
//    assign toggleThreshold = (SYSTEM_FREQ / (FREQs[tone] * 2));  // *2 for square wave toggle

//    always @(posedge clk) begin
//        if (ena) begin
//            if (counter >= toggleThreshold - 1) begin
//                counter <= 0;
//                waveState <= ~waveState;
//            end else begin
//                counter <= counter + 1;
//            end
//        end else begin
//            counter <= 0;
//            waveState <= 0;
//        end
//    end

//    // Generate PWM duty cycle based on wave state
//    wire [9:0] duty_cycle;
//    assign duty_cycle = waveState ? 10'd1023 : 10'd0;

//    // Instantiate PWM Serializer
//    PWMSerializer #(
//        .SYS_FREQ_MHZ(100),
//        .PERIOD_WIDTH_NS(10)
//    ) pwm (
//        .clk(clk),
//        .reset(~ena),
//        .duty_cycle(duty_cycle),
//        .signal(audioOut)
//    );

//endmodule
module AudioController(
    input        clk, 		// System Clock Input 100 Mhz
    input[3:0]   tone,	// Tone control switches
    output       audioOut,	// PWM signal to the audio jack	
    output       audioEn);	// Audio Enable

	localparam MHz = 1000000;
	localparam SYSTEM_FREQ = 100*MHz; // System clock frequency

	assign audioEn = (tone == 4'b1111) ? 0 : 1;  // Enable Audio Output

	// Initialize the frequency array. FREQs[0] = 261
	reg[10:0] FREQs[0:15];
	initial begin
		$readmemh("FREQs.mem", FREQs);
	end
	
	////////////////////
	// Your Code Here //
	////////////////////
	// Controlling scale:
	wire [9:0] duty_cycle;
	reg clk_custom = 0;
	reg [22:0] counter = 0;
	wire [22:0] CounterLimit = (SYSTEM_FREQ/FREQs[tone])/2 - 1;
	always @(posedge clk) begin 
		if (counter < CounterLimit)
			counter <= counter + 1;
		else begin
			counter <= 0;
			clk_custom <= ~clk_custom;
		end
	end

	wire [9:0] Max, Min;
	assign Max = 768;
	assign Min = 256;
	assign duty_cycle = clk_custom ? Max : Min;

	//Controlling microphone
//	wire[5:0]  micThresh;
//	assign micThresh = (SYSTEM_FREQ / (1*MHz)) >> 1;

//	reg capturedBit = 0;
//	reg[31:0] micCounter = 0;
//	always @(posedge clk) begin
//		if (micCounter < micThresh - 1)  
//			micCounter <= micCounter + 1;
//		else begin
//			micCounter <= 0;
//			micClk <= ~micClk;
//		end
//	end

//	always @(posedge micClk) begin
//		capturedBit <= micData; // Assign mic input on the clock edges
//	end

//	wire [9:0] duty_cycle_2;

//	PWMDeserializer deserializer1(
//		.clk(clk),  
//		.reset(1'b0),           
//		.duty_cycle(duty_cycle_2), 
//		.signal(capturedBit)   
//    );

//	wire [9:0] duty_cycle_total = (duty_cycle + duty_cycle_2)/2;

	PWMSerializer #(.SYS_FREQ_MHZ(50)) serializer1(
		.clk(clk),              // System Clock
		.reset(1'b0),            // Reset the counter
		.duty_cycle(duty_cycle), // Duty Cycle of the Wave, between 0 and 1023 - scaled to 0 and 100
		.signal(audioOut)   // Output PWM signal
    );


endmodule