//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Spring
//   Lab01 Exercise		: Code Calculator
//   Author     		  : Jhan-Yi LIAO
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CC.v
//   Module Name : CC
//   Release version : V1.0 (Release Date: 2024-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################


module CC (
    // Input signals
    opt,
    in_n0,
    in_n1,
    in_n2,
    in_n3,
    in_n4,
    // Output signals
    out_n
);

    //================================================================
    //   INPUT AND OUTPUT DECLARATION                         
    //================================================================
    input [3:0] in_n0, in_n1, in_n2, in_n3, in_n4;
    input [2:0] opt;
    output reg [9:0] out_n;

    //================================================================
    //    Wire & Registers 
    //================================================================
    wire       [3:0] out_sort               [0:4];  //sort from biggest to smallest
    //wire       [3:0] sort                   [0:4];  //opt[1]
    //wire signed [4:0] norm                   [0:4];
    wire       [3:0] n                      [0:4];  //opt[0]
    wire       [4:0] part_sum_maxmin;
    wire       [3:0] avg1;  // (max+min)>>1;
    reg signed [4:0] avg2;  //(n0+...n4)/5;
    reg signed [4:0] m1, m2, m3, m4;
    wire signed [8:0] mult1, mult2;
    reg signed [8:0] add_term2, add_term3;
    reg signed [4:0] add_term1;
    wire signed [7:0] sum;
    wire [6:0] total;
    reg [6:0] avg1_X5;
    wire signed [4:0] m1_norm, m2_norm, m4_norm;

    wire signed [9:0] sum_out;
    reg signed  [8:0] mux_out;
    //================================================================
    //    DESIGN
    //================================================================

    //opt1 大到小  or 小到大
    sort u_sort (
        .in0 (in_n0),
        .in1 (in_n1),
        .in2 (in_n2),
        .in3 (in_n3),
        .in4 (in_n4),
        .out0(out_sort[0]),
        .out1(out_sort[1]),
        .out2(out_sort[2]),
        .out3(out_sort[3]),
        .out4(out_sort[4])
    );

    assign part_sum_maxmin = out_sort[0] + out_sort[4];
    //four_bit_adder u_bit(.in1(out_sort[0]),.in2(out_sort[4]),.out(part_sum_maxmin)); 
    assign avg1 = (opt[0]) ? part_sum_maxmin[4:1] : 0;



    assign n[0] = (opt[1]) ? out_sort[0] : out_sort[4];
    assign n[1] = (opt[1]) ? out_sort[1] : out_sort[3];
    assign n[2] = out_sort[2];
    assign n[3] = (opt[1]) ? out_sort[3] : out_sort[1];
    //assign n[4] = (opt[1]) ? out_sort[4] : out_sort[0];
    
    //opt0  -avg1 or remain same     
    //assign n[0] = sort[0] - avg1;
    //assign n[1] = sort[1] - avg1;       乘之前 再- 可以變成四個
    //assign n[2] = sort[2] - avg1;
    //assign n[3] = sort[3] - avg1;
    //assign n[4] = sort[4] - avg1;

    //calculate

    //assign sum = n[0] + n[1] + n[2] + n[3] + n[4]);         //sort完 先減avg1 五個再相加/5 CP太大
    assign total = (in_n0 + in_n1 + in_n2 + in_n3 + in_n4);   //先加起來 再減5*avg1， overhead 多一個mux和減法器
    //assign total = (part_sum_maxmin + out_sort[1] + out_sort[2] + out_sort[3]);
    //wire [5:0] avg_X4;
    //assign avg_X4 = {avg1,2'b00};
    assign sum = total - avg1_X5;
    //  avg1 X 5 mux
    always @(*) begin
        case (avg1)
            4'd15: avg1_X5 = 75;
            4'd14: avg1_X5 = 70;
            4'd13: avg1_X5 = 65;
            4'd12: avg1_X5 = 60;
            4'd11: avg1_X5 = 55;
            4'd10: avg1_X5 = 50;
            4'd9: avg1_X5 = 45;
            4'd8: avg1_X5 = 40;
            4'd7: avg1_X5 = 35;
            4'd6: avg1_X5 = 30;
            4'd5: avg1_X5 = 25;
            4'd4: avg1_X5 = 20;
            4'd3: avg1_X5 = 15;
            4'd2: avg1_X5 = 10;
            4'd1: avg1_X5 = 5;
            4'd0: avg1_X5 = 0;
            default: avg1_X5 = 0;
        endcase
    end
    //  sum/5  mux
    always @(*) begin
        case (sum)
            8'd75: avg2 = 15;
            8'd74: avg2 = 14;
            8'd73: avg2 = 14;
            8'd72: avg2 = 14;
            8'd71: avg2 = 14;
            8'd70: avg2 = 14;
            8'd69: avg2 = 13;
            8'd68: avg2 = 13;
            8'd67: avg2 = 13;
            8'd66: avg2 = 13;
            8'd65: avg2 = 13;
            8'd64: avg2 = 12;
            8'd63: avg2 = 12;
            8'd62: avg2 = 12;
            8'd61: avg2 = 12;
            8'd60: avg2 = 12;
            8'd59: avg2 = 11;
            8'd58: avg2 = 11;
            8'd57: avg2 = 11;
            8'd56: avg2 = 11;
            8'd55: avg2 = 11;
            8'd54: avg2 = 10;
            8'd53: avg2 = 10;
            8'd52: avg2 = 10;
            8'd51: avg2 = 10;
            8'd50: avg2 = 10;
            8'd49: avg2 = 9;
            8'd48: avg2 = 9;
            8'd47: avg2 = 9;
            8'd46: avg2 = 9;
            8'd45: avg2 = 9;
            8'd44: avg2 = 8;
            8'd43: avg2 = 8;
            8'd42: avg2 = 8;
            8'd41: avg2 = 8;
            8'd40: avg2 = 8;
            8'd39: avg2 = 7;
            8'd38: avg2 = 7;
            8'd37: avg2 = 7;
            8'd36: avg2 = 7;
            8'd35: avg2 = 7;
            8'd34: avg2 = 6;
            8'd33: avg2 = 6;
            8'd32: avg2 = 6;
            8'd31: avg2 = 6;
            8'd30: avg2 = 6;
            8'd29: avg2 = 5;
            8'd28: avg2 = 5;
            8'd27: avg2 = 5;
            8'd26: avg2 = 5;
            8'd25: avg2 = 5;
            8'd24: avg2 = 4;
            8'd23: avg2 = 4;
            8'd22: avg2 = 4;
            8'd21: avg2 = 4;
            8'd20: avg2 = 4;
            8'd19: avg2 = 3;
            8'd18: avg2 = 3;
            8'd17: avg2 = 3;
            8'd16: avg2 = 3;
            8'd15: avg2 = 3;
            8'd14: avg2 = 2;
            8'd13: avg2 = 2;
            8'd12: avg2 = 2;
            8'd11: avg2 = 2;
            8'd10: avg2 = 2;
            8'd9: avg2 = 1;
            8'd8: avg2 = 1;
            8'd7: avg2 = 1;
            8'd6: avg2 = 1;
            8'd5: avg2 = 1;
            8'd4: avg2 = 0;
            8'd3: avg2 = 0;
            8'd2: avg2 = 0;
            8'd1: avg2 = 0;
            8'd0: avg2 = 0;
            -8'd1: avg2 = 0;
            -8'd2: avg2 = 0;
            -8'd3: avg2 = 0;
            -8'd4: avg2 = 0;
            -8'd5: avg2 = -1;
            -8'd6: avg2 = -1;
            -8'd7: avg2 = -1;
            -8'd8: avg2 = -1;
            -8'd9: avg2 = -1;
            -8'd10: avg2 = -2;
            -8'd11: avg2 = -2;
            -8'd12: avg2 = -2;
            -8'd13: avg2 = -2;
            -8'd14: avg2 = -2;
            -8'd15: avg2 = -3;
            -8'd16: avg2 = -3;
            -8'd17: avg2 = -3;
            -8'd18: avg2 = -3;
            -8'd19: avg2 = -3;
            -8'd20: avg2 = -4;
            -8'd21: avg2 = -4;
            default: avg2 = 0;
        endcase
    end


    always @(*) begin
        m4 = n[3];
        if (opt[2]) begin
            m1 = out_sort[0];
            m2 = out_sort[4];
            m3 = 3;
            //m4 = n[3];
        end else begin
            m1 = n[1];
            m2 = n[2];
            m3 = avg2;
            //m4 = n[3];
        end
    end

    assign m1_norm = m1 - avg1;
    assign m2_norm = m2 - avg1;
    assign m4_norm = m4 - avg1;

    //four_bit_signed_mult u_mult1(.in1(m1_norm),.in2(m2_norm),.out(mult1));
    //four_bit_signed_mult u_mult2(.in1(m3),.in2(m4_norm),.out(mult2));
    assign mult1   = m1_norm * m2_norm;
    assign mult2   = m3 * m4_norm;

    always @(*) begin
        case (opt[2])
            1'b1: begin
                //add_term1 = 0;
                //if (mult1 > mult2) begin
                    add_term2 = (mult1);
                    add_term3 = ~(mult2);
                //end else begin
               //     add_term2 = ~(mult1);
               //     add_term3 = mult2;
               // end
            end
            1'b0: begin
                //add_term1 = n[0] - avg1;
                add_term2 = mult1+n[0];
                add_term3 = mult2-avg1;
            end
        endcase
    end

    assign sum_out =  add_term2 + add_term3; //add_term1 +

    //sum_out / 3 mux
    always @(*) begin
        case (sum_out)
            10'd465: mux_out = 155;

  
            10'd452: mux_out = 150;
            10'd451: mux_out = 150;
            10'd450: mux_out = 150;
            10'd449: mux_out = 149;
            10'd448: mux_out = 149;
            10'd447: mux_out = 149;
            10'd446: mux_out = 148;
            10'd445: mux_out = 148;

            //10'd444: mux_out = 148;
            //10'd443: mux_out = 147;
            //10'd442: mux_out = 147;
            //10'd441: mux_out = 147;
            //10'd440: mux_out = 146;
            //10'd439: mux_out = 146;
            //10'd438: mux_out = 146;
            //10'd437: mux_out = 145;
            10'd436: mux_out = 145;
            10'd435: mux_out = 145;
            10'd434: mux_out = 144;
            10'd433: mux_out = 144;
            10'd432: mux_out = 144;
            10'd431: mux_out = 143;
            10'd430: mux_out = 143;

            10'd429: mux_out = 143;
            10'd428: mux_out = 142;
            10'd427: mux_out = 142;
            10'd426: mux_out = 142;
            10'd425: mux_out = 141;

            10'd424: mux_out = 141;
            10'd423: mux_out = 141;
            10'd422: mux_out = 140;
            10'd421: mux_out = 140;
            10'd420: mux_out = 140;
            10'd419: mux_out = 139;
            10'd418: mux_out = 139;
            10'd417: mux_out = 139;
            10'd416: mux_out = 138;
            10'd415: mux_out = 138;
            10'd414: mux_out = 138;
            10'd413: mux_out = 137;
            10'd412: mux_out = 137;
            10'd411: mux_out = 137;
            10'd410: mux_out = 136;
            10'd409: mux_out = 136;
            10'd408: mux_out = 136;
            10'd407: mux_out = 135;
            10'd406: mux_out = 135;
            10'd405: mux_out = 135;
            10'd404: mux_out = 134;
            10'd403: mux_out = 134;
            10'd402: mux_out = 134;
            10'd401: mux_out = 133;
            10'd400: mux_out = 133;
            10'd399: mux_out = 133;
            10'd398: mux_out = 132;
            10'd397: mux_out = 132;
            10'd396: mux_out = 132;
            10'd395: mux_out = 131;
            10'd394: mux_out = 131;
            10'd393: mux_out = 131;
            10'd392: mux_out = 130;
            10'd391: mux_out = 130;
            10'd390: mux_out = 130;
            10'd389: mux_out = 129;
            10'd388: mux_out = 129;
            10'd387: mux_out = 129;
            10'd386: mux_out = 128;
            10'd385: mux_out = 128;
            10'd384: mux_out = 128;
            10'd383: mux_out = 127;
            10'd382: mux_out = 127;
            10'd381: mux_out = 127;
            10'd380: mux_out = 126;
            10'd379: mux_out = 126;
            10'd378: mux_out = 126;
            10'd377: mux_out = 125;
            10'd376: mux_out = 125;
            10'd375: mux_out = 125;
            10'd374: mux_out = 124;
            10'd373: mux_out = 124;
            10'd372: mux_out = 124;
            10'd371: mux_out = 123;
            10'd370: mux_out = 123;
            10'd369: mux_out = 123;
            10'd368: mux_out = 122;
            10'd367: mux_out = 122;
            10'd366: mux_out = 122;
            10'd365: mux_out = 121;
            10'd364: mux_out = 121;
            10'd363: mux_out = 121;
            10'd362: mux_out = 120;
            10'd361: mux_out = 120;
            10'd360: mux_out = 120;
            10'd359: mux_out = 119;
            10'd358: mux_out = 119;
            10'd357: mux_out = 119;
            10'd356: mux_out = 118;
            10'd355: mux_out = 118;
            10'd354: mux_out = 118;
            10'd353: mux_out = 117;
            10'd352: mux_out = 117;
            10'd351: mux_out = 117;
            10'd350: mux_out = 116;
            10'd349: mux_out = 116;
            10'd348: mux_out = 116;
            10'd347: mux_out = 115;
            10'd346: mux_out = 115;
            10'd345: mux_out = 115;
            10'd344: mux_out = 114;
            10'd343: mux_out = 114;
            10'd342: mux_out = 114;
            10'd341: mux_out = 113;
            10'd340: mux_out = 113;
            10'd339: mux_out = 113;
            10'd338: mux_out = 112;
            10'd337: mux_out = 112;
            10'd336: mux_out = 112;
            10'd335: mux_out = 111;
            10'd334: mux_out = 111;
            10'd333: mux_out = 111;
            10'd332: mux_out = 110;
            10'd331: mux_out = 110;
            10'd330: mux_out = 110;
            10'd329: mux_out = 109;
            10'd328: mux_out = 109;
            10'd327: mux_out = 109;
            10'd326: mux_out = 108;
            10'd325: mux_out = 108;
            10'd324: mux_out = 108;
            10'd323: mux_out = 107;
            10'd322: mux_out = 107;
            10'd321: mux_out = 107;
            10'd320: mux_out = 106;
            10'd319: mux_out = 106;
            10'd318: mux_out = 106;
            10'd317: mux_out = 105;
            10'd316: mux_out = 105;
            10'd315: mux_out = 105;
            10'd314: mux_out = 104;
            10'd313: mux_out = 104;
            10'd312: mux_out = 104;
            10'd311: mux_out = 103;
            10'd310: mux_out = 103;
            10'd309: mux_out = 103;
            10'd308: mux_out = 102;
            10'd307: mux_out = 102;
            10'd306: mux_out = 102;
            10'd305: mux_out = 101;
            10'd304: mux_out = 101;
            10'd303: mux_out = 101;
            10'd302: mux_out = 100;
            10'd301: mux_out = 100;
            10'd300: mux_out = 100;
            10'd299: mux_out = 99;
            10'd298: mux_out = 99;
            10'd297: mux_out = 99;
            10'd296: mux_out = 98;
            10'd295: mux_out = 98;
            10'd294: mux_out = 98;
            10'd293: mux_out = 97;
            10'd292: mux_out = 97;
            10'd291: mux_out = 97;
            10'd290: mux_out = 96;
            10'd289: mux_out = 96;
            10'd288: mux_out = 96;
            10'd287: mux_out = 95;
            10'd286: mux_out = 95;
            10'd285: mux_out = 95;
            10'd284: mux_out = 94;
            10'd283: mux_out = 94;
            10'd282: mux_out = 94;
            10'd281: mux_out = 93;
            10'd280: mux_out = 93;
            10'd279: mux_out = 93;
            10'd278: mux_out = 92;
            10'd277: mux_out = 92;
            10'd276: mux_out = 92;
            10'd275: mux_out = 91;
            10'd274: mux_out = 91;
            10'd273: mux_out = 91;
            10'd272: mux_out = 90;
            10'd271: mux_out = 90;
            10'd270: mux_out = 90;
            10'd269: mux_out = 89;
            10'd268: mux_out = 89;
            10'd267: mux_out = 89;
            10'd266: mux_out = 88;
            10'd265: mux_out = 88;
            10'd264: mux_out = 88;
            10'd263: mux_out = 87;
            10'd262: mux_out = 87;
            10'd261: mux_out = 87;
            10'd260: mux_out = 86;
            10'd259: mux_out = 86;
            10'd258: mux_out = 86;
            10'd257: mux_out = 85;
            10'd256: mux_out = 85;
            10'd255: mux_out = 85;
            10'd254: mux_out = 84;
            10'd253: mux_out = 84;
            10'd252: mux_out = 84;
            10'd251: mux_out = 83;
            10'd250: mux_out = 83;
            10'd249: mux_out = 83;
            10'd248: mux_out = 82;
            10'd247: mux_out = 82;
            10'd246: mux_out = 82;
            10'd245: mux_out = 81;
            10'd244: mux_out = 81;
            10'd243: mux_out = 81;
            10'd242: mux_out = 80;
            10'd241: mux_out = 80;
            10'd240: mux_out = 80;
            10'd239: mux_out = 79;
            10'd238: mux_out = 79;
            10'd237: mux_out = 79;
            10'd236: mux_out = 78;
            10'd235: mux_out = 78;
            10'd234: mux_out = 78;
            10'd233: mux_out = 77;
            10'd232: mux_out = 77;
            10'd231: mux_out = 77;
            10'd230: mux_out = 76;
            10'd229: mux_out = 76;
            10'd228: mux_out = 76;
            10'd227: mux_out = 75;
            10'd226: mux_out = 75;
            10'd225: mux_out = 75;
            10'd224: mux_out = 74;
            10'd223: mux_out = 74;
            10'd222: mux_out = 74;
            10'd221: mux_out = 73;
            10'd220: mux_out = 73;
            10'd219: mux_out = 73;
            10'd218: mux_out = 72;
            10'd217: mux_out = 72;
            10'd216: mux_out = 72;
            10'd215: mux_out = 71;
            10'd214: mux_out = 71;
            10'd213: mux_out = 71;
            10'd212: mux_out = 70;
            10'd211: mux_out = 70;
            10'd210: mux_out = 70;
            10'd209: mux_out = 69;
            10'd208: mux_out = 69;
            10'd207: mux_out = 69;
            10'd206: mux_out = 68;
            10'd205: mux_out = 68;
            10'd204: mux_out = 68;
            10'd203: mux_out = 67;
            10'd202: mux_out = 67;
            10'd201: mux_out = 67;
            10'd200: mux_out = 66;
            10'd199: mux_out = 66;
            10'd198: mux_out = 66;
            10'd197: mux_out = 65;
            10'd196: mux_out = 65;
            10'd195: mux_out = 65;
            10'd194: mux_out = 64;
            10'd193: mux_out = 64;
            10'd192: mux_out = 64;
            10'd191: mux_out = 63;
            10'd190: mux_out = 63;
            10'd189: mux_out = 63;
            10'd188: mux_out = 62;
            10'd187: mux_out = 62;
            10'd186: mux_out = 62;
            10'd185: mux_out = 61;
            10'd184: mux_out = 61;
            10'd183: mux_out = 61;
            10'd182: mux_out = 60;
            10'd181: mux_out = 60;
            10'd180: mux_out = 60;
            10'd179: mux_out = 59;
            10'd178: mux_out = 59;
            10'd177: mux_out = 59;
            10'd176: mux_out = 58;
            10'd175: mux_out = 58;
            10'd174: mux_out = 58;
            10'd173: mux_out = 57;
            10'd172: mux_out = 57;
            10'd171: mux_out = 57;
            10'd170: mux_out = 56;
            10'd169: mux_out = 56;
            10'd168: mux_out = 56;
            10'd167: mux_out = 55;
            10'd166: mux_out = 55;
            10'd165: mux_out = 55;
            10'd164: mux_out = 54;
            10'd163: mux_out = 54;
            10'd162: mux_out = 54;
            10'd161: mux_out = 53;
            10'd160: mux_out = 53;
            10'd159: mux_out = 53;
            10'd158: mux_out = 52;
            10'd157: mux_out = 52;
            10'd156: mux_out = 52;
            10'd155: mux_out = 51;
            10'd154: mux_out = 51;
            10'd153: mux_out = 51;
            10'd152: mux_out = 50;
            10'd151: mux_out = 50;
            10'd150: mux_out = 50;
            10'd149: mux_out = 49;
            10'd148: mux_out = 49;
            10'd147: mux_out = 49;
            10'd146: mux_out = 48;
            10'd145: mux_out = 48;
            10'd144: mux_out = 48;
            10'd143: mux_out = 47;
            10'd142: mux_out = 47;
            10'd141: mux_out = 47;
            10'd140: mux_out = 46;
            10'd139: mux_out = 46;
            10'd138: mux_out = 46;
            10'd137: mux_out = 45;
            10'd136: mux_out = 45;
            10'd135: mux_out = 45;
            10'd134: mux_out = 44;
            10'd133: mux_out = 44;
            10'd132: mux_out = 44;
            10'd131: mux_out = 43;
            10'd130: mux_out = 43;
            10'd129: mux_out = 43;
            10'd128: mux_out = 42;
            10'd127: mux_out = 42;
            10'd126: mux_out = 42;
            10'd125: mux_out = 41;
            10'd124: mux_out = 41;
            10'd123: mux_out = 41;
            10'd122: mux_out = 40;
            10'd121: mux_out = 40;
            10'd120: mux_out = 40;
            10'd119: mux_out = 39;
            10'd118: mux_out = 39;
            10'd117: mux_out = 39;
            10'd116: mux_out = 38;
            10'd115: mux_out = 38;
            10'd114: mux_out = 38;
            10'd113: mux_out = 37;
            10'd112: mux_out = 37;
            10'd111: mux_out = 37;
            10'd110: mux_out = 36;
            10'd109: mux_out = 36;
            10'd108: mux_out = 36;
            10'd107: mux_out = 35;
            10'd106: mux_out = 35;
            10'd105: mux_out = 35;
            10'd104: mux_out = 34;
            10'd103: mux_out = 34;
            10'd102: mux_out = 34;
            10'd101: mux_out = 33;
            10'd100: mux_out = 33;
            10'd99:  mux_out = 33;
            10'd98:  mux_out = 32;
            10'd97:  mux_out = 32;
            10'd96:  mux_out = 32;
            10'd95:  mux_out = 31;
            10'd94:  mux_out = 31;
            10'd93:  mux_out = 31;
            10'd92:  mux_out = 30;
            10'd91:  mux_out = 30;
            10'd90:  mux_out = 30;
            10'd89:  mux_out = 29;
            10'd88:  mux_out = 29;
            10'd87:  mux_out = 29;
            10'd86:  mux_out = 28;
            10'd85:  mux_out = 28;
            10'd84:  mux_out = 28;
            10'd83:  mux_out = 27;
            10'd82:  mux_out = 27;
            10'd81:  mux_out = 27;
            10'd80:  mux_out = 26;
            10'd79:  mux_out = 26;
            10'd78:  mux_out = 26;
            10'd77:  mux_out = 25;
            10'd76:  mux_out = 25;
            10'd75:  mux_out = 25;
            10'd74:  mux_out = 24;
            10'd73:  mux_out = 24;
            10'd72:  mux_out = 24;
            10'd71:  mux_out = 23;
            10'd70:  mux_out = 23;
            10'd69:  mux_out = 23;
            10'd68:  mux_out = 22;
            10'd67:  mux_out = 22;
            10'd66:  mux_out = 22;
            10'd65:  mux_out = 21;
            10'd64:  mux_out = 21;
            10'd63:  mux_out = 21;
            10'd62:  mux_out = 20;
            10'd61:  mux_out = 20;
            10'd60:  mux_out = 20;
            10'd59:  mux_out = 19;
            10'd58:  mux_out = 19;
            10'd57:  mux_out = 19;
            10'd56:  mux_out = 18;
            10'd55:  mux_out = 18;
            10'd54:  mux_out = 18;
            10'd53:  mux_out = 17;
            10'd52:  mux_out = 17;
            10'd51:  mux_out = 17;
            10'd50:  mux_out = 16;
            10'd49:  mux_out = 16;
            10'd48:  mux_out = 16;
            10'd47:  mux_out = 15;
            10'd46:  mux_out = 15;
            10'd45:  mux_out = 15;
            10'd44:  mux_out = 14;
            10'd43:  mux_out = 14;
            10'd42:  mux_out = 14;
            10'd41:  mux_out = 13;
            10'd40:  mux_out = 13;
            10'd39:  mux_out = 13;
            10'd38:  mux_out = 12;
            10'd37:  mux_out = 12;
            10'd36:  mux_out = 12;
            10'd35:  mux_out = 11;
            10'd34:  mux_out = 11;
            10'd33:  mux_out = 11;
            10'd32:  mux_out = 10;
            10'd31:  mux_out = 10;
            10'd30:  mux_out = 10;
            10'd29:  mux_out = 9;
            10'd28:  mux_out = 9;
            10'd27:  mux_out = 9;
            10'd26:  mux_out = 8;
            10'd25:  mux_out = 8;
            10'd24:  mux_out = 8;
            10'd23:  mux_out = 7;
            10'd22:  mux_out = 7;
            10'd21:  mux_out = 7;
            10'd20:  mux_out = 6;
            10'd19:  mux_out = 6;
            10'd18:  mux_out = 6;
            10'd17:  mux_out = 5;
            10'd16:  mux_out = 5;
            10'd15:  mux_out = 5;
            10'd14:  mux_out = 4;
            10'd13:  mux_out = 4;
            10'd12:  mux_out = 4;
            10'd11:  mux_out = 3;
            10'd10:  mux_out = 3;
            10'd9:   mux_out = 3;
            10'd8:   mux_out = 2;
            10'd7:   mux_out = 2;
            10'd6:   mux_out = 2;
            10'd5:   mux_out = 1;
            10'd4:   mux_out = 1;
            10'd3:   mux_out = 1;
            -10'd3:  mux_out = -1;
            -10'd4:  mux_out = -1;
            -10'd5:  mux_out = -1;
            -10'd6:  mux_out = -2;
            -10'd7:  mux_out = -2;
            -10'd8:  mux_out = -2;
            -10'd9:  mux_out = -3;
            -10'd10: mux_out = -3;
            -10'd11: mux_out = -3;
            -10'd12: mux_out = -4;
            -10'd13: mux_out = -4;
            -10'd14: mux_out = -4;
            -10'd15: mux_out = -5;
            -10'd16: mux_out = -5;
            -10'd17: mux_out = -5;
            -10'd18: mux_out = -6;
            -10'd19: mux_out = -6;
            -10'd20: mux_out = -6;
            -10'd21: mux_out = -7;
            -10'd22: mux_out = -7;
            -10'd23: mux_out = -7;
            -10'd24: mux_out = -8;
            -10'd25: mux_out = -8;
            -10'd26: mux_out = -8;
            -10'd27: mux_out = -9;
            -10'd28: mux_out = -9;
            -10'd29: mux_out = -9;
            -10'd30: mux_out = -10;
            -10'd31: mux_out = -10;
            -10'd32: mux_out = -10;
            -10'd33: mux_out = -11;
            -10'd34: mux_out = -11;
            -10'd35: mux_out = -11;
            -10'd36: mux_out = -12;
            -10'd37: mux_out = -12;
            -10'd38: mux_out = -12;
            -10'd39: mux_out = -13;
            -10'd40: mux_out = -13;
            -10'd41: mux_out = -13;
            -10'd42: mux_out = -14;
            -10'd43: mux_out = -14;
            -10'd44: mux_out = -14;
            -10'd45: mux_out = -15;
            -10'd46: mux_out = -15;
            -10'd47: mux_out = -15;
            -10'd48: mux_out = -16;
            -10'd49: mux_out = -16;
            //-10'd50: mux_out = -16;
            default: mux_out = 0;
        endcase
    end




    always @(*) begin
        if (opt[2]) out_n = (sum_out[9])?~sum_out:sum_out+1;
        else out_n = mux_out;
    end

