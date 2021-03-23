`timescale 1ns / 1ps

interface mem_if(input clk, input srst);

    bit [31:0] wdata, rdata;
    bit [15:0] addr;
    bit we; 
   
    clocking driver_cb @(posedge clk);
        default input #1 output #2;
        input rdata;
        output we, wdata, addr;
    endclocking
    
    clocking monitor_cb @(posedge clk);
        default input #1 output #1;
        input addr, we, wdata, rdata;
    endclocking
   
    modport DRIVER (clocking driver_cb, input clk, srst);
    modport MONITOR (clocking monitor_cb, input clk, srst);
   
endinterface
