`timescale 1ns / 1ps

`ifndef TRANSACTION
    `include "Transaction.sv"
`endif

`define DRIVER


`define DRIV_IF mem_vif.DRIVER.driver_cb

class Driver;

    virtual mem_if mem_vif;
    
    mailbox gen2driv;
    
    event generated, checked;

    function new(virtual mem_if mem_vif, mailbox gen2driv, event generated, event checked);
        this.mem_vif = mem_vif;
        this.gen2driv = gen2driv;
        this.generated = generated;
        this.checked = checked;
    endfunction
    
    // Set reset values
    task reset;
        wait(mem_vif.srst);
        $display("--------- [DRIVER] Reset Started ---------");
        `DRIV_IF.addr <= 0;
        `DRIV_IF.wdata <= 0;
        `DRIV_IF.we <= 0;
        wait(!mem_vif.srst);
        $display("--------- [DRIVER] Reset Ended ---------");
    endtask
    
    
    // Used to count the number of transactions
    int no_transactions;
    
    task drive;
        Transaction trans;
        gen2driv.get(trans); // Get the transaction from the Driver
        
        $display("--------- [DRIVER-TRANSFER: %0d] ---------", no_transactions);

        @(posedge mem_vif.DRIVER.clk);
        `DRIV_IF.addr <= trans.addr;
        `DRIV_IF.we   <= trans.we;
        `DRIV_IF.wdata <= trans.wdata;
        if (trans.we == 1'b1) begin
            $display("\tADDR = %0h \tWDATA = %0h\n", trans.addr, trans.wdata);
        end else begin
            $display("\tADDR = %0h \tRDATA = %0h\n", trans.addr, `DRIV_IF.rdata);
            trans.rdata = `DRIV_IF.rdata;
        end
        no_transactions++;      
    endtask


    task run;
        forever begin
            fork
                begin
                    wait(mem_vif.srst);
                end

                begin
                    forever begin
                        drive();
                        -> generated;
                        wait(checked.triggered);     
                    end
                end
            join_any
        end
    endtask

endclass