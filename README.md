# Coding Assignment 4 — Memory (MEM) and Writeback (WB) Stages

ECE 4300, Fall 2026, Cal Poly Pomona.

Complete the Instruction Memory (MEM) and Writeback (WB) stages of the MIPS pipeline. The Memory stage receives the outputs of the Execute stage, accesses data memory for load and store instructions, determines whether a branch is taken, and passes the required values through the MEM/WB latch. The Writeback stage selects either memory data or the ALU result for writing back to the register file.

## Design Scope and Assumptions

- **In scope:** The Memory stage, data memory, branch decision logic, MEM/WB pipeline latch, and Writeback data selection.
- **Out of scope:** The Fetch, Decode, and Execute stages. Their outputs are supplied as inputs to the `MEMORY` module and `memoryTB.v`.
- **Assumptions:**
  - The design uses 32-bit data and address paths.
  - The writeback control bus uses two bits: `RegWrite` and `MemToReg`.
  - The Memory stage receives `ALUResult`, `ReadData2`, the selected destination register, and the Execute-stage control signals.
  - A branch is taken only when both `Branch` and `Zero` are 1.
  - Data memory contains 256 32-bit words and is initialized from `src/data.txt`.
  - Store operations occur on the rising edge of `clk`.
- **Limitations:**
  - The current data-memory implementation indexes `DMEM` directly with `addr`; it does not shift the byte address right by two.
  - The testbench focuses on the Memory stage because the Writeback stage only selects between memory data and the ALU result.

## Requirements

| Requirement | Description | Verification Method |
|---|---|---|
| REQ-01 | The Memory stage shall instantiate and connect the branch AND gate, data memory, and MEM/WB latch. | Inspection of `Memory.v` |
| REQ-02 | The branch logic shall assert `PCSrc` only when `Branch` and `Zero` are both 1. | `And.v`; branch cases in `memoryTB.v` |
| REQ-03 | Data memory shall read data when `MemRead` is 1. | Memory-read test in `memoryTB.v` |
| REQ-04 | Data memory shall write `WriteData` on a rising clock edge when `MemWrite` is 1. | Memory-write test in `memoryTB.v` |
| REQ-05 | The MEM/WB latch shall capture the writeback controls, read data, ALU result, and destination register. | Inspection of `src/mem_wb.v`; waveform |
| REQ-06 | The `MemToReg` signal shall select memory data for a load instruction and the ALU result for an ALU instruction. | `wb_write_data` in `Memory.v` |
| REQ-07 | The `RegWrite` and `MemToReg` outputs shall be decoded from the two-bit WB control bus. | MEM/WB latch test |
| REQ-08 | The testbench shall verify memory read, memory write, read-back, ALU writeback, and branch behavior. | `memoryTB.v` simulation |

## Architecture

The Memory and Writeback stages are organized as follows:

1. **Branch AND gate:** Combines `Branch` and `Zero` to produce `PCSrc` for the Fetch stage.
2. **Data memory:** Reads from or writes to `DMEM` using the ALU result as the address.
3. **MEM/WB latch:** Captures the memory output, ALU result, destination register, and writeback controls on the rising edge of the clock.
4. **Writeback multiplexer:** Selects memory data for a load instruction or the ALU result for an ALU instruction.

### Data-Path Connections

| Input or signal | Destination | Purpose |
|---|---|---|
| `alu_result` | `data_memory.addr` | Memory address and forwarded ALU result |
| `rdata2out` | `data_memory.write_data` | Data written during a store instruction |
| `memread` | `data_memory.memread` | Enables a memory read |
| `memwrite` | `data_memory.memwrite` | Enables a memory write |
| `branch` | `AND.membranch` | Branch control input |
| `zero` | `AND.zero` | ALU equality result used for branch decisions |
| `wb_ctlout` | `mem_wb.control_wb_in` | Writeback control bus |
| `five_bit_muxout` | `mem_wb.write_reg_in` | Destination-register number |

## Control Signals

| Signal | Width | Description |
|---|---:|---|
| `wb_ctlout` | 2 | Input WB control bus: `{RegWrite, MemToReg}` |
| `MEM_WB_regwrite` | 1 | Enables register-file writeback |
| `MEM_WB_memtoreg` | 1 | Selects memory data instead of the ALU result |
| `branch` | 1 | Indicates a branch instruction |
| `zero` | 1 | Indicates that the ALU comparison result is zero |
| `MEM_PCSrc` | 1 | Branch decision sent to the Fetch stage |
| `memread` | 1 | Enables reading from data memory |
| `memwrite` | 1 | Enables writing to data memory |

### Writeback Control Table

