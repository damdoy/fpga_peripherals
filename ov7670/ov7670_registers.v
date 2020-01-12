//registers as defined in the linux kernel driver for ov7670

parameter REG_GAIN = 8'h00;	/* Gain lower 8 bits (rest in vref) */
parameter REG_BLUE = 8'h01;	/* blue gain */
parameter REG_RED =	 8'h02;	/* red gain */
parameter REG_VREF = 8'h03;	/* Pieces of GAIN, VSTART, VSTOP */
parameter REG_COM1 = 8'h04;	/* Control 1 */
parameter  COM1_CCIR656 =   8'h40;  /* CCIR656 enable */
parameter REG_BAVE = 8'h05;	/* U/B Average level */
parameter REG_GbAVE = 8'h06;	/* Y/Gb Average level */
parameter REG_AECHH = 8'h07;	/* AEC MS 5 bits */
parameter REG_RAVE = 8'h08;	/* V/R Average level */
parameter REG_COM2 = 8'h09;	/* Control 2 */
parameter  COM2_SSLEEP =   8'h10;	/* Soft sleep mode */
parameter REG_PID =	 8'h0a;	/* Product ID MSB */
parameter REG_VER =	 8'h0b;	/* Product ID LSB */
parameter REG_COM3 = 8'h0c;	/* Control 3 */
parameter  COM3_SWAP =   8'h40;	  /* Byte swap */
parameter  COM3_SCALEEN =   8'h08;	  /* Enable scaling */
parameter  COM3_DCWEN =   8'h04;	  /* Enable downsamp/crop/window */
parameter REG_COM4 = 8'h0d;	/* Control 4 */
parameter REG_COM5 = 8'h0e;	/* All "reserved" */
parameter REG_COM6 = 8'h0f;	/* Control 6 */
parameter REG_AECH = 8'h10;	/* More bits of AEC value */
parameter REG_CLKRC = 8'h11;	/* Clocl control */
parameter   CLK_EXT =   8'h40;	  /* Use external clock directly */
parameter   CLK_SCALE =   8'h3f;	  /* Mask for internal clock scale */
parameter REG_COM7 = 8'h12;	/* Control 7 */
parameter   COM7_RESET =   8'h80;	  /* Register reset */
parameter   COM7_FMT_MASK =   8'h38;
parameter   COM7_FMT_VGA =   8'h00;
parameter	  COM7_FMT_CIF =   8'h20;	  /* CIF format */
parameter   COM7_FMT_QVGA =   8'h10;	  /* QVGA format */
parameter   COM7_FMT_QCIF =   8'h08;	  /* QCIF format */
parameter	  COM7_RGB =   8'h04;	  /* bits 0 and 2 - RGB format */
parameter	  COM7_YUV =   8'h00;	  /* YUV */
parameter	  COM7_BAYER =   8'h01;	  /* Bayer format */
parameter	  COM7_PBAYER =   8'h05;	  /* "Processed bayer" */
parameter REG_COM8 = 8'h13;	/* Control 8 */
parameter   COM8_FASTAEC =   8'h80;	  /* Enable fast AGC/AEC */
parameter   COM8_AECSTEP =   8'h40;	  /* Unlimited AEC step size */
parameter   COM8_BFILT =   8'h20;	  /* Band filter enable */
parameter   COM8_AGC =   8'h04;	  /* Auto gain enable */
parameter   COM8_AWB =   8'h02;	  /* White balance enable */
parameter   COM8_AEC =   8'h01;	  /* Auto exposure enable */
parameter REG_COM9 = 8'h14;	/* Control 9  - gain ceiling */
parameter REG_COM10 = 8'h15;	/* Control 10 */
parameter   COM10_HSYNC =   8'h40;	  /* HSYNC instead of HREF */
parameter   COM10_PCLK_HB =   8'h20;	  /* Suppress PCLK on horiz blank */
parameter   COM10_HREF_REV =  8'h08;	  /* Reverse HREF */
parameter   COM10_VS_LEAD =   8'h04;	  /* VSYNC on clock leading edge */
parameter   COM10_VS_NEG =   8'h02;	  /* VSYNC negative */
parameter   COM10_HS_NEG =   8'h01;	  /* HSYNC negative */
parameter REG_HSTART = 8'h17;	/* Horiz start high bits */
parameter REG_HSTOP = 8'h18;	/* Horiz stop high bits */
parameter REG_VSTART = 8'h19;	/* Vert start high bits */
parameter REG_VSTOP = 8'h1a;	/* Vert stop high bits */
parameter REG_PSHFT = 8'h1b;	/* Pixel delay after HREF */
parameter REG_MIDH = 8'h1c;	/* Manuf. ID high */
parameter REG_MIDL = 8'h1d;	/* Manuf. ID low */
parameter REG_MVFP = 8'h1e;	/* Mirror / vflip */
parameter   MVFP_MIRROR =   8'h20;	  /* Mirror image */
parameter   MVFP_FLIP =   8'h10;	  /* Vertical flip */

