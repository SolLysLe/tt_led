# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, Timer
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
    # Sử dụng thao tác bit an toàn cho ui_in
    def set_sdi(val):
        current_ui = int(dut.ui_in.value)
        if val:
            dut.ui_in.value = current_ui | (1 << 1)
        else:
            dut.ui_in.value = current_ui & ~(1 << 1)

    set_sdi(data[0])

    sck = Clock(SCK, SPI_PERIOD, unit="us")
    sck_gen = cocotb.start_soon(sck.start())
    for i in range(1, 24):
        await FallingEdge(SCK)
        set_sdi(data[i])

    await FallingEdge(SCK)

    sck_gen.kill()
    SCK.value = 0

    await Timer(SPI_PERIOD / 2, unit="us")


async def simulate_frame_input(dut, data):
    """
    Given a pixel's worth of data, simulate a frame transmission (64 sequential SPI transmissions)
    """
    # Hàm hỗ trợ set CS (ui_in[2])
    def set_cs(val):
        current_ui = int(dut.ui_in.value)
        if val:
            dut.ui_in.value = current_ui | (1 << 2)
        else:
            dut.ui_in.value = current_ui & ~(1 << 2)

    for i in range(0, 64):
        set_cs(0) # Sửa lỗi dut.value = 0 thành hạ CS xuống 0
        await simulate_spi_frame(dut, data)
        set_cs(1) # Sửa lỗi dut..value = 1 thành nâng CS lên 1
        await Timer(SPI_PERIOD, unit="us")


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
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

    # Khởi tạo CS ban đầu (ui_in[2] = 1)
    dut.ui_in.value = int(dut.ui_in.value) | (1 << 2)

    clock = Clock(dut.clk, CLOCK_PERIOD, unit="us")
    cocotb.start_soon(clock.start())

    await Timer(500, unit="us")
    await reset(dut)
    await Timer(500, unit="us")

    data = [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0]

    await simulate_frame_input(dut, data)

    await Timer(500, unit="us")

    data = [0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1]
    await simulate_frame_input(dut, data)

    await Timer(500, unit="us")

    await ClockCycles(dut.clk, 1000)
