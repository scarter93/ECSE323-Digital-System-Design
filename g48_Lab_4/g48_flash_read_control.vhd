-- g00_flash_read_control
--
-- This module implements the interface to the Flash memory chip located on the Altera DE1 board.
-- It assumes that a single 16-bit mono 48KHz WAV file is stored in the flash memory, starting at address 0.
-- It plays back the 16-bit audio sample data at a user selectable speed (set by the note and octave inputs).
--
-- Version 1.0
--
-- Designer: James Clark (james.j.clark@mcgill.ca)
-- March 6 2015
--
-- ** EACH GROUP SHOULD ADD THEIR INFORMATION HERE, INDICATING **
-- ** THE DATE AND THE NATURE OF THE CHANGES MADE **

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY g48_flash_read_control IS
	PORT
	(	
		clk_50 : IN std_logic; -- clk should be 50MHz 
		rst : IN std_logic;  
		read_done : IN std_logic; -- indication from the flash memory that the read operation is complete
		step : IN std_logic; -- signal from the audio interface indicating that the next sample should be read
		odata : IN std_logic_vector(7 downto 0); -- output of the flash memory
		trigger : IN std_logic; -- trigger = 1 resets the sample address to the beginning
		note : IN unsigned(3 downto 0); -- selects the note to be played (within an octave)
		octave : IN unsigned(2 downto 0); -- the octave the note should be played at (4 octave range)
		flash_address : OUT unsigned(21 downto 0); -- address for the flash memory read operation
		read_start : OUT std_logic; -- request a read operation on the flash memory
		sample_data : OUT std_logic_vector(15 downto 0); -- a single 16 bit sample value, to be sent to the audio codec chip
		data_size_o : OUT unsigned(21 downto 0) -- number of samples in the wave file (for display on the LEDs)
	);
END g48_flash_read_control;

ARCHITECTURE a OF g48_flash_read_control IS
signal iread_start : std_logic;
signal init : std_logic;
signal state : integer range 0 to 10;
signal iflash_address  : unsigned(21 downto 0);
signal sample_data_end : unsigned(21 downto 0);
signal sample_address : unsigned(44 downto 0);
signal data_size : unsigned(21 downto 0); -- sample data size in bytes (4 bytes in total, but only the 22 lsbits are used)
signal frequency, fmax : integer range 0 to 1048575; -- 20 bit integer

constant data_start_address : unsigned(21 downto 0) := "0000000000000000101100"; -- beginning of sample data in wavefile (at address 44 = x"2C")
constant size_address  : unsigned(21 downto 0) := "0000000000000000101000"; -- address for sample size data (4 bytes starting at address 40 = x"28")

begin
	
	flash_address <= iflash_address;
	data_size_o <= data_size;
	sample_data_end <= data_size + 44; -- sample data starts 44 bytes in

--------------------------------------------------------------------------------------------------------------------------------------------------
-- This process block generates the address for the next sample to be read.
-- The audio sampling rate is taken as 48KHz.
-- A 45-bit counter is used to generate the sample address. This counter is incremented by 'frequency' on each cycle of the 50MHz clock.
-- Counting will go faster when 'frequency' is higher.
-- The 22 most significant bits of the count is used as the address to be sent to the Flash Memory holding the audio samples.
-- This means that the counter must count 2^24 (45 - 22 + 1) times in order to increment the flash memory address by 2 (each sample is 2 bytes long).
-- There are 50,000,000/48000 = 1041.67 clock cycles for each audio sample. Thus if the counter is incremented by 2^24/1041.67 = 16106 on each clock cycle
-- then the flash memory address will increment by 2 every audio sample period. This will give the natural playback of the audio sample.
-- If frequency is set to 2 times 16106 = 32212, then the audio sample will be played back twice as fast, giving a pitch that is one octave higher.
-- The counter is reset when the Flash memory address reaches the end of the sample data. 
	
address_counter : process(rst, clk_50) -- updates the address counter for reading the audio samples from the flash memory
	begin
		if rst = '1' then
			sample_address <= data_start_address & "00000000000000000000000"; -- sample address has 23 more bits than the flash memory address
			init <= '1'; -- a flag to prevent playing of the sample right after a reset (without a trigger)
		elsif rising_edge(clk_50) then
			if trigger = '1' then  -- reset the sample address to the start when trigger is high, counting will commence when trigger goes low again
				sample_address <= data_start_address & "00000000000000000000000";
				init <= '0'; -- clear the init flag, as it is now OK to play the sample
			elsif init = '0' and sample_address(44 downto 23) < sample_data_end then -- keep counting until the end of the data is reached
				sample_address <= sample_address + frequency; 
			end if;
		end if;		
	end process;
	
