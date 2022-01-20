`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
    input   clk, reset, gray_ready;
    input   [7:0] gray_data;
    output  gray_req, lbp_valid, finish;
    output  [7:0] lbp_data;
    output  [13:0] gray_addr, lbp_addr;

    reg gReq, lValid, _fin;
    reg [3:0] status;
    reg [7:0] thresholdDat, overThreshold, rowCount;
    reg [13:0] gAddr, lAddr, tempAddr;

    wire [14:0] compareAddr, leftEdge, rightEdge;

    assign compareAddr = 8'd125 + (rowCount) * 8'd128;
    assign leftEdge = 8'd128 * rowCount;
    assign rightEdge = 8'd128 * (rowCount + 1'd1) - 1'd1;

    assign gray_req = gReq;
    assign lbp_valid = lValid;
    assign finish = _fin;
    assign lbp_data = (lValid) ? 1'd1 * overThreshold[0] + 2'd2 * overThreshold[1] + 3'd4 * overThreshold[2] + 4'd8 * overThreshold[3] + 5'd16 * overThreshold[4] + 6'd32 * overThreshold[5] + 7'd64 * overThreshold[6] + 8'd128 * overThreshold[7]: 14'd0;

    assign gray_addr = gAddr;
    assign lbp_addr = lAddr;

    // ---
    // 0 | 1 | 2
    // 3 | T | 4
    // 5 | 6 | 7
    // ---
    // 0: LOAD_DATA
    // 1: READ_THRESHOLD
    // 2: READ_0
    // 3: READ_1
    // 4: READ_2
    // 5: READ_3
    // 6: READ_4
    // 7: READ_5
    // 8: READ_6
    // 9: READ_7
    // A: COMPUTING
    // B: OUTPUT
    // C: FINISH
    // ---

    parameter LOAD_DATA = 4'h0;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            gReq            <= 1'b0;
            lValid          <= 1'b0;
            _fin            <= 1'b0;
            status          <= 4'h0;
            thresholdDat    <= 8'h00;
            overThreshold   <= 8'h00;
            rowCount        <= 8'd0;
            gAddr           <= 14'h00;
            lAddr           <= 14'h00;
            tempAddr        <= 14'h00;
        end else begin
            if (gray_ready) begin
                case(status)
                    4'h0: begin
                        gReq <= 1'b1;
                        tempAddr <= gAddr;
                        gAddr <= gAddr + 8'd129;
                        lAddr <= gAddr + 8'd129;
                        status <= 4'h1;
                    end
                    4'h1: begin
                        thresholdDat <= gray_data;
                        gAddr <= tempAddr;
                        status <= 4'h2;
                    end
                    4'h2: begin
                        overThreshold[0] <= (gray_data >= thresholdDat) ? 1 : 0;
                        gAddr <= tempAddr + 1'd1;
                        status <= 4'h3;
                    end
                    4'h3: begin
                        overThreshold[1] <= (gray_data >= thresholdDat) ? 1 : 0;
                        gAddr <= tempAddr + 2'd2;
                        status <= 4'h4;
                    end
                    4'h4: begin
                        overThreshold[2] <= (gray_data >= thresholdDat) ? 1 : 0;
                        gAddr <= tempAddr + 8'd128;
                        status <= 4'h5;
                    end
                    4'h5: begin
                        overThreshold[3] <= (gray_data >= thresholdDat) ? 1 : 0;
                        gAddr <= tempAddr + 8'd130;
                        status <= 4'h6;
                    end
                    4'h6: begin
                        overThreshold[4] <= (gray_data >= thresholdDat) ? 1 : 0;
                        gAddr <= tempAddr + 9'd256;
                        status <= 4'h7;
                    end
                    4'h7: begin
                        overThreshold[5] <= (gray_data >= thresholdDat) ? 1 : 0;
                        gAddr <= tempAddr + 9'd257;
                        status <= 4'h8;
                    end
                    4'h8: begin
                        overThreshold[6] <= (gray_data >= thresholdDat) ? 1 : 0;
                        gAddr <= tempAddr + 9'd258;
                        status <= 4'h9;
                    end
                    4'h9: begin
                        gReq <= 1'b0;
                        overThreshold[7] <= (gray_data >= thresholdDat) ? 1 : 0;
                        status <= 4'hA;
                    end
                    4'hA: begin
                        lValid <= 1'b1;
                        status <= 4'hB;
                    end
                    4'hB: begin
                        lValid <= 1'b0;
                        gAddr <= tempAddr + 1'd1;
                        status <= 4'hC;
                    end
                    4'hC: begin
                        if (gAddr == 14'd16126) begin
                            status <= 4'hD;
                        end else if (gAddr >= compareAddr + 1'd1 && gAddr < rightEdge + 1'd1) begin
                            gAddr <= gAddr + 1'd1;
                            status <= 4'hC;
                        end else if (gAddr == rightEdge + 1'd1) begin
                            rowCount <= rowCount + 1'd1;
                            status <= 4'h0;
                        end else begin
                            status <= 4'h0;
                        end
                    end
                    4'hD: begin
                        _fin <= 1'b1;
                    end
                endcase
            end
        end
    end
endmodule
