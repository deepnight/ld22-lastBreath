package render;

/** Flatten the lights first, then erase the isolated darkness layer.
    Heaps Erase uses source color; Flash ERASE uses source alpha.
    Writing alpha to all four channels makes destination-out identical. */
class LightErase extends h2d.filter.Shader<LightEraseShader> {
	public function new() {
		super(new LightEraseShader());
		nearest = true;
		smooth = false;
	}
}
private class LightEraseShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture:Sampler2D;
		function fragment() {
			output.color = vec4(texture.get(input.uv).a);
		}
	};
}
