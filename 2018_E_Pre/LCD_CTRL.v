module LCD_CTRL(
    input clk, cmd_valid, reset,
    input [3:0] cmd,
    input [7:0] IROM_Q,
    output IRAM_valid, IROM_rd, busy, done,
    output [5:0] IROM_A,
    output [5:0] IRAM_A,
    output [7:0] IRAM_D
);

    reg [3:0] status;
    reg [6:0] datAddr;
    reg [6:0] wrAddr;
    reg [7:0] dat [63:0];
    reg _ramVaild, _romRD, _busy, _done;

    reg [2:0] _x, _y;

    assign IRAM_valid = _ramVaild;
    assign IROM_rd = _romRD;
    assign busy = _busy;
    assign done = _done;
    assign IROM_A = datAddr[5:0];

    assign IRAM_A = wrAddr[5:0];
    assign IRAM_D = dat[0];

    integer idx;

    wire [7:0] max, min;

    wire [7:0] dat1, dat2, dat3, dat4;

    wire [9:0] total;
    wire [7:0] average;

    assign dat1 = dat[_y * 8 + _x];
    assign dat2 = dat[_y * 8 + _x + 1];
    assign dat3 = dat[(_y + 1) * 8 + _x];
    assign dat4 = dat[(_y + 1) * 8 + _x + 1];

    assign max = (dat1 > dat2) ? ((dat1 > dat3) ? (dat1 > dat4 ? dat1 : dat4) : (dat3 > dat4 ? dat3 : dat4)) : (dat2 > dat3 ? (dat2 > dat4 ? dat2 : dat4) : (dat3 > dat4 ? dat3 : dat4));
    assign min = (dat1 < dat2) ? ((dat1 < dat3) ? (dat1 < dat4 ? dat1 : dat4) : (dat3 < dat4 ? dat3 : dat4)) : (dat2 < dat3 ? (dat2 < dat4 ? dat2 : dat4) : (dat3 < dat4 ? dat3 : dat4));

    assign total = dat1 + dat2 + dat3 + dat4;
    assign average = total >> 2;

    // ---
    // dat1 | dat2
    // dat3 | dat4
    // ---
    
    // ---
    // 0: Write
    // 1: Up
    // 2: Down
    // 3: Left
    // 4: Right
    // 5: Max
    // 6: Min
    // 7: Average
    // 8: Counterclockwise Rotate
    // 9: Clockwise Rotae
    // A: Mirror X
    // B: Mirror Y
    // C: Read date from ROM
    // D: Read cmd number
    // E: Load new status
    // ---

    parameter WR = 4'h0, UP = 4'h1, DOWN = 4'h2, LEFT = 4'h3, RIGHT = 4'h4,
        MAX = 4'h5, MIN = 4'h6, AVG = 4'h7, CCWR = 4'h8, CWR = 4'h9, 
        MX = 4'hA, MY = 4'hB, RD = 4'hC, RCMD = 4'hD, TRANS = 4'hE;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            datAddr <= 7'd0;

            status <= 4'hC;
            _romRD <= 1'b1;
            _busy <= 1'b1;

            _y <= 3'd3;
            _x <= 3'd3;
        end else begin
            case(status)
                WR: begin
                    _busy <= (wrAddr[6] & !wrAddr[0]) ? 1'b0 : 1'b1;
                end
                UP: begin
                    if (_y == 3'd0) begin
                        _y <= 3'd0;
                    end else begin
                        _y <= _y - 1;
                    end
                    status <= TRANS;
                end
                DOWN: begin
                    if (_y == 3'd6) begin
                        _y <= 3'd6;
                    end else begin
                        _y <= _y + 1;
                    end
                    status <= TRANS;
                end
                LEFT: begin
                    if (_x == 3'd0) begin
                        _x <= 3'd0;
                    end else begin
                        _x <= _x - 1;
                    end
                    status <= TRANS;
                end
                RIGHT: begin
                    if (_x == 3'd6) begin
                        _x <= 3'd6;
                    end else begin
                        _x <= _x + 1;
                    end
                    status <= TRANS;
                end
                RD: begin
                    if (datAddr == 7'd63) begin
                        status <= RCMD;
                        _busy <= 1'b0;
                        _romRD <= 1'b0;
                    end else begin
                        datAddr <= datAddr + 1;
                    end
                end
                RCMD: begin
                    status <= (cmd_valid) ? cmd : status;
                    _busy <= 1'b1;
                end
                TRANS: begin
                    status <= RCMD;
                    _busy <= 1'b0;
                end
                default: status <= TRANS;
            endcase
        end
    end

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            for (idx = 63; idx >= 0; idx = idx - 1) begin
                dat[idx] <= 0;
            end
            wrAddr <= 7'd65;
            _done <= 1'b0;
            _ramVaild <= 1'b0;
        end else begin
            case(status)
                WR: begin
                    if (wrAddr[6] & wrAddr[0]) begin
                        wrAddr <= 7'd0;
                        _ramVaild <= 1'b1;
                    end else if (wrAddr[6]) begin
                        _done <= 1'b1;
                        _ramVaild <= 1'b0;
                    end else begin
                        dat[63] <= dat[0];
                        for (idx = 63; idx > 0; idx = idx - 1) begin
                            dat[idx - 1] <= dat[idx];
                        end
                        wrAddr <= wrAddr + 1;
                    end
                end
                MAX: begin
                    dat[_y * 8 + _x] <= max;
                    dat[_y * 8 + _x + 1] <= max;
                    dat[(_y + 1) * 8 + _x] <= max;
                    dat[(_y + 1) * 8 + _x + 1] <= max;
                end
                MIN: begin
                    dat[_y * 8 + _x] <= min;
                    dat[_y * 8 + _x + 1] <= min;
                    dat[(_y + 1) * 8 + _x] <= min;
                    dat[(_y + 1) * 8 + _x + 1] <= min;
                end
                AVG: begin
                    dat[_y * 8 + _x] <= average;
                    dat[_y * 8 + _x + 1] <= average;
                    dat[(_y + 1) * 8 + _x] <= average;
                    dat[(_y + 1) * 8 + _x + 1] <= average;
                end
                CCWR: begin
                    dat[_y * 8 + _x] <= dat2;
                    dat[_y * 8 + _x + 1] <= dat4;
                    dat[(_y + 1) * 8 + _x] <= dat1;
                    dat[(_y + 1) * 8 + _x + 1] <= dat3;
                end
                CWR: begin
                    dat[_y * 8 + _x] <= dat3;
                    dat[_y * 8 + _x + 1] <= dat1;
                    dat[(_y + 1) * 8 + _x] <= dat4;
                    dat[(_y + 1) * 8 + _x + 1] <= dat2;
                end
                MX: begin
                    dat[_y * 8 + _x] <= dat3;
                    dat[_y * 8 + _x + 1] <= dat4;
                    dat[(_y + 1) * 8 + _x] <= dat1;
                    dat[(_y + 1) * 8 + _x + 1] <= dat2;
                end
                MY: begin
                    dat[_y * 8 + _x] <= dat2;
                    dat[_y * 8 + _x + 1] <= dat1;
                    dat[(_y + 1) * 8 + _x] <= dat4;
                    dat[(_y + 1) * 8 + _x + 1] <= dat3;
                end
                RD: begin
                    for (idx = 63; idx > 0; idx = idx - 1) begin
                        dat[idx - 1] <= dat[idx];
                    end
                    dat[63] <= IROM_Q;
                end
            endcase
        end
    end

endmodule
