`timescale 1ns / 1ps

`include "./include/Test.sv"

module testbench;
    bit clk;
    bit reset;
    
    always #5 clk = ~clk;
    
    initial begin
        reset = 1;
        #5 reset = 0;
    end
    
    mem_if intf(clk, reset);
    
    test t1(intf);
    
    memory DUT (
        .clk_i(intf.clk),
        .srst_i(intf.srst),
        .addr_i(intf.addr),
        .we_i(intf.we),
        .wdata_i(intf.wdata),
        .rdata_o(intf.rdata)
    );
    
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end
    
endmodule