endmodule

//merge sort, from big to small
module sort (
    in0,
    in1,
    in2,
    in3,
    in4,
    out0,
    out1,
    out2,
    out3,
    out4
);
    //port
    input wire [3:0] in0, in1, in2, in3, in4;
    output wire [3:0] out0, out1, out2, out3, out4;
    //wire
    wire [3:0] round1[0:4];
    wire [3:0] round2[0:4];
    wire [3:0] round3[0:4];
    wire [3:0] round4[0:4];
    wire [3:0] round5[2:3];
    //round1
    assign round1[0] = (in0 > in1) ? in0 : in1;
    assign round1[1] = (in0 > in1) ? in1 : in0;
    assign round1[2] = (in2 > in3) ? in2 : in3;
    assign round1[3] = (in2 > in3) ? in3 : in2;
    assign round1[4] = in4;

    assign round2[0] = (round1[0] > round1[2]) ? round1[0] : round1[2];  //max_temp
    assign round2[2] = (round1[0] > round1[2]) ? round1[2] : round1[0];
    assign round2[1] = (round1[1] > round1[3]) ? round1[1] : round1[3];
    assign round2[3] = (round1[1] > round1[3]) ? round1[3] : round1[1];  //min_temp
    assign round2[4] = round1[4];

    assign round3[0] = round2[0];
    assign round3[1] = (round2[1] > round2[2]) ? round2[1] : round2[2];
    assign round3[2] = (round2[1] > round2[2]) ? round2[2] : round2[1];
    assign round3[3] = (round2[3] > round2[4]) ? round2[3] : round2[4];
    assign out4      = (round2[3] > round2[4]) ? round2[4] : round2[3];  //min

    assign out0      = (round3[0] > round3[3]) ? round3[0] : round3[3];  //max
    assign round4[3] = (round3[0] > round3[3]) ? round3[3] : round3[0];
    assign round4[1] = round3[1];
    assign round4[2] = round3[2];

    assign out1      = (round4[1] > round4[3]) ? round4[1] : round4[3];
    assign round5[3] = (round4[1] > round4[3]) ? round4[3] : round4[1];
    assign round5[2] = round4[2];

    assign out2      = (round5[2] > round5[3]) ? round5[2] : round5[3];
    assign out3      = (round5[2] > round5[3]) ? round5[3] : round5[2];

