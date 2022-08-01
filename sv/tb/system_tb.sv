/*
  Engineer    : Abarajithan G
  Company     : -
  Create Date : 31-July-2022
  Design Name : system_tb
  Description : Testbench to read given assembly file to be executed in the processor
*/

timeunit 1ns/1ps;

module system_tb;

  logic clk = 0, rstn=0, start=0, idle;

  localparam CLK_PERIOD =10;
  initial forever #(CLK_PERIOD/2) clk <= ~clk;

  localparam NUM_GPR = 8;
  string fn_iram = "D:/arisc/txt/input/test.txt";
  string fn_dram = "D:/arisc/txt/output/test.txt";

  logic iram_write, iram_write_mux, iram_write_tb, dram_write;
  logic [15:0] iram_din=0, iram_dout;
  logic [7 :0] iram_addr, dram_din, dram_dout, dram_addr;

  mock_ram #(.W_DATA(16), .DEPTH(256), .LATENCY(1)) IRAM (
    .clk      (clk), 
    .write_en (iram_write),
    .addr     (iram_addr),
    .din      (iram_din),
    .dout     (iram_dout)
  );

  mock_ram #(.W_DATA(8), .DEPTH(256), .LATENCY(1)) DRAM (
    .clk      (clk), 
    .write_en (dram_write),
    .addr     (dram_addr),
    .din      (dram_din),
    .dout     (dram_dout)
  );

  cpu #(.NUM_GPR(NUM_GPR)) CPU (.*);

  int fh_iram, fh_dram, status, addr=0;
  string line, opcode_s, operand_s;
  logic [7:0] opcode, operand;

  initial begin
    @(posedge clk); #1
    rstn = 1;

    fh_iram = $fopen(fn_iram, "r");

    while (1) begin
      status = $fgets(line, fh_iram);

      // skip empty lines & comment lines
      if (line == "\n" | line.substr(0,0) == "#") continue;

      // extract opcode & operand, read them as binary
      opcode_s = line.substr(0,3);
      operand_s = line.substr(6,9);
      opcode = opcode_s.atobin();
      operand = operand_s.atobin();

      // write into IRAM
      IRAM.ram[addr] = {operand, opcode};
      addr += 1;

      if (opcode == 8'b0) break;
    end
    $fclose(fh_iram);

    @(posedge clk); #1
    start = 1;
    @(posedge clk); #1
    start = 0;

    wait(idle);
    @(posedge clk); #1

    // Read from DRAM into file
    fh_dram = $fopen(fn_dram, "w");
    for (addr=0; addr<256; addr++) $fdisplay(fh_dram, "%d", DRAM.ram[addr]);
    $fclose(fh_dram);
  end

endmodule