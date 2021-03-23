`timescale 1ns / 1ps

`define TRANSACTION

class Transaction;

    // Random varibles
    rand  bit [31:0] wdata; 
    randc bit [15:0] addr;
    randc bit we;
    
    // Constraint addr inside the range [0:1023]
    constraint addr_ct { addr inside {[0:1023]}; };

    constraint we_ct { 
        we dist { 0:=50, 1:=50 };
    };

    bit [31:0] rdata;
    
endclass