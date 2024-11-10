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
    with open(filename, "a") as file:
        file.write(line_to_append)

def append_assert_to_file(filename, dut, value_name, gl_value_name=False, type="b"):
    if eval(f"{value_name}.value.is_resolvable"):
        if not gl_value_name:
            gl_value_name = value_name
        if type == "h" or type == "hex":
            value = eval(f"{value_name}.value.integer")
            line_to_append = f"    assert({gl_value_name}.value.integer == {hex(value)})\n"
        else:
            value = eval(f"{value_name}.value.binstr")
            line_to_append = f"    assert({gl_value_name}.value == 0b{value})\n"
        with open(filename, "a") as file:
            file.write(line_to_append)

RECORDED_TEST_FILENAME = "zealot.py"

@cocotb.test()
async def record_project(dut):
    create_and_write_header(RECORDED_TEST_FILENAME)

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

    cycles_per_step = 16
    # for cycle in range((800)//cycles_per_step):
    # for cycle in range((800*40)//cycles_per_step):
    # for cycle in range((800*64)//cycles_per_step):
    # for cycle in range((800*525*2)//cycles_per_step):
    for cycle in range((800*525*3)//cycles_per_step):
        await ClockCycles(dut.clk, cycles_per_step)
        append_to_file(RECORDED_TEST_FILENAME, f"await ClockCycles(dut.clk, {cycles_per_step})")
        append_assert_to_file(RECORDED_TEST_FILENAME, dut, "dut.uo_out")
        append_assert_to_file(RECORDED_TEST_FILENAME, dut, "dut.user_project.atari2600.cpu.PC", "dut.PC", "hex")
        # print (hex())
