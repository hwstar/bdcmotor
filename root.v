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
 */

/*
* Top level with all I/O polarities adjusted, pullups and tristate outputs added
*/ 
 
 
module root(
	 input clk,
	 input sclk,
	 input ss,
	 input mosi,
	 input tstn,
	 input wdogdisn,
	 input currentlimit,
	 input [1:0] tach,
	 output miso,
	 output motorena,
	 output [1:0] pwm);
	
	wire misoi;
	reg misoreg;

	system sys0(
    .clk(clk),
    .sclk(sclk),
    .ss(ss),
    .mosi(mosi),
    .spioe(spioe),
    .tst(tst),
    .wdogdis(wdogdis),
    .currentlimit(currentlimit),
    .tach(tach),
    .miso(misoi),
    .motorena(motorena),
    .pwm(pwm));
 
	
	assign miso = misoreg;
	assign tst = ~tstn;
	assign wdogdis = ~wdogdis;
	

	always @(*) begin
		if(spioe)
			misoreg <= misoi;
		else
			misoreg <= 1'bz;
			

	end
endmodule
