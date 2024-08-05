; xmm0 == x1 (rounded to whole number)
; xmm1 == y1 (rounded to whole number)
; xmm2 == x2 (rounded to whole number)
; xmm3 == y2 (rounded to whole number)
draw_line:
	sub rsp, 0x50
	movups [rsp], xmm10
	movups [rsp+0x10], xmm9
	movups [rsp+0x20], xmm8
	movups [rsp+0x30], xmm7
	movups [rsp+0x40], xmm6

	subss xmm2, xmm0 ; dx1 = x2 - x1
	subss xmm3, xmm1 ; dy1 = y2 - y1

	pcmpeqd xmm4, xmm4 ; xmm4 = 1111...
	psrld xmm4, 1 ; xmm4 = 0111...

	movaps xmm5, xmm2 ; dx2 -> xmm5
	andps xmm5, xmm4 ; abs_dx = dx2 AND 0111...
	andps xmm4, xmm3 ; abs_dy = 0111... AND dy1

	movaps xmm6, xmm4 ; abs_dy_2 -> xmm6
	cmpss xmm6, xmm5, 2 ; cmp = abs_dy_2 <= abs_dx ?

	andps xmm5, xmm6 ; abs_dx AND cmp
	andnps xmm6, xmm4 ; cmp NAND abs_dy
	orps xmm6, xmm5 ; step = (abs_dx AND cmp) OR (abs_dy NAND cmp)

	divss xmm2, xmm6 ; dx = dx / step
	divss xmm3, xmm6 ; dy = dy / step



	pxor xmm4, xmm4 ; xmm4 = 0

	pcmpeqw xmm5, xmm5
	pslld xmm5, 25
	psrld xmm5, 2 ; xmm5 = 1.0 f32

	mov eax, __float32__(4.0)
	movd xmm7, eax ; xmm7 = 4.0 f32

	cvtsi2ss xmm8, [PIXELS_PER_SCAN_LINE]

	mov rcx, [FRAMEBUFFER_BASE_PTR]

.loop_draw_line:
	movaps xmm9, xmm0 ; x1_2 -> xmm9
	mulss xmm9, xmm7 ; x = x1_2 * 4.0 f32

	movaps xmm10, xmm1 ; y1_2 -> xmm10
	mulss xmm10, xmm8 ; y = PIXELS_PER_SCAN_LINE f32 * y1
	mulss xmm10, xmm7 ; y = y * 4.0 f32

	addss xmm9, xmm10 ; xy = x + y

	cvttss2si eax, xmm9 ; int(xy) -> eax
	mov dword [abs rcx+rax], FG_COLOR_ARGB

	addss xmm0, xmm2 ; x1 = x1 + dx
	addss xmm1, xmm3 ; y1 = y1 + dy

	subss xmm6, xmm5 ; step = step - 1.0 f32
	comiss xmm6, xmm4 ; cmp step, 0
	jnb .loop_draw_line



	movups xmm6, [rsp+0x40]
	movups xmm7, [rsp+0x30]
	movups xmm8, [rsp+0x20]
	movups xmm9, [rsp+0x10]
	movups xmm10, [rsp]
	add rsp, 0x50
	ret

