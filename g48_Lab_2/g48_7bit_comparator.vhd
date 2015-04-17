-- entity name: g48_7bit_comparator
-- Greg Rohlicek - 260516980
-- Stephen Carter - 260500858

-- Copyright (C) 2015 Stephen Carter, Greg Rohlicek
-- Version 1.0 
-- Author: Stephen Carter; stephen.carter@mail.mcgill.ca, Greg Rohlicek; gregory.rohlicek@mail.mcgill.ca
-- Date: Feb. 2, 2015

-- This circuit determines when two 7-bit numbers, A and B, are equal.
library ieee;
use ieee.std_logic_1164.all;

entity g48_7bit_comparator is
	port(	A	:	in std_logic_vector(6 downto 0);
			B	:	in std_logic_vector(6 downto 0);
			AeqB	:	out std_logic
		);

end g48_7bit_comparator;

architecture implementation of g48_7bit_comparator is
begin
	AeqB <= '1' when A = B else '0';

end implementation;

