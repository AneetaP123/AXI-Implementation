`timescale 1ns/1ps

module axi_master_simple #(
  parameter ID_WIDTH   = 4,
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32,
  parameter LEN_WIDTH  = 8 // burst length field (AxLEN)
)(
  input  wire                   ACLK,
  input  wire                   ARESETn,

  // Command interface
  input  wire                   start_i,
  input  wire                   write_i,     // 1=write, 0=read
  input  wire [ADDR_WIDTH-1:0]  addr_i,
  input  wire [DATA_WIDTH-1:0]  wdata_i,
  input  wire [LEN_WIDTH-1:0]   burst_len_i, // beats-1
  output reg  [DATA_WIDTH-1:0]  rdata_o,
  output reg                    done_o,

  // AXI Write Address
  output reg  [ID_WIDTH-1:0]    AWID,
  output reg  [ADDR_WIDTH-1:0]  AWADDR,
  output reg  [7:0]             AWLEN,
  output reg  [2:0]             AWSIZE,
  output reg  [1:0]             AWBURST,
  output reg                    AWVALID,
  input  wire                   AWREADY,

  // AXI Write Data
  output reg  [DATA_WIDTH-1:0]  WDATA,
  output reg  [DATA_WIDTH/8-1:0]WSTRB,
  output reg                    WLAST,
  output reg                    WVALID,
  input  wire                   WREADY,

  // AXI Write Response
  input  wire [ID_WIDTH-1:0]    BID,
  input  wire [1:0]             BRESP,
  input  wire                   BVALID,
  output reg                    BREADY,

  // AXI Read Address
  output reg  [ID_WIDTH-1:0]    ARID,
  output reg  [ADDR_WIDTH-1:0]  ARADDR,
  output reg  [7:0]             ARLEN,
  output reg  [2:0]             ARSIZE,
  output reg  [1:0]             ARBURST,
  output reg                    ARVALID,
  input  wire                   ARREADY,

  // AXI Read Data
  input  wire [ID_WIDTH-1:0]    RID,
  input  wire [DATA_WIDTH-1:0]  RDATA,
  input  wire [1:0]             RRESP,
  input  wire                   RLAST,
  input  wire                   RVALID,
  output reg                    RREADY
);

  // Simple FSM (one txn at a time)
  localparam S_IDLE = 0, S_AW = 1, S_W = 2, S_B = 3, S_AR = 4, S_R = 5, S_DONE = 6;
  reg [2:0] state, nstate;

  // Burst counters
  reg [7:0] wcnt, rcnt;

  always @(*) begin
    // defaults
    AWVALID=0; WVALID=0; WLAST=0; BREADY=0;
    ARVALID=0; RREADY=0; done_o=0;
    nstate=state;
    case(state)
      S_IDLE: if(start_i) nstate= write_i?S_AW:S_AR;
      S_AW:   begin AWVALID=1; if(AWREADY) nstate=S_W; end
      S_W:    begin WVALID=1; WLAST=(wcnt==AWLEN); if(WREADY && WLAST) nstate=S_B; end
      S_B:    begin BREADY=1; if(BVALID) nstate=S_DONE; end
      S_AR:   begin ARVALID=1; if(ARREADY) nstate=S_R; end
      S_R:    begin RREADY=1; if(RVALID && RLAST) nstate=S_DONE; end
      S_DONE: begin done_o=1; nstate=S_IDLE; end
    endcase
  end

  always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn) begin
      state<=S_IDLE; wcnt<=0; rcnt<=0;
    end else begin
      state<=nstate;
      if(state==S_IDLE && start_i) begin
        AWADDR<=addr_i; ARADDR<=addr_i;
        AWLEN<=burst_len_i; ARLEN<=burst_len_i;
        AWSIZE<=3'd2; ARSIZE<=3'd2; // 4B beats
        AWBURST<=2'b01; ARBURST<=2'b01; // INCR
        AWID<=0; ARID<=0;
        wcnt<=0; rcnt<=0;
      end
      if(state==S_W && WREADY) begin
        WDATA<=wdata_i + wcnt; // pattern
        WSTRB<=4'hF;
        wcnt<=wcnt+1;
      end
      if(state==S_R && RVALID) begin
        rdata_o<=RDATA; rcnt<=rcnt+1; end
    end
  end
endmodule
