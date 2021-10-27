module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

    input clk, rst;
    input en;
    input [23:0] central;
    input [11:0] radius;
    input [1:0] mode;
    output busy;
    output valid;
    output [7:0] candidate;

    reg _busy, _valid;
    reg [7:0] _candidate;

    reg [3:0] xA, yA, xB, yB, xC, yC;
    reg [3:0] rA, rB, rC;
    reg [1:0] modeCom;

    reg [3:0] x, y;

    reg controlA, controlB, controlC;

    reg [9:0] temp_xA, temp_yA, temp_xB, temp_yB, temp_xC, temp_yC;

    assign busy = _busy;
    assign valid = _valid;
    assign candidate = _candidate;

    integer i, j;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            _busy = 1'b0;
            _valid = 1'b0;
        end else begin
            if (en && !_busy) begin
                xA = central[23:20];
                yA = central[19:16];
                xB = central[15:12];
                yB = central[11:8];
                xC = central[7:4];
                yC = central[3:0];
                rA = radius[11:8];
                rB = radius[7:4];
                rC = radius[3:0];
                modeCom = mode;
                _busy = 1'b1;
                _valid = 1'b0;
                _candidate = 8'd0;
                x = 4'd1;
                y = 4'd1;
            end else begin
                temp_xA = xA - x;
                temp_yA = yA - y;
                temp_xB = xB - x;
                temp_yB = yB - y;
                temp_xC = xC - x;
                temp_yC = yC - y;
                controlA = temp_xA * temp_xA + temp_yA * temp_yA <= rA * rA ? 1 : 0;
                controlB = temp_xB * temp_xB + temp_yB * temp_yB <= rB * rB ? 1 : 0;
                controlC = temp_xC * temp_xC + temp_yC * temp_yC <= rC * rC ? 1 : 0;
                case(modeCom)
                2'd0: begin
                    _candidate = controlA ? _candidate + 1 : _candidate;
                    if (x == 4'd8) begin
                        y = y + 1;
                        x = 4'd1;
                    end else begin
                        x = x + 1;
                    end
                    if (y == 4'd9) begin
                        _busy = 1'b0;
                        _valid = 1'b1;
                    end
                end
                2'd1: begin
                    _candidate = controlA && controlB ? _candidate + 1 : _candidate;
                    if (x == 4'd8) begin
                        y = y + 1;
                        x = 4'd1;
                    end else begin
                        x = x + 1;
                    end
                    if (y == 4'd9) begin
                        _busy = 1'b0;
                        _valid = 1'b1;
                    end
                end
                2'd2: begin
                    _candidate = ((controlA || controlB) && !(controlA && controlB)) ? _candidate + 1 : _candidate;
                    if (x == 4'd8) begin
                        y = y + 1;
                        x = 4'd1;
                    end else begin
                        x = x + 1;
                    end
                    if (y == 4'd9) begin
                        _busy = 1'b0;
                        _valid = 1'b1;
                    end
                end
                default: begin
                    if (controlA) begin
                        _candidate = (controlB || controlC) && !(controlB && controlC) ? _candidate + 1 : _candidate;
                    end else if (controlB) begin
                        _candidate = (controlA || controlC) && !(controlA && controlC) ? _candidate + 1 : _candidate;
                    end else begin
                        _candidate = (controlA || controlB) && !(controlA && controlB) ? _candidate + 1 : _candidate;
                    end
                    if (x == 4'd8) begin
                        y = y + 1;
                        x = 4'd1;
                    end else begin
                        x = x + 1;
                    end
                    if (y == 4'd9) begin
                        _busy = 1'b0;
                        _valid = 1'b1;
                    end
                end
                endcase
            end
        end
    end
endmodule
