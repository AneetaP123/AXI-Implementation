`timescale 1ns/1ps

module axi_slave_simple #(
  parameter ID_WIDTH=4,
  parameter ADDR_WIDTH=32,
  parameter DATA_WIDTH=32,
  parameter DEPTH=256
)(
  input  wire                   ACLK,
  input  wire                   ARESETn,

  // Write Address
  input  wire [ID_WIDTH-1:0]    AWID,
  input  wire [ADDR_WIDTH-1:0]  AWADDR,
  input  wire [7:0]             AWLEN,
  input  wire [2:0]             AWSIZE,
  input  wire [1:0]             AWBURST,
  input  wire                   AWVALID,
  output reg                    AWREADY,

  // Write Data
  input  wire [DATA_WIDTH-1:0]  WDATA,
  input  wire [DATA_WIDTH/8-1:0]WSTRB,
  input  wire                   WLAST,
  input  wire                   WVALID,
  output reg                    WREADY,

  // Write Response
  output reg [ID_WIDTH-1:0]     BID,
  output reg [1:0]              BRESP,
  output reg                    BVALID,
  input  wire                   BREADY,

  // Read Address
  input  wire [ID_WIDTH-1:0]    ARID,
  input  wire [ADDR_WIDTH-1:0]  ARADDR,
  input  wire [7:0]             ARLEN,
  input  wire [2:0]             ARSIZE,
  input  wire [1:0]             ARBURST,
  input  wire                   ARVALID,
  output reg                    ARREADY,

  // Read Data
  output reg [ID_WIDTH-1:0]     RID,
  output reg [DATA_WIDTH-1:0]   RDATA,
  output reg [1:0]              RRESP,
  output reg                    RLAST,
  output reg                    RVALID,
  input  wire                   RREADY
);

  reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  // Write FSM
  reg [ADDR_WIDTH-1:0] waddr;
  reg [7:0] wlen;
  always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn) begin AWREADY<=0; WREADY<=0; BVALID<=0; end
    else begin
      AWREADY<=!AWREADY && AWVALID; // accept once
      if(AWREADY && AWVALID) begin waddr<=AWADDR>>2; wlen<=AWLEN; BID<=AWID; end
      WREADY<=1;
      if(WVALID && WREADY) begin
        mem[waddr]<=WDATA; waddr<=waddr+1; if(WLAST) begin BVALID<=1; BRESP<=2'b00; end
      end
      if(BVALID && BREADY) BVALID<=0;
    end
  end

  // Read FSM
  reg [ADDR_WIDTH-1:0] raddr;
  reg [7:0] rlen;
  always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn) begin ARREADY<=0; RVALID<=0; end
    else begin
      ARREADY<=!ARREADY && ARVALID;
      if(ARREADY && ARVALID) begin raddr<=ARADDR>>2; rlen<=ARLEN; RID<=ARID; end
      if(ARVALID) begin
        RVALID<=1; RDATA<=mem[raddr]; RRESP<=2'b00; RLAST=(rlen==0);
        if(RREADY && RVALID) begin
          raddr<=raddr+1; if(rlen>0) rlen<=rlen-1; else RVALID<=0;
        end
      end
    end
  end

endmodule
📂 axi_interconnect_simple.v
Single-master, single-slave direct pass-through.

verilog
Copy
Edit
module axi_interconnect_simple(
  // Connect master <-> slave (all signals just wires)
);
  // In a 1x1 interconnect, you literally just wire master to slave
  // Example:
  // assign S_AWADDR = M_AWADDR;
  // assign M_AWREADY= S_AWREADY;
endmodule