endmodule
/*
module FA (in1, in2, cin, sum, cout);
  
input in1, in2, cin ;
output sum, cout ;

assign sum = in1 ^ in2 ^ cin ;
assign cout = (in1 & in2) | (in1 & cin) | (in2 & cin) ;

endmodule

module five_bit_adder (in1, in2, out) ;
  
  input  [4:0]in1, in2 ;
  output [5:0]out ;
  
  wire [3:0]cin ;
  
  FA m0 (.in1(in1[0]), .in2(in2[0]), .cin(1'b0), .sum(out[0]), .cout(cin[0])) ;
  FA m1 (.in1(in1[1]), .in2(in2[1]), .cin(cin[0]), .sum(out[1]), .cout(cin[1])) ;
  FA m2 (.in1(in1[2]), .in2(in2[2]), .cin(cin[1]), .sum(out[2]), .cout(cin[2])) ;
  FA m3 (.in1(in1[3]), .in2(in2[3]), .cin(cin[2]), .sum(out[3]), .cout(cin[3])) ;
  FA m4 (.in1(in1[4]), .in2(in2[4]), .cin(cin[3]), .sum(out[4]), .cout(out[5])) ;
  
  endmodule
  
  module six_bit_adder (in1, in2, out) ;
  
  input  [5:0]in1, in2 ;
  output [6:0]out ;
  
  wire [4:0]cin ;
  
  FA m5 (.in1(in1[0]), .in2(in2[0]), .cin(1'b0), .sum(out[0]), .cout(cin[0])) ;
  FA m6 (.in1(in1[1]), .in2(in2[1]), .cin(cin[0]), .sum(out[1]), .cout(cin[1])) ;
  FA m7 (.in1(in1[2]), .in2(in2[2]), .cin(cin[1]), .sum(out[2]), .cout(cin[2])) ;
  FA m8 (.in1(in1[3]), .in2(in2[3]), .cin(cin[2]), .sum(out[3]), .cout(cin[3])) ;
  FA m9 (.in1(in1[4]), .in2(in2[4]), .cin(cin[3]), .sum(out[4]), .cout(cin[4])) ;
  FA m10 (.in1(in1[5]), .in2(in2[5]), .cin(cin[4]), .sum(out[5]), .cout(out[6])) ;
  
  endmodule

  module seven_bit_adder (in1, in2, out) ;
  
  input  [6:0]in1, in2 ;
  output [7:0]out ;
  
  wire [5:0]cin ;
  
  FA m11 (.in1(in1[0]), .in2(in2[0]), .cin(1'b0), .sum(out[0]), .cout(cin[0])) ;
  FA m12 (.in1(in1[1]), .in2(in2[1]), .cin(cin[0]), .sum(out[1]), .cout(cin[1])) ;
  FA m13 (.in1(in1[2]), .in2(in2[2]), .cin(cin[1]), .sum(out[2]), .cout(cin[2])) ;
  FA m14 (.in1(in1[3]), .in2(in2[3]), .cin(cin[2]), .sum(out[3]), .cout(cin[3])) ;
  FA m15 (.in1(in1[4]), .in2(in2[4]), .cin(cin[3]), .sum(out[4]), .cout(cin[4])) ;
  FA m16 (.in1(in1[5]), .in2(in2[5]), .cin(cin[4]), .sum(out[5]), .cout(cin[5])) ;
  FA m17 (.in1(in1[6]), .in2(in2[6]), .cin(cin[5]), .sum(out[6]), .cout(out[7])) ; 
  endmodule

  module four_bit_signed_mult (
    in1,in2,out
  );
  input [4:0] in1,in2;
  output [8:0] out;

  wire flag1,flag2;
  wire [3:0] in1_inv,in2_inv;
  assign flag1 = in1[4];
  assign flag2 = in2[4];
  assign in1_inv = (flag1)? ~(in1)+1:in1;
  assign in2_inv = (flag2)? ~(in2)+1:in2;

  wire [5:0] temp_1;
  wire [6:0] temp_2;
  wire [7:0] temp_3;
  
  five_bit_adder s1 (.in1({1'b0, in1_inv&{4{in2_inv[0]}}}), .in2({in1_inv, 1'b0} & {5{in2_inv[1]}}), .out(temp_1));
  six_bit_adder s2 (.in1(temp_1), .in2({in1_inv, 2'b00} & {6{in2_inv[2]}}), .out(temp_2));
  seven_bit_adder s3 (.in1(temp_2), .in2({in1_inv, 3'b000} & {7{in2_inv[3]}}), .out(temp_3));

  assign out = (flag1 == flag2)? temp_3:~({1'b0,temp_3})+1;


    
  endmodule*/