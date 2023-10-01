#!/usr/bin/env fish

# bail on non interactive
if ! status is-interactive
  return
end

# hide greeting
set fish_greeting

functions -e l
functions -e la
functions -e ll