| Instruction type | `RegWrite` | `MemToReg` | `WBControl` | Writeback value |
|---|---:|---:|---:|---|
| Load word (`LW`) | 1 | 1 | `11` | Data memory output |
| ALU/R-type instruction | 1 | 0 | `10` | ALU result |
| Store word (`SW`) | 0 | 0 | `00` | No register write |
| Branch equal (`BEQ`) | 0 | 0 | `00` | No register write |

## Implementation

### Source Code

| File | Description |
|---|---|
| [`Memory.v`](Memory.v) | Top-level Memory and Writeback-stage module; connects the AND gate, data memory, MEM/WB latch, and writeback multiplexer |
| [`src/Mem.v`](src/Mem.v) | 256-word, 32-bit data memory with synchronous writes and conditional reads |
| [`src/mem_wb.v`](src/mem_wb.v) | MEM/WB pipeline latch for WB controls, memory data, ALU result, and destination register |
| [`src/And.v`](src/And.v) | Combines branch and zero signals to generate `PCSrc` |
| [`src/data.txt`](src/data.txt) | Binary initialization values for data memory locations 0 through 5 |
| [`memoryTB.v`](memoryTB.v) | Testbench for the Memory stage and its Writeback outputs |
### Top-Level `MEMORY` Module

The top-level module includes the supporting source files and connects the stage components:

```verilog
`include "src/And.v"
`include "src/Mem.v"
`include "src/mem_wb.v"
```

The final writeback value is selected with:

```verilog
assign wb_write_data = MEM_WB_memtoreg ? read_data : mem_alu_result;
```

When `MEM_WB_memtoreg` is 1, the value read from data memory is sent to Writeback. When it is 0, the ALU result is sent instead.

## Module Descriptions

### `AND`

The `AND` module implements the branch decision:

```verilog
assign PCSrc = membranch & zero;
```

Therefore, `PCSrc` becomes 1 only for a branch instruction whose ALU comparison produced zero.

### `data_memory`

The data-memory module declares `DMEM[0:255]` as 256 32-bit words. Its contents are initialized using:

```verilog
$readmemb("src/data.txt", DMEM);
```

Reads are combinational and return zero when `memread` is 0. Writes occur on the rising edge of `clk` when `memwrite` is 1.

### `mem_wb`

The MEM/WB latch captures its inputs on each positive clock edge:

- `control_wb_in[1]` becomes `regwrite`.
- `control_wb_in[0]` becomes `memtoreg`.
- `read_data_in` becomes `read_data`.
- `alu_result_in` becomes `mem_alu_result`.
- `write_reg_in` becomes `mem_write_reg`.

## Testbench Verification

`memoryTB.v` generates a 10 ns clock period and tests the complete Memory-stage path.

| Test interval | Test | Expected behavior |
|---|---|---|
| 0–10 ns | Memory read | Reads the value at address `4`; WB control is `11` |
| 10–20 ns | Memory write | Writes `32'h12345678` to address `8` on a rising clock edge |
| 20–30 ns | Read-back | Reads the value previously stored at address `8` |
| 30–40 ns | ALU writeback | With WB control `10`, selects the ALU result instead of memory data |
| 40–50 ns | Branch not taken | `Branch = 1`, `Zero = 0`, so `PCSrc = 0` |
| 50–60 ns | Branch taken | `Branch = 1`, `Zero = 1`, so `PCSrc = 1` |
| 60–70 ns | Branch disabled | `Branch = 0`, so `PCSrc = 0` even if the zero flag remains set |

The testbench also creates a VCD waveform file:

```verilog
$dumpfile("memoryTB.vcd");
$dumpvars(0, memoryTB);
```

<img width="1946" height="652" alt="image" src="https://github.com/user-attachments/assets/afe5aae0-dff4-402f-870b-bb194c5eaecd" />

## Compilation and Simulation

From the repository root, compile the top-level module and testbench with Icarus Verilog:

```bash
iverilog -g2012 -o memory_sim \
  Memory.v memoryTB.v \
  src/Mem.v src/mem_wb.v src/And.v
vvp memory_sim
```

To view the generated waveform with GTKWave:

```bash
gtkwave memoryTB.vcd
```

If the simulator cannot locate `src/data.txt`, run the command from the repository root so the relative path in `src/Mem.v` resolves correctly.

## Conclusion

This assignment completes the Memory and Writeback portions of the MIPS pipeline. The Memory stage handles data-memory access and branch decisions, while the MEM/WB latch preserves the control and data values needed by the Writeback stage. The final writeback multiplexer selects either the loaded memory value or the ALU result before the value is sent back to the Decode stage.
