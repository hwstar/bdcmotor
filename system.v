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
 */
`default_nettype none
 
 

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
	reg [3:0] sr;
  
	initial sr = 4'b0000;
  
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
	input [7:0] countl0,
	input [7:0] counthfrozen0,
	input [7:0] countl1,
	input [7:0] counthfrozen1,
	input [7:0] countl2,
	input [7:0] counthfrozen2,
	input [7:0] controlrdata,
	input [7:0] hwconfig,
	input [7:0] configrdreg0,
	input [7:0] configrdreg1,
	input [7:0] configrdreg2,
	output [7:0] rddata,
	output countlread0,
	output pwmld0,
	output cfgld0,
	output countlread1,
	output pwmld1,
	output cfgld1,
	output countlread2,
	output pwmld2,
	output cfgld2,
	output ctrlld,
	output wdogdivld,
	output wdreset);
  
	reg regdecr0;
	reg regdecw0;
	reg regdecw2;
	reg regdecr4;
	reg regdecw4;
	reg regdecw6;
	reg regdecr8;
	reg regdecw8;
	reg regdecwa;
	
	reg regdecwe;
	reg regdecwf;
	reg regdecrf;
	reg [7:0] rddatareg;
	
	initial regdecr0 = 0;
	initial regdecw0 = 0;
	initial regdecw2 = 0;
	initial regdecr4 = 0;
	initial regdecw4 = 0;
	initial regdecw6 = 0;
	initial regdecr8 = 0;
	initial regdecw8 = 0;
	initial regdecwa = 0;		
	initial regdecwe = 0;
	initial regdecwf = 0;
	initial regdecrf = 0;
  
	assign countlread0 = regdecr0;
	assign countlread1 = regdecr4;
	assign countlread2 = regdecr8;
	assign pwmld0 = regdecw0;
	assign pwmld1 = regdecw4;
	assign pwmld2 = regdecw8;
	assign cfgld0 = regdecw2;
	assign cfgld1 = regdecw6;
	assign cfgld2 = regdecwa;
	assign ctrlld = regdecwf;
	assign wdogdivld = regdecwe;
	assign wdreset = regdecrf;
  
	assign rddata = rddatareg;
  
	always @(*) begin
		// Default outputs
		rddatareg <= 8'h00;
		regdecr0 <= 0;
		regdecw0 <= 0;
		regdecw2 <= 0;
		regdecr4 <= 0;
		regdecw4 <= 0;
		regdecw6 <= 0;
		regdecr8 <= 0;
		regdecw8 <= 0;
		regdecwa <= 0;
		regdecwe <= 0;
		regdecwf <= 0;
		regdecrf <= 0;
		case(addr)
			// Channel 0 Tach low byte and PWM
			4'h0: begin
				rddatareg <= countl0;
				regdecw0 <= we;
				regdecr0 <= rdt;
			end
			// Channel 0 Tach high byte
			4'h1: begin
				rddatareg <= counthfrozen0;
			end
			    
			// Channel 0 Configuration
			4'h2: begin
				regdecw2 <= we;
				rddatareg <= configrdreg0;
			end
				
			// Channel 1 Tach low byte and PWM
			4'h4: begin
				rddatareg <= countl1;
				regdecw4 <= we;
				regdecr4 <= rdt;
			end
			// Channel 1 Tach high byte
			4'h5: begin
				rddatareg <= counthfrozen1;
			end
			    
			// Channel 1 Configuration
			4'h6: begin
				regdecw6 <= we;
				rddatareg <= configrdreg1;
			end
				
			// Channel 2 Tach low byte and PWM
			4'h8: begin
				rddatareg <= countl2;
				regdecw8 <= we;
				regdecr8 <= rdt;
			end
			// Channel 2 Tach high byte
			4'h9: begin
				rddatareg <= counthfrozen2;
			end
			    
			// Channel 2 Configuration
			4'ha: begin
				regdecwa <= we;   
				rddatareg <= configrdreg2;  
			end
      
			// Unimplemented decodes
			4'h3, 4'h7,
			4'hb, 4'hc: begin
				rddatareg <= 8'h00;
			end
			
			// Hardware configuration
			4'hd:
				rddatareg <= hwconfig;
			
 
			// Watchdog divisor
			4'he:
				regdecwe <= we;
			
			// Control
			4'hf:
				begin
					rddatareg <= controlrdata;
					regdecwf <= we;
					regdecrf <= rdt;
				end
      
			// BoGuS
			default: begin
				rddatareg <= 8'bxxxxxxxx;
				regdecr0 <= 1'bx;
				regdecr4 <= 1'bx;
				regdecr8 <= 1'bx;
				regdecw0 <= 1'bx;
				regdecw2 <= 1'bx;
				regdecwf <= 1'bx;
				regdecw4 <= 1'bx;
				regdecw6 <= 1'bx;
				regdecw8 <= 1'bx;
				regdecwa <= 1'bx;
			
			
				
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
	output [1:0] pwm0,
	output [1:0] pwm1,
	output [1:0] pwm2,
	// motor enable
	output motorena,
	// LED alive
	output ledalive,
	// spi output enable
	output spioe,
	// System clock
	input clk,
	// Slave Select (SS)
	input ss,
	// SPI Clock (SCLK)
	input sclk,
	// Master Out Slave In (MOSI)
	input mosi,
	// Current limit detect
	input currentlimit0,
	input currentlimit1,
	input currentlimit2,
	
	// Test input
	input tst,
	// Watchdog disable
	input wdogdis,
	// Tachometer phases
	input [1:0] tach0, 
	input [1:0] tach1,
	input [1:0] tach2);
  
  

	wire countlread0;
	wire countlread1;
	wire countlread2;
	wire freeze0;
	wire freeze1;
	wire freeze2;
	wire highce0;
	wire highce1;
	wire highce2;
	wire pwmld0;
	wire pwmld1;
	wire pwmld2;
	wire cfgld0;
	wire cfgld1;
	wire cfgld2;
	wire invertpwm0;
	wire invertpwm1;
	wire invertpwm2;
	wire invphase0;
	wire invphase1;
	wire invphase2;
	wire pwmcntce0;
	wire pwmcntce1;
	wire pwmcntce2;
	wire filterce0;
	wire filterce1;
	wire filterce2;
	wire run0;
	wire run1;
	wire run2;
	wire rdt;
	wire wrt;
	wire we;
	wire ctrlld;
	wire wdogdivld;
	wire motorenaint;
	wire wdreset;
	wire [7:0] counthfrozen0;
	wire [7:0] countl0;
	wire [7:0] counth0;
	wire [7:0] configrdreg0;
	wire [7:0] counthfrozen1;
	wire [7:0] countl1;
	wire [7:0] counth1;
	wire [7:0] configrdreg1;
	wire [7:0] counthfrozen2;
	wire [7:0] countl2;
	wire [7:0] counth2;
	wire [7:0] configrdreg2;
	wire [3:0] addr;
	wire [7:0] wrtdata;
	wire [7:0] rddata;
	wire [7:0] controlrdata;
	wire [7:0] hwconfig;
  

	assign motorena = motorenaint;
	
	
  
  
	negedgedet ned0(
		.clk(clk),
		.in(wrt),
		.out(we));
  
	decoder dec0(
		.we(we),
		.rdt(rdt),
		.addr(addr),
		.countl0(countl0),
		.counthfrozen0(counthfrozen0),
		.configrdreg0(configrdreg0),
		.countl1(countl1),
		.counthfrozen1(counthfrozen1),
		.configrdreg1(configrdreg1),
		.countl2(countl2),
		.counthfrozen2(counthfrozen2),
		.configrdreg2(configrdreg2),
		.controlrdata(controlrdata),
		.hwconfig(hwconfig),
		.rddata(rddata),
		.countlread0(countlread0),
		.countlread1(countlread1),
		.countlread2(countlread2),
		.pwmld0(pwmld0),
		.pwmld1(pwmld1),
		.pwmld2(pwmld2),
		.cfgld0(cfgld0),
		.cfgld1(cfgld1),
		.cfgld2(cfgld2),
		.ctrlld(ctrlld),
		.wdogdivld(wdogdivld),
		.wdreset(wdreset));
    
  
	freezer frz0(
		.clk(clk),
		.countlread(countlread0),
		.freeze(freeze0),
		.highce(highce0));
		
		
	freezer frz1(
		.clk(clk),
		.countlread(countlread1),
		.freeze(freeze1),
		.highce(highce1));
  
  	freezer frz2(
		.clk(clk),
		.countlread(countlread2),
		.freeze(freeze2),
		.highce(highce2));
  
	reg8 counthrreg0(
		.clk(clk),
		.ce(highce0),
		.in(counth0),
		.out(counthfrozen0));
		
		
	reg8 counthrreg1(
		.clk(clk),
		.ce(highce1),
		.in(counth1),
		.out(counthfrozen1));
		
	reg8 counthrreg2(
		.clk(clk),
		.ce(highce2),
		.in(counth2),
		.out(counthfrozen2));

	control ctrl0(
		.clk(clk),
		.cfgld0(cfgld0),
		.cfgld1(cfgld1),
		.cfgld2(cfgld2),
		.ctrlld(ctrlld),
		.wdogdivld(wdogdivld),
		.tst(tst),
		.wdogdis(wdogdis),
		.wdreset(wdreset),
		.wrtdata(wrtdata),
		.pwmcntce0(pwmcntce0),
		.pwmcntce1(pwmcntce1),
		.pwmcntce2(pwmcntce2),		
		.filterce0(filterce0),
		.filterce1(filterce1),
		.filterce2(filterce2),
		.invertpwm0(invertpwm0),
		.invertpwm1(invertpwm1),
		.invertpwm2(invertpwm2),
		.run0(run0),
		.run1(run1),
		.run2(run2),
		.invphase0(invphase0),
		.invphase1(invphase1),
		.invphase2(invphase2),
		.motorenaint(motorenaint),
		.ledalive(ledalive),
		.controlrdata(controlrdata),
		.hwconfig(hwconfig),
		.configrdreg0(configrdreg0),
		.configrdreg1(configrdreg1),
		.configrdreg2(configrdreg2));
		
		 
	bdcmotorchannel bdcm0(
		.clk(clk),
		.filterce(filterce0),
		.invphase(invphase0),
		.freeze(freeze0),
		.pwmcntce(pwmcntce0),
		.pwmldce(pwmld0),
		.invertpwm(invertpwm0),
		.enablepwm(motorenaint),
		.run(run0),
		.currentlimit(currentlimit0),
		.tach(tach0),
		.wrtdata(wrtdata),
		.countl(countl0),
		.counth(counth0),
		.pwmout(pwm0));
		
		
	bdcmotorchannel bdcm1(
		.clk(clk),
		.filterce(filterce1),
		.invphase(invphase1),
		.freeze(freeze1),
		.pwmcntce(pwmcntce1),
		.pwmldce(pwmld1),
		.invertpwm(invertpwm1),
		.enablepwm(motorenaint),
		.run(run1),
		.currentlimit(currentlimit1),
		.tach(tach1),
		.wrtdata(wrtdata),
		.countl(countl1),
		.counth(counth1),
		.pwmout(pwm1));
		
		
	bdcmotorchannel bdcm2(
		.clk(clk),
		.filterce(filterce2),
		.invphase(invphase2),
		.freeze(freeze2),
		.pwmcntce(pwmcntce2),
		.pwmldce(pwmld2),
		.invertpwm(invertpwm2),
		.enablepwm(motorenaint),
		.run(run2),
		.currentlimit(currentlimit2),
		.tach(tach2),
		.wrtdata(wrtdata),
		.countl(countl2),
		.counth(counth2),
		.pwmout(pwm2));
  
   
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

  
  
  
  
  
  


    
    
    
  
  
	
