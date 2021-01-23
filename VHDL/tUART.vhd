--Libraries declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL; -- VHDL basics syntax
use IEEE.numeric_std.ALL;    -- Unsigned types

entity tUART is
--  Generic ( );
    generic(
        clk_freq : integer := 100e6;
        baud     : integer := 115200
    );
--  Port ( );
    port(
        clk         : in  std_logic;
        reset       : in  std_logic;
        data_valid  : in  std_logic;  -- If data_valid is 1 ( button pressed ), go to next state
        data_in     : in  std_logic_vector(7 downto 0);
        data_active : out std_logic;
        Tx_done     : out std_logic;
        Tx          : out std_logic  -- Tx line
    );
end tUART;

architecture rtl of tUART is

    -- Declarative zone of VHDL
    constant max_value_baud : integer := clk_freq / baud;
    
    signal max_counter_baud  : integer range 0 to  max_value_baud - 1;
    signal bit_counter       : integer range 0 to 7 := 0;
    
    signal data_reg        : std_logic_vector(7 downto 0) := (others => '0'); -- Data byte register / If button is pressed data_in will go in data_reg to be serialized
    signal Tx_done_reg     : std_logic := '0';
    signal data_active_reg : std_logic := '0';
    
    signal start_count_lead   : std_logic := '0';
    signal start_count_follow : std_logic := '0';
    signal start_trans        : std_logic := '0';
    
    -- Finite State Machine
    type state_type is (idle, start, send_data, stop);
    signal state: state_type;

begin

    -- Out signal assigments
    Tx_done     <= Tx_done_reg;
    data_active <= data_active_reg;

    state_proc: process(clk) is
    begin
        if rising_edge(clk) then
        
            case state is
                
                when idle      =>
                    data_active_reg  <= '0';
                    Tx_done_reg      <= '0'; 
                    bit_counter      <= 0;
                    max_counter_baud <= 0;
                    data_reg         <= (others => '0');
                    Tx               <= '1'; -- Line is high for idle state
                
                    if (start_trans = '1') then
                        state    <= start;
                        data_reg <= data_in; -- Register is ready to be worked on
                    else
                        state    <= idle;
                    end if;
                
                when start     =>
                    Tx              <= '0'; -- Line is high for idle state
                    data_active_reg <= '1';
                    --wait max_counter_baud - 1 ticks for bit start to be done  to be done
                    if (max_counter_baud < max_value_baud - 1) then
                        max_counter_baud <= max_counter_baud + 1;
                        state            <= start;
                    else
                        max_counter_baud <= 0;
                        state            <= send_data;
                        
                    end if;
                
                when send_data => -- Data from paralel to serial through Tx line
                    Tx <= data_reg(bit_counter);
                    
                    -- We need to wait max_counter_baud - 1 ticks / data bit
                    if (max_counter_baud < max_value_baud - 1) then
                         max_counter_baud <= max_counter_baud + 1;
                         state            <= send_data;
                    else
                        max_counter_baud  <= 0;
                        if (bit_counter < 7) then
                            bit_counter <= bit_counter + 1;
                            state       <= send_data;
                        else
                            bit_counter <= 0;
                            state       <= stop;
                        end if;
                    end if;
                    
                when stop      =>
                    -- We need to drive Tx back to 1 and wait for another wait max_counter_baud - 1 ticks
                    Tx_done_reg <= '1';
                    
                    if (max_counter_baud < max_value_baud - 1) then
                         max_counter_baud <= max_counter_baud + 1;
                    else
                        max_counter_baud  <= 0;
                        state             <= idle;
                    end if;
                    
                when others    =>
                    state <= idle;
                    
            end case;  
                  
        end if;
    end process state_proc;
    
    start_trans <= start_count_lead and (not start_count_follow); -- Data_Valid rising edge detection
    
    edge_detection_proc: process(clk) is
    begin
        if rising_edge(clk) then
            if (reset = '0') then
                start_count_lead <= '0';
                start_count_follow <= '0';
            else
                start_count_lead <= data_valid;
                start_count_follow <= start_count_lead;
            end if;
        end if;
    end process edge_detection_proc;

end rtl;
