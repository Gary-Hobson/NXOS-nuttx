/****************************************************************************
 * boards/risc-v/espressif/common/scripts/esp32c3_flat_memory.ld
 *
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.  The
 * ASF licenses this file to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance with the
 * License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
 * License for the specific language governing permissions and limitations
 * under the License.
 *
 ****************************************************************************/

/****************************************************************************
 * ESP32-C3 Linker Script Memory Layout
 *
 * This file describes the memory layout (memory blocks) as virtual
 * memory addresses.
 *
 * esp32c3_<legacy/mcuboot>_sections.ld contains output sections to link compiler
 * output into these memory blocks.
 *
 ****************************************************************************/

#include <nuttx/config.h>

#define SRAM_IRAM_START     0x4037c000
#define SRAM_DRAM_START     0x3fc7c000

/* ICache size is fixed to 16KB on ESP32-C3 */

#define ICACHE_SIZE         0x4000
#define I_D_SRAM_OFFSET     (SRAM_IRAM_START - SRAM_DRAM_START)

/* 2nd stage bootloader iram_loader_seg start address */

#define SRAM_DRAM_END       (0x403ce710 - I_D_SRAM_OFFSET)

#define SRAM_IRAM_ORG       (SRAM_IRAM_START + ICACHE_SIZE)
#define SRAM_DRAM_ORG       (SRAM_DRAM_START + ICACHE_SIZE)

#define I_D_SRAM_SIZE       (SRAM_DRAM_END - SRAM_DRAM_ORG)

MEMORY
{
  /* Below values assume the flash cache is on, and have the blocks this
   * uses subtracted from the length of the various regions. The 'data access
   * port' dram/drom regions map to the same iram/irom regions but are
   * connected to the data port of the CPU and e.g. allow bytewise access.
   */

  iram0_0_seg (RX) :      org = SRAM_IRAM_ORG, len = I_D_SRAM_SIZE

  /* Flash mapped instruction data.
   *
   * The 0x20 offset is a convenience for the app binary image generation.
   * Flash cache has 64KB pages. The .bin file which is flashed to the chip
   * has a 0x18 byte file header, and each segment has a 0x08 byte segment
   * header. Setting this offset makes it simple to meet the flash cache MMU's
   * constraint that (paddr % 64KB == vaddr % 64KB).
   */

  irom0_0_seg (RX) :      org = 0x42000020, len = 0x800000 - 0x20

  /* Shared data RAM, excluding memory reserved for ROM bss/data/stack. */

  dram0_0_seg (RW) :      org = SRAM_DRAM_ORG, len = I_D_SRAM_SIZE

  /* Flash mapped constant data.
   *
   * The 0x20 offset is a convenience for the app binary image generation.
   * Flash cache has 64KB pages. The .bin file which is flashed to the chip
   * has a 0x18 byte file header, and each segment has a 0x08 byte segment
   * header. Setting this offset makes it simple to meet the flash cache MMU's
   * constraint that (paddr % 64KB == vaddr % 64KB).
   */

  drom0_0_seg (R) :      org = 0x3c000020, len = 0x800000 - 0x20

  /* RTC fast memory. Persists over deep sleep. */

  rtc_seg(RWX) :          org = 0x50000000, len = 0x2000
}

#if CONFIG_ESPRESSIF_RUN_IRAM
  REGION_ALIAS("default_rodata_seg", dram0_0_seg);
  REGION_ALIAS("default_code_seg", iram0_0_seg);
#else
  REGION_ALIAS("default_rodata_seg", drom0_0_seg);
  REGION_ALIAS("default_code_seg", irom0_0_seg);
#endif /* CONFIG_ESPRESSIF_RUN_IRAM */

/* Mark the end of the RTC heap (top of the RTC region) */

_ertcheap = 0x50001fff;
