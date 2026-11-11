module memoryTB();
    reg clk;
    reg [31:0] ALUResult, WriteData;
    reg [4:0] WriteReg;
    reg [1:0] WBControl;
    reg MemWrite, MemRead, Branch, Zero;
    wire [31:0] ReadData, ALUResult_out, WB_WriteData;
    wire [4:0] WriteReg_out;
    wire PCSrc, RegWrite, MemtoReg;

    MEMORY uut (
        .clk(clk),
        .wb_ctlout(WBControl),
        .branch(Branch),
        .memread(MemRead),
        .memwrite(MemWrite),
        .zero(Zero),
        .alu_result(ALUResult),
        .rdata2out(WriteData),
        .five_bit_muxout(WriteReg),
        .MEM_PCSrc(PCSrc),
        .MEM_WB_regwrite(RegWrite),
        .MEM_WB_memtoreg(MemtoReg),
        .read_data(ReadData),
        .mem_alu_result(ALUResult_out),
        .mem_write_reg(WriteReg_out),
        .wb_write_data(WB_WriteData)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("memoryTB.vcd");
        $dumpvars(0, memoryTB);
    end

    initial begin
    ALUResult = 32'h00000004;
    WriteData = 32'h12345678;
    WriteReg = 5'h02;
    WBControl = 2'b11;
    MemWrite = 0;
    MemRead = 1;
    Branch = 0;
    Zero = 0;
    #10;

    ALUResult = 32'h00000008;
    WBControl = 2'b00;
    MemWrite = 1;
    MemRead = 0;
    #10;

    WBControl = 2'b11;
    MemWrite = 0;
    MemRead = 1;
    #10;

    ALUResult = 32'hDEADBEEF;
    WBControl = 2'b10;
    MemRead = 0;
    #10;

    Branch = 1;
    Zero = 0;
    #10;

    Zero = 1;
    #10;

    Branch = 0;
    #10;

    $finish;
end
endmodule
