library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;

entity g48_Tempo is
	port(	bpm						: in std_logic_vector(7 downto 0);
			clk, reset, enable		: in std_logic;
			beat					: out std_logic;
			tempo_enable			: out std_logic;
			count2					: out std_logic_vector(4 downto 0));
end g48_Tempo;

Architecture implementation of g48_Tempo is
Signal 	data, q									: std_logic_vector(21 downto 0);
Signal	sload, enout, temp_beat, x, temp_x		: std_logic;
Signal	count									: std_logic_vector(4 downto 0);
attribute keep : boolean;
attribute keep of count : signal is true;
begin
		
tempo_table : lpm_rom -- use the altera rom library macrocell
GENERIC MAP(
lpm_widthad => 8, -- sets the width of the ROM address bus
lpm_numwords => 256, -- sets the words stored in the ROM
lpm_outdata => "UNREGISTERED", -- no register on the output
lpm_address_control => "REGISTERED", -- register on the input
lpm_file => "g48_tempo.mif", -- the ascii file containing the ROM data
lpm_width => 22) -- the width of the word stored in each ROM location
PORT MAP(inclock => clk, address => bpm, q => data);


lpm_counter_component : lpm_counter
GENERIC MAP (
		lpm_direction => "DOWN",
		lpm_port_updown => "PORT_UNUSED",
		lpm_type => "LPM_COUNTER",
		lpm_width => 22)
PORT MAP (
		sload => sload,
		aclr => not reset,
		clock => clk,
		data => data,
		cnt_en => enable,
		q => q);

with q select enout <=
	'1' when "0000000000000000000000",
	'0' when others;

sload <= enout and enable;
tempo_enable <= enout;

lpm_counter_component2 : lpm_counter
GENERIC MAP (
		lpm_direction => "DOWN",
		lpm_port_updown => "PORT_UNUSED",
		lpm_type => "LPM_COUNTER",
		lpm_width => 5)
PORT MAP (
		sload => x,
		aclr => not reset,
		clock => clk,
		data => "11000",
		cnt_en => enout,
		q => count);
		
with count select temp_x <=
	'1' when "00000",
	'0' when others;
	
x <= enout and temp_x;

beat <= count(4);
count2 <= count;

end implementation;
