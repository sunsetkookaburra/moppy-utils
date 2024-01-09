#!/bin/sh

# moppy-utils - Utilities for playing music on Moppy devices
# Copyright (C) 2024  Oliver Lenehan
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

printb ()
{
  echo "$@" | xargs -L 1 printf '\\\\%04o\n' | xargs -L 1 printf '%b'
}

moppy_play_sequence () {
  # Open Serial Port
  exec 3<> /dev/ttyACM0
  
  # 57600 baud raw mode
  # reset connection on open/close
  # 8 data bits, 1 stop, 0 parity
  stty -F /dev/ttyACM0 \
    57600 raw -echo \
    hupcl cs8 -cstopb -parenb
  
  # Wait for Arduino & Serial init
  sleep 2

  # Sequence Start
  printb 0x4D 0x00 0x00 0x01 0xFA >&3

  aseqdump -p "$1" | while read -r LINE
  do
    echo "$LINE" | sed -E 's/[^0-9]*([0-9]+)/\1 /g' | {
      read -r client port channel a1 a2 rest
      case "$LINE" in
        *"Note on"*)
          echo "c=$channel on=$a1 v=$a2"
          printb 0x4D 0x01 "$((channel + 1))" 0x03 0x09 "$a1" "$a2" >&3
          ;;
        *"Note off"*)
          echo "c=$channel off=$a1"
          printb 0x4D 0x01 "$((channel + 1))" 0x02 0x08 "$a1" >&3
          ;;
        #*"Pitch bend"*)
        #  echo "c=$channel pb=$a1"
        #  printb 0x4D 0x01 "$((channel + 1))" 0x03 0x0E "$(($a1))"
        #  echo -ne "$(printf '\\x4d\\x01\\x%02x\\x03\\x0e' "$((channel + 1))")\x$(printf "$a1" | head -c 2 | tail -n 2)\x$(printf "$a1" | tail -n 2)" >&3
        #  ;;
      esac
    }
  done

  # Sequence Stop
  printb 0x4D 0x00 0x00 0x01 0xFC >&3

  # Reset / Panic
  printb 0x4D 0x00 0x00 0x01 0xFF >&3

  # Close Serial Port
  exec 3<&-
}

moppy_play_sequence "$1"

#if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
#  echo "moppy [--help | --list | --port]"
#elif [ "$1" = "-l" ] || [ "$1" = "--list" ]; then
#  receivemidi list
#elif [ "$#" = "1" ]; then
#  moppy_play_sequence "$1"
#elif [ "$#" = 0 ]; then
#  moppy_play_sequence "$(receivemidi list | head -n 1)"
#else
#  echo "moppy [--help | --list | --port]"
#fi


#cat <&3 &
#hexdump -n 5 --no-squeezing --format '5/1 "%d"' <&3 >&1
#sleep 5
#moppy_stat ()
#{
#  hexdump --no-squeezing --format '1/1 "%d\n"'
  #| while true
  #do
  #  read -r line
  #  echo "$? $line"
  #done
  # hexdump -e '/1 "%d\n"' <&3 | xargs --no-run-if-empty --eof="77" echo | while read -r 
#}


#moppy_stat <&3 &

#echo "HERE"
#echo -ne "\x4d\x00\x00\x01\x80" >&3
#xxd <&3 &

