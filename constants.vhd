library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package constants is
    constant K : std_logic_vector (31 downto 0) := x"000026dd";
    constant QUANT_VAL_INT : integer := 16384; -- 2^14
    constant PI_OVER_TWO : integer := 25736;
    constant NEG_PI_OVER_TWO : integer := -25736;
    constant PI : integer := 51472;
    constant NEG_PI : integer := -51472;
    constant TWO_PI : integer := 102944;
    constant DATA_LENGTH : integer := 721;
    constant N_STAGES : integer := 16;
    constant MATH_PI : real := 3.14159265358979323846;	
	
	component cordic_stage is
	port (
		i : in integer;
		atan : in std_logic_vector (15 downto 0);
		x_i : in std_logic_vector (31 downto 0);
		y_i : in std_logic_vector (31 downto 0);
		z_i : in std_logic_vector (31 downto 0);
		x_o : out std_logic_vector (31 downto 0);
		y_o : out std_logic_vector (31 downto 0);
		z_o : out std_logic_vector (31 downto 0)
	);
	end component cordic_stage;

    component fifo is
        generic
        (
            constant FIFO_DATA_WIDTH : integer := 32;
            constant FIFO_BUFFER_SIZE : integer := 16
        );
        port
        (
            signal rd_clk : in std_logic;
            signal wr_clk : in std_logic;
            signal reset : in std_logic;
            signal rd_en : in std_logic;
            signal wr_en : in std_logic;
            signal din : in std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
            signal dout : out std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
            signal full : out std_logic;
            signal empty : out std_logic
        );
    end component fifo;

    component cordic is
        port (
			clock : in std_logic;
			reset : in std_logic;
			in_dout : in std_logic_vector (31 downto 0);
			in_rd_en : out std_logic;
			in_empty : in std_logic;
			out_cos_wr_en : out std_logic;
			out_cos_din : out std_logic_vector (31 downto 0);
			out_cos_full : in std_logic;
			out_sin_wr_en : out std_logic;
			out_sin_din : out std_logic_vector (31 downto 0);
			out_sin_full : in std_logic
        );
    end component cordic;
	
	component cordic_top is
        port (
			clock : in std_logic;
			reset : in std_logic;
			in_din : in std_logic_vector (31 downto 0);
			in_wr_en : in std_logic;
			in_full : out std_logic;
			out_cos_rd_en : in std_logic;
			out_cos_dout : out std_logic_vector (31 downto 0);
			out_cos_empty : out std_logic;
			out_sin_rd_en : in std_logic;
			out_sin_dout : out std_logic_vector (31 downto 0);
			out_sin_empty : out std_logic
        );
    end component cordic_top;

end package;