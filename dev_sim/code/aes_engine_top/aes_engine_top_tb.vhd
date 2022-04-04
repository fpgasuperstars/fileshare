--------------------------------------------------------------------------------------
-- Copyright nCipher Entrust 2022. All rights reserved.
-- Filename : aes_engine_top_tb.vhd
-- Creation date : 2022-01-21
-- Author(s) : okeefej
-- Description :
-- This testbench tests the functionality of the sbox
---------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

entity aes_engine_top_tb is
   generic (
      g_test_cases : std_ulogic_vector(31 downto 0) := x"00000001" -- AES128 = 0000000F, AES192 = 000000F0, AES256 = 00000F00 
   );
end entity;

architecture sim of aes_engine_top_tb is

   
end sim;
