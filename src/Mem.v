module data_memory (
input wire clk,
input wire [31:0] addr,
input wire [31:0] write_data,
input wire memread, memwrite,
output wire [31:0] read_data
);
reg [31:0] DMEM[0:255];
integer i;
initial begin
$readmemb("data.txt",DMEM);
for (i = 0; i < 6; i = i + 1)
$display("\tDMEM[%0d] = %0b", i, DMEM[i]);
end

assign read_data = memread ? DMEM[addr] : 0;

always@(posedge clk) begin
if (memwrite)
DMEM[addr] <= write_data;
end
endmodule