----------------------------------------------------------------------------------------------------------------------------------
	
flash_memory_read :	process(rst, clk_50)
		begin
		if rst = '1' then
			read_start <= '0';
			iflash_address <= size_address; -- start off reading the file size
			state <= 0;
			sample_data <= (others => '0');
		elsif rising_edge(clk_50) then
			case state is
			when 0 =>
				read_start <= '1';
				state <= 1;
			when 1 =>
				if read_done = '1' then
					data_size(7 downto 0) <= unsigned(odata); -- first byte of file size
					iflash_address <= iflash_address + 1;
					read_start <= '0';
					state <= 2;
				end if;			
			when 2 =>	
				if read_done = '0' then -- wait for memory to become ready for the next read
					read_start <= '1';
					state <= 3;
				end if;				
			when 3 =>
				if read_done = '1' then
					data_size(15 downto 8) <= unsigned(odata); -- second byte of file size
					iflash_address <= iflash_address + 1;
					read_start <= '0';
					state <= 4;
				end if;			
			when 4 =>	
				if read_done = '0' then -- wait for memory to become ready for the next read
					read_start <= '1';
					state <= 5;
				end if;	
			when 5 =>
				if read_done = '1' then
					data_size(21 downto 16) <= unsigned(odata(5 downto 0)); -- third byte of file size (fourth byte is not read since flash mem cannot fit any larger file)
					read_start <= '0';
					state <= 6; 
				end if;
			when 6 =>
				if step = '0' then
					iflash_address <= sample_address(44 downto 24) & "0";
					state <= 7;
				end if;
			when 7 =>
				if step = '1' and read_done = '0' then
					read_start <= '1';
					state <= 8;
				end if;
			when 8 =>
				if read_done = '1' then
					sample_data(7 downto 0) <= odata;
					iflash_address <= iflash_address + 1;
					read_start <= '0';
					state <= 9;
				end if;
			when 9 =>
				if read_done = '0' then
					read_start <= '1';
					state <= 10;
				end if;
			when 10 =>
				if read_done = '1' then
					sample_data(15 downto 8) <= odata;
					iflash_address <= iflash_address + 1;
					read_start <= '0';
					state <= 6;
				end if;
			
--------------------------LOOP FOR READING THE AUDIO SAMPLES FROM FLASH MEMORY 

-------  TO BE COMPLETED BY EACH GROUP IN LAB 4 --------------
-------  extending the FSM to read the wavefile --------------
-------  data sequentially until the end of the file ---------

--------------------------------------------------------------
			when others =>
				state <= 0;
			end case;	
		end if;
	end process;

--------------------------------------------------------------------------------------------------------------------------------------------	

pitch_to_frequency : process(note,octave) -- combinational circuit that converts the pitch number to frequency (exponential f = f(0)*2^(N/12))
begin
	case to_integer(note) is -- note is normally between 0 and 11 
	when 0 => fmax <= 515396; -- this will increment the address counter by 32x16106.13 per sample clock period, hence will be 32 times the natural pitch
	when 1 => fmax <= 546043; 
	when 2 => fmax <= 578513; 
	when 3 => fmax <= 612913; 
	when 4 => fmax <= 649358; 
	when 5 => fmax <= 687971; 
	when 6 => fmax <= 728880; 
	when 7 => fmax <= 772222; 
	when 8 => fmax <= 818140; 
	when 9 => fmax <= 866789;
	when 10 => fmax <= 918331; 
	when 11 => fmax <= 972938; 
	when others => fmax <= 1030792; -- one octave higher than note 0
	end case;
	
	case octave is
	when "000" =>
		frequency <= fmax/128; -- note: division by a power of 2 is easy to synthesize, but dividing by anything else will be hard to synthesize
	when "001" =>
		frequency <= fmax/64;
	when "010" =>
		frequency <= fmax/32;
	when "011" =>
		frequency <= fmax/16;
	when "100" =>
		frequency <= fmax/8; 
	when "101" =>
		frequency <= fmax/4;
	when "110" =>
		frequency <= fmax/2;
	when others =>
		frequency <= fmax;
	end case;	
end process;
	
end a;		