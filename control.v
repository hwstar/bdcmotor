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
 */
 
 
 
/*
* 8 bit register
*/

module reg8(
	input clk,
	input ce,
	input [7:0] in,
	output [7:0] out);
  
	reg [8:0] register;
	
	initial register = 8'h00;
  
	assign out = register;
  
	always @(posedge clk) begin
		if(ce) begin
			register = in;
		end
	end
endmodule

/*
* Divide a clock enable by a power of 2 (1,2,4 or 8)
*
* divisor:
* 00	- Divide by 1
* 01	- Divide by 2
* 10	- Divide by 4
* 11	- Divide by 8
*/
 
module divby1248(
	input clk,
	input cein,
	input [1:0] divisor,
	output ceout);
	
	
	reg ceoutmux;
	
	reg [2:0] counter;
	
	initial counter = 0;
	
	assign ceout = ceoutmux;
	
	always @(posedge clk) begin
		if(cein)
			counter <= counter + 1;
	end
	
	always @(*) begin
		case(divisor)
			2'b00:
				ceoutmux <= cein;
			2'b01:
				ceoutmux <= cein & counter[0];
			2'b10: 
				ceoutmux <= cein & counter[0] & counter[1];
			2'b11:
				ceoutmux <= cein & counter[0] & counter[1] & counter[2];
			default:
				ceoutmux <= 1'bx;
		endcase
	end
endmodule

/*
* Fixed divide by 64 of the system clock
*/

module fixeddivby64(
	input clk,
	input cein,
	output ceout);
	
	reg ceoutreg;
	reg ceoutregs;
	reg [5:0] counter;
	
	initial ceoutreg = 0;
	initial ceoutregs = 0;
	initial counter = 0;
	
	assign ceout = ceoutregs;
	
	always @(*) begin
		// Generate a ce every 64 clocks
		if(counter == 63)
			ceoutreg <= cein;
		else
			ceoutreg <= 0;
	end
	
	always @(posedge clk) begin
		// Resynchronize ceout
		ceoutregs <= ceoutreg;
		if(cein)
			counter <= counter + 1;
	end
endmodule

/*
* Fixed divide by 256 of the system clock
*/

module fixeddivby256(
	input clk,
	input cein,
	output ceout);
	
	reg ceoutreg;
	reg ceoutregs;
	reg [7:0] counter;
	
	initial ceoutreg = 0;
	initial ceoutregs = 0;
	initial counter = 0;
	
	assign ceout = ceoutregs;
	
	always @(*) begin
		// Generate a ce every 256 clocks
		if(counter == 255)
			ceoutreg <= cein;
		else
			ceoutreg <= 0;
	end
	
	always @(posedge clk) begin
		// Resynchronize ceout
		ceoutregs <= ceoutreg;
		if(cein)
			counter <= counter + 1;
	end
endmodule



/*
* Watchdog timer
* Outputs a 1 clock pulse wide clock enable if watchdog timer times out
*/

module wdtimer(
	input clk,
	input cein,
	input enable,
	input reset,
	input wdogdis,
	input [7:0] wdogdivreg,
	output wdtripce);
	
	reg [7:0] counter;
	reg wdtripcesreg;
	reg wdtripcereg;
	reg wdogdisreg;
	
	initial counter = 0;
	initial wdtripcesreg = 0;
	initial wdtripcereg = 0;
	initial wdogdisreg = 0;
	
	assign wdtripce = wdtripcesreg;
	
	always @(*) begin
		if ((wdogdivreg == counter) && ~reset && enable && ~wdogdisreg)
			wdtripcereg <= cein;
		else
			wdtripcereg <= 0;
	end
	
	always @(posedge clk) begin
		// Resynchronize wdtripcereg to clock
		wdtripcesreg <= wdtripcereg;
		// Synchronize watchdog disable to clock
		wdogdisreg = wdogdis;
		
		// Only count when enable is high and reset is low, and watchdog disable is low
		if(enable & ~reset & ~wdogdisreg) begin
			if(cein)
				counter <= counter + 1;
		end
		else
			counter <= 8'h00;
	end
endmodule

/*
* Watchdog register
*/

		
module wdregister(
	input clk,
	input ctrlld,
	input wdtripce,
	input [7:0] wrtdata,
	output motorenaint,
	output [7:0] controlrddata);
	
	reg motorenaintreg;
	reg wdtrip;
	reg [7:0] controlreg;
	reg [7:0] controlrddatareg;
	
	initial motorenaintreg = 0;
	initial wdtrip = 0;
	initial controlreg = 0;
	
	
	assign motorenaint = motorenaintreg;
	assign controlrddata = controlrddatareg;
	
	always @(*) begin
		// Assemble control register read value
		controlrddatareg <= {wdtrip, 1'b0, 1'b0, 1'b0, controlreg[3:0]};
		// Motor enable
		motorenaintreg <=  ~wdtrip & controlreg[3];
	end
	
	
	always @(posedge clk) begin
		if(ctrlld)
		    // Load new control register value
			controlreg <= wrtdata;
		if(wdtripce)
			// Set watchdog trip bit
			wdtrip <= 1;
		if(ctrlld && ( wrtdata == 8'h80))
			// Clear watchdog trip bit when a 0x80 is written to the control register
			wdtrip <= 0;
	end
endmodule
			
			
		
	
	
	
/*
* Top level module for this file
*/

module control(
	output pwmcntce,
	output filterce,
	output invphase,
	output invertpwm,
	output motorenaint,
	input clk,
	input cfgld,
	input ctrlld,
	input wdogdivld,
	input tst,
	input wdogdis,
	input [7:0] wrtdata);
	
	wire [7:0] configreg;
	wire [7:0] wdogdivreg;
	wire ce64;
	wire ce16384;
	wire cfgce;
	wire wdogdivregce;
	wire wdtripce;
	
	reg wdogcntce;
	
	
	
	reg tie1 = 1;
	
	reg ctrlrdce = 0; // FIXME
	
	// Prevent config and watchdog divisor register writes when motor is enabled
	assign cfgce = cfgld & ~motorenaint;
	assign wdogdivregce = wdogdivld & ~motorenaint;
	
	assign motorenaint = 0; // FIXME
	
	
	always @(*) begin
		if(tst)
			wdogcntce <= ce64;
		else
			wdogcntce <= ce16384;
	end
		
	reg8 wdogdivregister(
		.clk(clk),
		.ce(wdogdivregce),
		.in(wrtdata),
		.out(wdogdivreg));
	
	reg8 configregister(
		.clk(clk),
		.ce(cfgce),
		.in(wrtdata),
		.out(configreg));
		
	fixeddivby64 fdiv64(
		.cein(tie1),
		.clk(clk),
		.ceout(ce64));
		
	fixeddivby256 fdiv256(
		.cein(ce64),
		.clk(clk),
		.ceout(ce16384));
		
	divby1248 filterdiv(
		.clk(clk),
		.cein(ce64),
		.divisor(configreg[3:2]),
		.ceout(filterce));
		
	divby1248 pwmdiv(
		.clk(clk),
		.cein(tie1),
		.divisor(configreg[1:0]),
		.ceout(pwmcntce));
		
		
	wdtimer wdtimer0(
		.clk(clk),
		.cein(wdogcntce),
		.enable(motorenaint),
		.reset(ctrlrdce),
		.wdogdis(wdogdis),
		.wdogdivreg(wdogdivreg),
		.wdtripce(wdtripce));
	
	assign invphase = configreg[5];
	assign invertpwm = configreg[4];
endmodule

	
	

	
			
	
