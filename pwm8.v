//
// This file implements an 8 bit pwm channel with enable, selectable output inversion, and current limiting.
//
// The main module is pwm8
//


//`define WITH_DEADTIME			// Future deadtime support (not implemented yet)

// PWM counter

module pwmcounter(
  output [7:0] pwmcount,
  input clk,
  input pwmcntce);
  
  reg [7:0] counter = 8'h00;
  
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
  
  reg [7:0] pwmreg = 8'h80; // Set to 50% duty cycle which will turn the motor off.
  
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
  
  assign pwmseout = pwmseo;
  
  always@(posedge clk) begin
    if(pwmval == 8'b00) begin
      pwmseo = 0;
    end
    else begin
      if(pwmcount == 8'b00) begin
        pwmseo = 1;
      end
      else begin
        if((currentlimit == 1) || (pwmcount == pwmval)) begin
          pwmseo = 0;
        end
      end
    end  
  end  
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
  
  
  assign pwmcorrseout = (pwmseout ^ invertpwm);
  
  // No deadtime version
  `ifndef WITH_DEADTIME
  assign pwmout[0] = (pwmcorrseout & enablepwm);
  assign pwmout[1] = (~pwmcorrseout & enablepwm);
  `endif
  
  
endmodule
