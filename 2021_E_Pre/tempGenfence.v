module geofence (clk, reset, X, Y, valid, is_inside);
    input clk;
    input reset;
    input [9:0] X;
    input [9:0] Y;
    output valid;
    output is_inside;

    wire [2:0] status;
    wire [2:0] checkStatus;

    reg _valid, _inside;

    reg [2:0] countTemp;
    reg [9:0] targetX, targetY;
    reg [9:0] tempX [5:0];
    reg [9:0] tempY [5:0];

    reg [19:0] x1, y1, x2, y2;
    reg [31:0] computingXY;

    reg [2:0] nextStatus;
    reg [2:0] checkNextStatus;

    assign status = (countTemp == 7) ? nextStatus : 3'd0;
    assign checkStatus = (status == 3'd5) ? checkNextStatus : 3'd0;

    assign valid = _valid;
    assign is_inside = _inside;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            countTemp <= 3'd0;
        end else begin
            if (countTemp == 0) begin
                _valid <= 1'd0;
                targetX <= X;
                targetY <= Y;
                countTemp <= countTemp + 1;
            end else if (countTemp == 7) begin
                nextStatus <= 3'd1;
            end else begin
                tempX[5] <= tempX[4];
                tempX[4] <= tempX[3];
                tempX[3] <= tempX[2];
                tempX[2] <= tempX[1];
                tempX[1] <= tempX[0];
                tempX[0] <= X;
                tempY[5] <= tempY[4];
                tempY[4] <= tempY[3];
                tempY[3] <= tempY[2];
                tempY[2] <= tempY[1];
                tempY[1] <= tempY[0];
                tempY[0] <= X;
                countTemp <= countTemp + 1;
            end
        end
    end

    always @(status) begin
        if (status == 1) begin
            x1 <= tempX[1] - tempX[0];
            x2 <= tempX[2] - tempX[0];
            y1 <= tempY[1] - tempY[0];
            y2 <= tempY[2] - tempY[0];
        end else if (status == 2) begin
            x1 <= tempX[2] - tempX[0];
            x2 <= tempX[3] - tempX[0];
            y1 <= tempY[2] - tempY[0];
            y2 <= tempY[3] - tempY[0];
        end else if (status == 3) begin
            x1 <= tempX[3] - tempX[0];
            x2 <= tempX[4] - tempX[0];
            y1 <= tempY[3] - tempY[0];
            y2 <= tempY[4] - tempY[0];
        end else if (status == 4) begin
            x1 <= tempX[4] - tempX[0];
            x2 <= tempX[5] - tempX[0];
            y1 <= tempY[4] - tempY[0];
            y2 <= tempY[5] - tempY[0];
        end else begin
        end
        computingXY <= x1 * y2 - x2 * y1;
        if (computingXY > 0) begin
            case(status)
                3'd1: begin
                    tempX[1] <= tempX[2];
                    tempX[2] <= tempX[1];
                    tempY[1] <= tempY[2];
                    tempY[2] <= tempY[1];
                end
                3'd2: begin
                    tempX[2] <= tempX[3];
                    tempX[3] <= tempX[2];
                    tempY[2] <= tempY[3];
                    tempY[3] <= tempY[2];
                end
                3'd3: begin
                    tempX[3] <= tempX[4];
                    tempX[4] <= tempX[3];
                    tempY[3] <= tempY[4];
                    tempY[4] <= tempY[3];
                end
                3'd4: begin
                    tempX[4] <= tempX[5];
                    tempX[5] <= tempX[4];
                    tempY[4] <= tempY[5];
                    tempY[5] <= tempY[4];
                end
                default: begin
                end
            endcase
            nextStatus <= 3'd1;
        end else begin
            case(status)
                3'd1: nextStatus <= 3'd2;
                3'd2: nextStatus <= 3'd3;
                3'd3: nextStatus <= 3'd4;
                3'd4: nextStatus <= 3'd5;
                default: nextStatus <= 3'd1;
            endcase
        end
    end

    always @(checkStatus) begin
        case (checkStatus)
            3'd1: begin
                x1 <= tempX[0] - targetX;
                x2 <= tempX[1] - tempX[0];
                y1 <= tempY[0] - targetY;
                y2 <= tempY[1] - tempY[0];
            end
            3'd2: begin
                x1 <= tempX[1] - targetX;
                x2 <= tempX[2] - tempX[1];
                y1 <= tempY[1] - targetY;
                y2 <= tempY[2] - tempY[1];
            end
            3'd3: begin
                x1 <= tempX[2] - targetX;
                x2 <= tempX[3] - tempX[2];
                y1 <= tempY[2] - targetY;
                y2 <= tempY[3] - tempY[2];
            end
            3'd4: begin
                x1 <= tempX[3] - targetX;
                x2 <= tempX[4] - tempX[3];
                y1 <= tempY[3] - targetY;
                y2 <= tempY[4] - tempY[3];
            end
            3'd5: begin
                x1 <= tempX[4] - targetX;
                x2 <= tempX[5] - tempX[4];
                y1 <= tempY[4] - targetY;
                y2 <= tempY[5] - tempY[4];
            end
            3'd6: begin
                x1 <= tempX[5] - targetX;
                x2 <= tempX[0] - tempX[5];
                y1 <= tempY[5] - targetY;
                y2 <= tempY[0] - tempY[5];
            end
            default: begin
            end
        endcase
        computingXY <= x1 * y2 - x2 * y1;
        if (computingXY > 0) begin
            _valid <= 1'b1;
            _inside <= 1'b0;
            countTemp <= 3'd0;
        end else begin
            case (checkStatus)
                3'd1: checkNextStatus <= 3'd2;
                3'd2: checkNextStatus <= 3'd3;
                3'd3: checkNextStatus <= 3'd4;
                3'd4: checkNextStatus <= 3'd5;
                3'd5: checkNextStatus <= 3'd6;
                3'd6: checkNextStatus <= 3'd7;
                default: checkNextStatus <= 3'd0;
            endcase
        end
        if (checkNextStatus == 3'd7) begin
            _valid <= 1'b1;
            _inside <= 1'b1;
            countTemp <= 3'd0;
        end else begin
        end
    end

endmodule

