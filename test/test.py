# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 40 ns (25 MHz ~ VGA pixel clock)
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Run")

    # Wait for one clock cycle to see the output values
    # await ClockCycles(dut.clk, 128)
    # await ClockCycles(dut.clk, 800*16)
    # await ClockCycles(dut.clk, 800*64*2)
    # await ClockCycles(dut.clk, 800*525*3)
    await ClockCycles(dut.clk, 800*525*10)
