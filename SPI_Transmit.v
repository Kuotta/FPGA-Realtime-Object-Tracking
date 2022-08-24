`timescale 1ns / 1ps

module SPI_Transmit(
    input FSM_Clk,
	input  CVM_SPI_OUT,
    output CVM_SPI_CLK,
    output CVM_SPI_EN,
    output  CVM_SPI_IN,
    output reg SPI_CLK,
    output reg SPI_IN,
    output reg SPI_EN,
	input control_bit,
	input [7:0] write_data,
	input start_bit,
	input [6:0] address,
	output reg [7:0] read_data,	
	output reg write_complete, 
	output reg read_complete
);

    localparam STATE_INIT       = 8'd0;    
	reg [7:0] State; 
    assign CVM_SPI_CLK = SPI_CLK;
    assign CVM_SPI_IN = SPI_IN;
    assign CVM_SPI_EN = SPI_EN; 
    
    initial  begin
        SPI_EN = 1'b0;
        SPI_CLK = 1'b0;
        SPI_IN = 1'b0;
        State = STATE_INIT;
    end
	
    // SPI FSM
    always @(posedge FSM_Clk) begin                 
        case (State)    
			STATE_INIT : begin
                if (start_bit) 
					State <= 8'd1;                    
                else begin                 
                    SPI_EN = 1'b0;
                    SPI_CLK = 1'b0;
                end
            end            
            // Start sequence            
            8'd1 : begin
                SPI_EN <= 1'b1;
                SPI_CLK <= 1'b0;    
                write_complete <= 1'b0;
                read_complete <= 1'b0;
                State <= State + 1'b1;                          
            end   
            8'd2 : begin
                SPI_CLK <= 1'b0;
                SPI_IN <= control_bit;
                State <= State + 1'b1;             
            end   
            8'd3 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1;                 
            end   
            8'd4 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1;
            end   
            // start transmit address bit
            8'd5 : begin
                SPI_CLK <= 1'b0;
                SPI_IN <= address[6];
                State <= State + 1'b1;
            end   
            8'd6 : begin
                SPI_CLK <= 1'b0;
                State <= State + 1'b1;
            end   
            8'd7 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1;               
            end   
            8'd8 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd9 : begin
                SPI_CLK <= 1'b0;
                SPI_IN <= address[5];
                State <= State + 1'b1;
            end   
            8'd10 : begin
                SPI_CLK <= 1'b0;
                State <= State + 1'b1;
            end   
            8'd11 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1;              
            end   
            8'd12 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd13 : begin
                SPI_CLK <= 1'b0;
                SPI_IN <= address[4];
                State <= State + 1'b1;
            end   
            8'd14 : begin
                SPI_CLK <= 1'b0;
                State <= State + 1'b1;
            end   
            8'd15 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1;              
            end   
            8'd16 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1;    
            end   
            8'd17 : begin
                SPI_CLK <= 1'b0;
                SPI_IN <= address[3];
                State <= State + 1'b1;
            end   
            8'd18 : begin
                SPI_CLK <= 1'b0;
                State <= State + 1'b1;  
            end   
            8'd19 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1;                  
            end   
            8'd20 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1;  
            end  
            8'd21 : begin
                SPI_CLK <= 1'b0;
                SPI_IN <= address[2];
                State <= State + 1'b1;
            end   
            8'd22 : begin
                SPI_CLK <= 1'b0;
                State <= State + 1'b1; 
            end  
            8'd23 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1;                
            end   
            8'd24 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1; 
            end   
            8'd25 : begin
                SPI_CLK <= 1'b0;
                SPI_IN <= address[1];
                State <= State + 1'b1;
            end   
            8'd26 : begin
                SPI_CLK <= 1'b0;
                State <= State + 1'b1; 
            end  
            8'd27 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1;               
            end   
            8'd28 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1; 
            end   
            8'd29 : begin
                SPI_CLK <= 1'b0;
                SPI_IN <= address[0];
                State <= State + 1'b1;
            end   
            8'd30 : begin
                SPI_CLK <= 1'b0;
                State <= State + 1'b1;
            end
            8'd31 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1;     
            end   
            8'd32 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1;
            end   
            // control bit reveive
            8'd33 : begin
                SPI_CLK <= 1'b0;
                if(control_bit)
					SPI_IN <= write_data[7];
                State <= State + 1'b1;
            end   
            8'd34 : begin
                SPI_CLK <= 1'b0;
                State <= State + 1'b1;
            end        
            8'd35 : begin
                SPI_CLK <= 1'b1;
                if(!control_bit)
                    read_data[7] <= CVM_SPI_OUT;
                State <= State + 1'b1;                
            end   
            8'd36 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1;
            end   
            8'd37 : begin
                SPI_CLK <= 1'b0;
                if(control_bit)
                    SPI_IN <= write_data[6]; 
                State <= State + 1'b1;
            end   
            8'd38 : begin
                SPI_CLK <= 1'b0;
                State <= State + 1'b1;
            end        
            8'd39 : begin
                SPI_CLK <= 1'b1;
                if(!control_bit)
                    read_data[6] <= CVM_SPI_OUT;
                State <= State + 1'b1;                
            end   
            8'd40 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1;
            end
            8'd41 : begin
                SPI_CLK <= 1'b0;
                if(control_bit)
					SPI_IN <= write_data[5];  
                State <= State + 1'b1;
            end 
            8'd42 : begin
                SPI_CLK <= 1'b0;
                State <= State + 1'b1;
            end     
            8'd43 : begin
                SPI_CLK <= 1'b1;
                if(!control_bit) 
					read_data[5] <= CVM_SPI_OUT;
                State <= State + 1'b1;                
            end   
            8'd44 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1;
            end
            8'd45 : begin
                SPI_CLK <= 1'b0;
                if(control_bit == 1'b1)
                    SPI_IN <= write_data[4];
                State <= State + 1'b1;
            end   
            8'd46 : begin
                  SPI_CLK <= 1'b0;
                  State <= State + 1'b1;
            end  
            8'd47 : begin
                SPI_CLK <= 1'b1;
                if(!control_bit)
                    read_data[4] <= CVM_SPI_OUT;
                State <= State + 1'b1;                
            end   
            8'd48 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1;
            end
            8'd49 : begin
                SPI_CLK <= 1'b0;
                if(control_bit) begin
                    SPI_IN <= write_data[3];
                end  
                State <= State + 1'b1;
            end   
            8'd50 : begin
                SPI_CLK <= 1'b0;
                State <= State + 1'b1;
            end  
            8'd51 : begin
                SPI_CLK <= 1'b1;
                if(!control_bit)
                    read_data[3] <= CVM_SPI_OUT;
                State <= State + 1'b1;                
            end
            8'd52 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1;
            end
            8'd53 : begin
                SPI_CLK <= 1'b0;
                if(control_bit) begin
                    SPI_IN <= write_data[2];
                end  
                State <= State + 1'b1;
            end   
            8'd54 : begin
                SPI_CLK <= 1'b0;
                State <= State + 1'b1;
            end         
            8'd55 : begin
                SPI_CLK <= 1'b1;
                if(!control_bit) begin
                    read_data[2] <= CVM_SPI_OUT;
                end
                State <= State + 1'b1;                
            end   
            8'd56 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1;
            end
            8'd57 : begin
                SPI_CLK <= 1'b0;
                if(control_bit) 
                    SPI_IN <= write_data[1];
                State <= State + 1'b1;
            end   
            8'd58 : begin
                SPI_CLK <= 1'b0;
                State <= State + 1'b1;
            end   
            8'd59 : begin
                SPI_CLK <= 1'b1;
                if(!control_bit)
                    read_data[1] <= CVM_SPI_OUT;
                State <= State + 1'b1;                
            end   
            8'd60 : begin
                SPI_CLK <= 1'b1;
                State <= State + 1'b1;
            end
            8'd61 : begin
                SPI_CLK <= 1'b0;
                if(control_bit) begin
                    SPI_IN <= write_data[0];
                    write_complete <= 1'b1;
                end  
                State <= State + 1'b1;
            end   
            8'd62 : begin
                SPI_CLK <= 1'b0;
                State <= State + 1'b1;
            end       
            8'd63 : begin
                SPI_CLK <= 1'b1;
                if(!control_bit) begin
                    read_data[0] <= CVM_SPI_OUT;
                    read_complete <= 1'b1;
                end
                State <= State + 1'b1;                
            end   
            8'd64 : begin
                SPI_CLK <= 1'b1;
                if(!start_bit)
                    State <= STATE_INIT;
                else
                    State <= State;
            end
            default :;                      
        endcase                           
    end                               
endmodule
