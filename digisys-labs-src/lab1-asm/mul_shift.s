        .syntax unified
        .global func
        .text
        .thumb_func

@ r0 = x, r1 = y, r2 = accumulator
func:
        movs r2, #0             @ r2 = 0

loop:        
        cmp r1, #0              @ if r1 == 0, go to done
        beq done
        lsrs r1, r1, #1         @ r1 = r1 >> 1 (/2)
        bcc skip                @ if even (carry = 0) skip, odd (carry = 1) add
        adds r2, r2, r0         @ r2 = r2 + r0

skip:
        lsls r0, r0, #1         @ r0 = r0 << 1 (*2)
        b loop                  @ go to loop

done:
        movs r0, r2             @ r0 = r2
        bx lr                   @ return