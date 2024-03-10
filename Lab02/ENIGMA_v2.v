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
//   Release version : V2.0 (Release Date: 2024-02)   182482.980157
//                     B以7:0table判斷旋轉後的元素， always@(if....)判斷位置
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
    reg [5:0] A_rot[0:63];
    reg [5:0] A_inv[0:63];
    reg [5:0] B_rot[0:63];
    reg [5:0] B_inv[0:63];
    //reg [5:0] n_B_rot[0:63];
    reg [5:0] n_B_inv[0:63];
    reg [2:0] B_pos[0:7];
    reg [2:0] n_B_pos[0:7];

    reg [6:0] counter;  //0~63 64~127
    wire [2:0] in_B_column;
    wire [5:0] in_B;
    reg [2:0] in_A_inv_column;
    wire [5:0] in_A_inv;
    wire [5:0] out_A, out_B, out_reflect, out_B_inv, out_A_inv;
    reg [5:0] shift_right;
    wire [1:0] n_shift_right;
    reg [2:0] mode_rotate;
    wire [2:0] n_mode_rotate;
    reg valid_delay;
    reg [5:0] in_string;
    // ===============================================================
    // Design
    // ===============================================================
    assign out_A = A_rot[in_string-shift_right];
    assign in_B_column = B_pos[out_A[2:0]];
    assign in_B = {out_A[5:3],in_B_column};
    assign out_B = B_rot[in_B];
    assign out_reflect = ~(out_B);
    assign out_B_inv = B_inv[out_reflect];
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
    assign out_A_inv = A_inv[in_A_inv] + shift_right;
    assign n_shift_right = (mode) ? in_A_inv[1:0] : out_A[1:0];
    assign n_mode_rotate = (mode) ? out_reflect[2:0] : out_B[2:0];

    //
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) in_string <= 0;
        else if (in_valid_2) in_string <= code_in;
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
    //n_B_pos
    always@(*)begin
        if(valid_delay) begin
        case(n_mode_rotate)
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
        endcase end
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
    

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 64; i = i + 1) B_inv[i] <= 0;
        end
        else if (in_valid && counter[6]) begin
            B_inv[code_in] <= counter[5:0];
        end
        else begin
            for (i = 0; i < 64; i = i + 1) B_inv[i] <= B_inv[i];
        end
    end

    //B_rot
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 64; i = i + 1) B_rot[i] <= 0;
        end 
        else if (in_valid && counter[6]) begin
            B_rot[63] <= code_in;
            for (i = 0; i < 63; i = i + 1) B_rot[i] <= B_rot[i+1];
        end
        else begin
            for (i = 0; i < 64; i = i + 1) B_rot[i] <= B_rot[i];
        end
    end

    //A_inv
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 64; i = i + 1) A_inv[i] <= 0;
        end
        else if (in_valid && !counter[6]) begin
            A_inv[code_in] <= counter[5:0];
        end 
        else begin
            for (i = 0; i < 64; i = i + 1) A_inv[i] <= A_inv[i];
        end
    end
    //A_rot
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 64; i = i + 1) A_rot[i] <= 0;
        end 
        else if (in_valid && !counter[6]) begin
            A_rot[63] <= code_in;
            for (i = 0; i < 63; i = i + 1) A_rot[i] <= A_rot[i+1];
        end 
        else begin
            for (i = 0; i < 64; i = i + 1) A_rot[i] <= A_rot[i];
        end
    end



    //mode 
    assign n_mode = (counter == 0 && in_valid) ? crypt_mode : mode;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) mode <= 0;
        else mode <= n_mode;
    end

    //output

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) counter <= 0;
        else if (in_valid) counter <= counter + 1;
        else counter <= 0;
    end

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

