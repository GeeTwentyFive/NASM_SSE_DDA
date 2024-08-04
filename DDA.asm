; xmm0 == x1
; xmm1 == y1
; xmm2 == x2
; xmm3 == y2
draw_line:
	sub rsp, 0x40
	movups [rsp], xmm9
	movups [rsp+0x10], xmm8
	movups [rsp+0x20], xmm7
	movups [rsp+0x30], xmm6

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

.loop_draw_line:
	movaps xmm8, xmm0 ; x1_2 -> xmm8
	mulss xmm8, xmm7 ; x = x1_2 * 4.0 f32

	cvtsi2ss xmm9, [PIXELS_PER_SCAN_LINE]
	mulss xmm9, xmm1 ; y = PIXELS_PER_SCAN_LINE f32 * y1
	mulss xmm9, xmm7 ; y = y * 4.0 f32

	addss xmm8, xmm9 ; xy = x + y

	cvttss2si eax, xmm8 ; int(xy) -> eax
	mov ecx, [FRAMEBUFFER_BASE_PTR]
	mov dword [abs ecx+eax], FG_COLOR_ARGB

	addss xmm0, xmm2 ; x1 = x1 + dx
	addss xmm1, xmm3 ; y1 = y1 + dy

	subss xmm6, xmm5 ; step = step - 1.0 f32
	comiss xmm6, xmm4 ; cmp step, 0
	jnb .loop_draw_line



	movups xmm6, [rsp+0x30]
	movups xmm7, [rsp+0x20]
	movups xmm8, [rsp+0x10]
	movups xmm9, [rsp]
	add rsp, 0x40
	ret
