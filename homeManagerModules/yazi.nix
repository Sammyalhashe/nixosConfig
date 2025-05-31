{lib, inputs, ...}:
{
    programs.yazi = {
        enable = true;
        settings = {
            mgr = {
                prepend_keymap = [
                    {
                        on = [ "l" ];
                        run = "plugin --sync smart-enter";
                        desc = "Enter the child directory, or open the file";
                    }
                ];
            };
        };
    };
}
