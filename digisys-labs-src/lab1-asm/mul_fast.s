        .syntax unified
        .global func
        .text
        .thumb_func
func:
        muls r0, r1             @ r0 = r0 * r1
        bx lr                   @ Return