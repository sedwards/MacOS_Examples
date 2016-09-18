---------------
--GLImageWall--
---------------

Demonstrates different techniques of getting accelerated OpenGL contexts across multiple displays.

Fullscreen:
	One context is made per display and the frustum is set as needed.
	Supports overriding the display manager locations via 'FullScreen
	Display Settings'. This allows one to have overlapping views.

Windowed:
	One context is made per display and the frustum is set as needed.
	As the super-view is resized the sub-views move and resize as
	needed depending on how they intersect with the display

As well GLImageWall will tile textures, this could be used to limit the amount of texture data that has to be uploaded to each renderer.

---------
--Usage--
---------
Common:
	Click and drag on the rendering to translate the object
	 -- shift zooms
	Hold down 'ctrl' while clicking and dragging to rotate
	 -- shift changes rotation type

Windowed:
	Set 'Tile Size' to desired value
	Drag any image onto the 'Image'
	--Now you will see the image in the window
	Press 'W' to see how the texture was cut into tiles
	Press ' ' to start animating
	Stretch the window across multiple displays
	 -- notice that you can make the window very large
	 -- and it will run in HW (when possible)
	 -- the info box will reflect renderer info per display

Fullscreen:
	Click '>' to set the 'FullScreen Display Settings' drawer
		-- This allows you to override the display manager
	Set each display as desired
	Press the 'Full Screen' button 
	(it may be hard to read this if you pressed that button...)
	 -- the info box will reflect renderer info per display
	Press 'M' to enter mirrored mode
	 -- notice that each display now shows the same scene
	Press 'Esc' to leave fullscreen mode
	