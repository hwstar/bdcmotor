module negedgedet(
  input clk,
  input in,
  output out);
  
  reg outreg;
  reg [3:0] sr = 4'b0000;
  
  assign out = outreg;
  
  always @(*) begin
    outreg = 0;
    if((sr[2] == 0) && (sr[3] == 1))
      outreg = 1;
  end
  
  always @(posedge clk) begin
    sr[3] <= sr[2];
    sr[2] <= sr[1];
    sr[1] <= sr[0];
    sr[0] <= in;
  end
endmodule

// This module synchronizes the read transaction output from the spi module
// and generates a clock enable to latch the upper byte of the tach counter
// so that a future read can get a stable value

module freezer(
  input clk,
  input countlread,
  output freeze,
  output highce);
  
  reg highcereg;
  reg [4:0] sr = 5'b00000;
  
  assign highce = highcereg;
  assign freeze = sr[2];
  
  always @(*) begin
    highcereg = 0;
    if((sr[3] == 1) && (sr[4] == 0))
      highcereg = 1;
  end
  
  always @(posedge clk) begin
    sr[4] <= sr[3];
    sr[3] <= sr[2];
    sr[2] <= sr[1];
    sr[1] <= sr[0];
    sr[0] <= countlread;
  end
endmodule


// Address decoder

module decoder(
  input we,
  input rdt,
  input [3:0] addr,
  input [7:0] countl,
  input [7:0] counthfrozen,
  output [7:0] rddata,
  output countlread,
  output pwmld,
  output cfgld,
  output ctrlld);
  
  reg regdecr0 = 0;
  reg regdecw0 = 0;
  reg regdecw2 = 0;
  reg regdecw3 = 0;
  reg [7:0] rddatareg;
  
  assign countlread = regdecr0;
  assign pwmld = regdecw0;
  assign cfgld = regdecw2;
  assign ctrlld = regdecw3;
  
  assign rddata = rddatareg;
  
  always @(*) begin
    // Default outputs
    rddatareg <= 8'h00;
    regdecr0 <= 0;
    regdecw0 <= 0;
    regdecw2 <= 0;
    regdecw3 <= 0;
    case(addr)
      // Tach low byte and PWM
      4'h0: begin
        rddatareg <= countl;
        regdecw0 <= we;
        regdecr0 <= rdt;
      end
      // Tach high byte
      4'h1: begin
        rddatareg <= counthfrozen;
      end
      
      // Unimplemented decodes
      4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7,
      4'h8, 4'h9, 4'ha, 4'hb, 4'hc, 4'hd: begin
        rddatareg <= 8'h00;
      end
      
      // Configuration
      4'he:
        regdecw2 <= we;
      
      // Control
      4'hf:
        regdecw3 <= we;
      
      // BoGuS
      default: begin
        rddatareg <= 8'bxxxxxxxx;
        regdecr0 <= 1'bx;
        regdecw0 <= 1'bx;
        regdecw2 <= 1'bx;
        regdecw3 <= 1'bx;
      end
    
    endcase
  end
endmodule


// 8 bit register

module reg8(
  input clk,
  input ce,
  input [7:0] in,
  output [7:0] out);
  
  reg [8:0] register = 8'h00;
  
  assign out = register;
  
  always @(posedge clk) begin
    if(ce) begin
      register = in;
    end
  end
endmodule
  

module system(
  output miso, // Data to master (MISO)
  output [1:0] pwm, // motor pwm
  output motorena, // motor enable
  input clk, // System clock
  input ss, // SPI enable (SS)
  input sclk, // SPI clock (SCLK)
  input mosi, // Data from master (MOSI)
  input currentlimit, // Current limit detect input
  input [1:0] tach); // Tachometer phases
  
  
  
  
  wire rdt;
  wire wrt;
  wire we;
  wire spioe;
  wire countlread;
  wire freeze;
  wire highce;
  wire pwmld;
  wire cfgld;
  wire ctrlld;
  wire [3:0] addr;
  wire [7:0] wrtdata;
  wire [7:0] rddata;
  wire [7:0] counthfrozen;
  wire [7:0] countl;
  wire [7:0] counth;
  
 
  // Place keepers
  reg motorenareg = 1;
  reg filterce = 1;
  reg invphase = 0;
  reg invertpwm = 0;
  reg pwmcntce = 1;
  
 
  assign motorena = motorenareg;
  
  
  negedgedet ned0(
    .clk(clk),
    .in(wrt),
    .out(we));
  
  decoder dec0(
    .we(we),
    .rdt(rdt),
    .addr(addr),
    .countl(countl),
    .counthfrozen(counthfrozen),
    .rddata(rddata),
    .countlread(countlread),
    .pwmld(pwmld),
    .cfgld(cfgld),
    .ctrlld(ctrlld));
    
  
  freezer frz0(
    .clk(clk),
    .countlread(countlread),
    .freeze(freeze),
    .highce(highce));
  
  reg8 counthrreg(
    .clk(clk),
    .ce(highce),
    .in(counth),
    .out(counthfrozen));
  
  bdcmotorchannel bdcm0(
    .clk(clk),
    .filterce(filterce),
    .invphase(invphase),
    .freeze(freeze),
    .pwmcntce(pwmcntce),
    .pwmldce(pwmld),
    .invertpwm(invertpwm),
    .enablepwm(motorenareg),
    .currentlimit(currentlimit),
    .tach(tach),
    .wrtdata(wrtdata),
    .countl(countl),
    .counth(counth),
    .pwmout(pwm));
  
   
  spi spi0(
    .spidout(miso),
    .spiclk(sclk),
    .rdt(rdt),
    .wrt(wrt),
    .spioe(spioe),
    .wrtdata(wrtdata),
    .addr(addr),
    .spien(ss),
    .spidin(mosi),
    .rddata(rddata));
endmodule

  
  
  
  
  
  


    
    
    
  
  
	