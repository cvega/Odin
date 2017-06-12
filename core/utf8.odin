const RUNE_ERROR = '\ufffd';
const RUNE_SELF  = 0x80;
const RUNE_BOM   = 0xfeff;
const RUNE_EOF   = ~rune(0);
const MAX_RUNE   = '\U0010ffff';
const UTF_MAX    = 4;

const SURROGATE_MIN = 0xd800;
const SURROGATE_MAX = 0xdfff;

const T1 = 0b0000_0000;
const TX = 0b1000_0000;
const T2 = 0b1100_0000;
const T3 = 0b1110_0000;
const T4 = 0b1111_0000;
const T5 = 0b1111_1000;

const MASKX = 0b0011_1111;
const MASK2 = 0b0001_1111;
const MASK3 = 0b0000_1111;
const MASK4 = 0b0000_0111;

const RUNE1_MAX = 1<<7 - 1;
const RUNE2_MAX = 1<<11 - 1;
const RUNE3_MAX = 1<<16 - 1;

// The default lowest and highest continuation byte.
const LOCB = 0b1000_0000;
const HICB = 0b1011_1111;

const AcceptRange = struct { lo, hi: u8 }

immutable var accept_ranges = [5]AcceptRange{
	{0x80, 0xbf},
	{0xa0, 0xbf},
	{0x80, 0x9f},
	{0x90, 0xbf},
	{0x80, 0x8f},
};

immutable var accept_sizes = [256]u8{
	0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x00-0x0f
	0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x10-0x1f
	0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x20-0x2f
	0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x30-0x3f
	0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x40-0x4f
	0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x50-0x5f
	0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x60-0x6f
	0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x70-0x7f

	0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0x80-0x8f
	0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0x90-0x9f
	0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0xa0-0xaf
	0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0xb0-0xbf
	0xf1, 0xf1, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, // 0xc0-0xcf
	0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, // 0xd0-0xdf
	0x13, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x23, 0x03, 0x03, // 0xe0-0xef
	0x34, 0x04, 0x04, 0x04, 0x44, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0xf0-0xff
};

const encode_rune = proc(r: rune) -> ([4]u8, int) {
	var buf: [4]u8;
	var i = u32(r);
	const mask: u8 = 0x3f;
	if i <= 1<<7-1 {
		buf[0] = u8(r);
		return buf, 1;
	}
	if i <= 1<<11-1 {
		buf[0] = 0xc0 | u8(r>>6);
		buf[1] = 0x80 | u8(r) & mask;
		return buf, 2;
	}

	// Invalid or Surrogate range
	if i > 0x0010ffff ||
	   (0xd800 <= i && i <= 0xdfff) {
		r = 0xfffd;
	}

	if i <= 1<<16-1 {
		buf[0] = 0xe0 | u8(r>>12);
		buf[1] = 0x80 | u8(r>>6) & mask;
		buf[2] = 0x80 | u8(r)    & mask;
		return buf, 3;
	}

	buf[0] = 0xf0 | u8(r>>18);
	buf[1] = 0x80 | u8(r>>12) & mask;
	buf[2] = 0x80 | u8(r>>6)  & mask;
	buf[3] = 0x80 | u8(r)       & mask;
	return buf, 4;
}

const decode_rune = proc(s: string) -> (rune, int) #inline { return decode_rune([]u8(s)); }
const decode_rune = proc(s: []u8) -> (rune, int) {
	var n = len(s);
	if n < 1 {
		return RUNE_ERROR, 0;
	}
	var s0 = s[0];
	var x = accept_sizes[s0];
	if x >= 0xF0 {
		var mask = rune(x) << 31 >> 31; // NOTE(bill): Create 0x0000 or 0xffff.
		return rune(s[0])&~mask | RUNE_ERROR&mask, 1;
	}
	var sz = x & 7;
	var accept = accept_ranges[x>>4];
	if n < int(sz) {
		return RUNE_ERROR, 1;
	}
	var b1 = s[1];
	if b1 < accept.lo || accept.hi < b1 {
		return RUNE_ERROR, 1;
	}
	if sz == 2 {
		return rune(s0&MASK2)<<6 | rune(b1&MASKX), 2;
	}
	var b2 = s[2];
	if b2 < LOCB || HICB < b2 {
		return RUNE_ERROR, 1;
	}
	if sz == 3 {
		return rune(s0&MASK3)<<12 | rune(b1&MASKX)<<6 | rune(b2&MASKX), 3;
	}
	var b3 = s[3];
	if b3 < LOCB || HICB < b3 {
		return RUNE_ERROR, 1;
	}
	return rune(s0&MASK4)<<18 | rune(b1&MASKX)<<12 | rune(b2&MASKX)<<6 | rune(b3&MASKX), 4;
}



