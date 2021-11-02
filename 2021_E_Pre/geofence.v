module geofence (clk, reset, X, Y, valid, is_inside);
    input clk;
    input reset;
    input [9:0] X;
    input [9:0] Y;
    output valid;
    output is_inside;

    reg [9:0] targetX, targetY;

    integer i;
    reg [2:0] countGeofence;
    reg [9:0] geofenceX [5:0];
    reg [9:0] geofenceY [5:0];

    reg [1:0] readStatus;
    reg [2:0] calStatus;
    reg [2:0] countElement, countResult;

    reg signed [11:0] xA, yA, xB, yB;
    wire [9:0] sxA, syA, sxB, syB, subxA, subyA, subxB, subyB;

    wire [20:0] outPot;

    wire judge;
    wire [1:0] calResult;

    reg _valid, _inside, bitJudge;

    assign valid = _valid;
    assign is_inside = _inside;

    assign judge = outPot[20];

    assign sxA = (calStatus < 5) ? geofenceX[countElement + 1] : ((calStatus == 5) ? geofenceX[5] : geofenceX[countElement]);
    assign syA = (calStatus < 5) ? geofenceY[countElement + 1] : ((calStatus == 5) ? geofenceY[5] : geofenceY[countElement]);
    assign sxB = (calStatus < 5) ? geofenceX[countElement + 2] : ((calStatus == 5) ? geofenceX[0] : geofenceX[countElement + 1]);
    assign syB = (calStatus < 5) ? geofenceY[countElement + 2] : ((calStatus == 5) ? geofenceY[0] : geofenceY[countElement + 1]);
    assign subxA = (calStatus < 5) ? geofenceX[0] : targetX;
    assign subyA = (calStatus < 5) ? geofenceY[0] : targetY;
    assign subxB = (calStatus < 5) ? geofenceX[0] : ((calStatus == 5) ? geofenceX[5] : geofenceX[countElement]);
    assign subyB = (calStatus < 5) ? geofenceY[0] : ((calStatus == 5) ? geofenceY[5] : geofenceY[countElement]);

    assign outPot = (sxA - subxA) * (syB - subyB) - (sxB - subxB) * (syA - subyA);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            _valid <= 0;
            _inside <= 0;
            readStatus <= 0;
            calStatus <= 0;
            countGeofence <= 0;
        end else begin
            case(readStatus)
                2'd0: begin
                    _valid <= 0;
                    readStatus <= 1;
                    targetX <= X;
                    targetY <= Y;
                    calStatus <= 0;
                    countGeofence <= 0;
                end
                2'd1: begin
                    for (i = 0; i < 5; i = i + 1) begin
                        geofenceX[i] <= geofenceX[i + 1];
                        geofenceY[i] <= geofenceY[i + 1];
                    end
                    geofenceX[5] <= X;
                    geofenceY[5] <= Y;
                    countGeofence <= countGeofence + 1;
                    if (countGeofence == 5) readStatus <= 2;
                end
                2'd2: begin
                end
                default: begin
                    _valid <= 1'b0;
                    readStatus <= 2'd0;
                end
            endcase
            case(calStatus)
                3'd0: begin
                    if (readStatus == 2) begin
                        calStatus <= 1;
                        countElement <= 0;
                    end
                end
                3'd1: begin
                    if (judge) begin // 1, 2
                        calStatus <= calStatus + 1;
                        countElement <= countElement + 1;
                    end else begin
                        calStatus <= 3'd7;
                    end
                end
                3'd2: begin
                    if (judge) begin // 2, 3
                        calStatus <= calStatus + 1;
                        countElement <= countElement + 1;
                    end else begin
                        calStatus <= 3'd7;
                    end
                end
                3'd3: begin
                    if (judge) begin // 3, 4
                        calStatus <= calStatus + 1;
                        countElement <= countElement + 1;
                    end else begin
                        calStatus <= 3'd7;
                    end
                end
                3'd4: begin
                    if (judge) begin // 4, 5
                        calStatus <= calStatus + 1;
                    end else begin
                        calStatus <= 3'd7;
                    end
                end
                3'd5: begin
                    countElement <= 0;
                    calStatus <= 6;
                    countResult <= 0;
                    bitJudge <= outPot[20];
                end
                3'd6: begin
                    if (countElement == 5) begin
                        _valid <= 1;
                        _inside <= (countResult == 5) ? 1 : 0;
                        calStatus <= 0;
                        readStatus <= 3;
                    end else begin
                        countElement <= countElement + 1;
                        countResult <= (judge == bitJudge) ? countResult + 1 : countResult;
                    end
                end
                default: begin
                    geofenceX[countElement + 1] <= geofenceX[countElement + 2];
                    geofenceX[countElement + 2] <= geofenceX[countElement + 1];
                    geofenceY[countElement + 1] <= geofenceY[countElement + 2];
                    geofenceY[countElement + 2] <= geofenceY[countElement + 1];
                    calStatus <= 1;
                    countElement <= 3'd0;
                end
            endcase
        end
    end
    
endmodule

