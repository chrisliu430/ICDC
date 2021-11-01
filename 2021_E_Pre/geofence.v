module geofence (clk, reset, X, Y, valid, is_inside);
    input clk;
    input reset;
    input [9:0] X;
    input [9:0] Y;
    output valid;
    output is_inside;

    wire [2:0] status;
    wire [20:0] target, compare;
    reg [2:0] countIndex;
    reg [2:0] countResult;

    reg _valid, _inside;

    reg [2:0] countTemp;
    reg [2:0] nextStatus;
    reg [1:0] countNum;

    wire [20:0] outPot;

    reg [9:0] targetX, targetY;
    reg [9:0] tempX [5:0];
    reg [9:0] tempY [5:0];

    assign status = nextStatus;

    assign outPot = (tempX[countNum + 1] - tempX[0]) * (tempY[countNum + 2] - tempY[0]) - (tempX[countNum + 2] - tempX[0]) * (tempY[countNum + 1] - tempY[0]);

    assign compare = (tempX[countIndex] - targetX) * (tempY[countIndex + 1] - tempY[countIndex]) - (tempX[countIndex + 1] - tempX[countIndex]) * (tempY[countIndex] - targetY);
    assign target = (tempX[5] - targetX) * (tempY[0] - tempY[5]) - (tempX[0] - tempX[5]) * (tempY[5] - targetY);

    assign valid = _valid;
    assign is_inside = _inside;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            countTemp <= 0;
            nextStatus <= 0;
        end else begin
            case (status)
                3'd0: begin
                    _valid <= 0;
                    targetX <= X;
                    targetY <= Y;
                    nextStatus <= 1;
                    countResult <= 0;
                    countIndex <= 0;
                end
                3'd1: begin
                    if (countTemp == 6) begin
                        nextStatus <= 2;
                        countNum <= 0;
                    end else begin
                        tempX[0] <= tempX[1];
                        tempX[1] <= tempX[2];
                        tempX[2] <= tempX[3];
                        tempX[3] <= tempX[4];
                        tempX[4] <= tempX[5];
                        tempX[5] <= X;
                        tempY[0] <= tempY[1];
                        tempY[1] <= tempY[2];
                        tempY[2] <= tempY[3];
                        tempY[3] <= tempY[4];
                        tempY[4] <= tempY[5];
                        tempY[5] <= Y;
                        countTemp <= countTemp + 1;
                    end
                end
                3'd2: begin
                    if (outPot[20] == 1) begin
                        nextStatus <= 3;
                        countNum <= countNum + 1;
                    end else begin
                        tempX[1] <= tempX[2];
                        tempX[2] <= tempX[1];
                        tempY[1] <= tempY[2];
                        tempY[2] <= tempY[1];
                    end
                end
                3'd3: begin
                    if (outPot[20] == 1'b1) begin
                        nextStatus <= 4;
                        countNum <= countNum + 1;
                    end else begin
                        tempX[2] <= tempX[3];
                        tempX[3] <= tempX[2];
                        tempY[2] <= tempY[3];
                        tempY[3] <= tempY[2];
                        countNum <= 0;
                        nextStatus <= 2;
                    end
                end
                3'd4: begin
                    if (outPot[20] == 1'b1) begin
                        nextStatus <= 5;
                        countNum <= countNum + 1;
                    end else begin
                        tempX[3] <= tempX[4];
                        tempX[4] <= tempX[3];
                        tempY[3] <= tempY[4];
                        tempY[4] <= tempY[3];
                        countNum <= 0;
                        nextStatus <= 2;
                    end
                end
                3'd5: begin
                    if (outPot[20] == 1'b1) begin
                        nextStatus <= 6;
                    end else begin
                        tempX[4] <= tempX[5];
                        tempX[5] <= tempX[4];
                        tempY[4] <= tempY[5];
                        tempY[5] <= tempY[4];
                        countNum <= 0;
                        nextStatus <= 2;
                    end
                end
                3'd6: begin
                    if (countIndex == 3'b101) begin
                        _valid <= 1;
                        _inside <= (countResult == 5) ? 1 : 0;
                        nextStatus <= 7;
                    end else begin
                        countIndex <= countIndex + 1;
                        countResult <= (target[20] == compare[20]) ? countResult + 1 : countResult;
                    end
                end
                default: begin
                    _valid <= 0;
                    nextStatus <= 0;
                    countTemp <= 0;
                end
            endcase
        end
    end
    
endmodule

