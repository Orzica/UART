library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity UART is
    --  Generic ( );
    --  Port ( );
    port(
        clk   : in  std_logic;
        reset : in std_logic;
        Rx    : in  std_logic;
        Tx    : out std_logic
    );
end UART;

architecture rtl of UART is

    -- Declarative zone of VHDL
    
    signal w_Tx            : std_logic;
    signal w_data_active   : std_logic;
    signal w_Tx_done       : std_logic;
    
    signal w_data_valid    : std_logic;
    signal w_data          : std_logic_vector(7 downto 0);


begin

    UART_Tx : entity work.tUART
        generic map(
            clk_freq => 100e6,
            baud     => 115200
        )
        port map(
            clk         => clk,
            reset       => reset,
            data_valid  => w_data_valid,
            data_in     => w_data,
            data_active => w_data_active,
            Tx_done     => w_Tx_done,
            Tx          => w_Tx
        );
        
     UART_Rx : entity work.rUART
        generic map(
            clk_rate => 100e6,
            baud     => 115200
        )
        port map(
            clk        => clk,
            reset      => reset,
            Rx         => Rx,
            data_valid => w_data_valid,
            data_out   => w_data
        );

    Tx <= w_Tx when w_data_active = '1' else '1';

end rtl;