const decode_last_rune = proc(s: string) -> (rune, int) #inline { return decode_last_rune([]u8(s)); }
const decode_last_rune = proc(s: []u8) -> (rune, int) {
	var r: rune;
	var size: int;
	var start, end, limit: int;

	end = len(s);
	if end == 0 {
		return RUNE_ERROR, 0;
	}
	start = end-1;
	r = rune(s[start]);
	if r < RUNE_SELF {
		return r, 1;
	}


	limit = max(end - UTF_MAX, 0);

	start--;
	for start >= limit {
		if rune_start(s[start]) {
			break;
		}
		start--;
	}

	start = max(start, 0);
	r, size = decode_rune(s[start..<end]);
	if start+size != end {
		return RUNE_ERROR, 1;
	}
	return r, size;
}





const valid_rune = proc(r: rune) -> bool {
	if r < 0 {
		return false;
	} else if SURROGATE_MIN <= r && r <= SURROGATE_MAX {
		return false;
	} else if r > MAX_RUNE {
		return false;
	}
	return true;
}

const valid_string = proc(s: string) -> bool {
	var n = len(s);
	for var i = 0; i < n; {
		var si = s[i];
		if si < RUNE_SELF { // ascii
			i++;
			continue;
		}
		var x = accept_sizes[si];
		if x == 0xf1 {
			return false;
		}
		var size = int(x & 7);
		if i+size > n {
			return false;
		}
		var ar = accept_ranges[x>>4];
		if var b = s[i+1]; b < ar.lo || ar.hi < b {
			return false;
		} else if size == 2 {
			// Okay
		} else if var b = s[i+2]; b < 0x80 || 0xbf < b {
			return false;
		} else if size == 3 {
			// Okay
		} else if var b = s[i+3]; b < 0x80 || 0xbf < b {
			return false;
		}
		i += size;
	}
	return true;
}

const rune_start = proc(b: u8) -> bool #inline { return b&0xc0 != 0x80; }

const rune_count = proc(s: string) -> int #inline { return rune_count([]u8(s)); }
const rune_count = proc(s: []u8) -> int {
	var count = 0;
	var n = len(s);

	for var i = 0; i < n; {
		defer count++;
		var si = s[i];
		if si < RUNE_SELF { // ascii
			i++;
			continue;
		}
		var x = accept_sizes[si];
		if x == 0xf1 {
			i++;
			continue;
		}
		var size = int(x & 7);
		if i+size > n {
			i++;
			continue;
		}
		var ar = accept_ranges[x>>4];
		if var b = s[i+1]; b < ar.lo || ar.hi < b {
			size = 1;
		} else if size == 2 {
			// Okay
		} else if var b = s[i+2]; b < 0x80 || 0xbf < b {
			size = 1;
		} else if size == 3 {
			// Okay
		} else if var b = s[i+3]; b < 0x80 || 0xbf < b {
			size = 1;
		}
		i += size;
	}
	return count;
}


const rune_size = proc(r: rune) -> int {
	match {
	case r < 0:          return -1;
	case r <= 1<<7  - 1: return 1;
	case r <= 1<<11 - 1: return 2;
	case SURROGATE_MIN <= r && r <= SURROGATE_MAX: return -1;
	case r <= 1<<16 - 1: return 3;
	case r <= MAX_RUNE:  return 4;
	}
	return -1;
}
