------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
------------------------------------------------------------------------
entity test_cpu is
end test_cpu;
------------------------------------------------------------------------
architecture behavioral of test_cpu is 
 
type sig_in_t is
record
	--clk : STD_LOGIC;
	din : STD_LOGIC_VECTOR(11 downto 0);
	mem_valid : STD_LOGIC;
	--en_and : STD_LOGIC;
end record;
 
type sig_out_t is
record
	dout : STD_LOGIC_VECTOR(11 downto 0);
	addr : STD_LOGIC_VECTOR(11 downto 0);
	mem_read : STD_LOGIC;
	mem_write : STD_LOGIC;
	skip : STD_LOGIC;
end record;
 
signal sin : sig_in_t := (din => (others => '0'), mem_valid => '0');
signal sout : sig_out_t;

-- Component Declaration for the Unit Under Test (UUT)
component cpu
    Port( clk : in  STD_LOGIC;
	  din : in STD_LOGIC_VECTOR(11 downto 0);
	  dout : out STD_LOGIC_VECTOR(11 downto 0);
	  addr : out STD_LOGIC_VECTOR(11 downto 0);
	  mem_read : out STD_LOGIC;
	  mem_write : out STD_LOGIC;
	  mem_valid : in STD_LOGIC;
	  en_and : in  STD_LOGIC;
	  skip   : out STD_LOGIC
    );
end component;


--Inputs
signal clk : STD_LOGIC := '0';
signal din : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
signal mem_valid : STD_LOGIC := '0';
signal en_and : STD_LOGIC := '0';

--Outputs
signal dout : STD_LOGIC_VECTOR(11 downto 0);
signal addr : STD_LOGIC_VECTOR(11 downto 0);
signal mem_read : STD_LOGIC;
signal mem_write : STD_LOGIC;
signal skip : STD_LOGIC;

-- Clock period definitions
constant clk_period : TIME := 10 ns;
 
procedure instr( constant idx : in integer;
		 constant expected : in STD_LOGIC_VECTOR(11 downto 0);
		 constant val : in STD_LOGIC_VECTOR(11 downto 0);
		 signal o : out sig_in_t;
		 signal i : in sig_out_t
) is
begin
	-- Read instruction
	wait for clk_period*4;
	assert i.mem_read = '1'
	report "(" & INTEGER'image(idx) & ")CPU Not reading instruction"
	severity failure;
	assert i.addr = expected
	report "(" & INTEGER'image(idx) & ")Incorrect PC address"
	severity failure;

	-- Set instruction
	o.din <= val;
	o.mem_valid <= '1';
	wait for clk_period;
	o.mem_valid <= '0';
	assert i.mem_read = '0'
	report "(" & INTEGER'image(idx) & ")Read not finished"
	severity failure;
end instr;

procedure read( constant idx : in integer;
		constant expected : in STD_LOGIC_VECTOR(11 downto 0);
		constant val : in STD_LOGIC_VECTOR(11 downto 0);
		signal o : out sig_in_t;
		signal i : in sig_out_t
) is
begin
	--wait until rising_edge(clk) and mem_read = '1'
	wait for clk_period*4;
	assert i.mem_read = '1'
	report "(" & INTEGER'image(idx) & ")Not reading memory"
	severity failure;
	assert i.mem_write = '0'
	report "(" & INTEGER'image(idx) & ")Incorrectly writing memory"
	severity failure;
	assert i.addr = expected
	report "(" & INTEGER'image(idx) & ")Incorrect read address"
	severity failure;
	o.din <= val;
	o.mem_valid <= '1';
	wait for clk_period;
	o.mem_valid <= '0';
end read;

