# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

def create_and_write_header(filename):
    content = '''import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def validate(dut):
    dut._log.info("Start")

    F = 1 # clock frequency multiplier
    
    # Set the clock period to 40 ns (25 MHz ~ VGA pixel clock)
    clock = Clock(dut.clk, 40//F, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0 # 2 for built-in ROM
    dut.uio_in.value = 0
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2*F)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10*F)
    dut.rst_n.value = 1
    dut.ui_in.value = 0

    dut._log.info("Start")\n'''
    # Create and write to zealot.py
    with open(filename, "w") as file:
        file.write(content)

def append_to_file(filename, value):
    line_to_append = f"    {value}\n"
    with open("zealot.py", "a") as file:
        file.write(line_to_append)

def append_assert_to_file(filename, value):
    line_to_append = f"    assert(dut.uo_out.value == 0b{value})\n"    
    with open("zealot.py", "a") as file:
        file.write(line_to_append)

@cocotb.test()
async def record_project(dut):
    create_and_write_header("zealot.py")

    dut._log.info("Start")

    F = 1 # clock frequency multiplier
    
    # Set the clock period to 40 ns (25 MHz ~ VGA pixel clock)
    clock = Clock(dut.clk, 40//F, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0 # 2 for built-in ROM
    dut.uio_in.value = 0
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2*F)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10*F)
    dut.rst_n.value = 1
    dut.ui_in.value = 0

    dut._log.info("Record")

    for cycle in range(400):
        await ClockCycles(dut.clk, 16)
        append_to_file("zealot.py", "await ClockCycles(dut.clk, 16)")
        if dut.uo_out.value.is_resolvable:
            append_assert_to_file("zealot.py", dut.uo_out.value.binstr)
