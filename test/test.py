# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.utils import get_sim_time
import math

CLOCK_FREQUENCY = 12  # MHz
CLOCK_PERIOD = round(1 / CLOCK_FREQUENCY, int(-1 * math.log10(1e-4)))
SPI_FREQUENCY = 1  # MHz
SPI_PERIOD = round(1 / SPI_FREQUENCY, int(-1 * math.log10(1e-4)))


async def reset(dut):
    RESET = dut.rst_n
    RESET.value = 0
    await ClockCycles(dut.clk, 500)
    RESET.value = 1


async def simulate_spi_frame(dut, data):
    """
    Simulate a 24 bit SPI transmission
    """
    SCK = dut.SCK
    SDI = dut.ui_in[1]

    SDI.value = data[0]

    sck = Clock(SCK, SPI_PERIOD, units="us")
    sck_gen = cocotb.start_soon(sck.start())
    for i in range(1, 24):
        await FallingEdge(SCK)
        SDI.value = data[i]

    await FallingEdge(SCK)

    sck_gen.kill()
    SCK.value = 0

    await Timer(SPI_PERIOD / 2, units="us")


async def simulate_frame_input(dut, data):
    """
    Given a pixel's worth of data, simulate a frame transmission (64 sequential SPI transmissions)
    """
    CS = dut.ui_in[2]
    for i in range(0, 64):
        dut..value = 0
        await simulate_spi_frame(dut, data)
        dut..value = 1
        await Timer(SPI_PERIOD, units="us")


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    clock_gen = cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    clock_gen.kill()

    dut._log.info("Test project behavior")

    # Set the input values you want to test
    CLK = dut.clk
    CS.value = 1
    ui_in_val = dut.ui_in.value
    CS = ui_in_val[2]
    CS.value = 1

    clock = Clock(CLK, CLOCK_PERIOD, units="us")
    cocotb.start_soon(clock.start())

    await Timer(500, units="us")
    await reset(dut)
    await Timer(500, units="us")

    data = [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0]

    await simulate_frame_input(dut, data)

    await Timer(500, units="us")

    data = [0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1]
    await simulate_frame_input(dut, data)

    await Timer(500, units="us")

    await ClockCycles(dut.clk, 1000)
