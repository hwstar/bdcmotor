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
 *
 *****  REGISTER MAP *****
 * 
 *
 *** Address 0	:	Tach Low Byte (R), PWM Register (W) ***
 *
 * Read
 * 
 * Least significant byte of tach register. Reading automatically
 * latches the high byte for future access.
 *
 * Write
 *
 * PWM value. 8'h80 corresponds to a 50% duty cycle. The motor would
 * be off in this case. 8'h80 is the default at power on.
 *
 *** Address 1	:	Tach High Byte(R) ***
 *
 * Most significant byte of tach register. This has to be latched by
 * reading the low byte first.
 *
 *
 *** Address 2	:	Motor Config Register (W) ***
 *
 * Bit 7	:	Reserved set to 0
 * Bit 6	:	Reserved set to 0 
 * Bit 5	:	invert tach	
 * Bit 4	:	invert pwm
 * Bit 3    :   Tach filter divisor msb
 * Bit 2    :   Tach filter divisor lsb
 * Bit 1	:	PWM clock divisor msb
 * Bit 0	:	PWM clock divisor lsb
 *
 * Tach filter bits. number of 64 cycle system clock periods to use for
 * the tach filter
 *
 *	00 - Multiply by 1
 *  01 - Multiply by 2
 *  10 - Multiply by 4
 *  11 - Multiply by 8
 *	
 * PWM Generator clock divisor bits. Number of system clock periods
 * to use for one increment of the PWM counter
 *
 *	00 - Multiply by 1
 *  01 - Multiply by 2
 *  10 - Multiply by 4
 *  11 - Multiply by 8
 * 
 *
 *** Address d	:	Hardware Config Register (R) ***
 *
 * Bits 7,6	:	Reserved, set to 0.
 * Bits 5,4	:	Number of motor channels supported
 * Bits 3-0 :	FPGA code level.
 *
 *
 *** Address e  :   Watchdog divisor (W) ***
 *
 * Programs the watchdog trip time in counts of 16384 system clocks.
 * This register must be written when motor enable is false. All 
 * writes to this register will be ignored when motor enable is true.
 *
 * 
 *** Address f  :	Control Register (R/W) ***
 *
 * Bit 7	:	Watchdog tripped
 * Bit 6	:	Watchdog disabled
 * Bit 5	:	Reserved
 * Bit 4	:	Reserved
 * Bit 3	:	Motor Enable
 * Bit 2	:	Reserved
 * Bit 1	:	Reserved
 * Bit 0	:	Reserved
 *
 * 1. The watchdog timer is reset when this register is read.
 *
 * 2. The watchdog timer is enabled whenever the motor is enabled,
 *    and the wdogdisn pin is high. If the watchdog timer is enabled,
 *    the control register must be read periodically so that the
 *    watchdog does not trip.
 *
 * 3. If the watchdog is tripped, motor enable will be masked
 *    even though it is set true. To reset the watchdog, write a
 *    8'h80 to the port, then re-enable the motor by setting bit 3.
 *    A watchdog trip event is noted by bit 7 being set high.
 *
 */

/*
* Top level with all I/O polarities adjusted, and tristate outputs added
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
