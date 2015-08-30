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
    .currentlimit(currentlimit),
    .wrtdata(wrtdata),
    .pwmout(pwmout));
    
  
endmodule
