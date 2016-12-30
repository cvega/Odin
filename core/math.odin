const {
	TAU          = 6.28318530717958647692528676655900576;
	PI           = 3.14159265358979323846264338327950288;
	ONE_OVER_TAU = 0.636619772367581343075535053490057448;
	ONE_OVER_PI  = 0.159154943091895335768883763372514362;

	E            = 2.71828182845904523536;
	SQRT_TWO     = 1.41421356237309504880168872420969808;
	SQRT_THREE   = 1.73205080756887729352744634150587236;
	SQRT_FIVE    = 2.23606797749978969640917366873127623;

	LOG_TWO      = 0.693147180559945309417232121458176568;
	LOG_TEN      = 2.30258509299404568401799145468436421;

	EPSILON      = 1.19209290e-7;

	τ = TAU;
	π = PI;
}

type {
	Vec2 [vector 2]f32;
	Vec3 [vector 3]f32;
	Vec4 [vector 4]f32;

	Mat2 [2]Vec2;
	Mat3 [3]Vec3;
	Mat4 [4]Vec4;
}

proc sqrt32(x f32) -> f32 #foreign "llvm.sqrt.f32"
proc sqrt64(x f64) -> f64 #foreign "llvm.sqrt.f64"

proc sin32(x f32) -> f32 #foreign "llvm.sin.f32"
proc sin64(x f64) -> f64 #foreign "llvm.sin.f64"

proc cos32(x f32) -> f32 #foreign "llvm.cos.f32"
proc cos64(x f64) -> f64 #foreign "llvm.cos.f64"

proc tan32(x f32) -> f32 #inline { return sin32(x)/cos32(x); }
proc tan64(x f64) -> f64 #inline { return sin64(x)/cos64(x); }

proc lerp32(a, b, t f32) -> f32 { return a*(1-t) + b*t; }
proc lerp64(a, b, t f64) -> f64 { return a*(1-t) + b*t; }

proc sign32(x f32) -> f32 { if x >= 0 { return +1; } return -1; }
proc sign64(x f64) -> f64 { if x >= 0 { return +1; } return -1; }



proc copy_sign32(x, y f32) -> f32 {
	var ix = x transmute u32;
	var iy = y transmute u32;
	ix &= 0x7fffffff;
	ix |= iy & 0x80000000;
	return ix transmute f32;
}
proc round32(x f32) -> f32 {
	if x >= 0 {
		return floor32(x + 0.5);
	}
	return ceil32(x - 0.5);
}
proc floor32(x f32) -> f32 {
	if x >= 0 {
		return x as int as f32;
	}
	return (x-0.5) as int as f32;
}
proc ceil32(x f32) -> f32 {
	if x < 0 {
		return x as int as f32;
	}
	return ((x as int)+1) as f32;
}

proc remainder32(x, y f32) -> f32 {
	return x - round32(x/y) * y;
}

proc fmod32(x, y f32) -> f32 {
	y = abs(y);
	var result = remainder32(abs(x), y);
	if sign32(result) < 0 {
		result += y;
	}
	return copy_sign32(result, x);
}


proc to_radians(degrees f32) -> f32 { return degrees * TAU / 360; }
proc to_degrees(radians f32) -> f32 { return radians * 360 / TAU; }




proc dot2(a, b Vec2) -> f32 { var c = a*b; return c.x + c.y; }
proc dot3(a, b Vec3) -> f32 { var c = a*b; return c.x + c.y + c.z; }
proc dot4(a, b Vec4) -> f32 { var c = a*b; return c.x + c.y + c.z + c.w; }

proc cross3(x, y Vec3) -> Vec3 {
	var a = swizzle(x, 1, 2, 0) * swizzle(y, 2, 0, 1);
	var b = swizzle(x, 2, 0, 1) * swizzle(y, 1, 2, 0);
	return a - b;
}


proc vec2_mag(v Vec2) -> f32 { return sqrt32(dot2(v, v)); }
proc vec3_mag(v Vec3) -> f32 { return sqrt32(dot3(v, v)); }
proc vec4_mag(v Vec4) -> f32 { return sqrt32(dot4(v, v)); }

proc vec2_norm(v Vec2) -> Vec2 { return v / Vec2{vec2_mag(v)}; }
proc vec3_norm(v Vec3) -> Vec3 { return v / Vec3{vec3_mag(v)}; }
proc vec4_norm(v Vec4) -> Vec4 { return v / Vec4{vec4_mag(v)}; }

proc vec2_norm0(v Vec2) -> Vec2 {
	var m = vec2_mag(v);
	if m == 0 {
		return Vec2{0};
	}
	return v / Vec2{m};
}

proc vec3_norm0(v Vec3) -> Vec3 {
	var m = vec3_mag(v);
	if m == 0 {
		return Vec3{0};
	}
	return v / Vec3{m};
}

proc vec4_norm0(v Vec4) -> Vec4 {
	var m = vec4_mag(v);
	if m == 0 {
		return Vec4{0};
	}
	return v / Vec4{m};
}



