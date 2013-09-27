/*
 *
 * Copyright (c) 2012	Christoffer Dall <c.dall@virtualopensystems.com>
 * 					 <cdall@cs.columbia.edu>
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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 */

#include <config.h>

__smp_pen:
	wfe
	ldr	r1, [r0]
	mov	pc, r1

	.globl enter_smp_pen
enter_smp_pen:
	adr	r1, __smp_pen
	ldmia	r1, {r4, r5, r6}
	ldr	r2, =CONFIG_SPL_SMP_PEN
	stmia	r2, {r4, r5, r6}

	/*
	 * Store SMP pen into SYSFLAGS so the processor stays in the loop if
	 * it gets a spurious interrupt
	 */
	ldr	r0, =CONFIG_SYSFLAGS_ADDR
	str	r2, [r0]

	/*
	 * Make instruction copy coherent
	 */
	mcr	p15, 0, r2, c7, c11, 1 /* Clean the data cache by MVA*/
	mov	r10, #0
	mcr	p15, 0, r10, c7, c5, 0 /* Invalidate the I-cache */
	isb	/* Make sure the invalidate ops are complete */
	dsb

	mov	pc, r2

	.globl smp_kick_secondary
smp_kick_secondary:
	/* Bring up the secondary CPU */
	ldr	r0, =CONFIG_SYSFLAGS_ADDR
	ldr	r1, =CONFIG_SPL_TEXT_BASE
	str	r1, [r0]
	dsb
	ldr	r0, =(EXYNOS5_GIC_DIST_BASE + 0xf00) /* GICD_SGIR */
	ldr	r1, =(2 << 16)		/* Bring up CPU 1*/
	str	r1, [r0]
	dsb

	mov	pc, lr
