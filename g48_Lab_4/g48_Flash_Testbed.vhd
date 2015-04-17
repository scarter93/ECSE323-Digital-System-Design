library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;

USE ieee.std_logic_unsigned.all;

entity g48_Flash_Testbed is
GENERIC (
		FLASH_MEMORY_ADDRESS_WIDTH 		: INTEGER := 22;
		FLASH_MEMORY_DATA_WIDTH 		: INTEGER := 8
	);

		port(
		clk_50, rst				: in std_logic;
		trigger, step			: in std_logic;
		note					: in unsigned(3 downto 0);
		octave 					: in unsigned(2 downto 0);
		sample_data				: out std_logic_vector(15 downto 0);
		d0, d1, d2, d3			: out std_logic_vector(6 downto 0);
		
		FL_ADDR					: out std_logic_vector(FLASH_MEMORY_ADDRESS_WIDTH-1 downto 0);
		FL_DQ					: inout std_logic_vector(FLASH_MEMORY_DATA_WIDTH-1 downto 0);
		FL_CE_N					: out std_logic;
		FL_OE_N					: out std_logic;
		FL_WE_N					: out std_logic;
		FL_RST_N				: out std_logic);
end g48_Flash_Testbed;

architecture implementation of g48_Flash_Testbed is

component g48_flash_read_control
PORT
	(	
		clk_50		: IN std_logic; -- clk should be 50MHz 
		rst			: IN std_logic;  
		read_done	: IN std_logic; -- indication from the flash memory that the read operation is complete
		step		: IN std_logic; -- signal from the audio interface indicating that the next sample should be read
		odata		: IN std_logic_vector(7 downto 0); -- output of the flash memory
		trigger 	: IN std_logic; -- trigger = 1 resets the sample address to the beginning
		note 		: IN unsigned(3 downto 0); -- selects the note to be played (within an octave)
		octave 		: IN unsigned(2 downto 0); -- the octave the note should be played at (4 octave range)
		
		flash_address	: OUT unsigned(21 downto 0); -- address for the flash memory read operation
		read_start 		: OUT std_logic; -- request a read operation on the flash memory
		sample_data		: OUT std_logic_vector(15 downto 0); -- a single 16 bit sample value, to be sent to the audio codec chip
		data_size_o 	: OUT unsigned(21 downto 0) -- number of samples in the wave file (for display on the LEDs)
	);
end component;

component Altera_UP_Flash_Memory_IP_Core_Standalone 
	PORT 
	(
		-- Signals to local circuit 
		i_clock 						: IN STD_LOGIC;
		i_reset_n 						: IN STD_LOGIC;
		i_address				 		: IN STD_LOGIC_VECTOR(FLASH_MEMORY_ADDRESS_WIDTH - 1 DOWNTO 0);
		i_data 							: IN STD_LOGIC_VECTOR(FLASH_MEMORY_DATA_WIDTH - 1 DOWNTO 0);
		i_read,	i_write, i_erase 		: IN STD_LOGIC;
		o_data 							: OUT STD_LOGIC_VECTOR(FLASH_MEMORY_DATA_WIDTH - 1 DOWNTO 0);
		o_done 							: OUT STD_LOGIC;
		
		-- Signals to be connected to Flash chip via proper I/O ports
		FL_ADDR 								: OUT 	STD_LOGIC_VECTOR(FLASH_MEMORY_ADDRESS_WIDTH - 1 DOWNTO 0);
		FL_DQ 									: INOUT 	STD_LOGIC_VECTOR(FLASH_MEMORY_DATA_WIDTH - 1 DOWNTO 0);
		FL_CE_N, FL_OE_N, FL_WE_N, FL_RST_N 	: OUT 	STD_LOGIC
	);
end component;

component g48_7_segment_decoder
	port( code				: in std_logic_vector (3 downto 0);
		  RippleBlank_In	: in std_logic;
		  RippleBlank_Out	: out std_logic;
		  segments			: out std_logic_vector(6 downto 0));
end component;

signal R0,R1,R2,R3			: std_logic;
signal odone				: std_logic;
signal odata				: std_logic_vector(FLASH_MEMORY_DATA_WIDTH-1 downto 0);
signal iwrite 				: std_logic;
signal ierase				: std_logic;
signal iread				: std_logic;
signal idata				: std_logic_vector(FLASH_MEMORY_DATA_WIDTH-1 downto 0);
signal iaddress				: unsigned(FLASH_MEMORY_ADDRESS_WIDTH-1 downto 0);
signal iaddress_std			: std_logic_vector(FLASH_MEMORY_ADDRESS_WIDTH-1 downto 0);
signal data_size_o			: unsigned(FLASH_MEMORY_ADDRESS_WIDTH-1 downto 0);
signal data_size_display 	: std_logic_vector(FLASH_MEMORY_ADDRESS_WIDTH-1 downto 0);

begin
idata <= "00000000";
iwrite <= '0';
ierase <= '0';

iaddress_std <= std_logic_vector(iaddress);

readFlash : g48_flash_read_control port map(clk_50, not rst, odone, step, odata, trigger, note, octave, iaddress, iread, sample_data, data_size_o);
			
flashMem : Altera_UP_Flash_Memory_IP_Core_Standalone port map (clk_50, rst, iaddress_std, idata, iread, iwrite, ierase, odata, odone, FL_ADDR, FL_DQ, FL_CE_N, FL_OE_N,FL_WE_N, FL_RST_N);

data_size_display <= std_logic_vector(data_size_o);

S3: g48_7_segment_decoder port map(data_size_display(15 downto 12), '1', R0, d3);
S2: g48_7_segment_decoder port map(data_size_display(11 downto 8), R0, R1, d2);
S1:	g48_7_segment_decoder port map(data_size_display(7 downto 4), R1, R2, d1);
S0: g48_7_segment_decoder port map(data_size_display(3 downto 0), R2, R3, d0);

end implementation;