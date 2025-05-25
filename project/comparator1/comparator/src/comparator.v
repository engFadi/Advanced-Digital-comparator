module comparator_6bit (	 //Fadi Bassous 1221005
    input [5:0] A, B,
    input S, CLK, RST,
    output regE, regL, regG
);
    wire [5:0] regA, regB, notA, notB, X, Y_L, Y_G;
    wire Z, unsigned_L, unsigned_G, signed_L, signed_G;
    wire G, E, L,V,F,W,regS;
																							 
    D_FF #(6) dff_A (.D(A), .CLK(CLK), .Q(regA), .RST(RST));
    D_FF #(6) dff_B (.D(B), .CLK(CLK), .Q(regB), .RST(RST));	
	D_FF #(1) dff_S (.D(S), .CLK(CLK), .Q(regS), .RST(RST));

    // E = A == B
    genvar x;
    generate
        for (x = 0; x < 6; x = x + 1) begin : generate_logic
            not #4 (notA[x], regA[x]);
            not #4 (notB[x], regB[x]);
            xnor #9 (X[x], regA[x], regB[x]); 
        end
    endgenerate
    and #7 (E, X[5], X[4], X[3], X[2], X[1], X[0]);


    // Unsigned G = A > B
    and #7 (Y_G[5], regA[5], notB[5]);
    and #7 (Y_G[4], regA[4], notB[4], X[5]);
    and #7 (Y_G[3], regA[3], notB[3], X[5], X[4]);
    and #7 (Y_G[2], regA[2], notB[2], X[5], X[4], X[3]);
    and #7 (Y_G[1], regA[1], notB[1], X[5], X[4], X[3], X[2]);
    and #7 (Y_G[0], regA[0], notB[0], X[5], X[4], X[3], X[2], X[1]);
    or  #7 (unsigned_G, Y_G[5], Y_G[4], Y_G[3], Y_G[2], Y_G[1], Y_G[0]);	
	
	
    // Unsigned L = A < B	 
	assign zero=1'b0;
	assign one=1'b1;
	xor #10 (K,E,unsigned_G);
	 mux_2to1 muxL(one,zero, K, unsigned_L);
	

   // Signed L = A < B for signed numbers 
	   xor #10 (V,regA[5],regB[5]);
	   and #7 (F,regA[5],notB[5]);
	   or #7 (W,V,F);		
	   xor #10 (signed_G,unsigned_G,W);		  	
	   								
	   
	
	// Signed G = A > B for signed numbers
	 xor #10 (signed_L,unsigned_L,W);



    // Select Signed or Unsigned based on S
    mux_2to1 mux_L(unsigned_L, signed_L, regS, L);
    mux_2to1 mux_G(unsigned_G, signed_G, regS, G);

    // Register Outputs
  D_FF #(1) dff_E (.D(E), .CLK(CLK), .Q(regE), .RST(RST));
  D_FF #(1) dff_G (.D(G), .CLK(CLK), .Q(regG), .RST(RST));
  D_FF #(1) dff_L (.D(L), .CLK(CLK), .Q(regL), .RST(RST));
endmodule

module mux_2to1 (I1, I2, S, Y);
    input I1, I2, S;
    output Y;
    wire g, f, s;

    not  #4 (s, S);   
    and  #7 (g, I1, s);  
    and  #7 (f, I2, S);   
    or   #7 (Y, g, f);    
endmodule

module D_FF  (D, CLK, Q, RST);
	parameter N = 1; 
    output reg [N-1:0] Q;
    input [N-1:0] D;
    input CLK, RST;

    always @(posedge CLK or negedge RST) 
        if (~RST) 
            Q <= 0;    
        else 
            Q <= D;    
endmodule

module B_comparator (  // Behavioural comparator
  output reg EQ,
  output reg GT,
  output reg LT,
  input [5:0]A,B,
  input S
);

  always @(*) begin
    if (S) begin
      LT = ($signed(A)< $signed(B));
      EQ = ($signed(A) == $signed(B));
      GT = ($signed(A) > $signed(B));
    end else begin
      LT = (A < B);
      EQ = (A == B);
      GT = (A > B);
    end
  end
  
endmodule



module comparator_6bit_tb;

    reg [5:0] A, B;
    reg S, CLK, RST;

    wire regE, regL, regG;
    wire EH, GH, LH;

    integer error_count; // Counter to track errors

    // Instantiate the 6-bit comparator (Unit Under Test)
    comparator_6bit uut (
        .A(A),
        .B(B),
        .S(S),
        .CLK(CLK),
        .RST(RST),
        .regE(regE),
        .regL(regL),
        .regG(regG)
    );

    // Instantiate the behavioral comparator
    B_comparator uut2 (
        .EQ(EH),
        .GT(GH),
        .LT(LH),
        .A(A),
        .B(B),
        .S(S)
    );

    // Clock generation
    initial begin
        CLK = 0;
    end

    always #30 CLK = ~CLK;

    // Testbench logic
    initial begin
        // Initialize signals
        A = 6'b000000;
        B = 6'b000000;
        S = 0;
        RST = 0;
        error_count = 0;

        // Reset sequence
        #60 RST = 1;

        // Test cases
        #60; // Allow some time after reset

        // Test case 1
        A = 6'b000010;
        B = 6'b000010;
        S = 0;
        #180;
		 if ((regE !== EH) || (regL !== LH) || (regG !== GH)) begin
                $display("ERROR: Time: %0d | A = %b, B = %b, S = %b | uut: E=%b, L=%b, G=%b | uut2: E=%b, L=%b, G=%b",
                         $time, A, B, S, regE, regL, regG, EH, LH, GH);
                error_count = error_count + 1;
            end else begin
                $display("PASS: Time: %0d | A = %b, B = %b, S = %b | Equal = %b, Less = %b, Greater = %b",
                         $time, A, B, S, regE, regL, regG);
            end

        // Test case 2
        A = 6'b111110;
        B = 6'b111100;
        S = 1;
        #180;	 
		 if ((regE !== EH) || (regL !== LH) || (regG !== GH)) begin
                $display("ERROR: Time: %0d | A = %b, B = %b, S = %b | uut: E=%b, L=%b, G=%b | uut2: E=%b, L=%b, G=%b",
                         $time, A, B, S, regE, regL, regG, EH, LH, GH);
                error_count = error_count + 1;
            end else begin
                $display("PASS: Time: %0d | A = %b, B = %b, S = %b | Equal = %b, Less = %b, Greater = %b",
                         $time, A, B, S, regE, regL, regG);
            end

        // Randomized test cases
        repeat (10) begin
            A = $random % 64; // Generate a random 6-bit number
            B = $random % 64; // Generate a random 6-bit number
            S = $random % 2;  // Generate a random single-bit value
            #180;

            // Check results
            if ((regE !== EH) || (regL !== LH) || (regG !== GH)) begin
                $display("ERROR: Time: %0d | A = %b, B = %b, S = %b | uut: E=%b, L=%b, G=%b | uut2: E=%b, L=%b, G=%b",
                         $time, A, B, S, regE, regL, regG, EH, LH, GH);
                error_count = error_count + 1;
            end else begin
                $display("PASS: Time: %0d | A = %b, B = %b, S = %b | Equal = %b, Less = %b, Greater = %b",
                         $time, A, B, S, regE, regL, regG);
            end
        end

        // Final report
        if (error_count > 0) begin
            $display("SIMULATION COMPLETE: %0d errors detected.", error_count);
        end else begin
            $display("SIMULATION COMPLETE: No errors detected.");
        end

        // Stop simulation
        $stop;
    end

endmodule