proc mat4_identity() -> Mat4 {
	return Mat4{
		{1, 0, 0, 0},
		{0, 1, 0, 0},
		{0, 0, 1, 0},
		{0, 0, 0, 1},
	};
}

proc mat4_transpose(m Mat4) -> Mat4 {
	for var j = 0; j < 4; j++ {
		for var i = 0; i < 4; i++ {
			m[i][j], m[j][i] = m[j][i], m[i][j];
		}
	}
	return m;
}

proc mat4_mul(a, b Mat4) -> Mat4 {
	var c Mat4;
	for var j = 0; j < 4; j++ {
		for var i = 0; i < 4; i++ {
			c[j][i] = a[0][i]*b[j][0] +
			          a[1][i]*b[j][1] +
			          a[2][i]*b[j][2] +
			          a[3][i]*b[j][3];
		}
	}
	return c;
}

proc mat4_mul_vec4(m Mat4, v Vec4) -> Vec4 {
	return Vec4{
		m[0][0]*v.x + m[1][0]*v.y + m[2][0]*v.z + m[3][0]*v.w,
		m[0][1]*v.x + m[1][1]*v.y + m[2][1]*v.z + m[3][1]*v.w,
		m[0][2]*v.x + m[1][2]*v.y + m[2][2]*v.z + m[3][2]*v.w,
		m[0][3]*v.x + m[1][3]*v.y + m[2][3]*v.z + m[3][3]*v.w,
	};
}

proc mat4_inverse(m Mat4) -> Mat4 {
	var o Mat4;

	var sf00 = m[2][2] * m[3][3] - m[3][2] * m[2][3];
	var sf01 = m[2][1] * m[3][3] - m[3][1] * m[2][3];
	var sf02 = m[2][1] * m[3][2] - m[3][1] * m[2][2];
	var sf03 = m[2][0] * m[3][3] - m[3][0] * m[2][3];
	var sf04 = m[2][0] * m[3][2] - m[3][0] * m[2][2];
	var sf05 = m[2][0] * m[3][1] - m[3][0] * m[2][1];
	var sf06 = m[1][2] * m[3][3] - m[3][2] * m[1][3];
	var sf07 = m[1][1] * m[3][3] - m[3][1] * m[1][3];
	var sf08 = m[1][1] * m[3][2] - m[3][1] * m[1][2];
	var sf09 = m[1][0] * m[3][3] - m[3][0] * m[1][3];
	var sf10 = m[1][0] * m[3][2] - m[3][0] * m[1][2];
	var sf11 = m[1][1] * m[3][3] - m[3][1] * m[1][3];
	var sf12 = m[1][0] * m[3][1] - m[3][0] * m[1][1];
	var sf13 = m[1][2] * m[2][3] - m[2][2] * m[1][3];
	var sf14 = m[1][1] * m[2][3] - m[2][1] * m[1][3];
	var sf15 = m[1][1] * m[2][2] - m[2][1] * m[1][2];
	var sf16 = m[1][0] * m[2][3] - m[2][0] * m[1][3];
	var sf17 = m[1][0] * m[2][2] - m[2][0] * m[1][2];
	var sf18 = m[1][0] * m[2][1] - m[2][0] * m[1][1];

	o[0][0] = +(m[1][1] * sf00 - m[1][2] * sf01 + m[1][3] * sf02);
	o[0][1] = -(m[1][0] * sf00 - m[1][2] * sf03 + m[1][3] * sf04);
	o[0][2] = +(m[1][0] * sf01 - m[1][1] * sf03 + m[1][3] * sf05);
	o[0][3] = -(m[1][0] * sf02 - m[1][1] * sf04 + m[1][2] * sf05);

	o[1][0] = -(m[0][1] * sf00 - m[0][2] * sf01 + m[0][3] * sf02);
	o[1][1] = +(m[0][0] * sf00 - m[0][2] * sf03 + m[0][3] * sf04);
	o[1][2] = -(m[0][0] * sf01 - m[0][1] * sf03 + m[0][3] * sf05);
	o[1][3] = +(m[0][0] * sf02 - m[0][1] * sf04 + m[0][2] * sf05);

	o[2][0] = +(m[0][1] * sf06 - m[0][2] * sf07 + m[0][3] * sf08);
	o[2][1] = -(m[0][0] * sf06 - m[0][2] * sf09 + m[0][3] * sf10);
	o[2][2] = +(m[0][0] * sf11 - m[0][1] * sf09 + m[0][3] * sf12);
	o[2][3] = -(m[0][0] * sf08 - m[0][1] * sf10 + m[0][2] * sf12);

	o[3][0] = -(m[0][1] * sf13 - m[0][2] * sf14 + m[0][3] * sf15);
	o[3][1] = +(m[0][0] * sf13 - m[0][2] * sf16 + m[0][3] * sf17);
	o[3][2] = -(m[0][0] * sf14 - m[0][1] * sf16 + m[0][3] * sf18);
	o[3][3] = +(m[0][0] * sf15 - m[0][1] * sf17 + m[0][2] * sf18);

	var ood = 1.0 / (m[0][0] * o[0][0] +
	              m[0][1] * o[0][1] +
	              m[0][2] * o[0][2] +
	              m[0][3] * o[0][3]);

	o[0][0] *= ood;
	o[0][1] *= ood;
	o[0][2] *= ood;
	o[0][3] *= ood;
	o[1][0] *= ood;
	o[1][1] *= ood;
	o[1][2] *= ood;
	o[1][3] *= ood;
	o[2][0] *= ood;
	o[2][1] *= ood;
	o[2][2] *= ood;
	o[2][3] *= ood;
	o[3][0] *= ood;
	o[3][1] *= ood;
	o[3][2] *= ood;
	o[3][3] *= ood;

	return o;
}


