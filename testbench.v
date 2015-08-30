
// A parallel input shift register clocked on falling edge

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
  
module test;
  
  reg sclk;
  reg ss;
  reg clk;
  reg currentlimit;
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
      	#8 sclk = 0;
      	#8 sclk= 1;
      end
    end
  endtask
  
  // Select the dut, and send a write transaction
  
  task spiwrite;
    begin
    	#2 ss = 1;
    	#2 ss = 1;
    	begin
        outbyte = 8'h55;
      	spiclkburst;
        #2 outbyte = 8'hAA;
        spiclkburst;
    	end
    	#2 ss = 1;
    	#2 ss = 0;
    end  
  endtask

    // Select the dut, and send a read transaction
  
  task spiread;
    begin
    	#2 ss = 1;
    	#2 ss = 1;
    	begin
        outbyte = 8'h80;
      	spiclkburst;
        #2 outbyte = 8'h00;
        spiclkburst;
    	end
    	#2 ss = 1;
    	#2 ss = 0;
    end  
  endtask
  
  
  initial begin
    $dumpvars(0, test);
    clk = 0;
    sclk = 1;
    ss = 0;
    currentlimit = 0;
    tach = 2'b00;
 
    // Clear any pending SPI transaction
    outbyte = 0;
    #2
    spiclkburst;
    #2
    spiclkburst;
    #10
    
    
    spiwrite;
    spiwrite;
    
    spiread;

    
    #960 $finish; 
  end
 
  always #2 clk = ~clk;

endmodule



  