parameter REG_AEW =	 8'h24;	/* AGC upper limit */
parameter REG_AEB =	 8'h25;	/* AGC lower limit */
parameter REG_VPT =	 8'h26;	/* AGC/AEC fast mode op region */
parameter REG_HSYST = 8'h30;	/* HSYNC rising edge delay */
parameter REG_HSYEN = 8'h31;	/* HSYNC falling edge delay */
parameter REG_HREF = 8'h32;	/* HREF pieces */
parameter REG_TSLB = 8'h3a;	/* lots of stuff */
parameter   TSLB_YLAST =   8'h04;	  /* UYVY or VYUY - see com13 */
parameter REG_COM11 = 8'h3b;	/* Control 11 */
parameter   COM11_NIGHT =   8'h80;	  /* NIght mode enable */
parameter   COM11_NMFR =   8'h60;	  /* Two bit NM frame rate */
parameter   COM11_HZAUTO =   8'h10;	  /* Auto detect 50/60 Hz */
parameter	  COM11_50HZ =   8'h08;	  /* Manual 50Hz select */
parameter   COM11_EXP =   8'h02;
parameter REG_COM12 = 8'h3c;	/* Control 12 */
parameter   COM12_HREF =   8'h80;	  /* HREF always */
parameter REG_COM13 = 8'h3d;	/* Control 13 */
parameter   COM13_GAMMA =   8'h80;	  /* Gamma enable */
parameter	  COM13_UVSAT =   8'h40;	  /* UV saturation auto adjustment */
parameter   COM13_UVSWAP =   8'h01;	  /* V before U - w/TSLB */
parameter REG_COM14 = 8'h3e;	/* Control 14 */
parameter   COM14_DCWEN =   8'h10;	  /* DCW/PCLK-scale enable */
parameter REG_EDGE = 8'h3f;	/* Edge enhancement factor */
parameter REG_COM15 = 8'h40;	/* Control 15 */
parameter   COM15_R10F0 =   8'h00;	  /* Data range 10 to F0 */
parameter	  COM15_R01FE =   8'h80;	  /*            01 to FE */
parameter   COM15_R00FF =   8'hc0;	  /*            00 to FF */
parameter   COM15_RGB565 =   8'h10;	  /* RGB565 output */
parameter   COM15_RGB555 =   8'h30;	  /* RGB555 output */
parameter REG_COM16 = 8'h41;	/* Control 16 */
parameter   COM16_AWBGAIN =   8'h08;	  /* AWB gain enable */
parameter REG_COM17 = 8'h42;	/* Control 17 */
parameter   COM17_AECWIN =   8'hc0;	  /* AEC window - must match COM4 */
parameter   COM17_CBAR =   8'h08;	  /* DSP Color bar */

parameter	REG_CMATRIX_BASE = 8'h4f;
parameter   CMATRIX_LEN =6;
parameter REG_CMATRIX_SIGN = 8'h58;


parameter REG_BRIGHT = 8'h55;	/* Brightness */
parameter REG_CONTRAS = 8'h56;	/* Contrast control */

parameter REG_GFIX = 8'h69;	/* Fix gain control */

parameter REG_DBLV = 8'h6b;	/* PLL control an debugging */
parameter   DBLV_BYPASS =   8'h0a;	  /* Bypass PLL */
parameter   DBLV_X4 =   8'h4a;	  /* clock x4 */
parameter   DBLV_X6 =   8'h8a;	  /* clock x6 */
parameter   DBLV_X8 =   8'hca;	  /* clock x8 */

parameter REG_SCALING_XSC = 8'h70;	/* Test pattern and horizontal scale factor */
parameter   TEST_PATTTERN_0 = 8'h80;
parameter REG_SCALING_YSC = 8'h71;	/* Test pattern and vertical scale factor */
parameter   TEST_PATTTERN_1 = 8'h80;

parameter REG_REG76 = 8'h76;	/* OV's name */
parameter   R76_BLKPCOR =   8'h80;	  /* Black pixel correction enable */
parameter   R76_WHTPCOR =   8'h40;	  /* White pixel correction enable */

