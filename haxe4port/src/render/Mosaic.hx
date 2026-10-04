package render;

/** Overlay math adapted from dn.heaps.filter.OverlayTexture for current Heaps. */
class Mosaic extends h2d.filter.Shader<MosaicShader> {
	public function new() {
		super(new MosaicShader());
		nearest = true;
		smooth = false;
	}

	public function resize(size:Int, width:Int, height:Int) {
		resolutionScale = size;
		shader.blockSize = size;
		shader.dimensions.set(width,height);
	}
}

private class MosaicShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture : Sampler2D;
		@param var dimensions : Vec2;
		@param var blockSize : Float;

		function fragment() {
			var source = texture.get(input.uv);
			var p = floor(input.uv*dimensions) % vec2(blockSize);
			var overlay = vec3(0.5);
			if( blockSize>1 ) {
				if( p.y<1 && p.x<blockSize-1 ) overlay = vec3(224.0/255.0);
				else if( p.y>=blockSize-1 && p.x>0 ) overlay = vec3(0.0);
				else if( p.y>0 && p.y<blockSize-1 ) {
					if( p.x<1 ) overlay = vec3(1.0);
					else if( p.x>=blockSize-1 ) overlay = vec3(0.0);
				}
			}
			overlay = mix(vec3(0.5),overlay,0.25);
			var col = mix(
				1.0 - 2.0*(1.0-source.rgb)*(1.0-overlay),
				2.0*source.rgb*overlay,
				step(source.rgb,vec3(0.5))
			);
			pixelColor = vec4(col,source.a);
		}
	};
}
