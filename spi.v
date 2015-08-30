//
// This module implements a 16 bit SPI slave.
// The main module name is spi.
// 


// A parallel output shift register clocked on rising edge

module spirdshft(
  output [7:0] dout,
  input din,
  input clk,
  input en);
  
  reg [7:0] doutregister = 8'h00;
  
  assign dout = doutregister;
  
  always @(posedge clk) begin
    if(en) begin
      doutregister[7:1] <= doutregister[6:0];
      doutregister[0] <= din; // Clocked into LSB first
    end
    
  end
endmodule

// A parallel input shift register clocked on falling edge

module spiwrshft(
  output out,
  input [7:0] parallelin,
  input rdld,
  input clk);
  
  reg [7:0] dinregister = 8'h00;
  
  assign out = dinregister[7];
 
  always @(negedge clk) begin
    if(rdld)
      dinregister <= parallelin;
    else begin
      dinregister[7:1] <= dinregister[6:0];
    end
  end
endmodule



// Clock counter

module spiclkcounter(
  output [3:0] clkcount,
  input clk,
  input en);
  
  reg [3:0] countreg = 0;
  
  assign clkcount = countreg;
  
  always @(posedge clk) begin
    if(en)
    	countreg <= countreg + 1;
    else
    	countreg = 4'h0;
  end
endmodule


// Address register

module addrregister(
  output [3:0] addr,
  input clk,
  input din,
  input en);
  
  reg [3:0] addrreg = 0;
  
  assign addr = addrreg;
  
  always @(posedge clk) begin
    if(en) begin
      addrreg[3:1] <= addrreg[2:0];
      addrreg[0] = din; // Clocked into MSB first
    end
  end
endmodule


// Mode register (Stores first bit shifted out  as read/~write in a 16 bit transaction)
module moderegister(
  output mode,
  input clk,
  input modet,
  input in);
  
  reg modereg = 0;
  assign mode = modereg;
  always@(posedge clk) begin
    if(modet)
      modereg = in; // Save the state of the input bit
  end
endmodule

  

// Decode SPI counter counts into transactions

module spiseq(
  input [3:0] spiclkcounter,
  input spien,
  input mode,
  output addrt,
  output spioe,
  output rdt,
  output rdld,
  output wrt,
  output modet);
  
  reg modetreg;
  reg addrtreg;
  reg rdtreg;
  reg wrtreg;
  reg rdldreg;
  reg spioereg;
  
  assign modet = modetreg;
  assign addrt = addrtreg;
  assign rdt = rdtreg;
  assign wrt = wrtreg;
  assign rdld = rdldreg;
  assign spioe = spioereg;
  
  always @(*) begin
    modetreg = 0;
    rdtreg = 0;
    addrtreg = 0;
    wrtreg = 0;
    rdldreg = 0;
    spioereg = spien & mode;
    
    case(spiclkcounter)
      4'h0:
        modetreg = 1; // Signal to load mode register

      4'h1, 4'h2, 4'h3, 4'h4:
      	addrtreg = spien; // Signal to load address register
      
      
      4'h5, 4'h6, 4'h7:
        rdtreg = (mode & spien); // Signal to indicate read transaction
      
      4'h8:
        begin
          rdtreg = (mode & spien); // Signal to indicate read transaction
          rdldreg = (mode & spien); // Load shift register
          wrtreg = (~mode & spien); // Signal to indicate write transaction  
        end
        
      4'h9, 4'ha, 4'hb, 
      4'hc, 4'hd, 4'he, 4'hf:
        wrtreg = (~mode & spien); // Signal to indicate write transaction
     
      default:
        begin
          rdtreg = 1'bx;
          wrtreg = 1'bx;
          addrtreg = 1'bx;
          modetreg = 1'bx;
          rdldreg = 1'bx;
        end   
    endcase
  end
endmodule
  

  
// Main interface

module spi(
  output spidout, // Data to master (MISO)
  output rdt, // Indicates a read transaction
  output wrt, // Indicates a write transaction
  output spioe, // MISO 3 state enable
  output [7:0] wrtdata, // Parallel write data out 
  output [3:0] addr, // Parallel address out
  input spien, // SPI enable (SS)
  input spiclk, // SPI clock (SCLK)
  input spidin, // SPIDIN (MOSI)
  input [7:0] rddata); // Parallel read data in
  
  wire mode;
  wire rdld;
  wire modet;
  wire addrt;
  wire [3:0] clkcount;
  
  
  
  spiclkcounter scc (
    .clk(spiclk),
    .en(spien),
    .clkcount(clkcount));
  
  moderegister mreg (
    .clk(spiclk),
    .modet(modet),
    .in(spidin),
    .mode(mode));
  
  
  addrregister areg (
    .clk(spiclk),
    .en(addrt),
    .din(spidin),
    .addr(addr));
    
  
  spirdshft srs (
    .clk(spiclk),
    .din(spidin),
    .en(wrt),
    .dout(wrtdata));
  
  spiwrshft sws (
    .clk(spiclk),
    .parallelin(rddata),
    .rdld(rdld),
    .out(spidout));
  
  spiseq ssq (
    .spiclkcounter(clkcount),
    .spien(spien),
    .mode(mode),
    .modet(modet),
    .spioe(spioe),
    .addrt(addrt),
    .rdt(rdt),
    .rdld(rdld),
    .wrt(wrt));
    
endmodule