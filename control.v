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
 
`default_nettype none
 
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
* Fixed divide by 2
*/

module fixeddivby2(
	input clk,
	input cein,
	output ceout);

	reg q;
		
	initial q = 0;
	
	assign ceout = cein & q;

	always @(posedge clk) begin
		if(cein)
			q = ~q;
	end
	
endmodule



/*
* Fixed divide by 32 of the system clock
*/

module fixeddivby32(
	input clk,
	input cein,
	output ceout);
	
	reg ceoutreg;
	reg ceoutregs;
	reg [4:0] counter;
	
	initial ceoutreg = 0;
	initial ceoutregs = 0;
	initial counter = 0;
	
	assign ceout = ceoutregs;
	
	always @(*) begin
		// Generate a ce every 64 clocks
		if(counter == 31)
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
	input wdreset,
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
		if ((wdogdivreg == counter) && ~wdreset && enable && ~wdogdisreg)
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
		if(enable & ~wdreset & ~wdogdisreg) begin
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
	input wdogdis,
	input [7:0] wrtdata,
	output motorenaint,
	output run0,
	output run1,
	output run2,
	output [7:0] controlrdata);
	
	reg motorenaintreg;
	reg wdtrip;
	reg [7:0] controlreg;
	reg [7:0] controlrdatareg;
	
	initial motorenaintreg = 0;
	initial wdtrip = 0;
	initial controlreg = 0;
	
	
	assign motorenaint = motorenaintreg;
	assign run0 = controlreg[0];
	assign run1 = controlreg[1];
	assign run2 = controlreg[2];
	
	assign controlrdata = controlrdatareg;
	
	always @(*) begin
		// Assemble control register read value
		controlrdatareg <= {wdtrip, wdogdis, 1'b0, 1'b0, controlreg[3:0]};
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
			
module ledctr(
	input clk,
	input ce,
	output ledalive);
	
	reg [9:0] counter;
	
	assign ledalive = counter[9];
	
	initial counter = 0;
	
	always @ (posedge clk) begin
		if(ce)
			counter <= counter + 1;
	end
endmodule

		
		
	
	
	
/*
* Top level module for this file
*/

module control(
	output pwmcntce0,
	output pwmcntce1,
	output pwmcntce2,
	output filterce0,
	output filterce1,
	output filterce2,
	output invphase0,
	output invphase1,
	output invphase2,
	output invertpwm0,
	output invertpwm1,
	output invertpwm2,
	output run0,
	output run1,
	output run2,
	output motorenaint,
	output ledalive,
	output [7:0] controlrdata,
	output [7:0] hwconfig,
	input clk,
	input cfgld0,
	input cfgld1,
	input cfgld2,
	input ctrlld,
	input wdogdivld,
	input tst,
	input wdogdis,
	input wdreset,
	input [7:0] wrtdata);
	
	wire [7:0] configreg0;
	wire [7:0] configreg1;
	wire [7:0] configreg2;
	
	wire [7:0] wdogdivreg;
	wire ce32;
	wire ce64;
	wire ce16384;
	wire cfgce0;
	wire cfgce1;
	wire cfgce2;
	wire wdogdivregce;
	wire wdtripce;
	
	reg wdogcntce;
	
	
	
	
	reg tie1 = 1;
	
	
	// Prevent config and watchdog divisor register writes when motor is enabled
	assign cfgce0 = cfgld0 & ~motorenaint;
	assign cfgce1 = cfgld1 & ~motorenaint;
	assign cfgce2 = cfgld2 & ~motorenaint;
	assign wdogdivregce = wdogdivld & ~motorenaint;
	
	// Hardware configuration register
	assign hwconfig = {1'b0,1'b0,2'b11,4'b0000};

	
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
	
	reg8 configregister0(
		.clk(clk),
		.ce(cfgce0),
		.in(wrtdata),
		.out(configreg0));
		
	reg8 configregister1(
		.clk(clk),
		.ce(cfgce1),
		.in(wrtdata),
		.out(configreg1));
		
	reg8 configregister2(
		.clk(clk),
		.ce(cfgce2),
		.in(wrtdata),
		.out(configreg2));		
		
		
	fixeddivby2 fdiv2(
		.cein(ce32),
		.clk(clk),
		.ceout(ce64));
		
	fixeddivby32 fdiv32(
		.cein(tie1),
		.clk(clk),
		.ceout(ce32));
		
	fixeddivby256 fdiv256(
		.cein(ce64),
		.clk(clk),
		.ceout(ce16384));
		
	divby1248 filterdiv0(
		.clk(clk),
		.cein(ce32),
		.divisor(configreg0[3:2]),
		.ceout(filterce0));
		
	divby1248 pwmdiv0(
		.clk(clk),
		.cein(tie1),
		.divisor(configreg0[1:0]),
		.ceout(pwmcntce0));

	divby1248 filterdiv1(
		.clk(clk),
		.cein(ce32),
		.divisor(configreg1[3:2]),
		.ceout(filterce1));
		
	divby1248 pwmdiv1(
		.clk(clk),
		.cein(tie1),
		.divisor(configreg1[1:0]),
		.ceout(pwmcntce1));		

	divby1248 filterdiv2(
		.clk(clk),
		.cein(ce32),
		.divisor(configreg2[3:2]),
		.ceout(filterce2));
		
	divby1248 pwmdiv2(
		.clk(clk),
		.cein(tie1),
		.divisor(configreg2[1:0]),
		.ceout(pwmcntce2));		
		
	wdtimer wdtimer0(
		.clk(clk),
		.cein(wdogcntce),
		.enable(motorenaint),
		.wdreset(wdreset),
		.wdogdis(wdogdis),
		.wdogdivreg(wdogdivreg),
		.wdtripce(wdtripce));
	
	
	wdregister wdreg0(
		.clk(clk),
		.ctrlld(ctrlld),
		.wdtripce(wdtripce),
		.wdogdis(wdogdis),
		.wrtdata(wrtdata),
		.run0(run0),
		.run1(run1),
		.run2(run2),
		.motorenaint(motorenaint),
		.controlrdata(controlrdata));
	
	
	ledctr ledctr0(
		.clk(clk),
		.ce(ce16384),
		.ledalive(ledalive));
		
	assign invphase0 = configreg0[5];
	assign invertpwm0 = configreg0[4];
	assign invphase1 = configreg1[5];
	assign invertpwm1 = configreg1[4];
	assign invphase2 = configreg2[5];
	assign invertpwm2 = configreg2[4];

	
endmodule

	
	

	
			
	
