{lib, inputs, ...}:
{
    programs.yazi = {
        enable = true;
        settings = {
            manager = {
                prepend_keymap = [
                    {
                        on = [ "l" ];
                        run = "plugin --sync smart-enter";
                        desc = "Enter the child directory, or open the file";
                    }
                    {

                        on   = [ "<C-s>" ];
                        run  = ''shell "$SHELL" --block --confirm'';
                        desc = "Open shell here";
                    }
                ];
            };
        };
    };
}
