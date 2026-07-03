`timescale 1ns/1ps
module spi_master_tb;
reg clk;
reg resetn;
reg spi_sel;
reg [1:0] spi_addr;
reg mem_wstrb;
reg [31:0] mem_wdata;
wire [31:0] spi_rdata;
wire sclk;
wire mosi;
wire cs_n;
wire miso;
assign miso = mosi;
SPI_MASTER uut (
.clk(clk),
.resetn(resetn),
.spi_sel(spi_sel),
.spi_addr(spi_addr),
.mem_wstrb(mem_wstrb),
.mem_wdata(mem_wdata),
.spi_rdata(spi_rdata),
.sclk(sclk),
.mosi(mosi),
.miso(miso),
.cs_n(cs_n)
);
always #5 clk = ~clk;
task write_reg;
input [1:0] addr;
input [31:0] data;
begin
@(posedge clk);
spi_sel=1; spi_addr=addr; mem_wstrb=1; mem_wdata=data;
@(posedge clk);
spi_sel=0; mem_wstrb=0;
end
endtask
initial begin
$dumpfile("spi_master_tb.vcd");
$dumpvars(0, spi_master_tb);
clk=0; resetn=0; spi_sel=0; spi_addr=0; mem_wstrb=0; mem_wdata=0;
repeat(10) @(posedge clk);
resetn=1;
repeat(5) @(posedge clk);
$display("=== SPI Master Testbench ===");
$display("Writing CTRL register...");
write_reg(2'b00, 32'h00000201);
$display("Writing TXDATA = 0xA5...");
write_reg(2'b01, 32'h000000A5);
$display("Starting SPI transfer...");
write_reg(2'b00, 32'h00000203);
$display("Waiting for transfer to complete...");
repeat(2000) @(posedge clk);
$display("Reading STATUS...");
@(posedge clk);
spi_sel=1; spi_addr=2'b11;
@(posedge clk);
@(posedge clk);
$display("STATUS = 0x%08X", spi_rdata);
spi_sel=0;
$display("Reading RXDATA...");
@(posedge clk);
spi_sel=1; spi_addr=2'b10;
@(posedge clk);
@(posedge clk);
$display("RXDATA = 0x%08X", spi_rdata);
spi_sel=0;
if(spi_rdata[7:0] == 8'hA5)
$display("PASS: RXDATA == 0xA5");
else
$display("FAIL: Expected 0xA5, got 0x%02X", spi_rdata[7:0]);
$display("=== Simulation Done ===");
repeat(20) @(posedge clk);
$finish;
end
endmodule
