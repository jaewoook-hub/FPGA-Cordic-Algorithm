library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.constants.all;

entity cordic_stage is
port (
    i : in integer;
    x_i : in std_logic_vector (31 downto 0);
    y_i : in std_logic_vector (31 downto 0);
    z_i : in std_logic_vector (31 downto 0);
    x_o : out std_logic_vector (31 downto 0);
    y_o : out std_logic_vector (31 downto 0);
    z_o : out std_logic_vector (31 downto 0);
	atan : in std_logic_vector (15 downto 0)
);
end entity cordic_stage;

architecture behavior of cordic_stage is

    function if_cond( test : boolean; true_cond : signed; false_cond : signed )
	return signed is 
	begin
		if ( test ) then
			return true_cond;
		else
			return false_cond;
		end if;
    end function if_cond;

    function sra_func( val : signed; n : integer )
    return signed is
        variable temp : signed (val'length - 1 downto 0);
    begin
        temp := val srl n;
        temp(val'length - 1 downto val'length - n) := (others => val(val'length - 1));
        return temp;
    end function sra_func;
    
begin

    x_o <= std_logic_vector(signed(x_i) - if_cond( z_i(31) = '0', sra_func(signed(y_i), i), to_signed(1, 32) + not(sra_func(signed(y_i), i))));
    y_o <= std_logic_vector(signed(y_i) + if_cond( z_i(31) = '0', sra_func(signed(x_i), i), to_signed(1, 32) + not(sra_func(signed(x_i), i))));
    z_o <= std_logic_vector(signed(z_i) - if_cond( z_i(31) = '0', x"0000" & signed(atan), to_signed(1, 32) + not(x"0000" & signed(atan))));

end architecture behavior;