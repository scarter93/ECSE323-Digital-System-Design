-- Music Box
-- Stephen Carter & Greg Rohlicek (C) March 2015
-- stephen.carter@mail.mcgill.ca	greg.rohlicek@mail.mcgill.ca


library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;

entity g48_note_timer is
	port(
		tempo_enable, clk, reset, triplet, pause	: in std_logic;
		note_duration								: in std_logic_vector(2 downto 0);
		TRIGGER										: out std_logic;
		count_out									: out unsigned(8 downto 0));
end g48_note_timer;
	
architecture arch of g48_note_timer is
signal count	: unsigned(8 downto 0);
signal target	: std_logic_vector(8 downto 0);


begin

	
mux : process(note_duration, triplet)
	begin
	case triplet & note_duration is
		when "0000" => target <= "000000011";
		when "0001" => target <= "000000110";
		when "0010" => target <= "000001100";
		when "0011" => target <= "000011000";
		when "0100" => target <= "000110000";
		when "0101" => target <= "001100000";
		when "0110" => target <= "011000000";
		when "0111" => target <= "110000000";
		when "1000" => target <= "000000010";
		when "1001" => target <= "000000100";
		when "1010" => target <= "000001000";
		when "1011" => target <= "000010000";
		when "1100" => target <= "000100000";
		when "1101" => target <= "001000000";
		when "1110" => target <= "010000000";
		when "1111" => target <= "100000000";
	end case;
end process;
count_out <= count;	
counter : process(reset,clk) --process block to count
	begin
	if reset = '0' then
		count <= to_unsigned(0,count'length);
		TRIGGER <= '1';	
	elsif clk = '1' AND clk'event then
		if tempo_enable = '1' then
			count <= count+1;
		end if;
		if count = 1 then
			TRIGGER <= '0';
		elsif count >= unsigned(target)-1 AND tempo_enable = '1' then
			TRIGGER <= '1';
			count <= to_unsigned(0, count'length);
		end if;
		if pause = '1' then		-- pause function that stops the trigger from going high
			TRIGGER	<= '0';
		end if;
	end if;
end process;

end arch;