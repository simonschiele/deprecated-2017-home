
alias calc='calculator'
alias calculator='bc -l'
alias nmap.fast_udp="sudo nmap -sU --max-retries 1 --min-rate 5000 -p 1-65535"
alias patch.from_diff='patch -Np0 -i'
alias vim.bigfile=vim.blank
alias vim.blank="${EDITOR} -N -u NONE -U NONE"
alias vim.none=vim.blank
alias wget.mirror_complete='wget --random-wait -r -p -e robots=off -U mozilla'
alias wget.mirror_images='wget -r -l1 --no-parent -nH -nd -P/tmp -A".gif,.jpg,.png"'
