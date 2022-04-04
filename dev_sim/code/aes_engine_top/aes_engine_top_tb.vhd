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

library aes_engine;
use     aes_engine.aes_engine_pkg.all;

library tb_lib;
use     tb_lib.aes_engine_tb_pkg.all;

library blk_mem_gen_v8_4_5;
library xil_defaultlib;
library xpm;

entity aes_engine_top_tb is
   generic (
      g_test_cases : std_ulogic_vector(31 downto 0) := x"00000001" -- AES128 = 0000000F, AES192 = 000000F0, AES256 = 00000F00 
   );
end entity;

architecture sim of aes_engine_top_tb is
   -- Constants
   constant KEY               : std_logic_vector(DATA_WIDTH_128-1 downto 0) := (others => '0'); 
   constant clk_period        : time := 5 ns; 
   -- Signals
   signal out_word, in_word   : std_logic_vector(DATA_WIDTH_128-1 downto 0) := (others => '0');
   signal test_msg            : string(1 to STRING_LENGTH);
   signal rst, clk, speed_sel : std_logic := '0';
   
   signal test_id   : string(1 to 4);                        
   signal pt        : std_logic_vector(DATA_WIDTH_128-1 downto 0):= (others => '0');
   signal key_handle: std_logic_vector(9 downto 0):= (others => '0');
   signal exp_ct    : std_logic_vector(DATA_WIDTH_128-1 downto 0):= (others => '0');
   signal test_done, t_valid, t_last : std_logic := '0';
   signal t_keep    : std_logic_vector((WIDTH_BYTE*2)-1 downto 0):= (others => '1');
   signal t_ready   : std_logic;
   signal mode      : integer;
   
   signal en_cnt    : unsigned(4 downto 0);
   
   -- BRAM
   signal keys_128  : std_logic_vector(DATA_WIDTH_128-1 downto 0);
   signal keys_192  : std_logic_vector(DATA_WIDTH_192-1 downto 0);
   signal keys_256  : std_logic_vector(DATA_WIDTH_256-1 downto 0);
   
