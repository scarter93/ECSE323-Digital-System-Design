
library ieee;
use ieee.std_logic_1164.all;


entity g48_7_segment_decoder is
	port( code				: in std_logic_vector (3 downto 0);
		  RippleBlank_In	: in std_logic;
		  RippleBlank_Out	: out std_logic;
		  segments			: out std_logic_vector(6 downto 0));
end g48_7_segment_decoder;

architecture implementation of g48_7_segment_decoder is
signal temp : std_logic_vector(6 downto 0);
Begin

with code select temp <=
		"1000000" when "0000",
		"1111001" when "0001",
		"0100100" when "0010",
		"0110000" when "0011",
		"0011001" when "0100",
		"0010010" when "0101",
		"0000010" when "0110",
		"1011000" when "0111",
		"0000000" when "1000",
		"0010000" when "1001",
		"0001000" when "1010",
		"0000011" when "1011",
		"1000110" when "1100",
		"0100001" when "1101",
		"0000110" when "1110",
		"0001110" when "1111";
		
segments <= "1111111" when RippleBlank_In = '1' and code = "0000" else
	temp;
RippleBlank_Out <= '1' when RippleBlank_In = '1' and code = "0000" else
	'0';	
		
end implementation;

