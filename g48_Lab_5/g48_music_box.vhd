-- Music Box
-- Stephen Carter & Greg Rohlicek (C) April 2015
-- stephen.carter@mail.mcgill.ca	greg.rohlicek@mail.mcgill.ca

library ieee;
library lpm;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;

entity g48_music_box is
GENERIC (
		FLASH_MEMORY_ADDRESS_WIDTH 		: INTEGER := 22;
		FLASH_MEMORY_DATA_WIDTH 		: INTEGER := 8
	);

	port(	start, stop, pause, looping				: in std_logic;	--start/stop/ active low
			reset, clk_50, init, slct, octave_i		: in std_logic;	--reset active low
			bpm										: in std_logic_vector(7 downto 0);	--input to determine bpm
			d0,d1,d2,d3								: out std_logic_vector(6 downto 0); --output for 7 segment display
			beat									: out std_logic; --used to display beat on LED
			
			AUD_MCLK 								:OUT std_logic; -- codec master clock input
			AUD_BCLK 								:OUT std_logic; -- digital audio bit clock
			AUD_DACDAT 								:OUT std_logic; -- DAC data lines
			AUD_DACLRCK 							:OUT std_logic; -- DAC data left/right select
			I2C_SDAT 								:OUT std_logic; -- serial interface data line
			I2C_SCLK 								:OUT std_logic;  -- serial interface clock
			FL_ADDR									: out std_logic_vector(FLASH_MEMORY_ADDRESS_WIDTH-1 downto 0);
			FL_DQ									: inout std_logic_vector(FLASH_MEMORY_DATA_WIDTH-1 downto 0);
			FL_CE_N									: out std_logic;
			FL_OE_N									: out std_logic;
			FL_WE_N									: out std_logic;
			FL_RST_N								: out std_logic
			);
	
end g48_music_box;


architecture implementation of g48_music_box is
signal state						: integer range 0 to 3 := 0;	--state value for FSM
signal addr_rom						: unsigned(7 downto 0);	--address for song rom
signal music						: std_logic_vector(15 downto 0); --the output of lpm rom for the selected song
signal song1						: std_logic_vector(15 downto 0); --song1 of lpm rom 
signal song2						: std_logic_vector(15 downto 0); --song2 of lpm rom
signal music_play					: std_logic;	-- the MSB of music to determine if song is playing or not
signal data_size_o					: unsigned(21 downto 0);	--data output from the audio flash control circuit
signal tempo_e						: std_logic;	-- tempo enabled signal
signal trigger						: std_logic;	-- trigger for FSM
signal true_octave					: unsigned(2 downto 0);	-- signal for the actual octave to be played
signal w_en							: std_logic := '0';		-- signal for checking if to activate trigger
signal s_del						: std_logic;			-- signal to hold previous select signal

component g48_note_timer	
port(
		tempo_enable, clk, reset, triplet, pause	: in std_logic;
		note_duration								: in std_logic_vector(2 downto 0);
		TRIGGER										: out std_logic;
		count_out									: out unsigned(8 downto 0)
	);
end component;

component g48_Tempo			
	port(	bpm						: in std_logic_vector(7 downto 0);
			clk, reset, enable		: in std_logic;
			beat					: out std_logic;
			tempo_enable			: out std_logic;
			count2					: out std_logic_vector(4 downto 0)
		);
end component;

component g48_audio_flash_control	
port(
		clk_50, rst, init		: in std_logic;
		trigger					: in std_logic;
		loudness				: in signed(3 downto 0);
		note					: in unsigned(3 downto 0);
		octave 					: in unsigned(2 downto 0);
		data_size_o				: out unsigned(21 downto 0);
		
		FL_ADDR					: out std_logic_vector(FLASH_MEMORY_ADDRESS_WIDTH-1 downto 0);
		FL_DQ					: inout std_logic_vector(FLASH_MEMORY_DATA_WIDTH-1 downto 0);
		FL_CE_N					: out std_logic;
		FL_OE_N					: out std_logic;
		FL_WE_N					: out std_logic;
		FL_RST_N				: out std_logic;
		
		AUD_MCLK				: out std_logic;
		AUD_BCLK				: out std_logic;
		AUD_DACDAT				: out std_logic;
		AUD_DACLRCK				: out std_logic;
		I2C_SDAT				: out std_logic;
		I2C_SCLK				: out std_logic
	);
end component;

component g48_7_segment_decoder	-- decodes signals for 7 segment display
port( 
		code				: in std_logic_vector (3 downto 0);
		RippleBlank_In		: in std_logic;
		RippleBlank_Out		: out std_logic;
		segments			: out std_logic_vector(6 downto 0)
	);
end component;

begin

