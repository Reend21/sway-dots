
if test -z "$WAYLAND_DISPLAY" && test "$XDG_VTNR" = "1"
    exec sway
end

starship init fish | source
set -g fish_greeting ""
abbr -a up "sudo zypper dup --no-recommends"
abbr -a ff "fastfetch"
abbr -a op "sudo"
abbr -a in "sudo zypper install"
abbr -a mpeg "ffmpeg -i 1.mp4 -c:v dnxhd -profile:v dnxhr_lb -pix_fmt yuv420p -c:a pcm_s16le o1.mov"
abbr -a c "clear"
abbr -a fishconf "sudo nano .config/fish/config.fish"
abbr -a lazydocker "cd /home/reend/.local/bin/ && sudo ./lazydocker"
abbr -a flatpeak "sudo flatpak update"
abbr -a waypipetest "waypipe ssh reend@192.168.1.135 sway"
abbr -a waypipessh "waypipe ssh reend@192.168.1.135"
