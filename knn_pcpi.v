module KNN_PCPI(
input             clk, resetn,
	input             pcpi_valid,
	input      [31:0] pcpi_insn,
	input      [31:0] pcpi_rs1,
	input      [31:0] pcpi_rs2,
	output	reg	pcpi_wr,
	output	reg	[31:0] pcpi_rd,
	output	reg	pcpi_wait,
	output	reg	pcpi_ready,
	//memory interface
	input      [31:0] mem_rdata,
	input             mem_ready,
	output	reg	mem_valid,
	output	reg	mem_write,
	output	reg	[31:0] mem_addr,
	output	reg	[31:0] mem_wdata
);

	parameter [2:0]IDLE = 3'd0;
	parameter [2:0]MEM1 = 3'd1;
	parameter [2:0]MEM2 = 3'd2;
	parameter [2:0]END = 3'd3;
//	parameter [2:0]CALC1 = 3'd4;
	parameter [2:0]NUM1 = 3'd4;
	parameter [2:0]NUM2 = 3'd5;
//	parameter [2:0]CALC2 = 3'd7;
	wire pcpi_insn_valid = pcpi_valid && pcpi_insn[6:0] == 7'b0101011 && pcpi_insn[31:25] == 7'b0000001;

	//TODO: PCPI interface. Modify these values to fit your needs
	//reg pcpi_wr, pcpi_wait, pcpi_ready;
	//reg [31:0]pcpi_rd;

	//TODO: Memory interface. Modify these values to fit your needs
	//reg mem_write, mem_valid;
	//reg [31:0]mem_addr, mem_wdata;
	
	//TODO: Implement your k-NN design below
	
	reg [31:0]indeg, indeg_next;
	reg [31:0]addr, addr_next;
	reg [31:0]counter;
	reg [2:0]state, state_next;
	reg [31:0]num, num_next;
	reg [31:0]temp, temp_next;
	always@(posedge clk or negedge resetn)begin
		if(!resetn) begin
			state <= IDLE;
			addr <= 32'd0;
			counter <= 32'd0;
			indeg <= 32'd0;
			num <= 32'd0; 
		//	temp <= 32'd0;
		end else begin
			state <= state_next;
			addr <= addr_next;
			if(state== MEM2||state==NUM2)begin
				counter <= counter + 32'd1;
				num <= num_next;
			end else begin
				counter <= counter;
				num <= num_next;
			end
			indeg <= indeg_next;
			
	/*		if(temp==num-1)begin
				temp <= 0;
			end else if(state== CALC2)begin
				temp <= temp+32'd1;
			end else begin
				temp <= temp;
			end*/
		end
	end
			
	
	always@(*)begin
		case(state)
			IDLE:	begin
						if(pcpi_insn_valid)begin
							if(pcpi_rs2==0)begin
								state_next = END;
							end else begin
								addr_next = 32'h00010000;
								pcpi_wait = 1'b1;
								pcpi_ready = 1'b0;
								pcpi_wr = 1'b1;
								mem_valid = 1'b0;
								mem_write = 1'b0;
								indeg_next = 32'd0;
								state_next = NUM1;
							end
						end else begin
							state_next = IDLE;
							pcpi_wait = 1'b0;
							pcpi_ready = 1'b0;
						end
					end
			MEM1:	begin
						pcpi_wait = 1'b1;
						pcpi_ready = 1'b0;
						mem_valid = 1'b1;
						mem_addr = addr;
						pcpi_wr = 1'b0;
						mem_write = 1'b0;
						state_next = MEM2;
					end
			MEM2:	begin
						mem_valid = 1'b1;
						pcpi_wait = 1'b1;
						pcpi_ready = 1'b0;
						pcpi_wr = 1'b0;
						mem_write = 1'b0; 
						indeg_next = mem_rdata + indeg;
						if(counter<pcpi_rs2)begin
							addr_next = (pcpi_rs1+counter*pcpi_rs2)*4+32'h00010000+32'd4;
							state_next = MEM1;
						end else begin		
							state_next = END; 
						end
					end
			END:	begin
						state_next = IDLE;
						pcpi_wait = 1'b0;
						pcpi_ready = 1'b1;
						pcpi_wr = 1'b1;
						if(pcpi_rs2==32'd0)
							pcpi_rd = pcpi_rs1-32'd1;
						else 
							pcpi_rd = indeg;
						counter = 32'd0; 
						
					end
		/*	CALC1:	begin
						pcpi_wait = 1'b1;
						pcpi_ready = 1'b0;
						mem_valid = 1'b1;
						mem_addr = addr;
						$display("temp = %d", addr);
						pcpi_wr = 1'b0;
						mem_write = 1'b0;
						state_next = CALC2;
					end
			CALC2:	begin
						mem_valid = 1'b1;
						pcpi_wait = 1'b1;
						pcpi_ready = 1'b0;
						pcpi_wr = 1'b0;
						mem_write = 1'b0; 
						temp_next = mem_rdata;
						indeg = pcpi_rs1;
						state_next = END; 
					end*/
			NUM1:	begin
						pcpi_wait = 1'b1;
						pcpi_ready = 1'b0;
						mem_valid = 1'b1;
						mem_addr = addr;
						pcpi_wr = 1'b0;
						mem_write = 1'b0;
						state_next = NUM2; 
					end
			NUM2:	begin
						mem_valid = 1'b1;
						pcpi_wait = 1'b1;
						pcpi_ready = 1'b0;
						pcpi_wr = 1'b0;
						mem_write = 1'b0; 
						num_next = mem_rdata;
						if(pcpi_rs2 == mem_rdata)begin
							state_next = MEM1;
							addr_next = (pcpi_rs1+counter*mem_rdata)*4+32'h00010000+4'd4;
					/*	end else if(pcpi_rs2 != num)begin
							state_next = CALC1;
							addr_next = (pcpi_rs2*num)*4+32'h00010000+4'd4+temp*4;
							//$display("pcpi_rs2 = %d", pcpi_rs1);  */
						end
					end
		endcase
	end
endmodule
