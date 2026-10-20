module safecrack ( 
   input  logic        clk,        // clock
   input  logic        rst,        // reset key 
   input  logic        key_conf,   // confirmation key
   input  logic        btn_inc,    // increment btn
   input  logic        btn_dec,    // decrement btn
   output logic [3:0]  register0,
   output logic [3:0]  register1,
   output logic [3:0]  register2,
   output logic [3:0]  register3,
   output logic [1:0]  position,
   output logic [8:0]  led_green, 
   output logic [17:0] led_red 
);

   // using one hot encoding logic
   typedef enum logic [15:0] {
        A         = 16'b0000000000000001,
        A_INC     = 16'b0000000000000010,
        A_DEC     = 16'b0000000000000100,
        B         = 16'b0000000000001000,
        B_INC     = 16'b0000000000010000,
        B_DEC     = 16'b0000000000100000,
        C         = 16'b0000000001000000,
        C_INC     = 16'b0000000010000000,
        C_DEC     = 16'b0000000100000000,
        D         = 16'b0000001000000000,
        D_INC     = 16'b0000010000000000,
        D_DEC     = 16'b0000100000000000,
        CHECK     = 16'b0001000000000000,
        CORRECT   = 16'b0010000000000000,
        WRONG     = 16'b0100000000000000,
        WAIT      = 16'b1000000000000000
   } state_t;

   state_t state, next_state;

   // position counter (next value only; "position" itself is an output port)
   logic [1:0] next_position;
   logic [3:0] next_register0;
   logic [3:0] next_register1;
   logic [3:0] next_register2;
   logic [3:0] next_register3;

   // setting the clock logic - with a 50MHz clock, it is needed 50000000 ticks to account for one second
   localparam int ONE_SECOND = 50_000_000; // 1 second delay at 50MHz clock
   logic [$clog2(5*ONE_SECOND)-1:0] delay_cnt, next_delay_cnt;

	//flag for led time
   logic was_correct;

   // defining the edge for all of the buttons - this is needed so that the computer knows that each button has been pressed one time and not multiple
   logic btn_inc_prev, btn_inc_edge, btn_inc_pos;
   logic key_conf_prev, key_conf_edge, key_conf_pos;
   logic btn_dec_prev, btn_dec_edge, btn_dec_pos;

   // inverting buttons to active when high - this sets the edge as high: the computer detects that the button has been pressed when its state goes from 0 to 1
   always_comb begin
      btn_inc_pos   = ~btn_inc; 
      btn_dec_pos   = ~btn_dec;
      key_conf_pos  = ~key_conf;

      // get 0 -> 1 edges
      btn_inc_edge  = btn_inc_pos & ~btn_inc_prev; 
      btn_dec_edge  = btn_dec_pos & ~btn_dec_prev;
      key_conf_edge = key_conf_pos & ~key_conf_prev;
   end

   // creating the parameter logic to determine the password digits
   localparam logic [3:0] pass0 = 4'b0010; // digit 3 = 2
   localparam logic [3:0] pass1 = 4'b0111; // digit 2 = 7
   localparam logic [3:0] pass2 = 4'b0011; // digit 1 = 3
   localparam logic [3:0] pass3 = 4'b1001; // digit 0 = 9

   // transition logic
   always_comb begin 
      // default assignments
      next_state     = state;
      next_delay_cnt = delay_cnt;
      next_position  = position;

      unique case (state)
         A: begin
            if (key_conf_edge) begin 
               next_state    = B;
               next_position = position + 1'b1;
            end else if (btn_inc_edge) next_state = A_INC;
            else if      (btn_dec_edge) next_state = A_DEC;
            else next_state = A;
			
			end A_INC, A_DEC: next_state = A;

         B: begin
            if (key_conf_edge) begin 
               next_state    = C;
               next_position = position + 1'b1;
            end else if (btn_inc_edge) next_state = B_INC;
            else if      (btn_dec_edge) next_state = B_DEC;
            else next_state = B;
				
			end B_INC, B_DEC: next_state = B;

         C: begin
            if (key_conf_edge) begin 
               next_state    = D;
               next_position = position + 1'b1;
            end else if (btn_inc_edge) next_state = C_INC;
            else if      (btn_dec_edge) next_state = C_DEC;
            else next_state = C;
				
			end C_INC, C_DEC: next_state = C;

         D: begin
            if (key_conf_edge) begin 
               next_state    = CHECK;
               next_position = position + 1'b1;
            end else if (btn_inc_edge) next_state = D_INC;
            else if      (btn_dec_edge) next_state = D_DEC;
            else next_state = D;
				
			end D_INC, D_DEC: next_state = D;

         CHECK: begin
            if (register0 == pass0 &&
                register1 == pass1 &&
                register2 == pass2 &&
                register3 == pass3)
               next_state = CORRECT;
            else next_state = WRONG;
         end CORRECT: begin
            next_delay_cnt = ($bits(delay_cnt))'(5*ONE_SECOND);
            next_state     = WAIT;
         end WRONG: begin
            next_delay_cnt = ($bits(delay_cnt))'(3*ONE_SECOND);
            next_state     = WAIT;
         end WAIT: begin
            if (delay_cnt > 0) next_delay_cnt = delay_cnt - 1'b1;
            else next_state = A;
         end default: next_state = A;
      endcase
   end

   // increment and decrement logic
   always_comb begin
      // default assignments
      next_register0 = register0;
      next_register1 = register1;
      next_register2 = register2;
      next_register3 = register3;

      case (state)
			// if register > 9: returns to 0
			// if register < 0: jumps to 9
         A_INC: begin
            if      (register3 < 4'b1001)  next_register3 = register3 + 1'b1;
            else if (register3 == 4'b1001) next_register3 = 4'b0000;
         end A_DEC: begin
            if      (register3 > 4'b0000)  next_register3 = register3 - 1'b1;
            else if (register3 == 4'b0000) next_register3 = 4'b1001;
         end B_INC: begin
            if      (register2 < 4'b1001)  next_register2 = register2 + 1'b1;
            else if (register2 == 4'b1001) next_register2 = 4'b0000;
         end B_DEC: begin
            if      (register2 > 4'b0000)  next_register2 = register2 - 1'b1;
            else if (register2 == 4'b0000) next_register2 = 4'b1001;
         end C_INC: begin
            if      (register1 < 4'b1001)  next_register1 = register1 + 1'b1;
            else if (register1 == 4'b1001) next_register1 = 4'b0000;
         end C_DEC: begin
            if      (register1 > 4'b0000)  next_register1 = register1 - 1'b1;
            else if (register1 == 4'b0000) next_register1 = 4'b1001;
         end D_INC: begin
            if      (register0 < 4'b1001)  next_register0 = register0 + 1'b1;
            else if (register0 == 4'b1001) next_register0 = 4'b0000;
         end D_DEC: begin
            if      (register0 > 4'b0000)  next_register0 = register0 - 1'b1;
            else if (register0 == 4'b0000) next_register0 = 4'b1001;
         end
         default: ;
      endcase
   end

   // update logic
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
         state     <= A;
         delay_cnt <= 0;
         position  <= 2'b0;
         register0 <= 4'b0;
         register1 <= 4'b0;
         register2 <= 4'b0;
         register3 <= 4'b0;
         btn_inc_prev  <= 1'b0;
         btn_dec_prev  <= 1'b0;
         key_conf_prev <= 1'b0;
         was_correct   <= 1'b0;

      end else begin
         state     <= next_state;
         delay_cnt <= next_delay_cnt;
         position  <= next_position;

         btn_inc_prev  <= btn_inc_pos;
         btn_dec_prev  <= btn_dec_pos;
         key_conf_prev <= key_conf_pos;

         register0 <= next_register0;
         register1 <= next_register1;
         register2 <= next_register2;
         register3 <= next_register3;

         if (state == CORRECT)      was_correct <= 1'b1;
         else if (state == WRONG)   was_correct <= 1'b0;
      end
   end

   // combinational logic to light up the LEDs (drive the whole vector)
   always_comb begin
      led_green = (state == WAIT &&  was_correct) ? '1 : '0;
      led_red   = (state == WAIT && ~was_correct) ? '1 : '0;
   end
endmodule
