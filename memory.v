`timescale 1ns / 1ps

module memory(
  input wire clk_i,
  input wire srst_i,
  input wire we_i,
  input wire [15:0] addr_i,
  input wire [31:0] wdata_i,
  output reg [31:0] rdata_o
);

    reg [31:0] mem [0:1023];
    
    initial begin
       int i;
       for (i = 0; i < 1024; i = i + 1) begin
           mem[i] <= 32'hFFFFFFFF;
       end 
    end

    always @(posedge clk_i) begin
        if (we_i == 1'b1) begin
            mem[addr_i] <= wdata_i;
        end else begin
            if (srst_i == 1'b1) begin
                rdata_o <= 32'b0;
            end else begin
                rdata_o <= mem[addr_i];
            end
        end
    end

endmodule
