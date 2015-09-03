
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
// This module implements a complete brushed DC motor channel with 16 bit quadrature tach counter,
// tach filtering, tach phase inversion, 8 bit pwm with current limit, and pwm output polarity selection.


module bdcmotorchannel(
    // Tach counter low byte
  	output [7:0] countl,
    // Tach counter high byte
	output [7:0] counth,
    // Complmentary pwm signals out
  	output [1:0] pwmout,
  	// 4 bit pwm signals out
  	output [3:0] pwmout4,
    // System clock in
    input clk,
    // Clock enable for tach filter shift register
    input filterce,
    // Freeze tach counter ( used during reads)
    input freeze,
    // Invert tach counter phase
    input invphase,
    // PWM count enable (used to control PWM frequency)
    input pwmcntce,
    // Load a PWM value on the wrtdata bus into the PWM logic
	input pwmldce,
  	// Invert the PWM outputs
  	input invertpwm,
    // Enable the PWM outputs
    input enablepwm,
    // Run or send the brake signal to the pwm outputs
    input run,
    // Force early termination of the PWM cycle
    input currentlimit,
    // Quadrature tach inputs
  	input [1:0] tach,
    // Write data bus
  	input [7:0] wrtdata);
  

    tachcounter tc(
    .clk(clk),
    .tach(tach),
    .filterce(filterce),
    .freeze(freeze),
    .invphase(invphase),
    .countl(countl),
    .counth(counth));
  
  pwm8 pwm(
    .clk(clk),
    .pwmcntce(pwmcntce),
    .pwmldce(pwmldce),
    .invertpwm(invertpwm),
    .enablepwm(enablepwm),
    .run(run),
    .currentlimit(currentlimit),
    .wrtdata(wrtdata),
    .pwmout(pwmout),
    .pwmout4(pwmout4));
    
  
endmodule
