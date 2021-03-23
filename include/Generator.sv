`timescale 1ns / 1ps

`define GENERATOR

`ifndef TRANSACTION
    `include "Transaction.sv"
`endif

class Generator;
    
    rand Transaction trans;  // Transaction object
    mailbox gen2driv;        // Mailbox that communicates Generator and Driver.
    int repeat_count;        
    
    event ended;
    
    // Constructior
    function new(input mailbox gen2driv, input event ended);
        this.gen2driv = gen2driv;
        this.ended = ended;
    endfunction
    
    task run();
        // Generate random stimuli
        repeat (repeat_count) begin
            trans = new();
            if (!trans.randomize()) $fatal("Gen::trans randomization failed");
            gen2driv.put(trans);
        end

        -> ended;
    endtask

endclass