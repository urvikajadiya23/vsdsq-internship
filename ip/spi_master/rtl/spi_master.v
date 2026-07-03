  GNU nano 7.2                                         spi_master.v                                                  
module SPI_MASTER(

        input clk,
        input resetn,

        //bus interface
        input spi_sel,
        input [1:0]spi_addr,    
        input mem_wstrb,
        input [31:0] mem_wdata,
        output reg [31:0] spi_rdata,

        // SPI signals
        output reg sclk,
        output reg mosi,
        input miso,
        output reg cs_n
);

reg [31:0] ctrl_reg;
reg [31:0] tx_reg;
reg [31:0] rx_reg;
reg [31:0] status_reg;

reg [7:0] tx_shift;
reg [7:0] rx_shift;

reg [3:0] bit_count;
reg [7:0] clk_count;

reg busy;
reg done;


wire en   = ctrl_reg[0];
wire start   = ctrl_reg[1];
wire [7:0] clkdiv   = ctrl_reg[15:8];

always@(posedge clk or negedge resetn)
        begin

        if(!resetn) begin
        ctrl_reg <= 32'd0;
        tx_reg <= 32'd0;
        rx_reg<= 32'd0;
         status_reg <= 32'd0;
        end

        else if (spi_sel && mem_wstrb) begin

        case(spi_addr)

        2'b00:
        ctrl_reg <= mem_wdata;

        2'b01:
        tx_reg<=mem_wdata;

        2'b11:
        if(mem_wdata[1])
         status_reg[1]<= 1'b0;
        default: ;
        endcase
     end
        else if(en && start && !busy) begin
        ctrl_reg[1] <= 1'b0;
   end
end

always@(*)begin

if(spi_sel) begin

case(spi_addr)

2'b00: spi_rdata = ctrl_reg;
2'b01: spi_rdata = tx_reg;
2'b10: spi_rdata = rx_reg;
2'b11: spi_rdata = status_reg;
default: spi_rdata = 32'd0;
endcase
end

else begin
spi_rdata = 32'd0;
end
end

always@(posedge clk or negedge resetn) begin
        if(!resetn) begin
          sclk<= 1'b0;
          cs_n<= 1'b1;
          mosi<= 1'b0;
          busy<= 1'b0;
          done<= 1'b0;
          bit_count<= 4'b0;
          clk_count<= 8'b0;
          status_reg <= 32'd0;
end

else begin
        if(en && start && !busy) begin
        busy<= 1'b1;
        done<= 1'b0;

        status_reg[0] <= 1'b1;  
        status_reg[1] <= 1'b0;

        cs_n <= 1'b0;
        sclk <= 1'b0;
        tx_shift <= tx_reg[7:0];
        mosi <= tx_reg[7];
        rx_shift <= 8'd0;
        bit_count <= 4'd0;
        clk_count <= 8'd0;
end
        else if(busy) begin
        if(clk_count ==clkdiv) begin
        clk_count <= 8'd0;
        sclk<= ~sclk;

        if(sclk==1'b0) begin
        rx_shift <= {rx_shift[6:0],miso};
        bit_count <= bit_count + 1'b1;
  if(bit_count == 4'd7) begin
        busy <= 1'b0;
        done <= 1'b1;
        status_reg[0] <= 1'b0;
        status_reg[1] <= 1'b1;
        cs_n <= 1'b1;
        rx_reg <= {24'd0, rx_shift[6:0],miso};
        sclk <= 1'b0;

  end
end

else begin
mosi<= tx_shift [6];
tx_shift <= {tx_shift[6:0],1'b0};

end

end

else begin

        clk_count <= clk_count +1'b1;

end

end

end

end

endmodule

