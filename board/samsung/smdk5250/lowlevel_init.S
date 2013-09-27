/*
 * Lowlevel setup for SMDK5250 board based on S5PC520
 *
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

#include <config.h>
#include <version.h>
#include <asm/arch/cpu.h>

_TEXT_BASE:
	.word	CONFIG_SYS_TEXT_BASE

	.globl lowlevel_init
lowlevel_init:

#ifdef CONFIG_SPL_BUILD
	/* check if we're the first cpu or not */
	mrc	p15, 0, r0, c0, c0, 5	/* MPIDR */
	and	r0, r0, #15
	cmp	r0, #0
	beq	first_cpu

	/* Secondary CPU */
	bl	arch_timer_init
	bl	non_secure_init
	bl	monitor_init
	bl	enter_ns
	bl	enter_hyp
	b	enter_smp_pen

	/*
	 * We entered the SMP pen above, and we expect kernels to write an
	 * address into the ALIVE SFR SYSFLAGS register thingy at 0x02020000
	 * which should not be here, but some kernel secondary entry point.
	 */
#endif

first_cpu:
	/* use iRAM stack in bl2 */
	ldr	sp, =CONFIG_IRAM_STACK
	stmdb	r13!, {ip,lr}

	/* check reset status */
	ldr	r0, =(EXYNOS5_POWER_BASE + INFORM1_OFFSET)
	ldr	r1, [r0]

	/* AFTR wakeup reset */
	ldr	r2, =S5P_CHECK_DIDLE
	cmp	r1, r2
	beq	exit_wakeup

	/* LPA wakeup reset */
	ldr	r2, =S5P_CHECK_LPA
	cmp	r1, r2
	beq	exit_wakeup

	/* Sleep wakeup reset */
	ldr	r2, =S5P_CHECK_SLEEP
	cmp	r1, r2
	beq	wakeup_reset

	/* Init architected timers */
	bl	arch_timer_init

	/* Non-secure-init */
	bl	non_secure_init

	/*PS-Hold High*/
	ldr r0, =0x1004330c
	ldr r1, [r0]
	orr r1, r1, #0x100
	str r1, [r0] 
	/*
	 * If U-boot is already running in RAM, no need to relocate U-Boot.
	 * Memory controller must be configured before relocating U-Boot
	 * in ram.
	 */
	ldr	r0, =0x0ffffff		/* r0 <- Mask Bits*/
	bic	r1, pc, r0		/* pc <- current addr of code */
					/* r1 <- unmasked bits of pc */
	ldr	r2, _TEXT_BASE		/* r2 <- original base addr in ram */
	bic	r2, r2, r0		/* r2 <- unmasked bits of r2*/
	cmp	r1, r2			/* compare r1, r2 */
	beq	1f			/* r0 == r1 then skip sdram init */

	bl      read_om

	/* init system clock */
	bl	system_clock_init

	/* Memory initialize */
	bl	mem_ctrl_init

1:
	bl	tzpc_init
#ifdef CONFIG_SPL_BUILD
	bl	smp_kick_secondary	/* Bring other CPU1 into smp pen */
#else
	bl	monitor_init		/* Setup monitor mode */
#endif
	ldmia	r13!, {ip,pc}

wakeup_reset:
	bl	system_clock_init
	bl	mem_ctrl_init
	bl	tzpc_init

exit_wakeup:
	/* Load return address and jump to kernel */
	ldr	r0, =(EXYNOS5_POWER_BASE + INFORM0_OFFSET)

	/* r1 = physical address of exynos5_cpu_resume function*/
	ldr	r1, [r0]

	/* Jump to kernel */
	mov	pc, r1
	nop
	nop

read_om:
       /* Read booting information */
       ldr     r0, =EXYNOS5_POWER_BASE
       ldr     r1, [r0,#0x0]           /*OMR_OFFSET*/
       bic     r2, r1, #0xffffffc1

       /* SD/MMC BOOT */
       cmp     r2, #0x4
       moveq   r3, #BOOT_MMCSD

       /* eMMC 4.4 BOOT */
       cmp     r2, #0x8
       moveq   r3, #BOOT_EMMC_4_4
       cmp     r2, #0x28
       moveq   r3, #BOOT_EMMC_4_4

       ldr     r0, =(EXYNOS5_POWER_BASE + INFORM3_OFFSET)
       str     r3, [r0]

       mov     pc, lr
