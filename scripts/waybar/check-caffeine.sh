#!/bin/bash

if [ -f ~/.cache/hyprkarl-caffeine ]; then
  echo '{"text": "  ", "tooltip": "Caffeine (ON)"}';
else
  echo '{"text": " 󰽖 ", "tooltip": "Caffeine (OFF)"}';
fi