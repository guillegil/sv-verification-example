`timescale 1ns / 1ps

`include "SimClasses.sv"

program automatic test(mem_if intf);
    
    Environment env;
    
    initial begin
        env = new(intf);
        env.generator.repeat_count = 2*1024;
        env.run();
    end
    
endprogram