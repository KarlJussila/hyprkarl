#!/bin/bash

if systemctl --user is-active --quiet hypridle.service; then
  echo '{"text": " 󰽖 ", "tooltip": "Caffeine (OFF)"}'
else
  echo '{"text": "  ", "tooltip": "Caffeine (ON)"}'
fi

