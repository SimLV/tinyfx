#include "tinyfx.h"
#include "demo_util.h"

static void run(state_t *state) {
	tfx_reset(state->width, state->height);

	uint8_t back = 1;
	tfx_view_set_clear_color(back, 0x555555ff);
	tfx_view_set_clear_depth(back, 1.0);
	tfx_view_set_depth_test(back, TFX_DEPTH_TEST_LT);

	const char *vss = ""
		"attribute vec3 a_position;\n"
		"attribute vec4 a_color;\n"
		"varying vec4 v_col;\n"
		"void main() {\n"
		"	v_col = a_color;\n"
		"	gl_Position = vec4(a_position.xyz, 1.0);\n"
		"}\n"
	;
	const char *fss = ""
		"precision mediump float;\n"
		"varying vec4 v_col;\n"
		"void main() {\n"
		"	gl_FragColor = v_col;\n"
		"}\n"
	;
	const char *attribs[] = {
		"a_position",
		"a_color",
		NULL
	};

	tfx_program prog = tfx_program_new(vss, fss, attribs);

	float verts[] = {
		 0.0f,  0.5f, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f,
		-0.5f, -0.5f, 0.0f, 0.0f, 1.0f, 0.0f, 1.0f,
		 0.5f, -0.5f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f
	};

	tfx_vertex_format fmt = tfx_vertex_format_start();
	tfx_vertex_format_add(&fmt, 3, false, TFX_TYPE_FLOAT);
	tfx_vertex_format_add(&fmt, 4, true, TFX_TYPE_FLOAT);
	tfx_vertex_format_end(&fmt);

	tfx_buffer vbo = tfx_buffer_new(verts, sizeof(verts), &fmt, TFX_USAGE_STATIC);

	while (!state->dead) {
		state->dead = poll_events(state);
		tfx_touch(back);

		tfx_set_vertices(&vbo, 3);
		tfx_set_state(0);
		tfx_submit(back, prog, false);

		tfx_frame();
		demo_swap_buffers();
	}

	tfx_shutdown();
}

int main(int argc, char **argv) {
	demo_run(&run);
}