procedure write( constant idx : in integer;
		 constant expected : in STD_LOGIC_VECTOR(11 downto 0);
		 constant val : in STD_LOGIC_VECTOR(11 downto 0);
		 signal o : out sig_in_t;
		 signal i : in sig_out_t
) is
begin
	wait for clk_period*4;
	assert i.mem_read = '0'
	report "(" & INTEGER'image(idx) & ")Incorrectly reading memory"
	severity failure;
	assert i.mem_write = '1'
	report "(" & INTEGER'image(idx) & ")Not writing memory"
	severity failure;
	assert i.addr = expected
	report "(" & INTEGER'image(idx) & ")Incorrect write address"
	severity failure;
	assert i.dout = val
	report "(" & INTEGER'image(idx) & ")Storing wrong value"
	severity failure;
	o.mem_valid <= '1';
	wait for clk_period;
	o.mem_valid <= '0';
end write;

begin
 
	-- Instantiate the Unit Under Test (UUT)
	uut: cpu Port Map (
		clk => clk,
		din => din,
		dout => dout,
		addr => addr,
		mem_read => mem_read,
		mem_write => mem_write,
		mem_valid => mem_valid,
		en_and => en_and,
		skip => skip
        );

	-- Clock process definitions
	clk_process :process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;


	-- Stimulus process
	stim_proc: process
	begin		
		-- hold reset state for 100 ns.
		wait for 100 ns;	

		wait for clk_period*10;

		--    Idx  Address         Value
		instr(1,  "000000000000", "001001010000", sin, sout); -- TAD Z 101 0000
		read (1,  "000001010000", "000000011010", sin, sout); -- Read 00032 (26)
		instr(2,  "000000000001", "101101010001", sin, sout); -- JMP IZ 101 0001
		read (2,  "000001010001", "111000000000", sin, sout); -- Read 07000
		instr(3,  "111000000000", "001010000011", sin, sout); -- TAD 000 0011
		read (3,  "111000000011", "000000001110", sin, sout); -- Read 00016 (14)
		instr(4,  "111000000001", "011000001000", sin, sout); -- DCA Z 000 1000
		write(4,  "000000001000", "000000101000", sin, sout); -- Write 00050 (40)
		instr(5,  "111000000010", "011010001011", sin, sout); -- DCA 000 1011
		write(5,  "111000001011", "000000000000", sin, sout); -- Write 00000 (0)
		instr(6,  "111000000011", "010110010010", sin, sout); -- ISZ I 001 0010
		read (6,  "111000010010", "100100110110", sin, sout); -- Read 04466
		read (6,  "100100110110", "111111111110", sin, sout); -- Read 07776
		write(6,  "100100110110", "111111111111", sin, sout); -- Write 07777
		instr(7,  "111000000100", "010110010010", sin, sout); -- ISZ I 001 0010
		read (7,  "111000010010", "100100110110", sin, sout); -- Read 04466
		read (7,  "100100110110", "111111111111", sin, sout); -- Read 07777
		write(7,  "100100110110", "000000000000", sin, sout); -- Write 00000
		instr(8,  "111000000110", "001010011100", sin, sout); -- TAD 001 1100
		read (8,  "111000011100", "100010011001", sin, sout); -- Read 04231 (2245)
		instr(9,  "111000000111", "100000000101", sin, sout); -- JMS Z 000 0101
		write(9,  "000000000101", "111000001000", sin, sout); -- Write 07010
		instr(10, "000000000110", "000010001101", sin, sout); -- AND 000 1101
		read (10, "000000001101", "000000001111", sin, sout); -- Read 00017
		instr(11, "000000000111", "011010001011", sin, sout); -- DCA 000 1011
		write(11, "000000001011", "000000001001", sin, sout); -- Write 00011 (9)
		instr(12, "000000001000", "111011010111", sin, sout); -- CLA CLL CML RTL IAC
		instr(13, "000000001001", "011000010000", sin, sout); -- DCA 001 0000
		write(13, "000000010000", "000000000110", sin, sout); -- Write 00011 (9)

		wait;
	end process;

	--clk <= sin.clk;
	din <= sin.din;
	mem_valid <= sin.mem_valid;
	--en_and <= sin.en_and;
 
	sout.dout <= dout;
	sout.addr <= addr;
	sout.mem_read <= mem_read;
	sout.mem_write <= mem_write;
	sout.skip <= skip;
end behavioral;
