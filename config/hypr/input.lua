-- Control your input devices
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
hl.config({
	input = {
		-- Focus follows the mouse (follow_mouse = 1, the default), but only after
		-- the cursor has deliberately travelled this far (logical px) over an
		-- unfocused window. Avoids stealing focus on a tiny jitter — e.g. right
		-- after a floating window pops up — while still swapping on a real move.
		-- Replaces `mouse_refocus = false` (which only refocused on border cross).
		follow_mouse_threshold = 200,

		-- Use multiple keyboard layouts and switch between them with Left Alt + Right Alt
		-- kb_layout = "us,dk,eu",
		kb_layout = "us",

		-- Change speed of keyboard repeat
		repeat_rate = 40,
		repeat_delay = 600,

		-- Start with numlock on by default
		numlock_by_default = true,

		-- Increase sensitivity for mouse/trackpad (default: 0)
		sensitivity = 0.3,

		touchpad = {
			-- Use natural (inverse) scrolling
			natural_scroll = true,

			-- Use two-finger clicks for right-click instead of lower-right corner
			clickfinger_behavior = true,

			-- Control the speed of your scrolling
			scroll_factor = 0.4,

			-- Disable tap-and-drag
			tap_and_drag = false,

			-- Don't disable while typing
			disable_while_typing = false,

			-- Enable three-finger drag
			drag_3fg = 1,
		},
	},

	gestures = {
		workspace_swipe_min_speed_to_force = 10,
	},
})

-- Enable touchpad gestures for changing workspaces
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
