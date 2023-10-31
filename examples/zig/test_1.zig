const std = @import("std");
const sdl = @cImport({
	@cInclude("SDL.h");
});
const tfx = @import("tfx");

const FBuffer = tfx.TransientBuffer(f32);

const FrameState = struct {
	view : tfx.View,
	prog: tfx.Program,
	vertex_buf: FBuffer,
};

fn draw_frame(fd: FrameState) void
{
//	fd.view.setClearColor(0x442211FF);
    tfx.setTransientBuffer(fd.vertex_buf);
	tfx.setState(tfx.State.RGBWrite | tfx.State.DepthWrite);
	tfx.submit(fd.view, fd.prog, false);
	_ = tfx.frame();
}

pub fn main() !u8 {

	if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_AUDIO) != 0)
	{
		sdl.SDL_Log("Failed\n");
		return 1;
	}
	defer sdl.SDL_Quit();

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    defer
    {
    	 stdout.print("done\n", .{}) catch {};
      	 bw.flush() catch {};
    }
    const window = sdl.SDL_CreateWindow("Main", sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED, 800, 600, sdl.SDL_WINDOW_OPENGL);
    var tfx_view:tfx.View = undefined;
	{
    	const set_attr = sdl.SDL_GL_SetAttribute;
    	_ = set_attr(sdl.SDL_GL_RED_SIZE, 8);
    	_ = set_attr(sdl.SDL_GL_GREEN_SIZE, 8);
    	_ = set_attr(sdl.SDL_GL_BLUE_SIZE, 8);
    	_ = set_attr(sdl.SDL_GL_ALPHA_SIZE, 0);
    	_ = set_attr(sdl.SDL_GL_DEPTH_SIZE, 16);

    	_ = set_attr(sdl.SDL_GL_CONTEXT_PROFILE_MASK, sdl.SDL_GL_CONTEXT_PROFILE_ES);
    	_ = set_attr(sdl.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    	_ = set_attr(sdl.SDL_GL_CONTEXT_MINOR_VERSION, 1);
    	_ = set_attr(sdl.SDL_GL_CONTEXT_FLAGS, sdl.SDL_GL_CONTEXT_DEBUG_FLAG);

    	const context = sdl.SDL_GL_CreateContext(window);
		_ = sdl.SDL_GL_MakeCurrent(window, context);
		_ = sdl.SDL_GL_SetSwapInterval(1);


		var pd = tfx.PlatformData.create(31, sdl.SDL_GL_GetProcAddress);
		pd.use_gles = true;
    	tfx.setPlatformData( pd );
		tfx.reset(800, 600, tfx.ResetFlags.None);

    	tfx_view = tfx.getView(0);
    }
    var tfx_prog: tfx.Program = undefined;
    {
		const vs = 
			\\ in vec3 a_pos;
			\\ in vec4 a_color;
			\\ out vec4 v_col;
			\\ void main() {
			\\ v_col = a_color;
			\\ gl_Position = vec4(a_pos.xyz, 1.0);
			\\ }
			\\
			;
		const fs = 
			\\ precision mediump float;
			\\ in vec4 v_col;
			\\ out vec4 out_color;
			\\ void main() {
			\\   out_color = v_col;
			\\ }
			\\ 
			;
		const attrs: [2] [*] const u8 = .{
		    		"a_pos", 
		    		"a_color", };
    	tfx_prog = tfx.Program.create(vs, fs, &attrs) catch
    	{

    	 	stdout.print("unable to compile shaders\n", .{}) catch {};
      	 	bw.flush() catch {};
    		
    		return 2;
    	};
    }
    defer tfx.shutdown();

    var vert_buf: FBuffer = undefined;
    {
        // Create vertex format
        var fmt = tfx.VertexFormat.start();
        fmt.add(0, 3, false, tfx.ComponentType.Float);
        fmt.add(1, 4, true,  tfx.ComponentType.Float);
        fmt.end();
        // Create a buffer with verticies
        vert_buf = FBuffer.create(&fmt, 3);
        var p_len : usize = 7;
        var p : usize = 0;
        // Add p1 
        {
            const pt = comptime [_]f32 {0, 0.5, 0, 1.0, 0.0, 0.0, 1.0};
            for (vert_buf.ptr[p..p+p_len], 0..p_len) |*x, i|
            {
                x.* = pt[i];
            }
        }
        p += p_len;
        // Add p2
        {
            const pt = comptime [_]f32 {-0.5, -0.5, 0.0, 0.0, 1.0, 0.0, 1.0};
            for (vert_buf.ptr[p..p+p_len], 0..p_len) |*x, i|
            {
                x.* = pt[i];
            }
        }
        p += p_len;
        // Add p3
        {
            const pt = comptime [_]f32 {0.5, -0.5, 0.0, 0.0, 0.0, 1.0, 1.0};
            for (vert_buf.ptr[p..p+p_len], 0..p_len) |*x, i|
            {
                x.* = pt[i];
            }
        }
        p += p_len;
    }
    defer sdl.SDL_DestroyWindow(window);

	var view_state = .{
		.view = tfx_view,
		.prog = tfx_prog,
		.vertex_buf = vert_buf,
	};

    mainloop: while (true) 
    {
    	var sdl_event:sdl.SDL_Event = undefined;
    	while (sdl.SDL_PollEvent(&sdl_event) != 0)
    	{
    		switch (sdl_event.type)
    		{
    			sdl.SDL_QUIT => break :mainloop,
    			else => {},
    		}
    		
    	}
    	draw_frame(view_state);
    	sdl.SDL_GL_SwapWindow(window);
    	sdl.SDL_Delay(1);
    }
    
    return 0;
}