song_table1 : lpm_rom -- use the altera rom library macrocell
	GENERIC MAP(
	lpm_widthad => 8, -- sets the width of the ROM address bus
	lpm_numwords => 256, -- sets the words stored in the ROM
	lpm_outdata => "UNREGISTERED", -- no register on the output
	lpm_address_control => "REGISTERED", -- register on the input
	lpm_file => "g48_demo_song.mif", -- the ascii file containing the ROM data
	lpm_width => 16) -- the width of the word stored in each ROM location
	PORT MAP(inclock => clk_50, address => std_logic_vector(addr_rom), q => song1);
	
song_table2 : lpm_rom -- use the altera rom library macrocell
	GENERIC MAP(
	lpm_widthad => 8, -- sets the width of the ROM address bus
	lpm_numwords => 256, -- sets the words stored in the ROM
	lpm_outdata => "UNREGISTERED", -- no register on the output
	lpm_address_control => "REGISTERED", -- register on the input
	lpm_file => "g48_mary_lamb.mif", -- the ascii file containing the ROM data
	lpm_width => 16) -- the width of the word stored in each ROM location
	PORT MAP(inclock => clk_50, address => std_logic_vector(addr_rom), q => song2);

choose_song : process (reset, clk_50)	--process to get correct song based on switch input
	Begin
		if clk_50 = '1' and clk_50'event then
			if slct = '1' then
				music <= song2;
			else
				music <= song1;
			end if;
		end if;
end process;

music_play <= music(15);

choose_octave : process (reset, clk_50)	--process to get correct octave based on switch input

	Begin
		if clk_50 = '1' and clk_50'event then
			if octave_i = '1' then
				true_octave <=  unsigned(music(6 downto 4)) - 1;
			else
				true_octave <= unsigned(music(6 downto 4));
			end if;
		end if;
end process;

get_tempo : g48_Tempo	-- takes in a bpm and returns tempo enable to signal the tempo
port map(	bpm,
			clk_50,
			reset,
			'1',
			beat,
			tempo_e,
			open
		);

note_time : g48_note_timer -- compontent to activate trigger, and signal the note to play 
port map(	tempo_e,
			clk_50,
			reset,
			music(10),
			pause,
			music(9 downto 7),
			trigger,
			open
		);

flash_control : g48_audio_flash_control --audio control system to play guitar strum sound
port map( 	clk_50,
			reset, 
			init, 
			trigger and w_en, 
			signed(music(14 downto 11)), 
			unsigned(music(3 downto 0)), 
			true_octave, 
			data_size_o,
			FL_ADDR,
			FL_DQ,
			FL_CE_N,
			FL_OE_N,
			FL_WE_N,
			FL_RST_N,
			AUD_MCLK,
			AUD_BCLK,
			AUD_DACDAT,
			AUD_DACLRCK,
			I2C_SDAT,
			I2C_SCLK
		);

S0 : g48_7_segment_decoder -- for notenumber display
port map(	music(3 downto 0),
			'1',
			open,
			d0
		);
		
S1 : g48_7_segment_decoder -- for octave display
port map(	'0' & std_logic_vector(true_octave),
			'1',
			open,
			d1
		);

S2 : g48_7_segment_decoder -- for note duration display
port map(	'0' & std_logic_vector(music(9 downto 7)),
			'1',
			open,
			d2
		);
		
S3 : g48_7_segment_decoder -- for volume display
port map(	std_logic_vector(music(14 downto 11)),
			'1',
			open,
			d3
		);

play_music : process (reset, clk_50)

	Begin
		if reset = '0' then	--check to see if reset is enabled
			w_en <= '0';
			state <= 0;
			addr_rom <= to_unsigned(0,addr_rom'length);
		elsif clk_50 = '1' AND clk_50' event then
			if (slct = '1' and s_del = '0') or (slct = '0' and s_del = '1') then --at clock event check to see if user changed the song
				addr_rom <= to_unsigned(0,addr_rom'length);
			end if;
			s_del <= slct;
			if stop = '0' then		-- check to see if user stopped the song
				w_en <= '0';
				state <= 0;
				addr_rom <= to_unsigned(0,addr_rom'length);
			else
				case state is
				when 0 => --wait for start to be pressed
					if start = '0' then
						w_en <= '0';
						addr_rom <= to_unsigned(0,addr_rom'length);
						state <= 1;
					end if;
				when 1 => --wait for start to be released
					if start = '1' then
						w_en <= '1';
						addr_rom <= to_unsigned(0,addr_rom'length);
						state <= 2;
					end if;
				when 2 => --wait for trigger to go low
					if trigger = '0' then
						if (addr_rom >= 255 or music_play = '1') and looping = '0' then	--check to see if looping or not
							w_en <= '0';
							state <= 0;
						elsif (addr_rom >= 255 or music_play = '1') and looping = '1' then --if song is looping
							state <= 1;
						else		--proceed to next note if above is false
							state <= 3;
						end if;
					end if;
				when 3 => --wait for trigger to go high
					if trigger = '1' then
						addr_rom <= addr_rom + 1;
						state <= 2;
					end if;
				end case;
			end if;
		end if;
end process;

end implementation;