proc mat4_translate(v Vec3) -> Mat4 {
	var m = mat4_identity();
	m[3][0] = v.x;
	m[3][1] = v.y;
	m[3][2] = v.z;
	m[3][3] = 1;
	return m;
}

proc mat4_rotate(v Vec3, angle_radians f32) -> Mat4 {
	var c = cos32(angle_radians);
	var s = sin32(angle_radians);

	var a = vec3_norm(v);
	var t = a * Vec3{1-c};

	var rot = mat4_identity();

	rot[0][0] = c + t.x*a.x;
	rot[0][1] = 0 + t.x*a.y + s*a.z;
	rot[0][2] = 0 + t.x*a.z - s*a.y;
	rot[0][3] = 0;

	rot[1][0] = 0 + t.y*a.x - s*a.z;
	rot[1][1] = c + t.y*a.y;
	rot[1][2] = 0 + t.y*a.z + s*a.x;
	rot[1][3] = 0;

	rot[2][0] = 0 + t.z*a.x + s*a.y;
	rot[2][1] = 0 + t.z*a.y - s*a.x;
	rot[2][2] = c + t.z*a.z;
	rot[2][3] = 0;

	return rot;
}

proc mat4_scale(m Mat4, v Vec3) -> Mat4 {
	m[0][0] *= v.x;
	m[1][1] *= v.y;
	m[2][2] *= v.z;
	return m;
}

proc mat4_scalef(m Mat4, s f32) -> Mat4 {
	m[0][0] *= s;
	m[1][1] *= s;
	m[2][2] *= s;
	return m;
}


proc mat4_look_at(eye, centre, up Vec3) -> Mat4 {
	var f = vec3_norm(centre - eye);
	var s = vec3_norm(cross3(f, up));
	var u = cross3(s, f);

	var m Mat4;

	m[0] = Vec4{+s.x, +s.y, +s.z, 0};
	m[1] = Vec4{+u.x, +u.y, +u.z, 0};
	m[2] = Vec4{-f.x, -f.y, -f.z, 0};
	m[3] = Vec4{dot3(s, eye), dot3(u, eye), dot3(f, eye), 1};

	return m;
}
proc mat4_perspective(fovy, aspect, near, far f32) -> Mat4 {
	var m Mat4;
	var tan_half_fovy = tan32(0.5 * fovy);
	m[0][0] = 1.0 / (aspect*tan_half_fovy);
	m[1][1] = 1.0 / (tan_half_fovy);
	m[2][2] = -(far + near) / (far - near);
	m[2][3] = -1.0;
	m[3][2] = -2.0*far*near / (far - near);
	return m;
}


proc mat4_ortho3d(left, right, bottom, top, near, far f32) -> Mat4 {
	var m = mat4_identity();
	m[0][0] = +2.0 / (right - left);
	m[1][1] = +2.0 / (top - bottom);
	m[2][2] = -2.0 / (far - near);
	m[3][0] = -(right + left)   / (right - left);
	m[3][1] = -(top   + bottom) / (top   - bottom);
	m[3][2] = -(far + near) / (far - near);
	return m;
}





const F32_DIG        = 6;
const F32_EPSILON    = 1.192092896e-07;
const F32_GUARD      = 0;
const F32_MANT_DIG   = 24;
const F32_MAX        = 3.402823466e+38;
const F32_MAX_10_EXP = 38;
const F32_MAX_EXP    = 128;
const F32_MIN        = 1.175494351e-38;
const F32_MIN_10_EXP = -37;
const F32_MIN_EXP    = -125;
const F32_NORMALIZE  = 0;
const F32_RADIX      = 2;
const F32_ROUNDS     = 1;

const F64_DIG        = 15;                       // # of decimal digits of precision
const F64_EPSILON    = 2.2204460492503131e-016;  // smallest such that 1.0+F64_EPSILON != 1.0
const F64_MANT_DIG   = 53;                       // # of bits in mantissa
const F64_MAX        = 1.7976931348623158e+308;  // max value
const F64_MAX_10_EXP = 308;                      // max decimal exponent
const F64_MAX_EXP    = 1024;                     // max binary exponent
const F64_MIN        = 2.2250738585072014e-308;  // min positive value
const F64_MIN_10_EXP = -307;                     // min decimal exponent
const F64_MIN_EXP    = -1021;                    // min binary exponent
const F64_RADIX      = 2;                        // exponent radix
const F64_ROUNDS     = 1;                        // addition rounding: near


