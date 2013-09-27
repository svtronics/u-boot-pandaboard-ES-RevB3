/*
 * Copyright (C) 2012 Samsung Electronics
 *
 * See file CREDITS for list of people who contributed to this
 * project.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 */

#include<common.h>
#include<config.h>

/*
* Copy U-boot from mmc to RAM:
* COPY_BL2_FNPTR_ADDR: Address in iRAM, which Contains
* Pointer to API (Data transfer from mmc to ram)
*/
void copy_uboot_to_ram(void)
{
	u32 (*copy_bl2_from_mmc)(u32, u32, u32) = (void *) *(u32 *)COPY_BL2_FNPTR_ADDR;
	u32 (*copy_bl2_from_emmc)(u32, u32) = (void *) *(u32 *)COPY_BL2_FNPTR_ADDR_EMMC;
	u32 (*copy_bl2_from_emmc_done)() = (void *) *(u32 *)COPY_BL2_FNPTR_ADDR_EMMC_DONE;

	u32 inform3 = readl(EXYNOS5_POWER_BASE + INFORM3_OFFSET);

	if (inform3 == BOOT_MMCSD)
		copy_bl2_from_mmc(BL2_START_OFFSET, BL2_SIZE_BLOC_COUNT, CONFIG_SYS_TEXT_BASE);
	else if (inform3 == BOOT_EMMC_4_4) {
		copy_bl2_from_emmc(BL2_SIZE_BLOC_COUNT, CONFIG_SYS_TEXT_BASE);
		copy_bl2_from_emmc_done();
	}
}

void board_init_f(unsigned long bootflag)
{
	__attribute__((noreturn)) void (*uboot)(void);
	copy_uboot_to_ram();

	/* Jump to U-Boot image */
	uboot = (void *)CONFIG_SYS_TEXT_BASE;
	(*uboot)();
	/* Never returns Here */
}

/* Place Holders */
void board_init_r(gd_t *id, ulong dest_addr)
{
	/* Function attribute is no-return */
	/* This Function never executes */
	while (1)
		;
}

void save_boot_params(u32 r0, u32 r1, u32 r2, u32 r3) {}
