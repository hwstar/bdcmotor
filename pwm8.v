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



//
// This file implements an 8 bit pwm channel with enable, selectable output inversion, and current limiting.
//
// The main module is pwm8
//


//`define WITH_DEADTIME			// Deadtime support 

// PWM minimum and maximum clip values (only meaningful if WIYH_DEADTIME isn't defined)

`define PWM_MIN 3
`define PWM_MAX 251

/*
* PWM counter
*/

module pwmcounter(
  output [7:0] pwmcount,
  input clk,
  input pwmcntce);
  
  reg [7:0] counter;
  initial counter = 8'h00;
  
  assign pwmcount = counter;
  
  always @(posedge clk) begin
    if(pwmcntce) begin
      counter <= counter + 1;
    end
  end  
endmodule


// Holding register for the PWM value

module pwmregister(
  output [7:0] pwmval,
  input clk,
  input pwmldce,
  input [7:0] wrtdata);
  
  reg [7:0] pwmreg;
  
  initial pwmreg = 8'h80;
  
  assign pwmval = pwmreg;
  
  always@(posedge clk) begin
    if(pwmldce) begin
      pwmreg <= wrtdata;
    end
  end 
endmodule


// Pulse width modulator

module pwmod(
  output pwmseout,
  input clk,
  input currentlimit,
  input [7:0] pwmcount,
  input [7:0] pwmval);
  
  reg pwmseo;
  reg [7:0] pwmval_clipped;
  
  initial pwmseo = 0;
  
  assign pwmseout = pwmseo;
 
  // PWM generator	
		 
  always@(posedge clk) begin
	if(pwmcount == 8'hff) begin
		pwmseo = 1;
	end
	else begin
		if((currentlimit == 1) || (pwmcount == pwmval_clipped)) begin
			pwmseo = 0;
		end
	end
  end  
  
  `ifndef WITH_DEADTIME 
  // If using a bootstrapped MOSFET driver,
  // clip PWM at minimum and maximum values
  // This makes sure the MOSFET driver never sees
  // a DC level on the PWM output so that the
  // bootstrap circuit works correctly.
  
  always @(*) begin
	if(pwmval < `PWM_MIN)
		pwmval_clipped <= `PWM_MIN;
	else if(pwmval > `PWM_MAX)
		pwmval_clipped <= `PWM_MAX;
	else
		pwmval_clipped <= pwmval;
	end
  `else
  // If using deadtime, the above is not necessary
  always @(*) begin
	pwmval_clipped <= pwmval;
  end
  `endif
  
endmodule

/*
* This module makes complementary pwm signals from a single input
* with or without deadtime
*/

module deadtime(
	input clk,
	input pwmin,
	output [1:0] pwmout);
	
	reg [1:0] pwmoutreg;
	
	`ifndef WITH_DEADTIME
	always @(*) begin
	    // No deadtime
		pwmoutreg[0] = pwmin;
		pwmoutreg[1] = ~pwmin;
	end
	`else
	// Deadtime
	reg [2:0] counter = 0;
	reg pwmlastin = 0;
	always @(posedge clk) begin
		if(counter != 7)
			counter <= counter + 1;
		else if(pwmin != pwmlastin) begin
			counter <= 0;
			pwmlastin <= pwmin;
		end
	end
	
	always @(*) begin
		if(counter != 7) begin
			pwmoutreg[0] = 0;
			pwmoutreg[1] = 0;
		end
		else begin
			pwmoutreg[0] = pwmlastin;
			pwmoutreg[1] = ~pwmlastin;
		end
	end	
	`endif
	
	assign pwmout = pwmoutreg;
endmodule
	


// Top level module name

module pwm8(
  output [1:0] pwmout,
  input clk,
  input pwmcntce,
  input pwmldce,
  input invertpwm,
  input enablepwm,
  input currentlimit,
  input [7:0] wrtdata);
  
  wire [7:0] pwmcount;
  wire [7:0] pwmval;
  wire pwmseout;
  wire pwmcorrseout;
	
 
  pwmregister pwmr(
    .clk(clk),
    .pwmldce(pwmldce),
    .wrtdata(wrtdata),
    .pwmval(pwmval));
    
    
  pwmcounter pwmc(
    .clk(clk),
    .pwmcntce(pwmcntce),
    .pwmcount(pwmcount));
  
  
  pwmod pwmm(
    .clk(clk),
    .currentlimit(currentlimit),
    .pwmcount(pwmcount),
    .pwmval(pwmval),
    .pwmseout(pwmseout));
  
  
  deadtime deadt0(
	.clk(clk),
	.pwmin(pwmcorrseout),
	.pwmout(pwmout));
	
  assign pwmcorrseout = (pwmseout ^ invertpwm);


endmodule
