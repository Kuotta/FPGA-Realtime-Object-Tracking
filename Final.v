`timescale 1ns / 1ps

module Final(   
    input sys_clkn,
    input sys_clkp,  
    input CVM300_CLK_OUT,
    input CVM300_Line_valid,
    input CVM300_Data_valid,
    input [9:0] CVM300_D,
	input CVM300_SPI_OUT,
    output CVM300_SPI_EN,
    output CVM300_SPI_IN,
    output CVM300_SPI_CLK,
    output CVM300_CLK_IN,
    output CVM300_Enable_LVDS,
    output CVM300_SYS_RES_N,
    output CVM300_FRAME_REQ,
    output I2C_SCL_1,
    inout  I2C_SDA_1,
    output PMOD_A1,
    output PMOD_A2,
    output PMOD_A7,
    output PMOD_A8,
    output [7:0] led,
    input  [4:0] okUH,
    output [2:0] okHU,
    inout  [31:0] okUHU,
    inout  okAA      
);

    wire okClk;            //These are FrontPanel wires needed to IO communication    
    wire [112:0]    okHE;  //These are FrontPanel wires needed to IO communication    
    wire [64:0]     okEH;  //These are FrontPanel wires needed to IO communication  
	
    //Depending on the number of outgoing endpoints, adjust endPt_count accordingly.
    //In this example, we have 1 output endpoints, hence endPt_count = 1.
    localparam  endPt_count = 10;
    wire [endPt_count*65-1:0] okEHx;  
    okWireOR # (.N(endPt_count)) wireOR (okEH, okEHx);
	
    localparam STATE_INIT = 8'd0;
	wire [7:0] read_data;	
	wire [7:0] write_data;
	wire [6:0] address;
	wire pc_frame_req;
    wire pc_frame_req_new;
	reg spi_working;	
    reg [15:0] counter_delay = 16'd0;
	reg [15:0] CVM_start_delay = 16'd0;	
    reg [7:0] State = STATE_INIT;
    reg [7:0] led_register = 0;
    reg write_reset, read_reset;
    wire FIFO_read_enable, FIFO_BT_BlockSize_Full, FIFO_full, FIFO_empty, BT_Strobe;
    wire [31:0] FIFO_data_out;
    wire [31:0] FIFO_data_out_reorder;
    reg SYS_RES_N = 1'b0;
    reg FRAME_REQ = 1'b0;
    wire [23:0] ClkDivThreshold = 2; 
	wire [23:0] ClkDivThreshold_SPI = 5;
	wire [23:0] ClkDivThreshold_CVM = 1;
    reg [23:0] ClkDivSPI = 24'd0;	
    reg [23:0] ClkDivCVM = 24'd0;  
    wire FSM_Clk, ILA_Clk; 
	reg  SPI_FSM_Clk, CVM_Clk;
	reg [31:0] pix_cnt = 32'd0;	
	reg read_done = 1'b0;
	
	wire DIR;
	wire EN;
	wire [7:0] PULSE_NUM;
	wire [15:0] XHA;
	wire [15:0] YHA;
	wire [15:0] ZHA;
	wire [15:0] XHM;
	wire [15:0] YHM;
	wire [15:0] ZHM;
	wire I2C_Clk; 
	wire PMOD_Clk;
	
    assign led[0] = ~FIFO_empty; 
    assign led[1] = ~FIFO_full;
    assign led[2] = ~FIFO_BT_BlockSize_Full;
    assign led[3] = ~FIFO_read_enable;  
    assign led[7] = ~read_reset;
    assign led[6] = ~write_reset;
    assign CVM300_CLK_IN = CVM_Clk;
    assign CVM300_SYS_RES_N = SYS_RES_N;
    assign CVM300_FRAME_REQ = FRAME_REQ;
	
    ClockGenerator ClockGenerator1 (  .sys_clkn(sys_clkn),	
                                      .sys_clkp(sys_clkp),                                      	
                                      .ClkDivThreshold(ClkDivThreshold),	
                                      .FSM_Clk(FSM_Clk),                                      	
                                      .ILA_Clk(ILA_Clk),
									  .I2C_Clk(I2C_Clk),
									  .PMOD_Clk(PMOD_Clk));
	// Clock generator for SPI FSM								  
    always @(posedge FSM_Clk) begin	
        if (ClkDivSPI == ClkDivThreshold_SPI) begin	
           SPI_FSM_Clk <= !SPI_FSM_Clk;                   	
           ClkDivSPI <= 0;	
        end 
	    else begin	
           ClkDivSPI <= ClkDivSPI + 1'b1;             	
        end	
    end	
    // Clock generator for CVM300_CLK_IN	
    always @(posedge FSM_Clk) begin	
        if (ClkDivCVM == ClkDivThreshold_CVM) begin	
            CVM_Clk <= !CVM_Clk;                   	
            ClkDivCVM <= 0;	
        end 
	    else begin	
            ClkDivCVM <= ClkDivCVM + 1'b1;             	
        end	
    end	
									  			
    initial begin
        write_reset <= 1'b0;
        read_reset <= 1'b0;
    end
	
	// FSM for read image from sensor
    always @(posedge CVM300_CLK_IN) begin	
        if(pc_frame_req_new == 1'b1) 
            State = 8'd10;      	
        case(State)	
            8'd0:   begin	
                if (CVM_start_delay == 16'b1111_1111_1111_1111) begin	
                    SYS_RES_N <= 1'b1;	
                    State <= 8'd1;
                end	
                else begin	
                    SYS_RES_N <= 1'b0;	
                    CVM_start_delay <= CVM_start_delay + 1; 
                    State <= State; 
                end	
            end	
            8'd1:   begin	
                CVM_start_delay <= 16'd0;	
                spi_working <= 1'b0;	
                State <= 8'd2;  
            end	
            8'd2:   begin	
                if (CVM_start_delay == 16'b0000_1111_1111_1111) begin	
                    write_reset <= 1'b1;	
                    read_reset <= 1'b1;	
                    spi_working <= 1'b1;	
                    State <= 8'd3;
                end	
                else begin	
                    CVM_start_delay <= CVM_start_delay + 1;	
                    State <= State;	
                end	
            end	
            8'd3:   begin	
                write_reset <= 1'b1;	
                read_reset <= 1'b1;	
                counter_delay <= 16'd0;	
                FRAME_REQ <= 1'b0;	
                if(pc_frame_req) begin	
                    spi_working <= 1'b0;	
                    State <= 8'd4;	
                end	
            end	
            8'd4:   begin	
                write_reset <= 1'b0;	
                read_reset <= 1'b0;	
                if(!pc_frame_req)	
                    State <= 8'd5;	
            end	
            8'd5:   begin	
                if (counter_delay == 16'b0000_1111_1111_1111)  
					State <= 8'd6;	
                else 
					counter_delay <= counter_delay + 1;	
            end	
            8'd6:   begin	
                State <= 8'd7;       	
                counter_delay <= 16'd0;    	
            end	
            8'd7:   begin	
                 if (counter_delay == 16'b0000_0000_1111_1111) begin	
                    State <= 8'd8;	
                    FRAME_REQ <= 1'b1;	
                    spi_working <= 1'b1;	
                end	
                else 
					counter_delay <= counter_delay + 1;	
            end	
            8'd8:   begin	
                FRAME_REQ <= 1'b1;	
                State <= 8'd9;	
            end	
            8'd9:   begin	
                FRAME_REQ <= 1'b0; 	
                State <= 8'd9; 
            end	
            8'd10:   begin   
                write_reset <= 1'b1;    
                read_reset <= 1'b1;
                if(!pc_frame_req_new) 
                    State <= 8'd11; 
            end 
            8'd11:   begin   
                write_reset <= 1'b0;    
                read_reset <= 1'b0;
                FRAME_REQ <= 1'b1; 
                State <= 8'd12; 
            end 
            8'd12:   begin   
                FRAME_REQ <= 1'b1;  
                State <= 8'd13;  
            end 
            8'd13:   begin   
                FRAME_REQ <= 1'b0;  
                State <= 8'd13;  
            end 
        endcase            	
    end	

	I2C_Transmit I2C_T(
		.dir(DIR),
		.en(EN),
		.pulse_num(PULSE_NUM),
		.I2C_Clk(I2C_Clk),
		.PMOD_Clk(PMOD_Clk),
		.XHA(XHA),
		.YHA(YHA),
		.ZHA(ZHA),
		.XHM(XHM),
		.YHM(YHM),
		.ZHM(ZHM),
		.I2C_SCL(I2C_SCL_1),
		.I2C_SDA(I2C_SDA_1),
		.A1(PMOD_A1),
		.A2(PMOD_A2),
		.A7(PMOD_A7),
		.A8(PMOD_A8)  	
    );
	
    //Instantiate the module that we like to test
    SPI_Transmit SPI_T (        
		.FSM_Clk(SPI_FSM_Clk),
		.CVM_SPI_OUT(CVM300_SPI_OUT),
		.CVM_SPI_CLK(CVM300_SPI_CLK),
		.CVM_SPI_EN(CVM300_SPI_EN),
		.CVM_SPI_IN(CVM300_SPI_IN),
		.SPI_CLK(SPI_CLK),
		.SPI_IN(SPI_IN),
		.SPI_EN(SPI_EN),
		.control_bit(control_bit),
		.write_data(write_data),
		.start_bit(start_bit),
		.address(address),
		.read_data(read_data),	
		.write_complete(write_complete), 
		.read_complete(read_complete)
    );
    
    fifo_generator_0 FIFO_for_Counter_BTPipe_Interface (
        .wr_clk(!CVM300_CLK_OUT),
        .wr_rst(write_reset),
        .rd_clk(okClk),
        .rd_rst(read_reset),
        .din(CVM300_D[9:2]),
        .wr_en(CVM300_Data_valid & CVM300_Line_valid),
        .rd_en(FIFO_read_enable),
        .dout(FIFO_data_out),
        .full(FIFO_full),
        .empty(FIFO_empty),       
        .prog_full(FIFO_BT_BlockSize_Full)        
    );
      
    assign FIFO_data_out_reorder ={FIFO_data_out[7:0], FIFO_data_out[15:8], FIFO_data_out[23:16], FIFO_data_out[31:24]};
    
    okBTPipeOut CounterToPC (
        .okHE(okHE), 
        .okEH(okEHx[ 0*65 +: 65 ]),
        .ep_addr(8'ha0), 
        .ep_datain(FIFO_data_out_reorder), 
        .ep_read(FIFO_read_enable),
        .ep_blockstrobe(BT_Strobe), 
        .ep_ready(FIFO_BT_BlockSize_Full)
    );        
		
    //This is the OK host that allows data to be sent or recived    
    okHost hostIF (
        .okUH(okUH),
        .okHU(okHU),
        .okUHU(okUHU),
        .okClk(okClk),
        .okAA(okAA),
        .okHE(okHE),
        .okEH(okEH)
    );
     
     okWireIn wire10 (   .okHE(okHE), 
                        .ep_addr(8'h00), 
                        .ep_dataout(address));
                        
     okWireIn wire11 (   .okHE(okHE), 
                        .ep_addr(8'h01), 
                        .ep_dataout(control_bit));
                        
     okWireIn wire12 (   .okHE(okHE), 
                        .ep_addr(8'h02), 
                        .ep_dataout(write_data));
    
     okWireIn wire13 (   .okHE(okHE), 
                        .ep_addr(8'h03), 
                        .ep_dataout(start_bit));    	
                        	
    okWireIn wire14 (  .okHE(okHE), 	
                        .ep_addr(8'h04), 	
                        .ep_dataout(pc_frame_req)); 	

    okWireIn wire15 (  .okHE(okHE),     
                        .ep_addr(8'h05),    
                        .ep_dataout(pc_frame_req_new)); 
						
	// DIR Pin
	okWireIn wire16 (   .okHE(okHE), 
                        .ep_addr(8'h06), 
                        .ep_dataout(DIR));          
    // EN Pin                    
    okWireIn wire17 (   .okHE(okHE), 
                        .ep_addr(8'h07), 
                        .ep_dataout(EN));  
                        
    okWireIn wire18 (   .okHE(okHE), 
                        .ep_addr(8'h08), 
                        .ep_dataout(PULSE_NUM)); 

    okWireOut wire20 (  .okHE(okHE), 
                        .okEH(okEHx[ 1*65 +: 65 ]),
                        .ep_addr(8'h20), 
                        .ep_datain(read_data));
                        
    okWireOut wire21 (  .okHE(okHE), 
                        .okEH(okEHx[ 2*65 +: 65 ]),
                        .ep_addr(8'h21), 
                        .ep_datain(write_complete));
    okWireOut wire22 (  .okHE(okHE), 
                        .okEH(okEHx[ 3*65 +: 65 ]),
                        .ep_addr(8'h22), 
                        .ep_datain(read_complete));
                        	
    okWireOut wire23 (  .okHE(okHE), 	
                        .okEH(okEHx[ 4*65 +: 65 ]),	
                        .ep_addr(8'h23), 	
                        .ep_datain(spi_working));	

    okWireOut wire24 (  .okHE(okHE), 
                        .okEH(okEHx[ 5*65 +: 65 ]),
                        .ep_addr(8'h24), 
                        .ep_datain(XHA));
           
    okWireOut wire25 (  .okHE(okHE), 
                        .okEH(okEHx[ 6*65 +: 65 ]),
                        .ep_addr(8'h25), 
                        .ep_datain(YHA));
                                         
    okWireOut wire26 (  .okHE(okHE), 
                        .okEH(okEHx[ 7*65 +: 65 ]),
                        .ep_addr(8'h26), 
                        .ep_datain(ZHA));
  
//    okWireOut wire27 (  .okHE(okHE), 
//                        .okEH(okEHx[ 8*65 +: 65 ]),
//                        .ep_addr(8'h27), 
//                        .ep_datain(XHM));
     
//    okWireOut wire28 (  .okHE(okHE), 
//                        .okEH(okEHx[ 9*65 +: 65 ]),
//                        .ep_addr(8'h28), 
//                        .ep_datain(YHM));
                         
//    okWireOut wire29 (  .okHE(okHE), 
//                        .okEH(okEHx[ a*65 +: 65 ]),
//                        .ep_addr(8'h29), 
//                        .ep_datain(ZHM)); 						
		
endmodule