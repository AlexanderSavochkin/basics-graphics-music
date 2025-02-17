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
    output logic [4:0] blue
);

    d_flip_flop i0
    (
        .clock   ( slow_clock ),
        .d       ( key [0]    ),
        .q       ( led [0]    )
    );

    d_flip_flop_sync_reset i1
    (
        .clock   ( slow_clock ),
        .reset,
        .d       ( key [1]    ),
        .q       ( led [1]    )
    );

    d_flip_flop_async_reset i2
    (
        .clock   ( slow_clock ),
        .reset,
        .d       ( key [2]    ),
        .q       ( led [2]    )
    );

    //  Pulse generator, 50 times a second

    logic enable;
    strobe_gen # (.clk_mhz (27), .strobe_hz (1))
    i_strobe_gen (clock, reset, enable);

    d_flip_flop_sync_reset_and_enable i3
    (
        .clock   ( clock      ),  // Note this is not a slow_clock
        .reset,
        .enable,
        .d       ( key [3]    ),
        .q       ( led [3]    )
    );

endmodule
