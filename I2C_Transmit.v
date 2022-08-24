`timescale 1ns / 1ps

module I2C_Transmit(
	input dir,
	input en,
	input [7:0] pulse_num,
	input I2C_Clk,
	input PMOD_Clk,
	output reg [15:0] XHA,
	output reg [15:0] YHA,
	output reg [15:0] ZHA,
	output reg [15:0] XHM,
	output reg [15:0] YHM,
	output reg [15:0] ZHM,
	output I2C_SCL,
	inout I2C_SDA,
    output reg A1,
    output reg A2,
    output A7,
    output A8  	
    );
    
    reg SACK_bit;
    reg SCL;
    reg SDA;
    reg [7:0] State;   
	reg [1:0] PMOD_state;
	reg [2:0] XYZ_flag;
	reg [7:0] pulse_cnt;
	reg en_reg;
	
    reg [1:0] R_W_signal;  
	reg [1:0] R_W_signal_m;  
    reg [7:0] sensor_addr_w;
    reg [7:0] sensor_addr_r;
    reg [7:0] reg_addr_w;
	reg [7:0] reg_addr_r;
    reg [7:0] reg_write_data;
    reg error_bit = 1'b1; 

       
    localparam STATE_INIT       = 8'd0;    
    assign I2C_SCL = SCL;
    assign I2C_SDA = SDA; 
    assign A7 = A1; 
    assign A8 = A2; 
    
    initial  begin
        SCL = 1'b1;
        SDA = 1'b1;
        SACK_bit = 1'b1;
        State = 8'd0;
        PMOD_state = 2'd0;
		sensor_addr_w = 8'b00110010;
		sensor_addr_r = 8'b00110011;
		reg_addr_w = 8'b00100000;
		reg_addr_r = 8'b10101000;
		reg_write_data = 8'b10010111;
        A1 = 1'b0;
        A2 = 1'b0;
		XHA = 16'd0;
		YHA = 16'd0;  
		ZHA = 16'd0;
		XHM = 16'd0;
		YHM = 16'd0;  
		ZHM = 16'd0;
		XYZ_flag = 3'd0;
		R_W_signal = 2'd2;
		R_W_signal_m = 2'd2;
		en_reg = 1'b0;
    end
    // PMOD FSM
    always @(posedge PMOD_Clk) begin
        case (PMOD_state)     
            STATE_INIT : begin
                A1 <= 0;
                A2 <= 0;
                if (en && (!en_reg))  
					PMOD_state <= 2'd1; 
                else if (!en)  
					en_reg <= 1'b0;
            end              
            2'd1 : begin
                A2 <= dir;
                PMOD_state <= 2'd2;                                  
            end
            2'd2 : begin
                if (pulse_cnt == pulse_num) begin
                    A1 <= 1'b0;
                    pulse_cnt <= 0;
                    PMOD_state <= STATE_INIT;
					en_reg <= 1'b1;					
                end         
				else if (!A1)	
					A1 <= 1'b1;
                else if (A1)  begin
                    A1 <= 1'b0;
                    pulse_cnt <= pulse_cnt + 1;
                end		
            end
        endcase
    end
	// I2C FSM
    always @(posedge I2C_Clk) begin                       
        case (State)     
            STATE_INIT : begin
				SCL <= 1'b1;
				SDA <= 1'b1;
				XYZ_flag <= 3'b0;
				State <= 8'd1;
            end            
            // This is the Start sequence            
            8'd1 : begin
                SCL <= 1'b1;
                SDA <= 1'b0;
                State <= State + 1'b1;                                
            end   
            8'd2 : begin
                SCL <= 1'b0;
                SDA <= 1'b0;
                State <= State + 1'b1;                 
            end   
            // transmit bit 7   
            8'd3 : begin
                SCL <= 1'b0;
                SDA <= sensor_addr_w[7];
                State <= State + 1'b1;                 
            end   
            8'd4 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd5 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd6 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end   
            // transmit bit 6
            8'd7 : begin
                SCL <= 1'b0;
                SDA <= sensor_addr_w[6];  
                State <= State + 1'b1;               
            end   
            8'd8 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd9 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd10 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end   
            // transmit bit 5
            8'd11 : begin
                SCL <= 1'b0;
                SDA <= sensor_addr_w[5]; 
                State <= State + 1'b1;                
            end   
            8'd12 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd13 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd14 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end   
            // transmit bit 4
            8'd15 : begin
                SCL <= 1'b0;
                SDA <= sensor_addr_w[4]; 
                State <= State + 1'b1;                
            end  
            8'd16 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd17 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   

            8'd18 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end   
            // transmit bit 3
            8'd19 : begin
                SCL <= 1'b0;
                SDA <= sensor_addr_w[3]; 
                State <= State + 1'b1;                
            end   
            8'd20 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd21 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd22 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end          
            // transmit bit 2
            8'd23 : begin
                SCL <= 1'b0;
                SDA <= sensor_addr_w[2]; 
                State <= State + 1'b1;                
            end   
            8'd24 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd25 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd26 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end  
            // transmit bit 1
            8'd27 : begin
                SCL <= 1'b0;
                SDA <= sensor_addr_w[1];  
                State <= State + 1'b1;               
            end   
            8'd28 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd29 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd30 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end          
            // transmit bit 0
            8'd31 : begin
                SCL <= 1'b0;
                SDA <= sensor_addr_w[0];      
                State <= State + 1'b1;           
            end   
            8'd32 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd33 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd34 : begin
                SCL <= 1'b0;                  
                State <= State + 1'b1;
            end                      
            // read the ACK bit from the sensor 
            8'd35 : begin
                SCL <= 1'b0;
                SDA <= 1'bz;
                State <= State + 1'b1;                 
            end   
            8'd36 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd37 : begin
                SCL <= 1'b1;
                SACK_bit <= SDA;                 
                State <= State + 1'b1;
            end            
            8'd38 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end        
            //register address
            8'd39 : begin
                SCL <= 1'b0;
				if (R_W_signal == 2'd2) 
					SDA <= reg_addr_w[7];  
				else if (R_W_signal == 2'd1) 
					SDA <= reg_addr_r[7];      
				State <= State + 1'b1; 
            end                 
            8'd40 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd41 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd42 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end   
            // transmit bit 6
            8'd43 : begin
                SCL <= 1'b0;
				if (R_W_signal == 2'd2) 
					SDA <= reg_addr_w[6];  
				else if (R_W_signal == 2'd1) 
					SDA <= reg_addr_r[6];  
                State <= State + 1'b1;               
            end   
            8'd44 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd45 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd46 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end   
            // transmit bit 5
            8'd47 : begin
                SCL <= 1'b0;
				if (R_W_signal == 2'd2) 
					SDA <= reg_addr_w[5];  
				else if (R_W_signal == 2'd1) 
					SDA <= reg_addr_r[5]; 
                State <= State + 1'b1;                
            end   
            8'd48 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd49 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd50 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end   
            // transmit bit 4
            8'd51 : begin
                SCL <= 1'b0;
				if (R_W_signal == 2'd2) 
					SDA <= reg_addr_w[4];  
				else if (R_W_signal == 2'd1) 
					SDA <= reg_addr_r[4]; 
                State <= State + 1'b1;                
            end   
            8'd52 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd53 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd54 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end   
            // transmit bit 3
            8'd55 : begin
                SCL <= 1'b0;
				if (R_W_signal == 2'd2) 
					SDA <= reg_addr_w[3];  
				else if (R_W_signal == 2'd1) 
					SDA <= reg_addr_r[3]; 
                State <= State + 1'b1;                
            end   
            8'd56 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd57 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd58 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end        
            // transmit bit 2
            8'd59 : begin
                SCL <= 1'b0;
				if (R_W_signal == 2'd2) 
					SDA <= reg_addr_w[2];  
				else if (R_W_signal == 2'd1) 
					SDA <= reg_addr_r[2]; 
                State <= State + 1'b1;                
            end   
            8'd60 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd61 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd62 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end  
            // transmit bit 1
            8'd63 : begin
                SCL <= 1'b0;
				if (R_W_signal == 2'd2) 
					SDA <= reg_addr_w[1];  
				else if (R_W_signal == 2'd1) 
					SDA <= reg_addr_r[1];   
                State <= State + 1'b1;               
            end   
            8'd64 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd65 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd66 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end
            // transmit bit 0
            8'd67 : begin
                SCL <= 1'b0;
				if (R_W_signal == 2'd2) 
					SDA <= reg_addr_w[0];  
				else if (R_W_signal == 2'd1) 
					SDA <= reg_addr_r[0];    
                State <= State + 1'b1;           
            end   
            8'd68 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd69 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd70 : begin
                SCL <= 1'b0;                  
                State <= State + 1'b1;
            end  
            // read the ACK bit from the sensor 
            8'd71 : begin
                SCL <= 1'b0;
                SDA <= 1'bz;
                State <= State + 1'b1;                 
            end   
            8'd72 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end            
            8'd73 : begin
                SCL <= 1'b1;
                SACK_bit <= SDA;                 
                State <= State + 1'b1;
            end   
            8'd74 : begin
                SCL <= 1'b0;
				if (R_W_signal == 2'd1 && sensor_addr_w == 8'b00110010) 
					State <= State + 1'b1;
				else if (R_W_signal == 2'd2 && sensor_addr_w == 8'b00110010) 
					State <= 8'd152;
				else if (R_W_signal_m == 2'd1 && sensor_addr_w == 8'b00111100) 
					State <= State + 1'b1;
				else if (R_W_signal_m == 2'd2 && sensor_addr_w == 8'b00111100) 
					State <= 8'd152;
            end    
            // Repeated Start
            8'd75 : begin
                SDA <= 1'b1;
                State <= State + 1'b1;                                
            end
            8'd76 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;                                
            end
            8'd77 : begin
                SDA <= 1'b0;
                State <= State + 1'b1;                                
            end   
            8'd78 : begin
                SCL <= 1'b0;
                State <= 8'd80;                 
            end                                                                          
            //sensor address with read bit
            8'd80 : begin
                SDA <= sensor_addr_r[7];             
                State <= State + 1'b1; 
            end                 
            8'd81 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd82 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd83 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end   
            // transmit bit 6
            8'd84 : begin
                SCL <= 1'b0;
                SDA <= sensor_addr_r[6];  
                State <= State + 1'b1;               
            end   
            8'd85 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd86 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd87 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end   
            // transmit bit 5
            8'd88 : begin
                SCL <= 1'b0;
                SDA <= sensor_addr_r[5]; 
                State <= State + 1'b1;                
            end   
            8'd89 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd90 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd91 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end   
            // transmit bit 4
            8'd92 : begin
                SCL <= 1'b0;
                SDA <= sensor_addr_r[4]; 
                State <= State + 1'b1;                
            end   
            8'd93 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd94 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd95 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end   
            // transmit bit 3
            8'd96 : begin
                SCL <= 1'b0;
                SDA <= sensor_addr_r[3]; 
                State <= State + 1'b1;                
            end   
            8'd97 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd98 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd99 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end  
            // transmit bit 2
            8'd100 : begin
                SCL <= 1'b0;
                SDA <= sensor_addr_r[2]; 
                State <= State + 1'b1;                
            end   
            8'd101 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd102 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd103 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end  
            // transmit bit 1
            8'd104 : begin
                SCL <= 1'b0;
                SDA <= sensor_addr_r[1];  
                State <= State + 1'b1;               
            end   
            8'd105 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd106 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd107 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end
            // transmit bit 0
            8'd108 : begin
                SCL <= 1'b0;
                SDA <= sensor_addr_r[0];      
                State <= State + 1'b1;           
            end   
            8'd109 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd110 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd111 : begin
                SCL <= 1'b0;                  
                State <= State + 1'b1;
            end  
            // read the ACK bit from the sensor 
            8'd112 : begin
                SCL <= 1'b0;
                SDA <= 1'bz;
                State <= State + 1'b1;                 
            end   
            8'd113 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end            
            8'd114 : begin
                SCL <= 1'b1;
                SACK_bit <= SDA;                 
                State <= State + 1'b1;
            end   
            8'd115 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end                       
            // Read data from register
            8'd116 : begin
                SCL <= 1'b0;
                SDA <= 1'bz;
                State <= State + 1'b1;                 
            end   
            8'd117 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end            
            8'd118 : begin
                SCL <= 1'b1;
				if (XYZ_flag == 3'd0 && sensor_addr_w == 8'b00110010) XHA[7] <= SDA;
                else if (XYZ_flag == 3'd1 && sensor_addr_w == 8'b00110010) XHA[15] <= SDA;
                else if (XYZ_flag == 3'd2 && sensor_addr_w == 8'b00110010) YHA[7] <= SDA;
                else if (XYZ_flag == 3'd3 && sensor_addr_w == 8'b00110010) YHA[15] <= SDA;
                else if (XYZ_flag == 3'd4 && sensor_addr_w == 8'b00110010) ZHA[7] <= SDA;
                else if (XYZ_flag == 3'd5 && sensor_addr_w == 8'b00110010) ZHA[15] <= SDA;    
                else if (XYZ_flag == 3'd0 && sensor_addr_w == 8'b00111100) XHM[15] <= SDA;
                else if (XYZ_flag == 3'd1 && sensor_addr_w == 8'b00111100) XHM[7] <= SDA;
                else if (XYZ_flag == 3'd2 && sensor_addr_w == 8'b00111100) ZHM[15] <= SDA;
                else if (XYZ_flag == 3'd3 && sensor_addr_w == 8'b00111100) ZHM[7] <= SDA;
                else if (XYZ_flag == 3'd4 && sensor_addr_w == 8'b00111100) YHM[15] <= SDA;
                else if (XYZ_flag == 3'd5 && sensor_addr_w == 8'b00111100) YHM[7] <= SDA;                   
                State <= State + 1'b1;
            end   
            8'd119 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end       
            8'd120 : begin
                SCL <= 1'b0;
                SDA <= 1'bz;
                State <= State + 1'b1;                 
            end  
            8'd121 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end            
            8'd122 : begin
                SCL <= 1'b1;
                if (XYZ_flag == 3'd0 && sensor_addr_w == 8'b00110010) XHA[6] <= SDA;
                else if (XYZ_flag == 3'd1 && sensor_addr_w == 8'b00110010) XHA[14] <= SDA;
                else if (XYZ_flag == 3'd2 && sensor_addr_w == 8'b00110010) YHA[6] <= SDA;
                else if (XYZ_flag == 3'd3 && sensor_addr_w == 8'b00110010) YHA[14] <= SDA;
                else if (XYZ_flag == 3'd4 && sensor_addr_w == 8'b00110010) ZHA[6] <= SDA;
                else if (XYZ_flag == 3'd5 && sensor_addr_w == 8'b00110010) ZHA[14] <= SDA;    
                else if (XYZ_flag == 3'd0 && sensor_addr_w == 8'b00111100) XHM[14] <= SDA;
                else if (XYZ_flag == 3'd1 && sensor_addr_w == 8'b00111100) XHM[6] <= SDA;
                else if (XYZ_flag == 3'd2 && sensor_addr_w == 8'b00111100) ZHM[14] <= SDA;
                else if (XYZ_flag == 3'd3 && sensor_addr_w == 8'b00111100) ZHM[6] <= SDA;
                else if (XYZ_flag == 3'd4 && sensor_addr_w == 8'b00111100) YHM[14] <= SDA;
                else if (XYZ_flag == 3'd5 && sensor_addr_w == 8'b00111100) YHM[6] <= SDA;                   
                State <= State + 1'b1;
            end   
            8'd123 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end   
            8'd124 : begin
                SCL <= 1'b0;
                SDA <= 1'bz;
                State <= State + 1'b1;                 
            end   
            8'd125 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end            
            8'd126 : begin
                SCL <= 1'b1;
                if (XYZ_flag == 3'd0 && sensor_addr_w == 8'b00110010) XHA[5] <= SDA;
                else if (XYZ_flag == 3'd1 && sensor_addr_w == 8'b00110010) XHA[13] <= SDA;
                else if (XYZ_flag == 3'd2 && sensor_addr_w == 8'b00110010) YHA[5] <= SDA;
                else if (XYZ_flag == 3'd3 && sensor_addr_w == 8'b00110010) YHA[13] <= SDA;
                else if (XYZ_flag == 3'd4 && sensor_addr_w == 8'b00110010) ZHA[5] <= SDA;
                else if (XYZ_flag == 3'd5 && sensor_addr_w == 8'b00110010) ZHA[13] <= SDA;    
                else if (XYZ_flag == 3'd0 && sensor_addr_w == 8'b00111100) XHM[13] <= SDA;
                else if (XYZ_flag == 3'd1 && sensor_addr_w == 8'b00111100) XHM[5] <= SDA;
                else if (XYZ_flag == 3'd2 && sensor_addr_w == 8'b00111100) ZHM[13] <= SDA;
                else if (XYZ_flag == 3'd3 && sensor_addr_w == 8'b00111100) ZHM[5] <= SDA;
                else if (XYZ_flag == 3'd4 && sensor_addr_w == 8'b00111100) YHM[13] <= SDA;
                else if (XYZ_flag == 3'd5 && sensor_addr_w == 8'b00111100) YHM[5] <= SDA;                      
                State <= State + 1'b1;
            end   
            8'd127 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end    
            8'd128 : begin
                SCL <= 1'b0;
                SDA <= 1'bz;
                State <= State + 1'b1;                 
            end   
            8'd129 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end            
            8'd130 : begin
                SCL <= 1'b1;
                if (XYZ_flag == 3'd0 && sensor_addr_w == 8'b00110010) XHA[4] <= SDA;
                else if (XYZ_flag == 3'd1 && sensor_addr_w == 8'b00110010) XHA[12] <= SDA;
                else if (XYZ_flag == 3'd2 && sensor_addr_w == 8'b00110010) YHA[4] <= SDA;
                else if (XYZ_flag == 3'd3 && sensor_addr_w == 8'b00110010) YHA[12] <= SDA;
                else if (XYZ_flag == 3'd4 && sensor_addr_w == 8'b00110010) ZHA[4] <= SDA;
                else if (XYZ_flag == 3'd5 && sensor_addr_w == 8'b00110010) ZHA[12] <= SDA;    
                else if (XYZ_flag == 3'd0 && sensor_addr_w == 8'b00111100) XHM[12] <= SDA;
                else if (XYZ_flag == 3'd1 && sensor_addr_w == 8'b00111100) XHM[4] <= SDA;
                else if (XYZ_flag == 3'd2 && sensor_addr_w == 8'b00111100) ZHM[12] <= SDA;
                else if (XYZ_flag == 3'd3 && sensor_addr_w == 8'b00111100) ZHM[4] <= SDA;
                else if (XYZ_flag == 3'd4 && sensor_addr_w == 8'b00111100) YHM[12] <= SDA;
                else if (XYZ_flag == 3'd5 && sensor_addr_w == 8'b00111100) YHM[4] <= SDA;                 
                State <= State + 1'b1;
            end   
            8'd131 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end      
            8'd132 : begin
                SCL <= 1'b0;
                SDA <= 1'bz;
                State <= State + 1'b1;                 
            end   
            8'd133 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end            
            8'd134 : begin
                SCL <= 1'b1;
                if (XYZ_flag == 3'd0 && sensor_addr_w == 8'b00110010) XHA[3] <= SDA;
                else if (XYZ_flag == 3'd1 && sensor_addr_w == 8'b00110010) XHA[11] <= SDA;
                else if (XYZ_flag == 3'd2 && sensor_addr_w == 8'b00110010) YHA[3] <= SDA;
                else if (XYZ_flag == 3'd3 && sensor_addr_w == 8'b00110010) YHA[11] <= SDA;
                else if (XYZ_flag == 3'd4 && sensor_addr_w == 8'b00110010) ZHA[3] <= SDA;
                else if (XYZ_flag == 3'd5 && sensor_addr_w == 8'b00110010) ZHA[11] <= SDA;    
                else if (XYZ_flag == 3'd0 && sensor_addr_w == 8'b00111100) XHM[11] <= SDA;
                else if (XYZ_flag == 3'd1 && sensor_addr_w == 8'b00111100) XHM[3] <= SDA;
                else if (XYZ_flag == 3'd2 && sensor_addr_w == 8'b00111100) ZHM[11] <= SDA;
                else if (XYZ_flag == 3'd3 && sensor_addr_w == 8'b00111100) ZHM[3] <= SDA;
                else if (XYZ_flag == 3'd4 && sensor_addr_w == 8'b00111100) YHM[11] <= SDA;
                else if (XYZ_flag == 3'd5 && sensor_addr_w == 8'b00111100) YHM[3] <= SDA;                  
                State <= State + 1'b1;
            end   
            8'd135 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end 
            8'd136 : begin
                SCL <= 1'b0;
                SDA <= 1'bz;
                State <= State + 1'b1;                 
            end   
            8'd137 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end            
            8'd138 : begin
                SCL <= 1'b1;
                if (XYZ_flag == 3'd0 && sensor_addr_w == 8'b00110010) XHA[2] <= SDA;
                else if (XYZ_flag == 3'd1 && sensor_addr_w == 8'b00110010) XHA[10] <= SDA;
                else if (XYZ_flag == 3'd2 && sensor_addr_w == 8'b00110010) YHA[2] <= SDA;
                else if (XYZ_flag == 3'd3 && sensor_addr_w == 8'b00110010) YHA[10] <= SDA;
                else if (XYZ_flag == 3'd4 && sensor_addr_w == 8'b00110010) ZHA[2] <= SDA;
                else if (XYZ_flag == 3'd5 && sensor_addr_w == 8'b00110010) ZHA[10] <= SDA;    
                else if (XYZ_flag == 3'd0 && sensor_addr_w == 8'b00111100) XHM[10] <= SDA;
                else if (XYZ_flag == 3'd1 && sensor_addr_w == 8'b00111100) XHM[2] <= SDA;
                else if (XYZ_flag == 3'd2 && sensor_addr_w == 8'b00111100) ZHM[10] <= SDA;
                else if (XYZ_flag == 3'd3 && sensor_addr_w == 8'b00111100) ZHM[2] <= SDA;
                else if (XYZ_flag == 3'd4 && sensor_addr_w == 8'b00111100) YHM[10] <= SDA;
                else if (XYZ_flag == 3'd5 && sensor_addr_w == 8'b00111100) YHM[2] <= SDA;                   
                State <= State + 1'b1;
            end   
            8'd139 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end 
            8'd140 : begin
                SCL <= 1'b0;
                SDA <= 1'bz;
                State <= State + 1'b1;                 
            end   
            8'd141 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end            
            8'd142 : begin
                SCL <= 1'b1;
                if (XYZ_flag == 3'd0 && sensor_addr_w == 8'b00110010) XHA[1] <= SDA;
                else if (XYZ_flag == 3'd1 && sensor_addr_w == 8'b00110010) XHA[9] <= SDA;
                else if (XYZ_flag == 3'd2 && sensor_addr_w == 8'b00110010) YHA[1] <= SDA;
                else if (XYZ_flag == 3'd3 && sensor_addr_w == 8'b00110010) YHA[9] <= SDA;
                else if (XYZ_flag == 3'd4 && sensor_addr_w == 8'b00110010) ZHA[1] <= SDA;
                else if (XYZ_flag == 3'd5 && sensor_addr_w == 8'b00110010) ZHA[9] <= SDA;    
                else if (XYZ_flag == 3'd0 && sensor_addr_w == 8'b00111100) XHM[9] <= SDA;
                else if (XYZ_flag == 3'd1 && sensor_addr_w == 8'b00111100) XHM[1] <= SDA;
                else if (XYZ_flag == 3'd2 && sensor_addr_w == 8'b00111100) ZHM[9] <= SDA;
                else if (XYZ_flag == 3'd3 && sensor_addr_w == 8'b00111100) ZHM[1] <= SDA;
                else if (XYZ_flag == 3'd4 && sensor_addr_w == 8'b00111100) YHM[9] <= SDA;
                else if (XYZ_flag == 3'd5 && sensor_addr_w == 8'b00111100) YHM[1] <= SDA;                    
                State <= State + 1'b1;
            end   
            8'd143 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end  
            8'd144 : begin
                SCL <= 1'b0;
                SDA <= 1'bz;
                State <= State + 1'b1;                 
            end   
            8'd145 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end            
            8'd146 : begin
                SCL <= 1'b1;
                if (XYZ_flag == 3'd0 && sensor_addr_w == 8'b00110010) XHA[0] <= SDA;
                else if (XYZ_flag == 3'd1 && sensor_addr_w == 8'b00110010) XHA[8] <= SDA;
                else if (XYZ_flag == 3'd2 && sensor_addr_w == 8'b00110010) YHA[0] <= SDA;
                else if (XYZ_flag == 3'd3 && sensor_addr_w == 8'b00110010) YHA[8] <= SDA;
                else if (XYZ_flag == 3'd4 && sensor_addr_w == 8'b00110010) ZHA[0] <= SDA;
                else if (XYZ_flag == 3'd5 && sensor_addr_w == 8'b00110010) ZHA[8] <= SDA;    
                else if (XYZ_flag == 3'd0 && sensor_addr_w == 8'b00111100) XHM[8] <= SDA;
                else if (XYZ_flag == 3'd1 && sensor_addr_w == 8'b00111100) XHM[0] <= SDA;
                else if (XYZ_flag == 3'd2 && sensor_addr_w == 8'b00111100) ZHM[8] <= SDA;
                else if (XYZ_flag == 3'd3 && sensor_addr_w == 8'b00111100) ZHM[0] <= SDA;
                else if (XYZ_flag == 3'd4 && sensor_addr_w == 8'b00111100) YHM[8] <= SDA;
                else if (XYZ_flag == 3'd5 && sensor_addr_w == 8'b00111100) YHM[0] <= SDA;                    
                State <= State + 1'b1;
            end   
            8'd147 : begin
                SCL <= 1'b0;
			    if (XYZ_flag == 3'd5) 
					State <= State + 1'b1;
			    else 
					State <= 8'd188;
            end                                                                                       
            8'd148 : begin
                SCL <= 1'b0;
                SDA <= 1'b1;      
                State <= State + 1'b1;           
            end   
            8'd149 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd150 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd151 : begin
                SCL <= 1'b0;                  
                State <= 8'd192;
            end
            // register write data
            8'd152 : begin
                SCL <= 1'b0;
                SDA <= reg_write_data[7];             
                State <= State + 1'b1; 
            end                    
            8'd153 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd154 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd155 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end   
            // transmit bit 6
            8'd156 : begin
                SCL <= 1'b0;
                SDA <= reg_write_data[6];  
                State <= State + 1'b1;               
            end   
            8'd157 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd158 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd159 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end   
            // transmit bit 5
            8'd160 : begin
                SCL <= 1'b0;
                SDA <= reg_write_data[5]; 
                State <= State + 1'b1;                
            end   
            8'd161 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd162 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd163 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end   
            // transmit bit 4
            8'd164 : begin
                SCL <= 1'b0;
                SDA <= reg_write_data[4]; 
                State <= State + 1'b1;                
            end   
            8'd165 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd166 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd167 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end   
            // transmit bit 3
            8'd168 : begin
                SCL <= 1'b0;
                SDA <= reg_write_data[3]; 
                State <= State + 1'b1;                
            end   
            8'd169 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd170 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd171 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end  
            // transmit bit 2
            8'd172 : begin
                SCL <= 1'b0;
                SDA <= reg_write_data[2]; 
                State <= State + 1'b1;                
            end   
            8'd173 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd174 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd175 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end  
            // transmit bit 1
            8'd176 : begin
                SCL <= 1'b0;
                SDA <= reg_write_data[1];  
                State <= State + 1'b1;               
            end   
            8'd177 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd178 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd179 : begin
                SCL <= 1'b0;
                State <= State + 1'b1;
            end
            // transmit bit 0
            8'd180 : begin
                SCL <= 1'b0;
                SDA <= reg_write_data[0];     
                State <= State + 1'b1;           
            end   
            8'd181 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd182 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd183 : begin
                SCL <= 1'b0;                  
                State <= State + 1'b1;
            end
            // read the ACK bit from the sensor 
            8'd184 : begin
                SCL <= 1'b0;
                SDA <= 1'bz;
                State <= State + 1'b1;                 
            end   
            8'd185 : begin
                SCL <= 1'b1;
                State <= State + 1'b1;
            end            
            8'd186 : begin
                SCL <= 1'b1;
                SACK_bit <= SDA;                 
                State <= State + 1'b1;
            end   
            8'd187 : begin
                SCL <= 1'b0;
                if (sensor_addr_w == 8'b00110010) 
					R_W_signal <= 2'd1;
                else if (sensor_addr_w == 8'b00111100) 
					R_W_signal_m <= 2'd1;
                State <= 8'd192;
            end 
            // write the ACK bit to the sensor 
            8'd188  : begin
                  SCL <= 1'b0;
                  SDA <= 1'b0;     
                  State <= State + 1'b1;           
            end   
            8'd189 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   
            8'd190 : begin
                  SCL <= 1'b1;
                  State <= State + 1'b1;
            end   
            8'd191 : begin
                  SCL <= 1'b0;
                  State <= 8'd116;
                  XYZ_flag <= XYZ_flag + 3'd1;                 
            end
            //stop bit sequence and go back to STATE_INIT            
            8'd192 : begin
                  SCL <= 1'b0;
                  SDA <= 1'b0;             
                  State <= State + 1'b1;
            end   
            8'd193 : begin
                  SCL <= 1'b1;
                  SDA <= 1'b0;
                  State <= State + 1'b1;
            end                                    
            8'd194 : begin
                  SCL <= 1'b1;
                  SDA <= 1'b1;
                  XYZ_flag <= 3'd0;
                  if(R_W_signal == 2'd1 && sensor_addr_w == 8'b00110010) begin
                    sensor_addr_w <= 8'b00111100;
                    sensor_addr_r <= 8'b00111101;
                    reg_addr_w <= 8'b00000010;
					reg_write_data <= 8'b00000000;
                    reg_addr_r <= 8'b10000011;
                  end
                  else if(R_W_signal_m == 2'd1 && sensor_addr_w == 8'b00111100) begin
                    sensor_addr_w <= 8'b00110010;
                    sensor_addr_r <= 8'b00110011;
                    reg_addr_w <= 8'b00100000;
                    reg_write_data <= 8'b10010111;
                    reg_addr_r = 8'b10101000;
                  end
                  State <= STATE_INIT;                
            end             
            
            //If the FSM ends up in this state, there was an error in teh FSM code
            default : begin
                  error_bit <= 0;
            end                              
        endcase                           
    end                
endmodule
