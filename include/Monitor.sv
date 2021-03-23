`timescale 1ns / 1ps

`define MONITOR

`ifndef TRANSACTION
    `include "Transaction.sv"
`endif

`define MON_IF mem_vif.MONITOR.monitor_cb

class Monitor;
    virtual mem_if mem_vif;

    event generated, checked;
    mailbox mon2scb;    // Monitor to Scoreboard mailbox

    function new(virtual mem_if mem_vif, mailbox mon2scb, event generated, event checked);
        this.mem_vif = mem_vif;
        this.mon2scb = mon2scb;
        this.generated = generated;
        this.checked = checked;
    endfunction

    task run();
        forever begin
            Transaction trans;
            trans = new();

            wait(generated.triggered);
            @(posedge mem_vif.MONITOR.clk);
                trans.addr = `MON_IF.addr;
                trans.we = `MON_IF.we;
                trans.wdata = `MON_IF.wdata;

                // If a read transaction has been generated wait one clock cycle
                // before read data.
                if (`MON_IF.we == 1'b0) begin
                    @(posedge mem_vif.MONITOR.clk);
                    trans.rdata = `MON_IF.rdata;
                end

                // Send transfer to the scoreboard
                mon2scb.put(trans);
            -> checked;
        end
    endtask
endclass
