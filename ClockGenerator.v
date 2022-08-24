`timescale 1ns / 1ps

module ClockGenerator(
    input sys_clkn,
    input sys_clkp,     
    input [23:0] ClkDivThreshold,
    output reg FSM_Clk,    
    output reg ILA_Clk,
	output reg I2C_Clk,
	output reg PMOD_Clk
    );

    //Generate high speed main clock from two differential clock signals        
    wire clk;
    reg [23:0] ClkDiv = 24'd0;     
	reg [23:0] ClkDiv_I2C = 24'd0;     
    reg [23:0] ClkDivILA = 24'd0; 
	reg [23:0] ClkDivPMOD = 24'd0;   	

    IBUFGDS osc_clk(
        .O(clk),
        .I(sys_clkp),
        .IB(sys_clkn)
    );    
         
    // Initialize the two registers used in this module  
    initial begin
        FSM_Clk = 1'b0;        
        ILA_Clk = 1'b0;
		I2C_Clk = 1'b0;
		PMOD_Clk = 1'b0;
    end
 
    // We derive a clock signal that will be used for sampling signals for the PMOD
    // This clock will be 10 times slower than the system clock.    
    always @(posedge clk) begin        
        if (ClkDivILA == 10) begin
            ILA_Clk <= !ILA_Clk;                       
            ClkDivILA <= 0;
        end else begin                        
            ClkDivILA <= ClkDivILA + 1'b1;
        end
    end      

    // This clock signal will be used to run the finite state machine for the I2C protocol
    always @(posedge ILA_Clk) begin        
        if (ClkDiv == ClkDivThreshold) begin
            FSM_Clk <= !FSM_Clk;                   
            ClkDiv <= 0;
        end else begin
			ClkDiv <= ClkDiv + 1'b1;             
        end
    end   

    // We derive a clock signal that will be used for sampling signals for the PMOD
    // This clock will be 10 times slower than the system clock.    
    always @(posedge clk) begin        
        if (ClkDivPMOD == 250000) begin
            PMOD_Clk <= !PMOD_Clk;                       
            ClkDivPMOD <= 0;
        end else begin                        
            ClkDivPMOD <= ClkDivPMOD + 1'b1;
        end
    end      

    // This clock signal will be used to run the finite state machine for the I2C protocol
    always @(posedge clk) begin        
       if (ClkDiv_I2C == 100) begin
         I2C_Clk <= !I2C_Clk;                   
         ClkDiv_I2C <= 0;
       end else begin
         ClkDiv_I2C <= ClkDiv_I2C + 1'b1;             
       end
    end      	
endmodule
