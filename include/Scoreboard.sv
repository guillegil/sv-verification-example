`timescale 1ns / 1ps

`ifndef TRANSACTION
    `include "Transaction.sv"
`endif

`define SCOREBOARD

class Scoreboard;
    mailbox mon2scb;
    int no_transactions;

    bit [31:0] mem[0:1023];

    event generated, checked;

    function new(mailbox mon2scb, event generated, event checked);
        this.mon2scb = mon2scb;
        this.generated = generated;
        this.checked = checked;
        foreach(mem[i]) mem[i] = 32'hFFFF_FFFF;
    endfunction

    task run();
        Transaction trans;
        forever begin
            mon2scb.get(trans);  // Get the data from the monitor
            if (trans.we == 1'b0) begin
                if (mem[trans.addr] != trans.rdata) begin
                    $error("[SCB-FAIL] Addr = %0h, \n\t Data :: Expected = %0h Actual = %0h", trans.addr, mem[trans.addr], trans.rdata);
                end else begin
                    $display("[SCB-PASS] Addr = %0h, \n\t Data :: Expected = %0h Actual = %0h", trans.addr, mem[trans.addr], trans.rdata);
                end
            end else begin
                mem[trans.addr] = trans.wdata;
                no_transactions++;
            end
        end
    endtask
endclass
