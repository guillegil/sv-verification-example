`timescale 1ns / 1ps

`ifndef GENERATOR
    `include "Generator.sv"
`endif

`ifndef DRIVER
    `include "Driver.sv"
`endif 

`ifndef MONITOR
    `include "Monitor.sv"
`endif 

`ifndef SCOREBOARD
    `include "Scoreboard.sv"
`endif 

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