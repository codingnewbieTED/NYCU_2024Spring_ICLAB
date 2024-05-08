module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
	in_matrix_A,
    in_matrix_B,
    out_idle,
    handshake_sready,
    handshake_din,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

	fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    out_matrix,

    flag_clk1_to_fifo,
    flag_fifo_to_clk1
);
input clk;
input rst_n;
input in_valid;
input [3:0] in_matrix_A;
input [3:0] in_matrix_B;
input out_idle;
output reg handshake_sready;
output reg [7:0] handshake_din;
// You can use the the custom flag ports for your design
input  flag_handshake_to_clk1;
output flag_clk1_to_handshake;

input fifo_empty;
input [7:0] fifo_rdata;
output fifo_rinc;
output reg out_valid;
output reg [7:0] out_matrix;
// You can use the the custom flag ports for your design
output flag_clk1_to_fifo;
input flag_fifo_to_clk1;
//wire
integer i;
reg [7:0] matrix_reg[0:15];
reg [3:0] cnt_in;
parameter IDLE = 0 ,INPUT=1,  HANDSHAKE = 2 ;
reg [1:0] n_state,c_state;

//cnt
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) cnt_in <= 0;
    else if(in_valid || (n_state == HANDSHAKE && out_idle)) cnt_in <= cnt_in+1;
end
//================================================================
//  FSM                 
//================================================================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        c_state <= IDLE;
    end
    else begin
        c_state <= n_state;
    end
end


always@(*) begin
    case (c_state)
    IDLE : begin
        if(in_valid) n_state = INPUT;
        else n_state = IDLE;
    end 
    INPUT:begin
        if( cnt_in==0) n_state = HANDSHAKE;
        else n_state = INPUT;
    end
    HANDSHAKE : begin
        if(cnt_in == 0) n_state = IDLE;
        else n_state = HANDSHAKE;
    end
        default: n_state = IDLE;
    endcase
end
//================================================================
//  HANDSHAKE input Part                 
//================================================================
// assertion will consider all possiblity, only (in_valid) ,without (n_state == INPUT) will reconsider in_valid and make din unstable
// need store all input, after that go handshake syn, can't do them together!!!  otherwise, din unstable 
always@(posedge clk)begin
    if(n_state == INPUT ) begin   
        matrix_reg[15] <= {in_matrix_A,in_matrix_B};
        for(i=0;i<15;i=i+1) matrix_reg[i] <= matrix_reg[i+1];
    end
    else if(c_state == HANDSHAKE && out_idle)
        for(i=0;i<15;i=i+1) matrix_reg[i] <= matrix_reg[i+1];
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) handshake_sready <= 0;
    else if(n_state == HANDSHAKE && out_idle) handshake_sready <= ~handshake_sready;
    else handshake_sready <= handshake_sready;
end
//handshake data in
always@(*) begin
    handshake_din = matrix_reg[0];
end
//================================================================
//  FIFO output Part                 
//================================================================
//output
assign fifo_rinc = ! fifo_empty;

always@(*)begin
    out_valid <= flag_fifo_to_clk1;
    out_matrix <= fifo_rdata;
end

endmodule








module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    in_matrix,
    out_valid,
    out_matrix,
    busy,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [7:0] in_matrix;
output reg out_valid;
output reg [7:0] out_matrix;
output reg busy;

// You can use the the custom flag ports for your design
input  flag_handshake_to_clk2;
output flag_clk2_to_handshake;
input  flag_fifo_to_clk2;
output flag_clk2_to_fifo;

integer i;
reg [3:0] cnt_in;
reg [3:0] cnt_fifo;

parameter IDLE = 0 ,  INPUT = 1 , MULT = 2;
reg [1:0] c_state,n_state;

reg [3:0] matrix_A[0:15];
reg [3:0] matrix_B[0:15];
//================================================================
//  Handshake output  &&   FIFO input Part                 
//================================================================
//input
always@(posedge clk)begin
    if(in_valid)begin
        matrix_A[15] <= in_matrix[7:4];
        for(i=0;i<15;i=i+1)  matrix_A[i] <= matrix_A[i+1];
    end
    else if( c_state == MULT && !fifo_full && &cnt_in[3:0]) 
        for(i=0;i<15;i=i+1)  matrix_A[i] <= matrix_A[i+1];
end