parameter REG_RGB444 = 8'h8c;	/* RGB 444 control */
parameter   R444_ENABLE =   8'h02;	  /* Turn on RGB444, overrides 5x5 */
parameter   R444_RGBX =   8'h01;	  /* Empty nibble at end */

parameter REG_HAECC1 = 8'h9f;	/* Hist AEC/AGC control 1 */
parameter REG_HAECC2 = 8'ha0;	/* Hist AEC/AGC control 2 */

parameter REG_BD50MAX = 8'ha5;	/* 50hz banding step limit */
parameter REG_HAECC3 = 8'ha6;	/* Hist AEC/AGC control 3 */
parameter REG_HAECC4 = 8'ha7;	/* Hist AEC/AGC control 4 */
parameter REG_HAECC5 = 8'ha8;	/* Hist AEC/AGC control 5 */
parameter REG_HAECC6 = 8'ha9;	/* Hist AEC/AGC control 6 */
parameter REG_HAECC7 = 8'haa;	/* Hist AEC/AGC control 7 */
parameter REG_BD60MAX = 8'hab;	/* 60hz banding step limit */

parameter NUMBER_CAM_PARAMS_NEW = 114;
// parameter NUMBER_CAM_PARAMS_NEW = 168; //if using commented parameters sequence
parameter [2*NUMBER_CAM_PARAMS_NEW*8-1:0] camera_params_new =
   {REG_CLKRC, 8'h1,	/* OV: clock scale (30 fps) */
   REG_TSLB,  8'h04,	/* OV */
   REG_COM7, 8'h00,	/* VGA */
   /*
    * Set the hardware window.  These values from OV don't entirely
    * make sense - hstop is less than hstart.  But they work...
    */
   REG_HSTART, 8'h13,
   REG_HSTOP, 8'h01,
   REG_HREF, 8'hb6,
   REG_VSTART, 8'h02,
   REG_VSTOP, 8'h7a,
   REG_VREF, 8'h0a,

   // REG_COM3, 8'h0, //VGA
   REG_COM3, 8'h08, //QVGA
   REG_COM14, 8'h0,
   /* Mystery scaling numbers */
   REG_SCALING_XSC, 8'h3a,
   REG_SCALING_YSC, 8'h35,
   8'h72, 8'h11,
   8'h73, 8'hf0,
   8'ha2, 8'h02,
   REG_COM10, 8'h0,
   /* Gamma curve values */
   8'h7a, 8'h20,
   8'h7b, 8'h10,
   8'h7c, 8'h1e,
   8'h7d, 8'h35,
   8'h7e, 8'h5a,
   8'h7f, 8'h69,
   8'h80, 8'h76,
   8'h81, 8'h80,
   8'h82, 8'h88,
   8'h83, 8'h8f,
   8'h84, 8'h96,
   8'h85, 8'ha3,
   8'h86, 8'haf,
   8'h87, 8'hc4,
   8'h88, 8'hd7,
   8'h89, 8'he8,

   /* AGC and AEC parameters.  Note we start by disabling those features,
      then turn them only after tweaking the values. */
   REG_COM8, 8'hE0,
   REG_GAIN, 8'h0,
   REG_AECH, 8'h0,
   REG_COM4, 8'h40, /* magic reserved bit */
   REG_COM9, 8'h18, /* 4x gain + magic rsvd bit */
   REG_BD50MAX, 8'h05,
   REG_BD60MAX, 8'h07,
   REG_AEW, 8'h95,
   REG_AEB, 8'h33,
   REG_VPT, 8'he3,
   REG_HAECC1, 8'h78,
   REG_HAECC2, 8'h68,
   8'ha1, 8'h03, /* magic */
   REG_HAECC3, 8'hd8,
   REG_HAECC4, 8'hd8,
   REG_HAECC5, 8'hf0,
   REG_HAECC6, 8'h90,
   REG_HAECC7, 8'h94,
   REG_COM8, 8'hE5,

   /* Almost all of these are magic "reserved" values.  */
   REG_COM5, 8'h61,
   REG_COM6, 8'h4b,
   8'h16, 8'h02,
   REG_MVFP, 8'h07,
   8'h21, 8'h02,
   8'h22, 8'h91,
   8'h29, 8'h07,
   8'h33, 8'h0b,
   8'h35, 8'h0b,
   8'h37, 8'h1d,
   8'h38, 8'h71,
   8'h39, 8'h2a,
   REG_COM12, 8'h78,
   8'h4d, 8'h40,
   8'h4e, 8'h20,
   REG_GFIX, 8'h0,
   8'h6b, 8'h4a,
   8'h74, 8'h10,
   8'h8d, 8'h4f,
   8'h8e, 8'h0,
   8'h8f, 8'h0,
   8'h98, 8'h0,
   8'h91, 8'h0,
   8'h96, 8'h0,
   8'h9a, 8'h0,
   8'hb0, 8'h84,
   8'hb1, 8'h0c,
   8'hb2, 8'h0e,
   8'hb3, 8'h82,
   8'hb8, 8'h0a,

   /* More reserved magic, some of which tweaks white balance */
	8'h43, 8'h0a,
   8'h44, 8'hf0,
	8'h45, 8'h34,
   8'h46, 8'h58,
	8'h47, 8'h28,
   8'h48, 8'h3a,
	8'h59, 8'h88,
   8'h5a, 8'h88,
	8'h5b, 8'h44,
   8'h5c, 8'h67,
	8'h5d, 8'h49,
   8'h5e, 8'h0e,
	8'h6c, 8'h0a,
   8'h6d, 8'h55,
	8'h6e, 8'h11,
   8'h6f, 8'h9f, /* "9e for advance AWB" */
	8'h6a, 8'h40,
   REG_BLUE, 8'h40,
	REG_RED, 8'h60,
	REG_COM8, 8'hE7,

   //seems to make the image less "grainy" more smooth
   /* Matrix coefficients */
	// 8'h4f, 8'h80,
   // 8'h50, 8'h80,
	// 8'h51, 8'h0,
   // 8'h52, 8'h22,
	// 8'h53, 8'h5e,
   // 8'h54, 8'h80,
	// 8'h58, 8'h9e,
	// REG_COM16, COM16_AWBGAIN,
   // REG_EDGE, 8'h0,
	// 8'h75, 8'h05,
   // 8'h76, 8'he1,
	// 8'h4c, 8'h0,
   // 8'h77, 8'h01,
	// REG_COM13, 8'hc3,
   // 8'h4b, 8'h09,
	// 8'hc9, 8'h60,
   // REG_COM16, 8'h38,
	// 8'h56, 8'h40,
	// 8'h34, 8'h11,
   // REG_COM11, 8'h12,
	// 8'ha4, 8'h88,
   // 8'h96, 8'h0,
	// 8'h97, 8'h30,
   // 8'h98, 8'h20,
	// 8'h99, 8'h30,
   // 8'h9a, 8'h84,
	// 8'h9b, 8'h29,
   // 8'h9c, 8'h03,
	// 8'h9d, 8'h4c,
   // 8'h9e, 8'h3f,
	// 8'h78, 8'h04,
   //
   // /* Extra-weird stuff.  Some sort of multiplexor register */
	// 8'h79, 8'h01,
   // 8'hc8, 8'hf0,
	// 8'h79, 8'h0f,
   // 8'hc8, 8'h00,
	// 8'h79, 8'h10,
   // 8'hc8, 8'h7e,
	// 8'h79, 8'h0a,
   // 8'hc8, 8'h80,
	// 8'h79, 8'h0b,
   // 8'hc8, 8'h01,
	// 8'h79, 8'h0c,
   // 8'hc8, 8'h0f,
	// 8'h79, 8'h0d,
   // 8'hc8, 8'h20,
	// 8'h79, 8'h09,
   // 8'hc8, 8'h80,
	// 8'h79, 8'h02,
   // 8'hc8, 8'hc0,
	// 8'h79, 8'h03,
   // 8'hc8, 8'h40,
	// 8'h79, 8'h05,
   // 8'hc8, 8'h30,
	// 8'h79, 8'h26,

   //RGB selection
   // REG_COM7, COM7_RGB,	/* Selects RGB mode */
   // REG_COM7, 8'h04,	/* Selects RGB mode */ //for VGA
   REG_COM7, 8'h14,	/* Selects RGB mode */ //QGVA
	REG_RGB444, 8'h0,	/* No RGB444 please */
	REG_COM1, 8'h0,	/* CCIR601 */
	REG_COM15, COM15_RGB565,
	REG_COM9, 8'h38,	/* 16x gain ceiling; 8'h8 is reserved bit */
	8'h4f, 8'hb3,		/* "matrix coefficient 1" */
	8'h50, 8'hb3,		/* "matrix coefficient 2" */
	8'h51, 8'h0,		/* vb */
	8'h52, 8'h3d,		/* "matrix coefficient 4" */
	8'h53, 8'ha7,		/* "matrix coefficient 5" */
	8'h54, 8'he4,		/* "matrix coefficient 6" */
	REG_COM13, 8'hC0};
