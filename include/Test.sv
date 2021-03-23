`timescale 1ns / 1ps

`include "./interfaces/mem_if.sv"
`include "Transaction.sv"
`include "Generator.sv"
`include "Driver.sv"
`include "Monitor.sv"
`include "Scoreboard.sv"
`include "Environment.sv"

program test(mem_if intf);
    
    Environment env;
    
    initial begin
        env = new(intf);
        env.generator.repeat_count = 2*1024;
        env.run();
    end
    
endprogram