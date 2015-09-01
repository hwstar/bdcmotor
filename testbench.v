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

// A parallel input shift register clocked on falling edge

`timescale 10ns/1ns

module tbshftout(
  output sout,
  input [7:0] outbyte,
  input ld,
  input clk);
  
  reg [7:0] register = 8'h00;
  
  assign sout = register[7]; // MSB output
 
  always @(negedge clk) begin
    if(ld) begin
      register <= outbyte;
    end
    else begin
      register[7:1] <= register[6:0];
      register[0] <= 0;
    end
  end
endmodule


// A parallel output shift register clocked on rising edge

module tbshftin(
  output [7:0] out,
  input sin,
  input clk);
  
  reg [7:0] register = 8'h00;
  
  assign out = register;
 
  always @(posedge clk) begin
    register[7:1] <= register[6:0];
    register[0] = sin; // LSB input
  end
endmodule




// Count spi clocks modulo 16

module tbclkctr(
  output [2:0] cycle,
  input clk,
  input en);
  
  reg [2:0] register = 3'b000;
  
  assign cycle = register;
  
  always @(posedge clk) begin
    if(en)
    	register <= register + 1;
    else
      register = 0;
  end
endmodule

// Clock sequence decode

module tbseq(
  output sold,
  input [2:0] cycle);
  
  reg [2:0] regsold = 0;
  
  assign sold = regsold;
  
  always @(cycle) begin
    regsold = 0;
    case(cycle)
      4'h0:
      	regsold = 1;
      4'h1, 4'h2, 4'h3, 4'h4,
      4'h5, 4'h6, 4'h7:
        regsold = 0;
      default:
        regsold = 1'bx;
    endcase
  end
endmodule

// Main test module        
  
module testbench;
  
  reg sclk;
  reg ss;
  reg clk;
  reg currentlimit;
  reg tst;
  reg wdogdis;
  reg [7:0] outbyte;
  reg [1:0] tach;
 
  
  wire mosi;
  wire miso;
  wire sold;
  wire spioe;
  wire motorena;
 
  wire [2:0] cycle;
  wire [7:0] inbyte;
  wire [1:0] pwm;

  
 
  tbclkctr tbcc0(
    .clk(sclk),
    .en(ss),
    .cycle(cycle));
  
  tbseq tbs0(
    .cycle(cycle),
    .sold(sold));
  
  tbshftout so0(
    .clk(sclk),
    .outbyte(outbyte),
    .ld(sold),
    .sout(mosi));
  
  tbshftin si0(
    .clk(sclk),
    .sin(miso),
    .out(inbyte));
 
 
  system sys0(
    .clk(clk),
    .sclk(sclk),
    .ss(ss),
    .mosi(mosi),
    .tst(tst),
    .wdogdis(wdogdis),
    .currentlimit(currentlimit),
    .tach(tach),
    .miso(miso),
    .motorena(motorena),
    .pwm(pwm));
 
  
 
  
 
  
  // Send a burst of 16 spiclks
  
  task spiclkburst;
    integer i;
    begin
      for(i = 0; i < 8; i = i + 1) begin
      	#16 sclk = 0;
      	#16 sclk= 1;
      end
    end
  endtask
  
  // Select the dut, and send a write transaction
  
  task spiwrite([3:0] addr, [7:0] data);
    begin
    	#40 ss = 1;
    	#40 ss = 1;
    	begin
    	outbyte = {1'b0, addr, 3'b0};
      	spiclkburst;
        #40 outbyte = data;
        spiclkburst;
    	end
    	#40 ss = 1;
    	#40 ss = 0;
    end  
  endtask

    // Select the dut, and send a read transaction
  
  task spiread([3:0] addr);
    begin
    	#40 ss = 1;
    	#40 ss = 1;
    	begin
        outbyte = {1'b1, addr, 3'b0};
      	spiclkburst;
        #40 outbyte = 8'h00;
        spiclkburst;
    	end
    	#40 ss = 1;
    	#40 ss = 0;
    end  
  endtask
  
  
  initial begin
    $dumpvars(0, testbench);
    clk = 0;
    sclk = 1;
    ss = 0;
    currentlimit = 0;
    tst = 1;
    wdogdis = 0;
    tach = 2'b00;
 
    // Clear any pending SPI transaction
    outbyte = 0;
    #40
    spiclkburst;
    #40
    spiclkburst;
    #100
    
   
    // Write config register
    spiwrite(4'h2, 8'h0); 
    
    
    
    // Write pwm register
    spiwrite(4'h0, 8'h80);
   
    
    spiread(4'h0);

    
    #960000 $finish; 
  end
 
  always #4 clk = ~clk;

endmodule



  