always@(posedge clk)begin
    if(in_valid)begin
        matrix_B[15] <= in_matrix[3:0];
        for(i=0;i<15;i=i+1)  matrix_B[i] <= matrix_B[i+1];
    end
    else if(c_state == MULT && !fifo_full)  begin
        matrix_B[15] <= matrix_B[0];
        for(i=0;i<15;i=i+1)  matrix_B[i] <= matrix_B[i+1];
    end
end
//cnt
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) cnt_in <= 0;
    else if(in_valid || (c_state == MULT && !fifo_full)) cnt_in <= cnt_in + 1;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) cnt_fifo <= 0;
    else if(c_state == MULT && !fifo_full && &cnt_in[3:0])  cnt_fifo <= cnt_fifo + 1;
end
//output
always@(*)begin
    out_matrix =  matrix_A[0] * matrix_B[0];
end

always@(*) begin
    if(c_state == MULT  )   out_valid = !fifo_full;   
    else out_valid = 0;
end
//================================================================
//  FSM                 
//================================================================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        c_state <= IDLE;
    end
    else begin
        c_state <= n_state;
    end
end

always@(*) begin
    case (c_state)
    IDLE : begin
        if(in_valid) n_state = INPUT;
        else n_state = IDLE;
    end 
    INPUT : begin
        if(cnt_in == 0) n_state = MULT;
        else n_state = INPUT;
    end
    MULT: begin
        if( &cnt_fifo && &cnt_in && !fifo_full) n_state = IDLE;
         else n_state = MULT;
    end
    default:n_state = IDLE;
    endcase
end




endmodule

    //================================================================
    //  Optimize                  
    //================================================================
    //================================
    //  Design 1                  
    //================================
    /*
    reg [3:0] cnt_handshake;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) cnt_handshake <= 0;
        else if(n_state == HANDSHAKE && out_idle) cnt_handshake <= cnt_handshake + 1;
    end
    */

    //================================
    //  Design 2              
    //================================
    //84421.768806 --> 82393.773546  by reduce mux area
    //cnt
    /*
    reg [7:0] matrix_reg_clk2 [0:15];
    always@(posedge clk)begin
        if(in_valid)begin
            matrix_reg_clk2[15] <= in_matrix;
            for(i=0;i<15;i=i+1)  matrix_reg_clk2[i] <= matrix_reg_clk2[i+1];
        end
    end

    always@(*)begin
        out_matrix =  matrix_reg_clk2[cnt_fifo[7:4]][7:4] * matrix_reg_clk2[cnt_fifo[3:0]][3:0];
    end
    */

    //================================================================
    // BUG from jasper gold                 
    //================================================================
    //================================
    //  Design 1                  
    //================================
    
    //fifo back
    /*
    reg read_en;
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n) read_en <= 0;
        else read_en <= ~fifo_empty;
    end 
    assign fifo_rinc = read_en;
    */

    /*
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            out_valid <= 0;
            out_matrix <= 0;
        end
        else if(flag_fifo_to_clk1) begin
            out_valid <= 1;
            out_matrix <= fifo_rdata;
        end
        else begin
            out_valid <= 0;
            out_matrix <= 0; 
        end
    end*/

    //================================
    //  Design 2   function right but JG fail(push when wfull)                
    //================================
    /*
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n) cnt_fifo <= 0;
        else if(c_state == FIFO_IN && (n_state == MULT || n_state == IDLE)) cnt_fifo <= cnt_fifo + 1;
                        //n_state != mult (mean c_state&&n_state == FIFO_IN ---> wfull)
    end*/
    /*

    always@(*) begin
        case (c_state)
        IDLE : begin
            if(in_valid) n_state = INPUT;
            else n_state = IDLE;
        end 
        INPUT : begin
            if(cnt_in == 0) n_state = MULT;
            else n_state = INPUT;
        end
        MULT: begin
        // if(cnt_fifo[8]) n_state = IDLE;
            n_state = FIFO_IN;
        end
        FIFO_IN:begin
            if(cnt_fifo==255) n_state = IDLE;
            else if(fifo_full) n_state = FIFO_IN;
            else n_state = MULT;
        end
        endcase
    end

    //assign flag_clk2_to_fifo = (c_state ==IDLE&& n_state == INPUT)? 1:0;
    always@(posedge clk) begin
        if(c_state == MULT ) begin
            out_matrix <= matrix_reg_clk2[cnt_fifo[7:4]][7:4] * matrix_reg_clk2[cnt_fifo[3:0]][3:0];
        end
    end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) out_valid <= 0;
        else if(n_state == MULT)   out_valid <= 1;
        else out_valid <=0;
    end
    */

    