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
//
// This file instantiates a 16 bit quadrature counter. This is primarily used to handle the output
// of a motor tach wheel encoder, linear optical encoder, or other source of quadrature signals.
//
// The main module to instantiate in a higher level file is qc16.
//


module digitalfilter(output out, input clk, input ce, input in);
  
  reg [5:0] taps;
  reg result;
  
  initial taps = 6'b000000;
  initial result = 0;
  
  assign out = result;
  
 
  always @(posedge clk)
  begin
    if(ce)
      begin
        taps[5] <= taps[4];
        taps[4] <= taps[3];
    	taps[3] <= taps[2];
    	taps[2] <= taps[1];
    	taps[1] <= taps[0];
        taps[0] <= in;
      end
    if(taps[2] & taps[3] & taps[4] & taps[5])
      result <= 1;
    if(~taps[2] & ~taps[3] & ~taps[4] & ~taps[5])
      result <= 0;
  end

 
  
endmodule


//
// Convert 2 bit gray code into a series of up or down pulses one clock period wide
//
// Pulses the up output if the count direction is up, otherwise pulses the
// down output if the count direction is down. Does nothing if there was no 
// change, or an invalid state

// Module to do primitive digital filtering
//
// Uses a 4 bit shift register and and output register to
// filter an incoming signal on the in pin. 
//
// The first two bits of the shift register are used to synchronize
// the input signal to the clock.

// If the signa is low for 2 clock enables, the output will go low.
// If the signal is high for 2 clock enables, the output will go high
//


module graycode2(
  output up,
  output down,
  input clk,
  input freeze,
  input [1:0] tach);
  
  reg [1:0] last;
  reg u;
  reg d;
  
  
  wire [3:0] encodedstate; 
  
  initial last = 0;
  initial u = 0;
  initial d = 0;
  
  assign encodedstate = {tach, last};
  assign up = u;
  assign down = d;
  
  always @(posedge clk) begin
    u <= 0;
    d <= 0;
    if(~freeze) begin
      case(encodedstate) 
        4'b0000, // Do nothing states
        4'b1111,
        4'b1010,
        4'b0101:
          begin
          end
        4'b0100, // Increment state
        4'b1101,
        4'b1011,
        4'b0010:
          begin
            last <= tach;
            u <= 1;
            d <= 0;  
          end
        4'b0001, // Decrement State
        4'b0111,
        4'b1110,
        4'b1000:
          begin
            last <= tach;
          	u <= 0;
            d <= 1;
          end
        4'b0011, // Error states
        4'b1100,
        4'b0110,
        4'b1001:
          begin
          end 
        
        default: // Catch all for bad inputs
          begin
          	u <= 1'bx;
          	d <= 1'bx;
          end
      endcase    
    end  
  end
  
  
endmodule

//
// 16 bit synchronous up down counter
//

module udcounter16(
  output [15:0] counter,
  input clk,
  input up,
  input down);
  
  reg [15:0] result;
  
  initial result = 16'h0000;
  
  assign counter = result;
  
  always@(posedge clk) begin
    if(up) begin
      result <= result + 1;
    end
    if(down) begin
        result <= result - 1;
    end
  end
endmodule
 
// 16 bit quadrature counter
//
// counth 	output	High byte of tach counter
// countl	output	Low byte of tach counter
// tach     input   2 bit tach input
// clk		input	Clock
// freeze	input	Freezes the counter when high
// invphase input   Inverts the phase of the incoming tach signals
// 


module qc16(
  output [7:0] counth, 
  output [7:0] countl, 
  input [1:0] tach, 
  input clk,
  input freeze,
  input invphase);
 
  wire [15:0] counter;
  wire up;
  wire down;
  reg [1:0] adjtach;
  
  // Swap tach signals if invphase is true
  
  always @(*) begin
    if(invphase) begin
      adjtach[0] = tach[1];
      adjtach[1] = tach[0];
    end
    else begin
      adjtach[0] = tach[0];
      adjtach[1] = tach[1];
    end
  end
  
  
  graycode2 gc2(
    .clk(clk), 
    .freeze(freeze),
    .up(up), 
    .down(down), 
    .tach(adjtach));
    
  udcounter16 udc16(
    .clk(clk),
    .up(up),
    .down(down),
    .counter(counter));
  
  // Assign the 16 bit counter to the high and low bytes
  assign counth = counter[15:8];
  assign countl = counter[7:0];
 
endmodule


// Top level module for this file


module tachcounter(
    output [7:0] countl,
	output [7:0] counth,
    input clk,
    input filterce,
    input freeze,
    input invphase,
    input [1:0] tach);
  
  wire [1:0] filttach;
  
  qc16 q16(
    .clk(clk),
    .tach(filttach),
    .freeze(freeze),
    .invphase(invphase),
    .countl(countl),
    .counth(counth));
  
  digitalfilter filterph0(
    .clk(clk),
    .ce(filterce),
    .in(tach[0]),
    .out(filttach[0]));
  
  digitalfilter filterph1(
    .clk(clk),
    .ce(filterce),
    .in(tach[1]),
    .out(filttach[1]));
  
endmodule   

