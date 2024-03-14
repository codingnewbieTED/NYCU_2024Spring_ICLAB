//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Spring
//   Lab02 Exercise		: Enigma
//   Author     		: Yi-Xuan, Ran
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : ENIGMA.v
//   Module Name : ENIGMA
//   Release version : V3.0 (Release Date: 2024-02)   157285.497937    140560.360673  122697.589481 119933.353907  119860.173100 119640.630808 119351.234076 11680.8
// 
//                                                    拔rst_n          拔A_inv         拔B_inv       control    
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module ENIGMA (
    // Input Ports
    clk,
    rst_n,
    in_valid,
    in_valid_2,
    crypt_mode,
    code_in,

    // Output Ports
    out_code,
    out_valid
);

    // ===============================================================
    // Input & Output Declaration
    // ===============================================================
    input clk;  // clock input
    input rst_n;  // asynchronous reset (active low)
    input in_valid;  // code_in valid signal for rotor (level sensitive). 0/1: inactive/active
    input in_valid_2;  // code_in valid signal for code  (level sensitive). 0/1: inactive/active
    input crypt_mode;  // 0: encrypt; 1:decrypt; only valid for 1 cycle when in_valid is active

    input [6-1:0] code_in;  // When in_valid   is active, then code_in is input of rotors. 
    // When in_valid_2 is active, then code_in is input of code words.

    output reg out_valid;  // 0: out_code is not valid; 1: out_code is valid
    output reg [6-1:0] out_code;  // encrypted/decrypted code word
    //================================================================
    //  integer / genvar / parameters
    //================================================================
    integer i;
    genvar r;
    genvar rotation;
    //================================================================
    //   Wires & Registers 
    //================================================================
    reg mode;
    wire n_mode;
    reg [5:0] A_rot[0:127];
    //reg [5:0] B_rot[0:63];
    reg [2:0] B_pos[0:7];
    reg [2:0] n_B_pos[0:7];

    //reg [6:0] counter;  //0~63 64~127
    wire [2:0] in_B_column;
    wire [6:0] in_B;
    reg [2:0] in_A_inv_column;
    wire [5:0] in_A_inv;
    wire [5:0] out_reflect, out_A_inv; 
	reg [5:0] out_A,out_B;
    reg [5:0] out_B_inv;
    reg [5:0] shift_right;
    wire [1:0] n_shift_right;
    wire [2:0] n_mode_rotate;
    reg valid_delay;
    reg [5:0] in_string;
    // ===============================================================
    // Design
    // ===============================================================

    //================================================================
    //  PREOUTPUT//latency 1
    //================================================================
    // A
    //assign out_A = A_rot[{1'd0,in_string}];   
    // B
	always@(*)begin
		if(in_string[5:3]==0)  out_A = A_rot[{1'd0,3'd0,in_string[2:0]}];
		else if(in_string[5:3]==1)  out_A = A_rot[{1'd0,3'd1,in_string[2:0]}];
		else if(in_string[5:3]==2)  out_A = A_rot[{1'd0,3'd2,in_string[2:0]}];	
		else if(in_string[5:3]==3)  out_A = A_rot[{1'd0,3'd3,in_string[2:0]}];
		else if(in_string[5:3]==4)  out_A = A_rot[{1'd0,3'd4,in_string[2:0]}];
		else if(in_string[5:3]==5)  out_A = A_rot[{1'd0,3'd5,in_string[2:0]}];
		else if(in_string[5:3]==6)  out_A = A_rot[{1'd0,3'd6,in_string[2:0]}];
		else out_A = A_rot[{1'd0,3'd7,in_string[2:0]}];
	end
    assign in_B_column =  B_pos[out_A[2:0]]; //B_pos[in_string[2:0]];
	/*
	always@(*)begin
		if(out_A[2:0]==0)  in_B_column = B_pos[0];
		else if(out_A[2:0]==1)  in_B_column = B_pos[1];
		else if(out_A[2:0]==2)  in_B_column = B_pos[2];
		else if(out_A[2:0]==3)  in_B_column = B_pos[3];
		else if(out_A[2:0]==4)  in_B_column = B_pos[4];
		else if(out_A[2:0]==5)  in_B_column =  B_pos[5];
		else if(out_A[2:0]==6)  in_B_column = B_pos[6];
		else in_B_column = B_pos[7];
	end*/
    //assign in_B = {1'd1,out_A[5:3],in_B_column};//{in_string[5:3],in_B_column};
    //assign out_B = A_rot[in_B];
	always@(*)begin
		if(out_A[5:3]==0)  out_B = A_rot[{1'd1,3'd0,in_B_column[2:0]}];
		else if(out_A[5:3]==1)  out_B = A_rot[{1'd1,3'd1,in_B_column[2:0]}];
		else if(out_A[5:3]==2)  out_B = A_rot[{1'd1,3'd2,in_B_column[2:0]}];	
		else if(out_A[5:3]==3)  out_B = A_rot[{1'd1,3'd3,in_B_column[2:0]}];
		else if(out_A[5:3]==4)  out_B = A_rot[{1'd1,3'd4,in_B_column[2:0]}];
		else if(out_A[5:3]==5)  out_B = A_rot[{1'd1,3'd5,in_B_column[2:0]}];
		else if(out_A[5:3]==6)  out_B = A_rot[{1'd1,3'd6,in_B_column[2:0]}];
		else out_B = A_rot[{1'd1,3'd7,in_B_column[2:0]}];
	end

    // reflector
    assign out_reflect = ~(out_B);
    //B_inv
    always@(*)begin
        if(out_reflect == A_rot[64])  out_B_inv = 0;
        else if (out_reflect == A_rot[65]) out_B_inv = 1;
            else if (out_reflect == A_rot[66]) out_B_inv = 2;
            else if (out_reflect == A_rot[67]) out_B_inv = 3;
            else if (out_reflect == A_rot[68]) out_B_inv = 4;
            else if (out_reflect == A_rot[69]) out_B_inv = 5;
            else if (out_reflect == A_rot[70]) out_B_inv = 6;
            else if (out_reflect == A_rot[71]) out_B_inv = 7;
            else if (out_reflect == A_rot[72]) out_B_inv = 8;
            else if (out_reflect == A_rot[73]) out_B_inv = 9;
            else if (out_reflect == A_rot[74]) out_B_inv = 10;
            else if (out_reflect == A_rot[75]) out_B_inv = 11;
            else if (out_reflect == A_rot[76]) out_B_inv = 12;
            else if (out_reflect == A_rot[77]) out_B_inv = 13;
            else if (out_reflect == A_rot[78]) out_B_inv = 14;
            else if (out_reflect == A_rot[79]) out_B_inv = 15;
            else if (out_reflect == A_rot[80]) out_B_inv = 16;
            else if (out_reflect == A_rot[81]) out_B_inv = 17;
            else if (out_reflect == A_rot[82]) out_B_inv = 18;
            else if (out_reflect == A_rot[83]) out_B_inv = 19;
            else if (out_reflect == A_rot[84]) out_B_inv = 20;
            else if (out_reflect == A_rot[85]) out_B_inv = 21;
            else if (out_reflect == A_rot[86]) out_B_inv = 22;
            else if (out_reflect == A_rot[87]) out_B_inv = 23;
            else if (out_reflect == A_rot[88]) out_B_inv = 24;
            else if (out_reflect == A_rot[89]) out_B_inv = 25;
            else if (out_reflect == A_rot[90]) out_B_inv = 26;
            else if (out_reflect == A_rot[91]) out_B_inv = 27;
            else if (out_reflect == A_rot[92]) out_B_inv = 28;
            else if (out_reflect == A_rot[93]) out_B_inv = 29;
            else if (out_reflect == A_rot[94]) out_B_inv = 30;
            else if (out_reflect == A_rot[95]) out_B_inv = 31;
            else if (out_reflect == A_rot[96]) out_B_inv = 32;
            else if (out_reflect == A_rot[97]) out_B_inv = 33;
            else if (out_reflect == A_rot[98]) out_B_inv = 34;
            else if (out_reflect == A_rot[99]) out_B_inv = 35;
            else if (out_reflect == A_rot[100]) out_B_inv = 36;
            else if (out_reflect == A_rot[101]) out_B_inv = 37;
            else if (out_reflect == A_rot[102]) out_B_inv = 38;
            else if (out_reflect == A_rot[103]) out_B_inv = 39;
            else if (out_reflect == A_rot[104]) out_B_inv = 40;
            else if (out_reflect == A_rot[105]) out_B_inv = 41;
            else if (out_reflect == A_rot[106]) out_B_inv = 42;
            else if (out_reflect == A_rot[107]) out_B_inv = 43;
            else if (out_reflect == A_rot[108]) out_B_inv = 44;
            else if (out_reflect == A_rot[109]) out_B_inv = 45;
            else if (out_reflect == A_rot[110]) out_B_inv = 46;
            else if (out_reflect == A_rot[111]) out_B_inv = 47;
            else if (out_reflect == A_rot[112]) out_B_inv = 48;
            else if (out_reflect == A_rot[113]) out_B_inv = 49;
            else if (out_reflect == A_rot[114]) out_B_inv = 50;
            else if (out_reflect == A_rot[115]) out_B_inv = 51;
            else if (out_reflect == A_rot[116]) out_B_inv = 52;
            else if (out_reflect == A_rot[117]) out_B_inv = 53;
            else if (out_reflect == A_rot[118]) out_B_inv = 54;
            else if (out_reflect == A_rot[119]) out_B_inv = 55;
            else if (out_reflect == A_rot[120]) out_B_inv = 56;
            else if (out_reflect == A_rot[121]) out_B_inv = 57;
            else if (out_reflect == A_rot[122]) out_B_inv = 58;
            else if (out_reflect == A_rot[123]) out_B_inv = 59;
            else if (out_reflect == A_rot[124]) out_B_inv = 60;
            else if (out_reflect == A_rot[125]) out_B_inv = 61;
            else if (out_reflect == A_rot[126]) out_B_inv = 62;
            else  out_B_inv = 63;
    end
    always@(*)begin
        if(out_B_inv[2:0] == B_pos[0])  in_A_inv_column = 0;
        else if(out_B_inv[2:0] == B_pos[1])  in_A_inv_column = 1;
        else if(out_B_inv[2:0] == B_pos[2])  in_A_inv_column = 2;
        else if(out_B_inv[2:0] == B_pos[3])  in_A_inv_column = 3;
        else if(out_B_inv[2:0] == B_pos[4])  in_A_inv_column = 4;
        else if(out_B_inv[2:0] == B_pos[5])  in_A_inv_column = 5;
        else if(out_B_inv[2:0] == B_pos[6])  in_A_inv_column = 6;
        else   in_A_inv_column = 7;
    end
    assign in_A_inv = {out_B_inv[5:3] , in_A_inv_column};
    //A_inv 
    reg [5:0] n_out_A_inv;
    always@(*)begin
        if(in_A_inv == A_rot[0])  n_out_A_inv = 0;
        else if (in_A_inv == A_rot[1]) n_out_A_inv = 1;
        else if (in_A_inv == A_rot[2]) n_out_A_inv = 2;
        else if (in_A_inv == A_rot[3]) n_out_A_inv = 3;
        else if (in_A_inv == A_rot[4]) n_out_A_inv = 4;
        else if (in_A_inv == A_rot[5]) n_out_A_inv = 5;
        else if (in_A_inv == A_rot[6]) n_out_A_inv = 6;
        else if (in_A_inv == A_rot[7]) n_out_A_inv = 7;
        else if (in_A_inv == A_rot[8]) n_out_A_inv = 8;
        else if (in_A_inv == A_rot[9]) n_out_A_inv = 9;
        else if (in_A_inv == A_rot[10]) n_out_A_inv = 10;
        else if (in_A_inv == A_rot[11]) n_out_A_inv = 11;
        else if (in_A_inv == A_rot[12]) n_out_A_inv = 12;
        else if (in_A_inv == A_rot[13]) n_out_A_inv = 13;
        else if (in_A_inv == A_rot[14]) n_out_A_inv = 14;
        else if (in_A_inv == A_rot[15]) n_out_A_inv = 15;
        else if (in_A_inv == A_rot[16]) n_out_A_inv = 16;
        else if (in_A_inv == A_rot[17]) n_out_A_inv = 17;
        else if (in_A_inv == A_rot[18]) n_out_A_inv = 18;
        else if (in_A_inv == A_rot[19]) n_out_A_inv = 19;
        else if (in_A_inv == A_rot[20]) n_out_A_inv = 20;
        else if (in_A_inv == A_rot[21]) n_out_A_inv = 21;
        else if (in_A_inv == A_rot[22]) n_out_A_inv = 22;
        else if (in_A_inv == A_rot[23]) n_out_A_inv = 23;
        else if (in_A_inv == A_rot[24]) n_out_A_inv = 24;
        else if (in_A_inv == A_rot[25]) n_out_A_inv = 25;
        else if (in_A_inv == A_rot[26]) n_out_A_inv = 26;
        else if (in_A_inv == A_rot[27]) n_out_A_inv = 27;
        else if (in_A_inv == A_rot[28]) n_out_A_inv = 28;
        else if (in_A_inv == A_rot[29]) n_out_A_inv = 29;
        else if (in_A_inv == A_rot[30]) n_out_A_inv = 30;
        else if (in_A_inv == A_rot[31]) n_out_A_inv = 31;
        else if (in_A_inv == A_rot[32]) n_out_A_inv = 32;
        else if (in_A_inv == A_rot[33]) n_out_A_inv = 33;
        else if (in_A_inv == A_rot[34]) n_out_A_inv = 34;
        else if (in_A_inv == A_rot[35]) n_out_A_inv = 35;
        else if (in_A_inv == A_rot[36]) n_out_A_inv = 36;
        else if (in_A_inv == A_rot[37]) n_out_A_inv = 37;
        else if (in_A_inv == A_rot[38]) n_out_A_inv = 38;
        else if (in_A_inv == A_rot[39]) n_out_A_inv = 39;
        else if (in_A_inv == A_rot[40]) n_out_A_inv = 40;
        else if (in_A_inv == A_rot[41]) n_out_A_inv = 41;
        else if (in_A_inv == A_rot[42]) n_out_A_inv = 42;
        else if (in_A_inv == A_rot[43]) n_out_A_inv = 43;
        else if (in_A_inv == A_rot[44]) n_out_A_inv = 44;
        else if (in_A_inv == A_rot[45]) n_out_A_inv = 45;
        else if (in_A_inv == A_rot[46]) n_out_A_inv = 46;
        else if (in_A_inv == A_rot[47]) n_out_A_inv = 47;
        else if (in_A_inv == A_rot[48]) n_out_A_inv = 48;
        else if (in_A_inv == A_rot[49]) n_out_A_inv = 49;
        else if (in_A_inv == A_rot[50]) n_out_A_inv = 50;
        else if (in_A_inv == A_rot[51]) n_out_A_inv = 51;
        else if (in_A_inv == A_rot[52]) n_out_A_inv = 52;
        else if (in_A_inv == A_rot[53]) n_out_A_inv = 53;
        else if (in_A_inv == A_rot[54]) n_out_A_inv = 54;
        else if (in_A_inv == A_rot[55]) n_out_A_inv = 55;
        else if (in_A_inv == A_rot[56]) n_out_A_inv = 56;
        else if (in_A_inv == A_rot[57]) n_out_A_inv = 57;
        else if (in_A_inv == A_rot[58]) n_out_A_inv = 58;
        else if (in_A_inv == A_rot[59]) n_out_A_inv = 59;
        else if (in_A_inv == A_rot[60]) n_out_A_inv = 60;
        else if (in_A_inv == A_rot[61]) n_out_A_inv = 61;
        else if (in_A_inv == A_rot[62]) n_out_A_inv = 62;
        else  n_out_A_inv = 63;
    end

    assign out_A_inv = n_out_A_inv + shift_right;

    //rotate&shift 
    assign n_shift_right = (mode) ? in_A_inv[1:0] : out_A[1:0];
    assign n_mode_rotate = (mode) ? out_reflect[2:0] : out_B[2:0];

    //instring
    //wire [5:0]shift;
    ////wire [5:0]shift_in;
    //assign shift = n_shift_right + shift_right;
    //assign shift_in = code_in - shift;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) in_string <= 0;
        else if (valid_delay) in_string <= code_in - shift_right - n_shift_right;//A_rot[shift_in]; cp is <<10ns further reduce cp gains no benefits!
        else if(in_valid_2) in_string <= code_in; //A_rot[code_in];
        else in_string <= 0;
    end


    //shift_reg
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) shift_right <= 0;
        else if (valid_delay) shift_right <= shift_right + n_shift_right;
        else shift_right <= 0;
    end

    //out_control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) valid_delay <= 0;
        else valid_delay <= in_valid_2;
    end
    //================================================================
    //  ROTATE Feature
    //================================================================
    //B_pos
    always@(*)begin
        if(valid_delay) begin
            if(n_mode_rotate == 1) n_B_pos[0] = B_pos[1];
            else if(n_mode_rotate == 2) n_B_pos[0] = B_pos[2];
            else if(n_mode_rotate == 4) n_B_pos[0] = B_pos[4];
            else if(n_mode_rotate == 5) n_B_pos[0] = B_pos[5];
            else if(n_mode_rotate == 6) n_B_pos[0] = B_pos[6];
            else if(n_mode_rotate == 7) n_B_pos[0] = B_pos[7];   
            else n_B_pos[0] = B_pos[0]; 
            
            if (n_mode_rotate == 0) n_B_pos[1] = B_pos[1];
            else if(n_mode_rotate == 1) n_B_pos[1] = B_pos[0];
            else if(n_mode_rotate == 2) n_B_pos[1] = B_pos[3];
            else if(n_mode_rotate == 3) n_B_pos[1] = B_pos[4];
            else if(n_mode_rotate == 4) n_B_pos[1] = B_pos[5];
            //else if(n_mode_rotate == 5) n_B_pos[1] = B_pos[6];
            else if(n_mode_rotate == 6) n_B_pos[1] = B_pos[7];   
            //else if(n_mode_rotate == 7) n_B_pos[1] = B_pos[6]; 
            else  n_B_pos[1] = B_pos[6];

            if(n_mode_rotate == 0) n_B_pos[2] = B_pos[2];  
            else if(n_mode_rotate == 2) n_B_pos[2] = B_pos[0];
            else if(n_mode_rotate == 3) n_B_pos[2] = B_pos[5];
            else if(n_mode_rotate == 4) n_B_pos[2] = B_pos[6];
            else if(n_mode_rotate == 5) n_B_pos[2] = B_pos[7];
            //else if(n_mode_rotate = 6) n_B_pos[2] = B_pos[7];   
            else if(n_mode_rotate == 7) n_B_pos[2] = B_pos[5]; 
            else  n_B_pos[2] = B_pos[3];

            if(n_mode_rotate == 1) n_B_pos[3] = B_pos[2];   //3 2 1 6 7 3 2 4
            else if(n_mode_rotate == 2) n_B_pos[3] = B_pos[1];
            else if(n_mode_rotate == 3) n_B_pos[3] = B_pos[6];
            else if(n_mode_rotate == 4) n_B_pos[3] = B_pos[7];
            else if(n_mode_rotate == 6) n_B_pos[3] = B_pos[2];
            else if(n_mode_rotate == 7) n_B_pos[3] = B_pos[4];   
           // else if(n_mode_rotate = 7) n_B_pos[3] = B_pos[6]; 
            else  n_B_pos[3] = B_pos[3];

            if(n_mode_rotate ==1) n_B_pos[4] = B_pos[5];   //4 5 6 1 0 4 5 3
            else if(n_mode_rotate == 2) n_B_pos[4] = B_pos[6];
            else if(n_mode_rotate == 3) n_B_pos[4] = B_pos[1];
            else if(n_mode_rotate == 4) n_B_pos[4] = B_pos[0];
            else if(n_mode_rotate == 6) n_B_pos[4] = B_pos[5];
            else if(n_mode_rotate == 7) n_B_pos[4] = B_pos[3];   
           // else if(n_mode_rotate = 7) n_B_pos[4] = B_pos[6]; 
            else  n_B_pos[4] = B_pos[4];

            if(n_mode_rotate == 0) n_B_pos[5] = B_pos[5];   //5 4 7 2 1 0 4 2
            else if(n_mode_rotate== 2) n_B_pos[5] = B_pos[7];
            else if(n_mode_rotate == 3) n_B_pos[5] = B_pos[2];
            else if(n_mode_rotate == 4) n_B_pos[5] = B_pos[1];
            else if(n_mode_rotate == 5) n_B_pos[5] = B_pos[0];
            else if(n_mode_rotate == 7) n_B_pos[5] = B_pos[2];   
           // else if(n_mode_rotate = 7) n_B_pos[3] = B_pos[6]; 
            else  n_B_pos[5] = B_pos[4];

            if(n_mode_rotate == 0) n_B_pos[6] = B_pos[6];   //6 7 4 3 2 1 0 1
            else if(n_mode_rotate== 1) n_B_pos[6] = B_pos[7];
            else if(n_mode_rotate== 2) n_B_pos[6] = B_pos[4];
            else if(n_mode_rotate == 3) n_B_pos[6] = B_pos[3];
            else if(n_mode_rotate == 4) n_B_pos[6] = B_pos[2];
            else if(n_mode_rotate == 6) n_B_pos[6] = B_pos[0];   
           // else if(n_mode_rotate = 7) n_B_pos[3] = B_pos[6]; 
            else  n_B_pos[6] = B_pos[1];
     
            if(n_mode_rotate == 1) n_B_pos[7] = B_pos[6];   //7 6 5 7 3 2 1 0
            else if(n_mode_rotate == 2) n_B_pos[7] = B_pos[5];
            else if(n_mode_rotate == 4) n_B_pos[7] = B_pos[3];
            else if(n_mode_rotate == 5) n_B_pos[7] = B_pos[2];
            else if(n_mode_rotate == 6) n_B_pos[7] = B_pos[1];
            else if(n_mode_rotate == 7) n_B_pos[7] = B_pos[0];   
           // else if(n_mode_rotate = 7) n_B_pos[3] = B_pos[6]; 
            else  n_B_pos[7] = B_pos[7];            
        
                             
        /*case(n_mode_rotate)
        3'd0: begin
            n_B_pos[0] = B_pos[0];
            n_B_pos[1] = B_pos[1];
            n_B_pos[2] = B_pos[2];
            n_B_pos[3] = B_pos[3];
            n_B_pos[4] = B_pos[4];
            n_B_pos[5] = B_pos[5];
            n_B_pos[6] = B_pos[6];
            n_B_pos[7] = B_pos[7];
        end
        3'd1: begin
            n_B_pos[0] = B_pos[1];
            n_B_pos[1] = B_pos[0];
            n_B_pos[2] = B_pos[3];
            n_B_pos[3] = B_pos[2];
            n_B_pos[4] = B_pos[5];
            n_B_pos[5] = B_pos[4];
            n_B_pos[6] = B_pos[7];
            n_B_pos[7] = B_pos[6];
        end        
        3'd2: begin
            n_B_pos[0] = B_pos[2];
            n_B_pos[1] = B_pos[3];
            n_B_pos[2] = B_pos[0];
            n_B_pos[3] = B_pos[1];
            n_B_pos[4] = B_pos[6];
            n_B_pos[5] = B_pos[7];
            n_B_pos[6] = B_pos[4];
            n_B_pos[7] = B_pos[5];
        end        
        3'd3: begin
            n_B_pos[0] = B_pos[0];
            n_B_pos[1] = B_pos[4];
            n_B_pos[2] = B_pos[5];
            n_B_pos[3] = B_pos[6];
            n_B_pos[4] = B_pos[1];
            n_B_pos[5] = B_pos[2];
            n_B_pos[6] = B_pos[3];
            n_B_pos[7] = B_pos[7];
        end        
        3'd4: begin
            n_B_pos[0] = B_pos[4];
            n_B_pos[1] = B_pos[5];
            n_B_pos[2] = B_pos[6];
            n_B_pos[3] = B_pos[7];
            n_B_pos[4] = B_pos[0];
            n_B_pos[5] = B_pos[1];
            n_B_pos[6] = B_pos[2];
            n_B_pos[7] = B_pos[3];
        end       
         3'd5: begin
            n_B_pos[0] = B_pos[5];
            n_B_pos[1] = B_pos[6];
            n_B_pos[2] = B_pos[7];
            n_B_pos[3] = B_pos[3];
            n_B_pos[4] = B_pos[4];
            n_B_pos[5] = B_pos[0];
            n_B_pos[6] = B_pos[1];
            n_B_pos[7] = B_pos[2];
        end        
        3'd6: begin
            n_B_pos[0] = B_pos[6];
            n_B_pos[1] = B_pos[7];
            n_B_pos[2] = B_pos[3];
            n_B_pos[3] = B_pos[2];
            n_B_pos[4] = B_pos[5];
            n_B_pos[5] = B_pos[4];
            n_B_pos[6] = B_pos[0];
            n_B_pos[7] = B_pos[1];
        end        
        3'd7: begin
            n_B_pos[0] = B_pos[7];
            n_B_pos[1] = B_pos[6];
            n_B_pos[2] = B_pos[5];
            n_B_pos[3] = B_pos[4];
            n_B_pos[4] = B_pos[3];
            n_B_pos[5] = B_pos[2];
            n_B_pos[6] = B_pos[1];
            n_B_pos[7] = B_pos[0];
        end
        endcase*/ end
        else begin
            n_B_pos[0] = 0;
            n_B_pos[1] = 1;
            n_B_pos[2] = 2;
            n_B_pos[3] = 3;
            n_B_pos[4] = 4;
            n_B_pos[5] = 5;
            n_B_pos[6] = 6;
            n_B_pos[7] = 7;
        end
    end

    always@(posedge clk )begin
        for(i=0;i<8;i=i+1)
            B_pos[i] <= n_B_pos[i];
    end

    //================================================================
    //  INPUT
    //================================================================
    //B_rot 
    /*
    always @(posedge clk) begin
        if (in_valid && counter[6]) begin
            B_rot[63] <= code_in;
            for (i = 0; i < 63; i = i + 1) B_rot[i] <= B_rot[i+1];
        end
        else begin
            for (i = 0; i < 64; i = i + 1) B_rot[i] <= B_rot[i];
        end
    end*/

    //A_rot
    always @(posedge clk ) begin
        if (in_valid) begin
            A_rot[127] <= code_in;
            for (i = 0; i < 127; i = i + 1) A_rot[i] <= A_rot[i+1];
        end 
        else begin
            for (i = 0; i < 128; i = i + 1) A_rot[i] <= A_rot[i];
        end
    end

    //mode 
   reg valid_1_delay;
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n) valid_1_delay <=0;
        else valid_1_delay <= in_valid;
    end
    assign n_mode = (!valid_1_delay && in_valid) ? crypt_mode : mode;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) mode <= 0;
        else mode <= n_mode;
    end

    //cnt
    /*
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) counter <= 0;
        else if (in_valid) counter <= counter + 1;
        else counter <= 0;
    end*/

    //================================================================
    //  OUTPUT : out_valid & out
    //================================================================
    // output reg out_valid;

    always @(negedge rst_n or posedge clk) begin
        if (!rst_n) begin
            out_valid <= 0;
            out_code  <= 0;
        end 
        else if (valid_delay) begin
            out_valid <= 1;
            out_code  <= out_A_inv;
        end 
        else begin
            out_valid <= 0;
            out_code  <= 0;
        end
    end


endmodule


