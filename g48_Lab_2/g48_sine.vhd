-- this circuit computes sine(angle), where angle is in degrees
--
-- entity name: g48_sine
--
-- Copyright (C) 2015 Greg Rohlicek, 260516980; Stephen Carter
-- Version 1.0
-- Author: designer name(s); gregory.rohlicek@mail.mcgill.ca, stephen.carter@mail.mcgill.ca
-- Date: February 2, 2015

library lpm;
use lpm.lpm_components.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity g48_sine is
	port	(	clock	:	in std_logic;
				angle : in unsigned(8 downto 0);
				sine : out signed(15 downto 0));
end g48_sine;

architecture implementation of g48_sine is
signal temp_angle : std_logic_vector(8 downto 0);
signal temp_sine : std_logic_vector(15 downto 0);

begin
temp_angle <= std_logic_vector(angle);

sin_table : lpm_rom -- use the altera rom library macrocell
GENERIC MAP(
lpm_widthad => 9, -- sets the width of the ROM address bus
lpm_numwords => 512, -- sets the words stored in the ROM
lpm_outdata => "UNREGISTERED", -- no register on the output
lpm_address_control => "REGISTERED", -- register on the input
lpm_file => "g48_sine.mif", -- the ascii file containing the ROM data
lpm_width => 16) -- the width of the word stored in each ROM location
PORT MAP(inclock => clock, address => temp_angle, q => temp_sine);
sine <= signed(temp_sine);



end implementation;