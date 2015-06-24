# FHLight

ps ax|grep Warcraft|grep -v grep

— X64 build 20173

echo -e "process attach -p `ps ax|grep 'MacOS/World of Warcraft'|grep -v grep|awk '{print $1}'`\nmemory write 0x100bca07a 0xeb\nprocess detach\nquit" > /tmp/luaunlock && lldb -s /tmp/luaunlock 

