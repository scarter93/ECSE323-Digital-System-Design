library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;

entity g48_note_timer_testbed is
	port(
		bpm									: in std_logic_vector(7 downto 0);
		clk, reset, triplet					: in std_logic;
		note_duration						: in std_logic_vector(2 downto 0);
		TRIGGER								: out std_logic;
		count_out							: out unsigned(8 downto 0));
end g48_note_timer_testbed;

architecture arch of g48_note_timer_testbed is
signal beat 		: std_logic;
signal count		: std_logic_vector(4 downto 0);
signal enable_tempo : std_logic;
	
component g48_Tempo
	port(	bpm						: in std_logic_vector(7 downto 0);
			clk, reset, enable		: in std_logic;
			beat					: out std_logic;
			tempo_enable			: out std_logic;
			count2					: out std_logic_vector(4 downto 0)); 
end component;

component g48_note_timer
	port(
		tempo_enable, clk, reset, triplet	: in std_logic;
		note_duration						: in std_logic_vector(2 downto 0);
		TRIGGER								: out std_logic;
		count_out							: out unsigned(8 downto 0));
end component;


Begin
	tempo: g48_Tempo port map(bpm,clk,'1','1',beat,enable_tempo,count);
	timer: g48_note_timer port map(enable_tempo, clk, not reset, triplet,note_duration,TRIGGER,count_out);

end arch;