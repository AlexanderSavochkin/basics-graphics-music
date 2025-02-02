module waveform_gen
# (
    parameter clk_mhz        = 50,
              y_width        = 16,      // sound samples resolution
              waveform_width = 4,
              y_max          = 21844,   // amplitude, to avoid overflow < 30000
              freq           = 440      // frequency
)
(
    input                         clk,
    input                         reset,
    input        [           2:0] octave,
    input        [           3:0] waveform, // waveform type
    output logic [y_width  - 1:0] y
);

    // We are grouping together clk_mhz ranges of
    // (12-19), (20-35), (36-67), (68-131).
    // Sampling_rate = clk_mhz / 512  ( < 36 mhz)
    //               = clk_mhz / 1024 (36-67 mhz)
    //               = clk_mhz / 2048 ( > 67 mhz)

    localparam CLK_BIT  =  $clog2 ( clk_mhz - 4 ) + 4;
    localparam CLK_DIV_DATA_OFFSET = { { CLK_BIT - 2 { 1'b0 } }, 1'b1 };

    //  Vertical step of triangle waveform generator

    localparam int step = ((y_max * freq * ((clk_mhz < 36) ? 1 :
                          ((clk_mhz > 67) ? 4 : 2))) / (clk_mhz * 488));

    logic        [CLK_BIT - 1:0] clk_div;
    logic        [          0:0] down = '0;

    logic signed [y_width - 1:0] yt   = '0;
    logic        [y_width - 1:0] ys;
    logic        [y_width - 1:0] yq;

    always_ff @ (posedge clk or posedge reset)
        if (reset)
            clk_div <= '0;
        else
            clk_div <= clk_div + 1'b1;

    //------------------------------------------------------------------------
    //
    //  Triangle waveform generator ( signed format )
    //  One sample for L and R audio channels
    //
    //------------------------------------------------------------------------

    always_ff @ (posedge clk)
        if ((clk_div == CLK_DIV_DATA_OFFSET)
              && (((yt < -y_max) &&  down) || ((yt > y_max) && ~down)))
            down <= ~down;
        else if ((clk_div == CLK_DIV_DATA_OFFSET) && !down)
            yt   <= yt + step;
        else if ((clk_div == CLK_DIV_DATA_OFFSET) &&  down)
            yt   <= yt - step;

    //------------------------------------------------------------------------
    //
    //  Wave selector
    //
    //------------------------------------------------------------------------

    always_comb begin
        case (waveform)
           'b0001: y = ys; // sinus
           'b0010: y = yt; // triangle
           'b0100: y = yq; // square
          default: y = '0;
        endcase
    end

    //------------------------------------------------------------------------

    sinus i_sinus
    (
        .y_max    ( y_max ),
        .yt       ( yt    ),
        .ys       ( ys    )
    );

    //------------------------------------------------------------------------

    square i_square
    (
        .y_max    ( y_max ),
        .yt       ( yt    ),
        .yq       ( yq    )
    );

endmodule

    //------------------------------------------------------------------------
    //
    //  Sinus from triangle waveform generator ( signed format )
    //
    //------------------------------------------------------------------------

module sinus
(
    input  logic    [15:0] y_max,
    input  logic    [15:0] yt,
    output logic    [15:0] ys
);
    localparam [15:0] MAX = '1;

    // Made as analog waveform generator ICL8038.
    // The sine wave is created by feeding the triangle wave into a
    // nonlinear sine converter. This converter provides a
    // decreasing transmission ratio as the level of the triangle
    // moves toward the two extremes. Accuracy of the sine is 1%.

    always_comb
    begin
    if     (yt > (MAX >> 1)) // Shifting to right >> 1 for positive numbers is equivalent to dividing by 2
    begin
        if       (yt >   MAX - (y_max >> 1) + (y_max >> 4))                   // negative half-wave
            ys =  yt - ((MAX - yt) >> 1) + ((MAX - yt) >> 5);
        else if  (yt >  (MAX - (y_max >> 1) - (y_max >> 3)))
            ys =  yt + ((MAX - yt) >> 4) - (y_max >> 2);
        else if  (yt >   MAX - (y_max >> 1) - (y_max >> 2) - (y_max >> 4))
            ys = MAX - ((MAX - yt) >> 1) - ((MAX - yt) >> 4) - (y_max >> 1);
        else
            ys = MAX - ((MAX - yt) >> 3) - ((MAX - yt) >> 5) - y_max + (y_max >> 3) + (y_max >> 5);
    end
    else
    begin
        if       (yt < (y_max >> 1) - (y_max >> 4))                           // < 0.4375  y_max
            ys =  yt + (yt >> 1) - (yt >> 5);                                 //                 + 1.46875 yt
        else if  (yt < (y_max >> 1) + (y_max >> 3))                           // < 0.625   y_max
            ys =  yt - (yt >> 4) + (y_max >> 2);                              //   0.25    y_max + 0.9375  yt
        else if  (yt < (y_max >> 1) + (y_max >> 2) + (y_max >> 4))            // < 0.8125  y_max
            ys = (yt >> 1) + (yt >> 4) + (y_max >> 1);                        //   0.5     y_max + 0.5625  yt
        else
            ys = (yt >> 3) + (yt >> 5) + y_max - (y_max >> 3) - (y_max >> 5); //   0.84375 y_max + 0.15625 yt
    end
    end

endmodule

    //------------------------------------------------------------------------
    //
    //  Square from triangle waveform generator ( signed format )
    //
    //------------------------------------------------------------------------

module square
(
    input      [15:0] y_max,
    input      [15:0] yt,
    output     [15:0] yq
);
    localparam [15:0] MAX = '1;

    assign yq = (yt > (MAX >> 1)) ?
               ((yt > (MAX - (y_max >> 6))) ? MAX : (MAX - y_max)) :
              (((yt < (y_max >> 6))) ? '0 : y_max);

endmodule
