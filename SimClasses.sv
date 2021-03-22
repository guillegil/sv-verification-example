`timescale 1ns / 1ps

class Transaction;

    rand bit [31:0] wdata; 
    randc bit [15:0] addr;
    randc bit we;
    
    constraint addr_ct { addr inside {[0:1023]}; };

    bit [31:0] rdata;
    
endclass

class Generator;
    
    rand Transaction trans;
    mailbox gen2driv;
    int repeat_count;
    
    event ended;
    
    function new(input mailbox gen2driv, input event ended);
        this.gen2driv = gen2driv;
        this.ended = ended;
    endfunction
    
    task run();
        repeat (repeat_count) begin
            trans = new();
            if ( !trans.randomize() ) $fatal("Gen::trans randomization failed");
            gen2driv.put(trans);
        end
        
        -> ended;
    endtask

endclass

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
    
    task reset;
        wait(mem_vif.srst);
        $display("--------- [DRIVER] Reset Started ---------");
        `DRIV_IF.addr <= 0;
        `DRIV_IF.wdata <= 0;
        `DRIV_IF.we <= 0;
        wait(!mem_vif.srst);
        $display("--------- [DRIVER] Reset Ended ---------");
    endtask
    
    
    //used to count the number of transactions
    int no_transactions;
    
    task run();
        forever begin
           Transaction trans;
           
           `DRIV_IF.we <= 0;
           gen2driv.get(trans);
           
           $display("--------- [DRIVER-TRANSFER: %0d] ---------", no_transactions);
           @(posedge mem_vif.DRIVER.clk);
           `DRIV_IF.addr <= trans.addr;
           `DRIV_IF.we   <= trans.we;
           if (trans.we == 1'b1) begin
               `DRIV_IF.wdata <= trans.wdata;
               $display("\tADDR = %0h \tWDATA = %0h\n", trans.addr, trans.wdata);
               // @(posedge mem_vif.DRIVER.clk);
           end else begin
              `DRIV_IF.we <= 0;
              // @(posedge mem_vif.DRIVER.clk);
              trans.rdata = `DRIV_IF.rdata;
              $display("\tADDR = %0h \tRDATA = %0h\n", trans.addr, `DRIV_IF.rdata);
           end
           
           //$display("-----------------------------------------");
           no_transactions++;      
           -> generated;
           wait(checked.triggered);     
        end
    endtask
endclass

`define MON_IF mem_vif.MONITOR.monitor_cb

class Monitor;
    virtual mem_if mem_vif;

    event generated, checked;

    mailbox mon2scb;

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

                if (`MON_IF.we == 1'b0) begin
                    @(posedge mem_vif.MONITOR.clk);
                    //@(posedge mem_vif.MONITOR.clk);
                    trans.rdata = `MON_IF.rdata;
                end

                mon2scb.put(trans);
            -> checked;
        end
    endtask
endclass

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
            mon2scb.get(trans);
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

class Environment;
    Generator generator;
    Driver    driver;
    Monitor   monitor;
    Scoreboard scoreboard;

    mailbox gen2driv;
    mailbox mon2scb;
    event     gen_ended, generated, checked;
    virtual mem_if mem_vif;
    
    function new(virtual mem_if mem_vif);
        this.mem_vif = mem_vif;

        gen2driv = new();
        mon2scb  = new();

        generator   = new(gen2driv, gen_ended);
        driver      = new(mem_vif, gen2driv, generated, checked);
        monitor     = new(mem_vif, mon2scb, generated, checked);
        scoreboard  = new(mon2scb, generated, checked);
    endfunction
    
    task pre_test();
        driver.reset();
    endtask

    task test();
        fork
            generator.run();
            driver.run();
            monitor.run();
            scoreboard.run();
        join_any
    endtask
    
    task post_test();
        wait(gen_ended.triggered);
        wait(generator.repeat_count == driver.no_transactions);
        wait(generator.repeat_count == scoreboard.no_transactions); 
    endtask
    
    task run;
        pre_test();
        test();
        post_test();
        $finish;
    endtask

endclass