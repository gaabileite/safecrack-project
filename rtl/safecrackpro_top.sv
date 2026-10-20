module safecrackpro_top (
    input  logic        clk,
    input  logic        rst,
    input  logic	 btn_inc, 	// increment btn
    input  logic	 btn_dec, 	// decrement btn
    input  logic	 key_conf, 	// confirmation key
    output logic [6:0]  seg_pos1,  // 7-seg do dígito 0 (menos significativo)
    output logic [6:0]  seg_pos2,  // 7-seg do dígito 1
    output logic [6:0]  seg_pos3,  // 7-seg do dígito 2
    output logic [6:0]  seg_pos4,  // 7-seg do dígito 3 (mais significativo)
    output logic [6:0]  seg_cur_pos,     // 7-seg do índice da posição atual
    output logic [17:0] led_red,     // 18 LEDs vermelhos (senha errada)
    output logic [8:0]  led_green    // 9 LEDs verdes (senha correta)
);

    logic [3:0] register0;
	 logic [3:0] register1;
	 logic [3:0] register2;
	 logic [3:0] register3;
    logic [1:0] position;

    safecrack u_safecrack		(
        .clk                  (clk),
        .rst                  (rst),
        .btn_inc             	(btn_inc),
		  .btn_dec             	(btn_dec),
		  .key_conf             (key_conf),
        .register0            (register0),
		  .register1            (register1),
		  .register2            (register2),
		  .register3            (register3),
        .position					(position),
        .led_red              (led_red),
        .led_green            (led_green)
    );

    bcd_to_7segment_anodo dec_pos1 (
        .bcd (register0),
        .seg (seg_pos1)
    );

    bcd_to_7segment_anodo dec_pos2 (
        .bcd (register1),
        .seg (seg_pos2)
    );

    bcd_to_7segment_anodo dec_pos3 (
        .bcd (register2),
        .seg (seg_pos3)
    );

    bcd_to_7segment_anodo dec_pos4 (
        .bcd (register3),
        .seg (seg_pos4)
    );

    bcd_to_7segment_anodo dec_cur_pos (
        .bcd ({2'b00, position} + 4'd1),
        .seg (seg_cur_pos)
    );

endmodule