begin
   dut : entity aes_engine.aes_engine_top
      generic map(
         g_speed_sel    => '0' -- 1 = Lo speed
      )
      port map(
         i_key_handle   => key_handle,
         i_t_valid      => t_valid,
         i_t_last       => t_last,
         i_t_keep       => t_keep,
         i_clk          => clk,
         i_rst          => rst,
         i_t_data       => in_word, 
         o_t_data       => out_word,
         o_t_ready      => t_ready
      );
      
   p_clk : process
   begin
      clk <= '1';
      wait for clk_period/2;
      clk <= '0';
      wait for clk_period/2;
   end process;

   -- reverse keys for initialisation file of BRAM due to key format being wrong way round MSB and LSB 
   p_rev_keys : process
      variable v_oline : line;
      variable status               : file_open_status;
   begin
      if g_test_cases(31) = '1' then
         file_open(status, f_keys_128   , KEYS_128_FILE);
         file_open(status, f_keys_192   , KEYS_192_FILE);
         file_open(status, f_keys_256   , KEYS_256_FILE);
         file_open(status, f_output_keys, KEYS_OUT_FILE, write_mode);
         
         wait until rising_edge(clk);
         
         wait for 2 ns;
         write(v_OLINE, header1);
         writeline(f_output_keys, v_OLINE);
         wait for 2 ns;
         write(v_OLINE, header2);
         writeline(f_output_keys, v_OLINE);
         wait for 2 ns;
         write(v_OLINE, header3);
         writeline(f_output_keys, v_OLINE);
         
         while not endfile(f_keys_128) loop -- run at full speed
         get_ct(f_keys_128,keys_128 ); -- get data from 128 key file and reverse the order
         wait for 2 ns;
            hwrite(v_OLINE, keys_128);
            write(v_OLINE, comma);
            writeline(f_output_keys, v_OLINE);
         end loop;
      
         while not endfile(f_keys_192) loop -- run at full speed
         get_ct(f_keys_192,keys_192 ); -- get data from 192 key file and reverse the order
         wait for 2 ns;
         hwrite(v_OLINE, keys_192);
         write(v_OLINE, comma);
            writeline(f_output_keys, v_OLINE);
         end loop;
         
         while not endfile(f_keys_256) loop -- run at full speed
         get_ct(f_keys_256,keys_256 ); -- get data from 256 key file and reverse the order
         wait for 2 ns;
         hwrite(v_OLINE, keys_256);
         write(v_OLINE, comma);
            writeline(f_output_keys, v_OLINE);
         end loop;
      
         wait until rising_edge(clk);
          
         file_close(f_keys_128);
         file_close(f_keys_192);
         file_close(f_keys_256);
         file_close(f_output_keys);
      end if;
      wait;
   end process;

   p_main_tests : process
      variable status               : file_open_status;
   begin
   --%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   -- AES 128
   --%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
      ------------------------------------------------------------------------------------
      ---- Test case 1
      ------------------------------------------------------------------------------------
      if g_test_cases(0) = '1' then
         file_open(status, f_128_vectors  , CMD_128_FILE);
         file_open(status, f_ct_vectors   , CT_128_FILE);
         key_handle  <= (others  =>  '0');
         test_msg <= pad_string(" Test case 1 : AES128 HI speed ", ' ', STRING_LENGTH);
         wait for 0 ns;
         report lf & lf & test_msg & lf;
         speed_sel <= '0';
         rst       <= '1';             
         wait for RESET_DURATION;
         rst       <= '0';           
         wait until rising_edge(clk);
         wait until t_ready = '1';
         t_valid   <= '1'; 
         get_inputs(f_128_vectors, in_word, key_handle); -- load key
         wait until rising_edge(clk);
         while not endfile(f_128_vectors) loop -- run at full speed
            if t_ready = '1' then
               get_inputs(f_128_vectors, in_word, key_handle); -- get data from test vectors
               wait until rising_edge(clk);
               get_ct(f_ct_vectors, exp_ct); -- get data from test vectors
               wait for 2 ns;
               assertion(test_msg, "compare output cipher with text file FIPS cipher", exp_ct, out_word);
            else
               wait until rising_edge(clk);
            end if;
         end loop;
         wait for clk_period*20;
         t_valid  <= '0';
         file_close(f_128_vectors);
         file_close(f_ct_vectors);
      end if;
      
      ------------------------------------------------------------------------------------
      ---- Test case 2
      ------------------------------------------------------------------------------------
      if g_test_cases(1) = '1' then
         file_open(status, f_128_vectors, CMD_128_FILE);
         file_open(status, f_ct_vectors   , CT_128_FILE);
         key_handle  <= (others  =>  '0');
         test_msg <= pad_string(" Test case 2 : AES128 LO speed ", ' ', STRING_LENGTH);
         wait for 0 ns;
         report lf & lf & test_msg & lf;
         speed_sel <= '1';
         rst       <= '1';       
         exp_ct    <= (others => '0');      
         wait for RESET_DURATION;
         rst      <= '0';  
         key_handle  <= std_logic_vector(to_unsigned(0,10)); -- load key
         wait until rising_edge(clk);
         wait until t_ready = '1';
         t_valid   <= '1'; 
         get_inputs(f_128_vectors, in_word, key_handle); -- load key
         
         for i in 0 to AES128+1 loop -- input next plain text inline with Lo speed 
            wait until rising_edge(clk);
         end loop;
         
         --get_ct(f_ct_vectors, exp_ct); -- get data from test vectors
         --assertion(test_msg, "compare output cipher with text file FIPS cipher", exp_ct, out_word);
         
         while not endfile(f_128_vectors) loop 
            if t_ready = '1' then
               get_inputs(f_128_vectors, in_word, key_handle); -- get data from test vectors
               for i in 0 to AES128+1 loop -- input next plain text inline with Lo speed 
                  wait until rising_edge(clk);
               end loop;
               get_ct(f_ct_vectors, exp_ct); -- get data from test vectors
               assertion(test_msg, "compare output cipher with text file FIPS cipher", exp_ct, out_word);
            else
               wait until rising_edge(clk);
            end if;
         end loop;
         wait for clk_period*20;
         t_valid  <= '0'; 
         file_close(f_128_vectors);
         file_close(f_ct_vectors);
      end if;
      
      --%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      -- TKEEP tests
      --%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
      if g_test_cases(2) = '1' then
         file_open(status, f_128_vectors, CMD_128_FILE);
         file_open(status, f_ct_vectors   , CT_128_FILE);
         key_handle  <= (others  =>  '0');
         test_msg <= pad_string(" Test case 3 : TKEEP tests", ' ', STRING_LENGTH);
         wait for 0 ns;
         report lf & lf & test_msg & lf;
         
         speed_sel  <= '0';
         rst        <= '1';           
         wait for RESET_DURATION;
         rst <= '0';         
         key_handle  <= std_logic_vector(to_unsigned(0,10)); -- load key
         -- TKEEP one byte                      
         wait until rising_edge(clk);
         t_valid  <= '1';
         t_keep   <= std_logic_vector(to_unsigned(1, 16)); 
         
         get_inputs(f_128_vectors, in_word, key_handle); -- get data from test vectors
         
         -- account for delay in pipeline
         for i in 0 to AES128+1 loop
            wait until rising_edge(clk);
            get_inputs(f_128_vectors, in_word, key_handle); -- get data from test vectors
         end loop;
         
         get_ct(f_ct_vectors,exp_ct); -- get data from test vectors
         wait for 2 ns;
         assertion(test_msg, "compare output cipher with text file FIPS cipher", exp_ct, out_word);
         
         for i in 0 to AES128 loop
            wait until rising_edge(clk);
            if t_ready = '1' then
               get_inputs(f_128_vectors, in_word, key_handle); -- get data from test vectors
               get_ct(f_ct_vectors, exp_ct); -- get data from test vectors
               wait for 2 ns;
               assertion(test_msg, "compare output cipher with text file FIPS cipher", exp_ct, out_word);
            else
               wait until rising_edge(clk);
            end if;
         end loop;
         wait for clk_period*20;
         t_valid  <= '0';
         
         
         file_close(f_128_vectors);
         file_close(f_ct_vectors);
      end if;
      
      --%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      -- AES 192
      --%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      ------------------------------------------------------------------------------------
      ---- Test case 4
      ------------------------------------------------------------------------------------
      if g_test_cases(4) = '1' then
         file_open(status, f_192_vectors      , CMD_192_FILE);
         file_open(status, f_192_ct_vectors   , CT_192_FILE );
         key_handle  <= (others  =>  '0');
         test_msg <= pad_string(" Test case 4 : AES192 HI speed ", ' ', STRING_LENGTH);
         wait for 0 ns;
         report lf & lf & test_msg & lf;
         speed_sel <= '0';
         rst       <= '1';             
         wait for RESET_DURATION;
         rst       <= '0';  
         key_handle  <= std_logic_vector(to_unsigned(150,10)); -- load key
         wait until rising_edge(clk);
         wait until t_ready = '1';
         t_valid   <= '1'; 
         get_inputs(f_192_vectors, in_word, key_handle); -- load key
         -- account for delay in pipeline
         wait until rising_edge(clk);
         while not endfile(f_192_vectors) loop -- run at full speed
            if t_ready = '1' then
               get_inputs(f_192_vectors, in_word, key_handle); -- get data from test vectors
               wait until rising_edge(clk);
               get_ct(f_192_ct_vectors, exp_ct); -- get data from test vectors
               wait for 2 ns;
               assertion(test_msg, "compare output cipher with text file FIPS cipher", exp_ct, out_word);
            else
               wait until rising_edge(clk);
            end if;
         end loop;
         wait for clk_period*20;
         t_valid  <= '0';
         file_close(f_192_vectors);
         file_close(f_192_ct_vectors);
      end if;
      
      ------------------------------------------------------------------------------------
      ---- Test case 5
      ------------------------------------------------------------------------------------
      if g_test_cases(5) = '1' then
         file_open(status, f_192_vectors      , CMD_192_FILE);
         file_open(status, f_192_ct_vectors   , CT_192_FILE );
         key_handle  <= (others  =>  '0');
         test_msg <= pad_string(" Test case 5 : AES192 LO speed ", ' ', STRING_LENGTH);
         wait for 0 ns;
         report lf & lf & test_msg & lf;
         speed_sel <= '1';
         rst       <= '1';       
         exp_ct    <= (others => '0');      
         wait for RESET_DURATION;
         rst      <= '0';  
         key_handle  <= std_logic_vector(to_unsigned(150,10)); -- load key
         wait until rising_edge(clk);
         wait until t_ready = '1';
         t_valid   <= '1'; 
         get_inputs(f_192_vectors, in_word, key_handle); -- load key
         for i in 0 to AES192+1 loop -- input next plain text inline with Lo speed 
            wait until rising_edge(clk);
         end loop;
         
         get_ct(f_192_ct_vectors, exp_ct); -- get data from test vectors
         assertion(test_msg, "compare output cipher with text file FIPS cipher", exp_ct, out_word);
         
         while not endfile(f_192_vectors) loop 
            if t_ready = '1' then
               get_inputs(f_192_vectors, in_word, key_handle); -- get data from test vectors
               for i in 0 to AES192+1 loop -- input next plain text inline with Lo speed 
                  wait until rising_edge(clk);
               end loop;
               get_ct(f_192_ct_vectors, exp_ct); -- get data from test vectors
               assertion(test_msg, "compare output cipher with text file FIPS cipher", exp_ct, out_word);
            else
               wait until rising_edge(clk);
            end if;
         end loop;
         wait for clk_period*20;
         t_valid  <= '0'; 
         file_close(f_192_vectors);
         file_close(f_192_ct_vectors);
      end if;
      
      --%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      -- AES 256
      --%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
      ------------------------------------------------------------------------------------
      ---- Test case 6
      ------------------------------------------------------------------------------------
      if g_test_cases(8) = '1' then
         file_open(status, f_256_vectors      , CMD_256_FILE);
         file_open(status, f_256_ct_vectors   , CT_256_FILE );
         key_handle  <= (others  =>  '0');
         test_msg <= pad_string(" Test case 6 : AES256 same key HI speed ", ' ', STRING_LENGTH);
         wait for 0 ns;
         report lf & lf & test_msg & lf;
         speed_sel <= '0';
         rst       <= '1';             
         wait for RESET_DURATION;
         rst       <= '0';
         key_handle  <= std_logic_vector(to_unsigned(367,10)); -- load key
         wait until rising_edge(clk);
         wait until t_ready = '1'; -- wait for slave ready
         t_valid   <= '1';  -- now send valid and data
         get_inputs(f_256_vectors, in_word, key_handle);  
         -- account for delay in pipeline
         wait until rising_edge(clk);
         while not endfile(f_256_vectors) loop -- run at full speed
            if t_ready = '1' then
               get_inputs(f_256_vectors, in_word, key_handle); -- get data from test vectors
               wait until rising_edge(clk);
               get_ct(f_256_ct_vectors, exp_ct); -- get data from test vectors
               wait for 2 ns;
               assertion(test_msg, "compare output cipher with text file FIPS cipher", exp_ct, out_word);
            else
               wait until rising_edge(clk);
            end if;
         end loop;
         wait for clk_period*20;
         t_valid  <= '0';
         file_close(f_256_vectors);
         file_close(f_256_ct_vectors);
      end if;
      
      ------------------------------------------------------------------------------------
      ---- Test case 7
      ------------------------------------------------------------------------------------
      if g_test_cases(9) = '1' then
         file_open(status, f_256_vectors      , CMD_256_FILE);
         file_open(status, f_256_ct_vectors   , CT_256_FILE );
         key_handle  <= (others  =>  '0');
         test_msg <= pad_string(" Test case 7 : AES256 same key LO speed ", ' ', STRING_LENGTH);
         wait for 0 ns;
         report lf & lf & test_msg & lf;
         speed_sel <= '1';
         rst       <= '1';       
         exp_ct    <= (others => '0');      
         wait for RESET_DURATION;
         rst      <= '0';  
         key_handle  <= std_logic_vector(to_unsigned(367,10)); -- load key
         wait until rising_edge(clk);
         wait until t_ready = '1'; -- wait for slave ready
         t_valid   <= '1';  -- now send valid and data
         get_inputs(f_256_vectors, in_word, key_handle); -- load key 
         for i in 0 to AES256+1 loop -- input next plain text inline with Lo speed 
            wait until rising_edge(clk);
         end loop;
         
         get_ct(f_256_ct_vectors, exp_ct); -- get data from test vectors
         assertion(test_msg, "compare output cipher with text file FIPS cipher", exp_ct, out_word);
         
         while not endfile(f_256_vectors) loop 
            if t_ready = '1' then
               get_inputs(f_256_vectors, in_word, key_handle); -- get data from test vectors
               for i in 0 to AES256+1 loop -- input next plain text inline with Lo speed 
                  wait until rising_edge(clk);
               end loop;
               get_ct(f_256_ct_vectors, exp_ct); -- get data from test vectors
               assertion(test_msg, "compare output cipher with text file FIPS cipher", exp_ct, out_word);
            else
               wait until rising_edge(clk);
            end if;
            end loop;
         wait for clk_period*20;
         t_valid  <= '0'; 
         file_close(f_256_vectors);
         file_close(f_256_ct_vectors);
      end if;
      
      -- stop simulation
      assert false report "END OF SIMULATION!" severity failure;
      wait;
      
   end process;
   
   
end sim;
