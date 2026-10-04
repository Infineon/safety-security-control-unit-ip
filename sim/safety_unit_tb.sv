module safety_unit_tb();

    localparam CLK_PERIOD = 10;

    // This parameter can be used to enable (0) or disable (1) the masking of the errors
    // Disabling the masking implies that all errors will be considered regardless of previous occurrence of the same error
    localparam DISABLE_MASKING = 1;

    // The threshold value for corrected/uncorrected overflows is set to 4 (according to the design of the safety unit)
    localparam THRESHOLD = 4;

    // Signals of the safety unit and the corresponding CSRs
    logic        trap1_csr_wr_en;
    logic        trap1_corrected_error;
    logic        trap1_trigger;
    logic [1:0]  trap1_uncorrected_error;
    logic [2:0]  trap1_corrected_error_extended;
    logic [2:0]  trap1_uncorrected_error_extended;
    logic [31:0] trap1_csr_wr_data;
    logic [31:0] trap1_csr_rd_data;

    logic        trap2_csr_wr_en;
    logic        trap2_trigger;
    logic [1:0]  trap2_corrected_error;
    logic [1:0]  trap2_uncorrected_error;
    logic [2:0]  trap2_corrected_error_extended;
    logic [2:0]  trap2_uncorrected_error_extended;
    logic [31:0] trap2_csr_wr_data;
    logic [31:0] trap2_csr_rd_data;

    // Clock and reset signals
    logic        clk;
    logic        rst_pin;

    // Error vector representing the occurrence of different errors
    logic [6:0]  error_vector;

    // Internal test-bench signals for masking and counting errors
    logic [2:0]  trap1_corrected_error_masked;
    logic [2:0]  trap1_uncorrected_error_masked;
    logic [31:0] trap1_corrected_error_count;
    logic [31:0] trap1_uncorrected_error_count;

    logic [2:0]  trap2_corrected_error_masked;
    logic [2:0]  trap2_uncorrected_error_masked;
    logic [31:0] trap2_corrected_error_count;
    logic [31:0] trap2_uncorrected_error_count;
    
    function void drive_errors();

        // Set the error vector on a random value to simulate different error conditions
        randomize(error_vector);
            
    endfunction
    
    function void check_trap1_response();

        // Mask the corrected and uncorrected errors with the inverse of the CSR read data to ignore already handled errors as long as they are not unmasked again
        trap1_corrected_error_masked = trap1_corrected_error_extended & ~trap1_csr_rd_data[2:0];
        trap1_uncorrected_error_masked = trap1_uncorrected_error_extended & ~trap1_csr_rd_data[2:0];

        // Keep track of the counter value to check for overflow conditions
        if (trap1_corrected_error_count == THRESHOLD) begin
            trap1_corrected_error_count = 32'b0;
        end
        if (|trap1_corrected_error_masked) begin
            trap1_corrected_error_count++;
        end

        if (trap1_uncorrected_error_count == THRESHOLD) begin
            trap1_uncorrected_error_count = 32'b0;
        end
        if (|trap1_uncorrected_error_masked) begin
            trap1_uncorrected_error_count++;
        end

        // Check trap1 trigger for uncorrected/corrected error (trap must enable CSR)
        // Check for uncorrected error
        if (|trap1_uncorrected_error_masked) begin
            assert(trap1_trigger) else $fatal(1, "Trap1 was not triggered when uncorrected error detected");
            assert(trap1_csr_wr_en) else $fatal(1, "Trap1 CSR write enable is not set when uncorrected error detected");
        end
        // Check for corrected overflow
        else if (trap1_corrected_error_count == THRESHOLD) begin
            assert(trap1_trigger) else $fatal(1, "Trap1 was not triggered when corrected overflow detected");
            assert(trap1_csr_wr_en) else $fatal(1, "Trap1 CSR write enable is not set when corrected overflow detected");
        end
        // Check no-error condition
        else begin
            assert(~trap1_trigger) else $fatal(1, "Trap1 was triggered although there was no non-masked error");
            assert(~trap1_csr_wr_en) else $fatal(1, "Trap1 CSR write enable is set although there was no non-masked error");
        end

        // Check error encoding
        // Check for uncorrected error
        if (|trap1_uncorrected_error_masked) begin
            assert(trap1_csr_wr_data[31]) else $fatal(1, "Trap1 error encoding for uncorrected error is not set correctly");
            // Check for uncorrected overflow
            if(trap1_uncorrected_error_count == THRESHOLD) begin
                assert(trap1_csr_wr_data[30]) else $fatal(1, "Trap1 error encoding for uncorrected overflow is not set correctly");
            end
            else begin
                assert(~trap1_csr_wr_data[30]) else $fatal(1, "Trap1 error encoding for uncorrected overflow is not set correctly");
            end
        end
        // Check for corrected overflow
        else if (trap1_corrected_error_count == THRESHOLD) begin
            assert(~trap1_csr_wr_data[31] & trap1_csr_wr_data[30]) else $fatal(1, "Trap1 error encoding for corrected overflow is not set correctly");
        end
        // Check no-error condition
        else begin
            assert(~trap1_csr_wr_data[31] & ~trap1_csr_wr_data[30]) else $fatal(1, "Trap1 error encoding is not zero although there is no non-masked error");
        end

        // Check CSR trap1 write value (except error encoding)
        assert(~|trap1_csr_wr_data[29:3]) else $fatal(1, "Trap1 CSR write data bits [29:3] are not zero although respective nodes are not configured");
        // If uncorrected error/overflow -> forward uncorrected error nodes
        if (|trap1_uncorrected_error_masked) begin
            assert(trap1_csr_wr_data[2:0] == (trap1_uncorrected_error_masked | trap1_csr_rd_data[2:0])) else $fatal(1, "Trap1 CSR write data is not set according to error nodes");
        end
        // Otherwise -> forward corrected error nodes (it's also the default case for no-error condition -> but will only update the CSR if it is enabled in case of an actual corrected overflow)
        else begin
            assert(trap1_csr_wr_data[2:0] == (trap1_corrected_error_masked | trap1_csr_rd_data[2:0])) else $fatal(1, "Trap1 CSR write data is not set according to error nodes");
        end
    
    endfunction
    
    function void check_trap2_response();

        // Mask the corrected and uncorrected errors with the inverse of the CSR read data to ignore already handled errors as long as they are not unmasked again
        trap2_corrected_error_masked = trap2_corrected_error_extended & ~trap2_csr_rd_data[2:0];
        trap2_uncorrected_error_masked = trap2_uncorrected_error_extended & ~trap2_csr_rd_data[2:0];

        // Keep track of the counter value to check for overflow conditions
        if (trap2_corrected_error_count == THRESHOLD) begin
            trap2_corrected_error_count = 32'b0;
        end
        if (|trap2_corrected_error_masked) begin
            trap2_corrected_error_count++;
        end

        if (trap2_uncorrected_error_count == THRESHOLD) begin
            trap2_uncorrected_error_count = 32'b0;
        end
        if (|trap2_uncorrected_error_masked) begin
            trap2_uncorrected_error_count++;
        end

        // Check trap2 trigger for uncorrected/corrected error (trap must enable CSR)
        // Check for uncorrected error
        if (|trap2_uncorrected_error_masked) begin
            assert(trap2_trigger) else $fatal(1, "Trap2 was not triggered when uncorrected error detected");
            assert(trap2_csr_wr_en) else $fatal(1, "Trap2 CSR write enable is not set when uncorrected error detected");
        end
        // Check for corrected overflow 
        else if (trap2_corrected_error_count == THRESHOLD) begin
            assert(trap2_trigger) else $fatal(1, "Trap2 was not triggered when corrected overflow detected");
            assert(trap2_csr_wr_en) else $fatal(1, "Trap2 CSR write enable is not set when corrected overflow detected");
        end
        // Check no-error condition
        else begin
            assert(~trap2_trigger) else $fatal(1, "Trap2 was triggered although there was no non-masked error");
            assert(~trap2_csr_wr_en) else $fatal(1, "Trap2 CSR write enable is set although there was no non-masked error");
        end

        // Check error encoding
        // Check for uncorrected error
        if (|trap2_uncorrected_error_masked) begin
            assert(trap2_csr_wr_data[31]) else $fatal(1, "Trap2 error encoding for uncorrected error is not set correctly");
            // Check for uncorrected overflow
            if(trap2_uncorrected_error_count == THRESHOLD) begin
                assert(trap2_csr_wr_data[30]) else $fatal(1, "Trap2 error encoding for uncorrected overflow is not set correctly");
            end
            else begin
                assert(~trap2_csr_wr_data[30]) else $fatal(1, "Trap2 error encoding for uncorrected overflow is not set correctly");
            end
        end
        // Check for corrected overflow
        else if (trap2_corrected_error_count == THRESHOLD) begin
            assert(~trap2_csr_wr_data[31] & trap2_csr_wr_data[30]) else $fatal(1, "Trap2 error encoding for corrected overflow is not set correctly");
        end
        // Check no-error condition
        else begin
            assert(~trap2_csr_wr_data[31] & ~trap2_csr_wr_data[30]) else $fatal(1, "Trap2 error encoding is not zero although there is no non-masked error");
        end

        // Check CSR trap2 write value (except error encoding)
        assert(~|trap2_csr_wr_data[29:3]) else $fatal(1, "Trap2 CSR write data bits [29:3] are not zero although respective nodes are not configured");
        // If uncorrected error/overflow -> forward uncorrected error nodes
        if (|trap2_uncorrected_error_masked) begin
            assert(trap2_csr_wr_data[2:0] == (trap2_uncorrected_error_masked | trap2_csr_rd_data[2:0])) else $fatal(1, "Trap2 CSR write data is not set according to error nodes");
        end
        // Otherwise -> forward corrected error nodes (it's also the default case for no-error condition -> but will only update the CSR if it is enabled in case of an actual corrected overflow)
        else begin
            assert(trap2_csr_wr_data[2:0] == (trap2_corrected_error_masked | trap2_csr_rd_data[2:0])) else $fatal(1, "Trap2 CSR write data is not set according to error nodes");
        end
    
    endfunction

    Top_SoC_CPUCore_safety_management_unit DUT(
        .trap1_corrected_error                           ( trap1_corrected_error   ),
        .trap1_uncorrected_error                         ( trap1_uncorrected_error ),
        .trap2_corrected_error                           ( trap2_corrected_error   ),
        .trap2_uncorrected_error                         ( trap2_uncorrected_error ),
        .trap1_group_process_csr_hw_wr_out_out           ( trap1_csr_wr_data       ),
        .trap1_group_process_csr_hw_en_out_out           ( trap1_csr_wr_en         ),
        .ig_EU_CSR_MU_trap1_trap1_rd_data_out_out_out_in ( trap1_csr_rd_data       ),
        .trap2_group_process_csr_hw_wr_out_out           ( trap2_csr_wr_data       ),
        .trap2_group_process_csr_hw_en_out_out           ( trap2_csr_wr_en         ),
        .ig_EU_CSR_MU_trap2_trap2_rd_data_out_out_out_in ( trap2_csr_rd_data       ),
        .trap1_group_process_trap1_trap_trigger_out      ( trap1_trigger           ),
        .trap2_group_process_trap2_trap_trigger_out      ( trap2_trigger           ),
        .clk                                             ( clk                     ),
        .rst_pin                                         ( rst_pin                 )
    );

    // Assign error vectors according to node configuration
    assign trap1_corrected_error = error_vector[6];
    assign trap1_corrected_error_extended = {error_vector[6], 1'b0, 1'b0};
    assign trap1_uncorrected_error = {error_vector[5], error_vector[4]};
    assign trap1_uncorrected_error_extended = {1'b0, error_vector[4], error_vector[5]};

    assign trap2_corrected_error = {error_vector[3], error_vector[2]};
    assign trap2_corrected_error_extended = {error_vector[2], 1'b0, error_vector[3]};
    assign trap2_uncorrected_error = {error_vector[1], error_vector[0]};
    assign trap2_uncorrected_error_extended = {1'b0, error_vector[0], error_vector[1]};
    
    // Store trap1 CSR value
    always_ff @(posedge clk) begin
        if (rst_pin) begin
            trap1_csr_rd_data <= 0;
        end
        else begin
            if (trap1_csr_wr_en) begin
                if (DISABLE_MASKING) begin
                    // Masking of errors disabled -> only write error encoding
                    trap1_csr_rd_data <= {trap1_csr_wr_data[31:30], 30'b0};
                end
                else begin
                    // Masking of errors enabled
                    trap1_csr_rd_data <= trap1_csr_wr_data; 
                end
            end       
        end
    end
    
    // Store trap2 CSR value
    always_ff @(posedge clk) begin
        if (rst_pin) begin
            trap2_csr_rd_data <= 0;
        end
        else begin
            if (trap2_csr_wr_en) begin
                if (DISABLE_MASKING) begin
                    // Masking of errors disabled -> only write error encoding
                    trap2_csr_rd_data <= {trap2_csr_wr_data[31:30], 30'b0};
                end
                else begin
                    // Masking of errors enabled
                    trap2_csr_rd_data <= trap2_csr_wr_data;
                end
            end
        end
    end

    initial begin
        clk = 0;
        while (1) begin
             #(CLK_PERIOD/2) clk = ~clk;
        end
	end

	initial begin
	    rst_pin = 1'b1;
	    error_vector = 7'b0;
        trap1_corrected_error_count = 32'b0;
        trap1_uncorrected_error_count = 32'b0;
        trap2_corrected_error_count = 32'b0;
        trap2_uncorrected_error_count = 32'b0;
        #15
	    rst_pin = 1'b0;

        repeat(100) @(posedge clk) begin
            drive_errors();
            check_trap1_response();
            check_trap2_response();
        end

        $display("SUCCESS FINISH");
        $finish;
	end

endmodule