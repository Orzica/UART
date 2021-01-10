--Libraries declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity tUART is
--  Generic( );
    generic(
        baud     : integer := 115200; --Bits / second
        clk_rate : integer := 100000000 --100MHz
    );
--  Port ( );
    port (
        data_out	: out std_logic;                   -- Transmit Line Out
        tx_ready	: out std_logic;                   -- We are ready for more data to come in
        start 		: in std_logic;                    -- When '1', we will transmit data
        data_in		: in std_logic_vector(7 downto 0); -- Data we wanna transmit
        reset 		: in std_logic;                    -- Negative Reset
        clk 		: in std_logic
    );
end tUART;

architecture rtl of tUART is
    --Declarative zone of VHDL
    
    constant max_clk_counter        : integer := clk_rate / baud;
    constant max_bits               : integer := 10;
    constant max_clk_count_delay	: integer := clk_rate / 19200; -- creates a 52uS delay between character transmissions

    
    signal number_bits       : integer range 0 to max_bits;
    signal clk_counter       : integer range 0 to max_clk_counter;
    signal clk_delay_counter : integer range 0 to max_clk_count_delay;
    signal shift_data        : std_logic := '0';
    
    --State machine
    type state_type is (init, load, shift);
    signal state, nxt_state : state_type;
    
    signal done_shifting    : std_logic := '0';
    signal start_trans      : std_logic := '0';
    signal load_data        : std_logic := '0';
    signal transmit_done    : std_logic := '0';
    signal tx_ready_reg     : std_logic := '0';
    signal delay_clock      : std_logic := '0';
    signal delay_clock_done : std_logic := '0';



    
    -- signals used for edge detection circuitry
    signal start_count_lead			: std_logic := '0';
    signal start_count_follow		: std_logic := '0';
    
    --UART shift register
    signal data_reg 				: std_logic_vector(9 downto 0) := (others => '1');
    
begin

    start_trans <= start_count_lead and (not start_count_follow); --Make sure that data is sent once when we press the button
    data_out <= data_reg(0);
	tx_ready <= transmit_done and tx_ready_reg and not delay_clock;

    --Process that said what next state is
    state_proc : process(clk) is
    begin
        if rising_edge(clk) then
            if (reset = '0') then
                state <= init;
            else
                state <= nxt_state;
            end if;
        end if;
    end process state_proc;
    
    --Process that actually goes from state to state
    next_state_proc : process(done_shifting, start_trans, state) is
    begin
        nxt_state     <= state;
        load_data     <= '0';
        transmit_done <= '0';
        
        case state is   
        
            when init  =>           
                transmit_done <= '1'; --Indicate we are no longer transmit
            
                if (start_trans = '1') then
                    nxt_state <= load;
                else
                    nxt_state <= init;
                end if;
            
            when load  =>
                load_data <= '1';
                nxt_state <= shift;
               
            when shift =>
                if (done_shifting = '1') then
                    nxt_state <= init;
                else
                    nxt_state <= shift;
                end if;
             
            when others =>
                nxt_state <= init;
               
        end case;
    end process next_state_proc;
    
    --Generate Baud Rate --When we rich max value we set shift_data = '1'
    clk_count : process(clk) is
    begin
        if rising_edge(clk) then
            if (state = shift) then --We need to be in shift state
                if (clk_counter = max_clk_counter) then
                    clk_counter <= 0;
                    shift_data  <= '1';
                else
                    clk_counter <= clk_counter + 1;
                    shift_data  <= '0';
                end if;
            end if;
        end if;
    end process clk_count;
    
    begin_trans_proc : process(clk)
	begin
		if(rising_edge(clk)) then
			if(reset = '0') then
				start_count_lead <= '0';
				start_count_follow <= '0';
			else
				start_count_lead <= start;
				start_count_follow <= start_count_lead;
			end if;
		end if;
	end process begin_trans_proc;
	
	count_bits_proc: process(clk)
	begin
		if(rising_edge(clk)) then
			if(reset = '0') then
				number_bits <= 0;
			elsif(number_bits = max_bits) then
				done_shifting <= '1';
				number_bits <= 0;
			elsif(load_data = '1') then
				data_reg <= '1' & data_in & '0';
				done_shifting <= '0';
			elsif(shift_data = '1') then
				data_reg <= '1' & data_reg(9 downto 1);
				number_bits <= number_bits + 1;
			end if;
		end if;
	end process count_bits_proc;
    
   	clock_delay_proc: process(clk)
	begin
	   if(rising_edge(clk)) then
	       if(delay_clock = '1') then
	           if(clk_delay_counter < max_clk_count_delay) then
	               clk_delay_counter <= clk_delay_counter + 1;
	               delay_clock_done <= '0';
	           else
	               delay_clock_done <= '1';
	           end if;
	       else
	           -- Set counters to 0    
	           clk_delay_counter <= 0;
	       end if;
	   end if;
	end process clock_delay_proc;

    tx_ready_proc: process(clk)
    begin
        if(rising_edge(clk)) then
            if(start = '1') then
                tx_ready_reg <= '0';    -- indicate tx is not ready for data
            else
                tx_ready_reg <= '1';
            end if;
        end if;
    end process tx_ready_proc; 

    
end rtl;
