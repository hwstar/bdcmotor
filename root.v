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
 ********************* REGISTER MAP ************************************
 * 
 * ******** Motor channel registers ********
 *
 * There are 3 sets of motor channel registers:
 *
 * Channel 0 has addresses 0,1, and 2
 * Channel 1 has addresses 4,5, and 6
 * Channel 2 has addresses 8,9 and a
 *
 *
 *** Address 0,4,8	:	Tach Low Byte (R), PWM Register (W) ***
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
 *** Address 1,5,9	:	Tach High Byte(R) ***
 *
 * Most significant byte of tach register. This has to be latched by
 * reading the low byte first.
 *
 *
 *** Address 2,6,a	:	Motor Config Register (W) ***
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
 ******** Control Registers *********
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
 * Bit 5	:	Reserved, reads back as 0
 * Bit 4	:	Reserved, reads back as 0
 * Bit 3	:	Master Motor Enable
 * Bit 2	:	Run2/~Brake2
 * Bit 1	:	Run1/~Brake1
 * Bit 0	:	Run0/~Brake0
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
 * 4. Runx/~Brakex
 *
 * When these bits are high, the motor is in run mode and will respond
 * to pwm commands if the master motor enable is also set. If these
 * bits get set to 0, then the motor dynamic brake circuit will be
 * activated.
 */

/*
* Top level with all I/O polarities adjusted, and tristate outputs added
*/ 
`default_nettype none
 
module root(
	 input clk,
	 input sclk,
	 input ss,
	 input mosi,
	 input tstn,
	 input wdogdisn,
	 input currentlimit0,
	 input currentlimit1,
	 input currentlimit2,
	 input [1:0] tach0,
	 input [1:0] tach1,
	 input [1:0] tach2,
	 output miso,
	 output motorena,
	 output ledaliven,
	 output redled0,
	 output redled1,
	 output redled2,
	 output redled3,
	 output [1:0] pwm0,
	 output [1:0] pwm1,
	 output [1:0] pwm2);
	
	wire misoi;
	wire ledalive;
	wire spioe;
	wire tst;
	wire wdogdis;
	reg misoreg;
	reg redledreg0;
	reg redledreg1;
	reg redledreg2;
	reg redledreg3;
	
	initial redledreg3 = 0;
	initial redledreg2 = 0;
	initial redledreg1 = 0;
	initial redledreg0 = 0;

	system sys0(
    .clk(clk),
    .sclk(sclk),
    .ss(ss),
    .mosi(mosi),
    .spioe(spioe),
    .tst(tst),
    .wdogdis(wdogdis),
    .currentlimit0(currentlimit0),
    .currentlimit1(currentlimit1),
    .currentlimit2(currentlimit2),
    .tach0(tach0),
    .tach1(tach1),
    .tach2(tach2),
    .miso(misoi),
    .motorena(motorena),
    .ledalive(ledalive),
    .pwm0(pwm0),
    .pwm1(pwm1),
    .pwm2(pwm2));
 

	
	assign miso = misoreg;
	assign tst = ~tstn;
	assign wdogdis = ~wdogdisn;
	assign ledaliven = ~ledalive;
	assign redled0 = redledreg0;
	assign redled1 = redledreg1;
	assign redled2 = redledreg2;
	assign redled3 = redledreg3;

	always @(*) begin
		if(spioe)
			misoreg <= misoi;
		else
			misoreg <= 1'bz;
			

	end
endmodule
