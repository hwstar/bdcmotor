/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 *****  REGISTER MAP *****
 * 
 *
 *** Address 0	:	Tach Low Byte (R), PWM Register (W) ***
 *
 * Read
 * 
 * Least significant byte of tach register. Reading automatically
 * latches the high byte for future access.
 *
 * Write
 *
 * PWM value. 8'h80 correleates to a 50% duty cycle. The motor would
 * be off in this case.
 *
 *** Address 1	:	Tach High Byte(R) ***
 *
 * Most significant byte of tach register. This has to be latched by
 * reading the low byte first.
 *
 *
 *** Address 2	:	Config Register (W) ***
 *
 * Bit 7	:	Reserved
 * Bit 6	:	Reserved  
 * Bit 5	:	invert tach	
 * Bit 4	:	invert pwm
 * Bit 3    :   Tach filter divisor msb
 * Bit 2    :   Tach filter divisor lsb
 * Bit 1	:	PWM clock divisor msb
 * Bit 0	:	PWM clock divisor lsb
 *
 */
 
 
 

/*
* This module detects a negative going edge
* It first synchronizes the input signal to the clock,
* Then it looks for the negative edge.
* This will introduce a 4 clock cycle delay
*/

module negedgedet(
	input clk,
	input in,
	output out);
  
	reg outreg;
	reg [3:0] sr = 4'b0000;
  
	assign out = outreg;
  
	always @(*) begin
		outreg = 0;
		if((sr[2] == 0) && (sr[3] == 1))
			outreg = 1;
	end
  
	always @(posedge clk) begin
		sr[3] <= sr[2];
		sr[2] <= sr[1];
		sr[1] <= sr[0];
		sr[0] <= in;
	end
endmodule

/*
* This module synchronizes the read transaction output from the spi module
* and generates a clock enable to latch the upper byte of the tach counter
* so that a future read can get a stable value
*/

module freezer(
	input clk,
	input countlread,
	output freeze,
	output highce);
  
	reg highcereg;
	reg [4:0] sr = 5'b00000;
  
	assign highce = highcereg;
	assign freeze = sr[2];
  
	always @(*) begin
		highcereg = 0;
		if((sr[3] == 1) && (sr[4] == 0))
			highcereg = 1;
	end
  
	always @(posedge clk) begin
		sr[4] <= sr[3];
		sr[3] <= sr[2];
		sr[2] <= sr[1];
		sr[1] <= sr[0];
		sr[0] <= countlread;
	end
endmodule

/*
* Address decoder and read mux
*/

module decoder(
	input we,
	input rdt,
	input [3:0] addr,
	input [7:0] countl,
	input [7:0] counthfrozen,
	output [7:0] rddata,
	output countlread,
	output pwmld,
	output cfgld,
	output ctrlld,
	output wdogdivld);
  
	reg regdecr0 = 0;
	reg regdecw0 = 0;
	reg regdecw2 = 0;
	reg regdecwe = 0;
	reg regdecwf = 0;
	reg [7:0] rddatareg;
  
	assign countlread = regdecr0;
	assign pwmld = regdecw0;
	assign cfgld = regdecw2;
	assign ctrlld = regdecwf;
	assign wdogdivld = regdecwe;
  
	assign rddata = rddatareg;
  
	always @(*) begin
		// Default outputs
		rddatareg <= 8'h00;
		regdecr0 <= 0;
		regdecw0 <= 0;
		regdecw2 <= 0;
		regdecwe <= 0;
		regdecwf <= 0;
		case(addr)
			// Tach low byte and PWM
			4'h0: begin
				rddatareg <= countl;
				regdecw0 <= we;
				regdecr0 <= rdt;
			end
			// Tach high byte
			4'h1: begin
				rddatareg <= counthfrozen;
			end
			    
			// Configuration
			4'h2:
				regdecw2 <= we;
      
			// Unimplemented decodes
			4'h3, 4'h4, 4'h5, 4'h6, 4'h7, 4'h8,
			4'h9, 4'ha, 4'hb, 4'hc, 4'hd: begin
				rddatareg <= 8'h00;
			end
 
			// Watchdog divisor
			4'he:
				regdecwe <= we;
			
			// Control
			4'hf:
				regdecwf <= we;
      
			// BoGuS
			default: begin
				rddatareg <= 8'bxxxxxxxx;
				regdecr0 <= 1'bx;
				regdecw0 <= 1'bx;
				regdecw2 <= 1'bx;
				regdecwf <= 1'bx;
			end
		endcase
	end
endmodule



/*
* Main interface to all underlying logic modules
*/  
  
  

module system(
	// Data to master (MISO)
	output miso,
	// motor pwm
	output [1:0] pwm,
	// motor enable
	output motorena,
	// System clock
	input clk,
	// Slave Select (SS)
	input ss,
	// SPI Clock (SCLK)
	input sclk,
	// Master Out Slave In (MOSI)
	input mosi,
	// Current limit detect
	input currentlimit,
	// Test input
	input tst,
	// Watchdog disable
	input wdogdis,
	// Tachometer phases
	input [1:0] tach); 
  
  
	wire rdt;
	wire wrt;
	wire we;
	wire spioe;
	wire countlread;
	wire freeze;
	wire highce;
	wire pwmld;
	wire cfgld;
	wire ctrlld;
	wire wdogdivld;
	wire invertpwm;
	wire invphase;
	wire motorenaint;
	wire [3:0] addr;
	wire [7:0] wrtdata;
	wire [7:0] rddata;
	wire [7:0] counthfrozen;
	wire [7:0] countl;
	wire [7:0] counth;
	wire [7:0] configreg;
  

	assign motorena = motorenaint;
  
  
	negedgedet ned0(
		.clk(clk),
		.in(wrt),
		.out(we));
  
	decoder dec0(
		.we(we),
		.rdt(rdt),
		.addr(addr),
		.countl(countl),
		.counthfrozen(counthfrozen),
		.rddata(rddata),
		.countlread(countlread),
		.pwmld(pwmld),
		.cfgld(cfgld),
		.ctrlld(ctrlld),
		.wdogdivld(wdogdivld));
    
  
	freezer frz0(
		.clk(clk),
		.countlread(countlread),
		.freeze(freeze),
		.highce(highce));
  
	reg8 counthrreg0(
		.clk(clk),
		.ce(highce),
		.in(counth),
		.out(counthfrozen));

	control ctrl0(
		.clk(clk),
		.cfgld(cfgld),
		.ctrlld(ctrlld),
		.wdogdivld(wdogdivld),
		.tst(tst),
		.wdogdis(wdogdis),
		.wrtdata(wrtdata),
		.pwmcntce(pwmcntce),
		.filterce(filterce),
		.invertpwm(invertpwm),
		.invphase(invphase),
		.motorenaint(motorenaint));
		
		 
	bdcmotorchannel bdcm0(
		.clk(clk),
		.filterce(filterce),
		.invphase(invphase),
		.freeze(freeze),
		.pwmcntce(pwmcntce),
		.pwmldce(pwmld),
		.invertpwm(invertpwm),
		.enablepwm(motorenaint),
		.currentlimit(currentlimit),
		.tach(tach),
		.wrtdata(wrtdata),
		.countl(countl),
		.counth(counth),
		.pwmout(pwm));
  
   
	spi spi0(
		.spidout(miso),
		.spiclk(sclk),
		.rdt(rdt),
		.wrt(wrt),
		.spioe(spioe),
		.wrtdata(wrtdata),
		.addr(addr),
		.spien(ss),
		.spidin(mosi),
		.rddata(rddata));

		
endmodule

  
  
  
  
  
  


    
    
    
  
  
	
