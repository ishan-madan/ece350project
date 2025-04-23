module AudioController(
    input        clk,        // System Clock Input 100 MHz
    input  [3:0] tone,       // 4-bit input to select tone (16 options)
    input        ena,        // Enable signal
    output       audioOut,   // PWM signal to the audio jack
    output       audioEn     // Audio Enable
);

    localparam MHz = 1000000;
    localparam SYSTEM_FREQ = 100 * MHz; // System clock frequency

    assign audioEn = ena;  // Enable Audio Output

    // Initialize the frequency array. FREQs[0] = 261
    reg [10:0] FREQs[0:15];
    initial begin
        $readmemh("FREQs.mem", FREQs);
    end

    // Generate square wave using counter
    reg [31:0] counter = 0;
    reg waveState = 0;
    wire [31:0] toggleThreshold;

    // Compute counter threshold based on selected frequency
    assign toggleThreshold = (SYSTEM_FREQ / (FREQs[tone] * 2));  // *2 for square wave toggle

    always @(posedge clk) begin
        if (ena) begin
            if (counter >= toggleThreshold - 1) begin
                counter <= 0;
                waveState <= ~waveState;
            end else begin
                counter <= counter + 1;
            end
        end else begin
            counter <= 0;
            waveState <= 0;
        end
    end

    // Generate PWM duty cycle based on wave state
    wire [9:0] duty_cycle;
    assign duty_cycle = waveState ? 10'd1023 : 10'd0;

    // Instantiate PWM Serializer
    PWMSerializer #(
        .SYS_FREQ_MHZ(100),
        .PERIOD_WIDTH_NS(10)
    ) pwm (
        .clk(clk),
        .reset(~ena),
        .duty_cycle(duty_cycle),
        .signal(audioOut)
    );

endmodule
