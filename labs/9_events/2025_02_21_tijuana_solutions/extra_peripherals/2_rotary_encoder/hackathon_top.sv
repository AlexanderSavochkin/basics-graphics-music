// Board configuration: tang_nano_9k_lcd_480_272_tm1638_hackathon
// This module uses few parameterization and relaxed typing rules

module hackathon_top
(
    input  logic       clock,
    input  logic       slow_clock,
    input  logic       reset,

    input  logic [7:0] key,
    output logic [7:0] led,

    // A dynamic seven-segment display

    output logic [7:0] abcdefgh,
    output logic [7:0] digit,

    // LCD screen interface

    input  logic [8:0] x,
    input  logic [8:0] y,

    output logic [4:0] red,
    output logic [5:0] green,
    output logic [4:0] blue,

    inout  logic [3:0] gpio
);

    // Exercise: Instantiate the ultrasonic module
    // and the 7-segment display controller module,
    // connect them with each other and with GPIO

    // START_SOLUTION

    wire [15:0] value;

    rotary_encoder i_rotary_encoder
    (
        .clk    ( clock    ),
        .reset  ( reset    ),
        .a      ( gpio [2] ),
        .b      ( gpio [3] ),
        .value  ( value    )
    );

    seven_segment_display
    # (.w_digit (8))
    i_7segment
    (
        .clk      ( clock       ),
        .rst      ( reset       ),
        .number   ( 32' (value) ),
        .dots     ( '0          ),
        .abcdefgh ( abcdefgh    ),
        .digit    ( digit       )
    );

    // END_SOLUTION

endmodule
