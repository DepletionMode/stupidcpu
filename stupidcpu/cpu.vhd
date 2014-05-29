library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu is
	port(
			clk: 			in std_logic;
			n_srst:		in std_logic;
			n_hrst:		in std_logic;
			halt:			out std_logic; -- high on catastrophic failure
			
			-- bus
			spi_ss:		out std_logic_vector(3 downto 0);
			spi_sck:		out std_logic;
			spi_mosi:	out std_logic;
			spi_miso:	in std_logic
		);
end entity;

-- instructions
-- 1 bit - alu  indicator
-- 4 bit - instruction
-- 1 bit - immediate indicator
-- 1 bit - register 1
-- 1 bit - register 2 (ignored if imm)

-- 10000 NOP
-- 10001 MOV
-- 10010 PUSH
-- 10011 POP
-- 10100 LD
-- 10101 ST

architecture behavioural of cpu is
signal r0, r1:	unsigned(7 downto 0);
signal pc, sp:	unsigned(15 downto 0) := x"0000";
signal f: unsigned(3 downto 0) := x"0";
signal ins: unsigned(7 downto 0);
signal imm_value: unsigned(7 downto 0);
signal addr_value: unsigned(15 downto 0);
type stages is (fetch, decode, execute, writeback, reset, fetch_imm, fetch_addr);
signal stage, stage_nxt: stages;-- <= 'reset';
signal data: unsigned(7 downto 0) := x"ff";
-- alu
signal			alu_en:		std_logic;
signal			alu_ra:		unsigned(7 downto 0);
signal			alu_rb:		unsigned(7 downto 0);
signal			alu_res:		unsigned(7 downto 0);
signal			alu_zf:		unsigned(0 downto 0);
component alu
   port(
			n_en:		in std_logic;
			op:		in std_logic_vector(3 downto 0);
			a, b:		in unsigned(7 downto 0);
			r:			out unsigned(7 downto 0);
			zf:		out unsigned(0 downto 0)
		);
end component;

-- mmu
signal 			mem_addr:	std_logic_vector(15 downto 0);
signal 			mem_data:	std_logic_vector(7 downto 0);
signal 			mem_en:		std_logic;
signal 			mem_wr:		std_logic;
component mmu
	port(
			clk:		in std_logic;
			
			addr:		in std_logic_vector(15 downto 0);
			data:		inout std_logic_vector(7 downto 0);
			n_en:		in std_logic;
			n_wr:		in std_logic;	
			
			spi_ss:			out std_logic_vector(3 downto 0);
			spi_sck:			out std_logic;
			spi_mosi:		out std_logic;
			spi_miso:		in std_logic
		);
end component;	
begin
alu1: alu port map(alu_en, std_logic_vector(ins(6 downto 3)), alu_ra, alu_rb, alu_res, alu_zf);
mmu1: mmu port map(clk, mem_addr, mem_data, mem_en, mem_wr, spi_ss, spi_sck, spi_mosi, spi_miso);

f <= "000" & alu_zf;

process(clk,stage)
variable imm_fetched: bit;
variable addr1_fetched: bit;
variable addr2_fetched: bit;
variable rtmp, rwb: unsigned(7 downto 0);
variable ra, rb: unsigned(7 downto 0);
variable sp_next: unsigned(15 downto 0);
begin
--data <= unsigned(mem_data);

if rising_edge(clk) then
	--data <= unsigned(mem_data);
	mem_data <= std_logic_vector(rwb);
end if;
	
case stage is
	when fetch =>
		mem_addr <= std_logic_vector(pc);
		ins <= data;
		mem_wr <= '1';
		mem_en <= '0';
		stage_nxt <= decode;
	when fetch_imm =>
		imm_value <= data;
		mem_en <= '0';
		imm_fetched := '1';
		stage_nxt <= decode;
	when fetch_addr =>
		mem_en <= '0';
		if addr1_fetched = '0' then
			addr_value <= data & x"00";
			addr1_fetched := '1';
			pc <= pc + 1;
			stage_nxt <= fetch_addr;
		else
			addr_value <= addr_value(15 downto 8) & data;
			addr2_fetched := '1';
			stage_nxt <= decode;
		end if;
	when decode =>
		pc <= pc + 1;
		mem_en <= '1';
		
		-- fetch imm
		if(ins(2) = '1' and imm_fetched = '0') then
			-- fetch imm
			stage_nxt <= fetch_imm;
		else
			-- handle addressed instructions			
			case ins(6 downto 3) is
				when "0101" => -- ST
					if(addr2_fetched = '0') then
						stage_nxt <= fetch_addr;
					end if;
				when others => NULL;
			end case;
		
			-- register decode
			if(ins(0) = '0') then ra := r0; else ra := r1; end if;
			if(ins(1) = '0') then rb := r0; else ra := r1; end if;
			--ra := r0 when ins(0)='0' else r1;
			
			-- alu setup
			if(ins(7) = '0') then
				alu_ra <= ra;
				if(imm_fetched = '1') then alu_rb <= imm_value; else alu_rb <= rb; end if;
			end if;
			stage_nxt <= execute;
		end if;
	when execute =>		
		-- exec alu
		if(ins(7) = '0') then alu_en <= '0'; end if;
		
		if(imm_fetched = '1') then
			rtmp := imm_value;
		else
			rtmp := rb;
		end if;
		
		case ins(6 downto 3) is
			when "0010" => -- PUSH
				mem_addr <= std_logic_vector(sp);
				sp_next := sp + 1;
			when "0101" => -- ST
				mem_addr <= std_logic_vector(addr_value);
			when others => NULL;
		end case;
		
		stage_nxt <= writeback;
	when writeback =>
		-- get result from alu
		if(ins(7)='0') then
				alu_en <= '1';
				rtmp := alu_res;
		end if;
		
		case ins(6 downto 3) is
			when "0001" => -- MOV
				-- write back into register
				if(ins(0) = '0') then
					r0 <= rtmp;
				else
					r1 <= rtmp;
				end if;
			when "0010" => -- PUSH
			when "0101" => -- ST
				-- write back into memory
				mem_wr <= '0';
				mem_en <= '0';
				rwb := rtmp;
				--mem_data <= std_logic_vector(rtmp);
			when others => NULL;
		end case;
		
		-- make sp change if necessary
		sp <= sp_next;
		
		-- clear up
		imm_fetched := '0';
		addr1_fetched := '0';
		addr2_fetched := '0';
		
		stage_nxt <= fetch;
	when reset =>
		r0 <= x"00";
		r1 <= x"00";
		sp <= x"0100";
		sp_next := x"0100";
		pc <= x"1000";
		stage_nxt <= fetch;
	when others =>
		stage_nxt <= reset;
	end case;
end process;

process(clk)
begin
	if(n_hrst = '0') then
		stage <= reset;
	else
		stage <= stage_nxt;
	end if;
end process;

end architecture;