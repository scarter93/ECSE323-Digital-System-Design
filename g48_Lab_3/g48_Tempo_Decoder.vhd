-- Tempo Decoder
-- Stephen Carter and Greg Rohlicek
-- W2015 DSD

library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;

entity g48_tempo_decoder is
	port(
		clk		 	   : in std_logic;
		bpm 	 	   : in std_logic_vector(7 downto 0);
		BCD1,BCD2,BCD3 : out std_logic_vector(3 downto 0));
end g48_tempo_decoder;

architecture arch of g48_tempo_decoder is
signal bpm_offset : std_logic_vector(11 downto 0);

begin

offset_table : lpm_rom -- use the altera rom library macrocell
GENERIC MAP(
lpm_widthad => 8, -- sets the width of the ROM address bus
lpm_numwords => 256, -- sets the words stored in the ROM
lpm_outdata => "UNREGISTERED", -- no register on the output
lpm_address_control => "REGISTERED", -- register on the input
lpm_file => "g48_bpm_offset.mif", -- the ascii file containing the ROM data
lpm_width => 12) -- the width of the word stored in each ROM location
PORT MAP(inclock => clk, address => bpm, q => bpm_offset);

BCD1 <= bpm_offset(11 downto 8); -- pad zeros
BCD2 <= bpm_offset(7 downto 4);
BCD3 <= bpm_offset(3 downto 0);

end arch;
