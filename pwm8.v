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


//
// This file implements an 8 bit pwm channel with enable, selectable output inversion, and current limiting.
//
// The main module is pwm8
//


`define WITH_DEADTIME			// Deadtime support 

// PWM minimum and maximum clip values (only meaningful if WITH_DEADTIME isn't defined)

`define PWM_MIN 3
`define PWM_MAX 251

/*
* PWM counter
*/

module pwmcounter(
  output [7:0] pwmcount,
  input clk,
  input pwmcntce);
  
  reg [7:0] counter = 0;
 
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
  
  reg [7:0] pwmreg = 8'h00;
  
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
  
  reg pwmseo = 0;
  reg [7:0] pwmsyncreg = 0;
  reg [7:0] pwmval_clipped;
  
  
  assign pwmseout = pwmseo;
 
  // PWM generator	
		 
  always@(posedge clk) begin
	if(pwmcount == 8'hff) begin
	    //
	    // New cycle, then pwm output on.
	    // 
	    // At the beginning of a cycle, save a copy of the pwm
	    // value. This prevents the pwm value from changing
	    // erratically as it is only updated when a new cycle
	    // begins.
		pwmsyncreg = pwmval_clipped;
		pwmseo = 1;
	end
	else begin
		// If current limit, or the count equals the desired
		// duty cycle, turn the output off.

		if((currentlimit == 1) || (pwmcount == pwmsyncreg)) begin
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
*
* PWM output bit truth table
*
* 2 bit	4 bit
* 00 - 	0000	-	Motor coast (All H-bridge drivers should be off).
* 01 -  0110	-	Run CCW (Upper MOSFET driving the motor negative terminal)
* 10 - 	1001	-	Run CW (Upper MOSFET driving the motor positive terminal)
* 11 - 	0101	-	Enable dynamic braking (Lower MOSFETS on, upper MOSFETS off)
*
* PWM flips the output bits between 01 and 10 according to the programmed
* duty cycle. This only is allowed to happen when the motor is enabled
* and the brake is off.
*
* If compiled with deadtime, then when the PWM state changes, the motor
* outputs will go into coast mode for 8 system clock cycles.
*
*/

module deadtime(
	input clk,
	input pwmin,
	input enablepwm,
	input run,
	output [1:0] pwmout,
	output [3:0] pwmout4);
	
	reg [1:0] qualifiedpwm2;
	reg [1:0] pwmoutreg;
	reg [3:0] pwmoutreg4;
	
	`ifdef WITH_DEADTIME
	reg [2:0] counter = 0;
	reg [2:0] pwmlastin = 2'b00;
	`endif
	
	assign pwmout4 = pwmoutreg4;
	assign pwmout = pwmoutreg;
	
	always @(*) begin
		case(pwmoutreg)
			2'b00:
				pwmoutreg4 <= 4'b0000;
			
			2'b01:
				pwmoutreg4 <= 4'b0110;
			
			2'b10:
				pwmoutreg4 <= 4'b1001;
			
			2'b11:
				pwmoutreg4 <= 4'b0101;
				
			default:
				pwmoutreg4 <= 4'bxxxx;
				
		endcase
		
		if(enablepwm) begin
			if(run) begin
				qualifiedpwm2[0] <= pwmin;
				qualifiedpwm2[1] <= ~pwmin;
			end
			else begin
				qualifiedpwm2[0] <= 1;
				qualifiedpwm2[1] <= 1;
			end
		end
		else begin
			if(run) begin
				qualifiedpwm2[0] <= 0;
				qualifiedpwm2[1] <= 0;
			end
			else begin
				qualifiedpwm2[0] <= 1;
				qualifiedpwm2[1] <= 1;
			end
		end
		
		`ifndef WITH_DEADTIME
			// No deadtime
			pwmoutreg[0] <= qualifiedpwm[0];
			pwmoutreg[1] <= qualifiedpwm[1];

		`else
			// Deadtime
			if(counter != 7) begin
				pwmoutreg[0] <= 0;
				pwmoutreg[1] <= 0;
			end
			else begin
				pwmoutreg[0] <= pwmlastin[0];
				pwmoutreg[1] <= pwmlastin[1];
			end	
		`endif				
	end
	

	`ifdef WITH_DEADTIME
	// Deadtime
	always @(posedge clk) begin
		if(counter != 7)
			counter <= counter + 1;
		else if(qualifiedpwm2 != pwmlastin) begin
			counter <= 0;
			pwmlastin <= qualifiedpwm2;
		end
	end
	`endif
	
	
endmodule
	


// Top level module name

module pwm8(
  output [1:0] pwmout,
  output [3:0] pwmout4,
  input clk,
  input pwmcntce,
  input pwmldce,
  input invertpwm,
  input enablepwm,
  input run,
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
	.enablepwm(enablepwm),
	.run(run),
	.pwmout(pwmout),
	.pwmout4(pwmout4));
	
  assign pwmcorrseout = (pwmseout ^ invertpwm);


endmodule
