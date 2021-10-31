module geofence (clk, reset, X, Y, valid, is_inside);
    input clk;
    input reset;
    input [9:0] X;
    input [9:0] Y;
    output valid;
    output is_inside;

    wire [2:0] status;
    wire [31:0] result0, result1, result2, result3, result4, result5;
    wire [5:0] result;

    reg _valid, _inside;

    reg [2:0] countTemp;
    reg [2:0] nextStatus;

    reg signed [19:0] xA, yA, xB, yB;
    reg signed [31:0] outPot;

    reg [9:0] targetX, targetY;
    reg [9:0] tempX [5:0];
    reg [9:0] tempY [5:0];

    assign status = nextStatus;

    assign result0 = (tempX[0] - targetX) * (tempY[1] - tempY[0]) - (tempX[1] - tempX[0]) * (tempY[0] - targetY);
    assign result1 = (tempX[1] - targetX) * (tempY[2] - tempY[1]) - (tempX[2] - tempX[1]) * (tempY[1] - targetY);
    assign result2 = (tempX[2] - targetX) * (tempY[3] - tempY[2]) - (tempX[3] - tempX[2]) * (tempY[2] - targetY);
    assign result3 = (tempX[3] - targetX) * (tempY[4] - tempY[3]) - (tempX[4] - tempX[3]) * (tempY[3] - targetY);
    assign result4 = (tempX[4] - targetX) * (tempY[5] - tempY[4]) - (tempX[5] - tempX[4]) * (tempY[4] - targetY);
    assign result5 = (tempX[5] - targetX) * (tempY[0] - tempY[5]) - (tempX[0] - tempX[5]) * (tempY[5] - targetY);

    assign result = {result0[31], result1[31], result2[31], result3[31], result4[31], result5[31]};

    assign valid = _valid;
    assign is_inside = _inside;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            countTemp <= 0;
            nextStatus <= 0;
        end else begin
            if (status == 0) begin
                _valid <= 0;
                targetX <= X;
                targetY <= Y;
                nextStatus <= 1;
            end else if (status == 1) begin
                if (countTemp == 6) begin
                    nextStatus <= 2;
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
            end else if (status == 2) begin
                xA = tempX[1] - tempX[0];
                yA = tempY[1] - tempY[0];
                xB = tempX[2] - tempX[0];
                yB = tempY[2] - tempY[0];
                outPot = xA * yB - xB * yA;
                if (outPot < 0) begin
                    nextStatus <= 3;
                end else begin
                    tempX[1] <= tempX[2];
                    tempX[2] <= tempX[1];
                    tempY[1] <= tempY[2];
                    tempY[2] <= tempY[1];
                end
            end else if (status == 3) begin
                xA = tempX[2] - tempX[0];
                yA = tempY[2] - tempY[0];
                xB = tempX[3] - tempX[0];
                yB = tempY[3] - tempY[0];
                outPot = xA * yB - xB * yA;
                if (outPot < 0) begin
                    nextStatus <= 4;
                end else begin
                    tempX[2] <= tempX[3];
                    tempX[3] <= tempX[2];
                    tempY[2] <= tempY[3];
                    tempY[3] <= tempY[2];
                    nextStatus <= 2;
                end
            end else if (status == 4) begin
                xA = tempX[3] - tempX[0];
                yA = tempY[3] - tempY[0];
                xB = tempX[4] - tempX[0];
                yB = tempY[4] - tempY[0];
                outPot = xA * yB - xB * yA;
                if (outPot < 0) begin
                    nextStatus <= 5;
                end else begin
                    tempX[3] <= tempX[4];
                    tempX[4] <= tempX[3];
                    tempY[3] <= tempY[4];
                    tempY[4] <= tempY[3];
                    nextStatus <= 2;
                end
            end else if (status == 5) begin
                xA = tempX[4] - tempX[0];
                yA = tempY[4] - tempY[0];
                xB = tempX[5] - tempX[0];
                yB = tempY[5] - tempY[0];
                outPot = xA * yB - xB * yA;
                if (outPot < 0) begin
                    nextStatus <= 6;
                end else begin
                    tempX[4] <= tempX[5];
                    tempX[5] <= tempX[4];
                    tempY[4] <= tempY[5];
                    tempY[5] <= tempY[4];
                    nextStatus <= 2;
                end
            end else if (status == 6) begin
                _valid <= 1;
                _inside <= (result == 6'b111111 || result == 6'b000000) ? 1 : 0;
                nextStatus <= 7;
            end else begin
                _valid <= 0;
                nextStatus <= 0;
                countTemp <= 0;
            end
        end
    end
    
endmodule

