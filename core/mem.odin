#import "fmt.odin";
#import "os.odin";

const swap = proc(b: u16) -> u16 #foreign __llvm_core "llvm.bswap.i16";
const swap = proc(b: u32) -> u32 #foreign __llvm_core "llvm.bswap.i32";
const swap = proc(b: u64) -> u64 #foreign __llvm_core "llvm.bswap.i64";


const set = proc(data: rawptr, value: i32, len: int) -> rawptr {
	return __mem_set(data, value, len);
}
const zero = proc(data: rawptr, len: int) -> rawptr {
	return __mem_zero(data, len);
}
const copy = proc(dst, src: rawptr, len: int) -> rawptr {
	return __mem_copy(dst, src, len);
}
const copy_non_overlapping = proc(dst, src: rawptr, len: int) -> rawptr {
	return __mem_copy_non_overlapping(dst, src, len);
}
const compare = proc(a, b: []u8) -> int {
	return __mem_compare(&a[0], &b[0], min(len(a), len(b)));
}



const kilobytes = proc(x: int) -> int #inline { return          (x) * 1024; }
const megabytes = proc(x: int) -> int #inline { return kilobytes(x) * 1024; }
const gigabytes = proc(x: int) -> int #inline { return megabytes(x) * 1024; }
const terabytes = proc(x: int) -> int #inline { return gigabytes(x) * 1024; }

const is_power_of_two = proc(x: int) -> bool {
	if x <= 0 {
		return false;
	}
	return (x & (x-1)) == 0;
}

const align_forward = proc(ptr: rawptr, align: int) -> rawptr {
	assert(is_power_of_two(align));

	var a = uint(align);
	var p = uint(ptr);
	var modulo = p & (a-1);
	if modulo != 0 {
		p += a - modulo;
	}
	return rawptr(p);
}



const AllocationHeader = struct {
	size: int,
}

const allocation_header_fill = proc(header: ^AllocationHeader, data: rawptr, size: int) {
	header.size = size;
	var ptr = ^int(header+1);

	for var i = 0; rawptr(ptr) < data; i++ {
		(ptr+i)^ = -1;
	}
}
const allocation_header = proc(data: rawptr) -> ^AllocationHeader {
	if data == nil {
		return nil;
	}
	var p = ^int(data);
	for (p-1)^ == -1 {
		p = (p-1);
	}
	return ^AllocationHeader(p-1);
}





// Custom allocators
const Arena = struct {
	backing:    Allocator,
	offset:     int,
	memory:     []u8,
	temp_count: int,
}

const ArenaTempMemory = struct {
	arena:          ^Arena,
	original_count: int,
}





const init_arena_from_memory = proc(using a: ^Arena, data: []u8) {
	backing    = Allocator{};
	memory     = data[0..<0];
	temp_count = 0;
}

const init_arena_from_context = proc(using a: ^Arena, size: int) {
	backing = context.allocator;
	memory = make([]u8, size);
	temp_count = 0;
}

const free_arena = proc(using a: ^Arena) {
	if backing.procedure != nil {
		push_allocator backing {
			free(memory);
			memory = nil;
			offset = 0;
		}
	}
}

const arena_allocator = proc(arena: ^Arena) -> Allocator {
	return Allocator{
		procedure = arena_allocator_proc,
		data = arena,
	};
}

const arena_allocator_proc = proc(allocator_data: rawptr, mode: AllocatorMode,
                          size, alignment: int,
                          old_memory: rawptr, old_size: int, flags: u64) -> rawptr {
	using AllocatorMode;
	var arena = ^Arena(allocator_data);

	match mode {
	case Alloc:
		var total_size = size + alignment;

		if arena.offset + total_size > len(arena.memory) {
			fmt.fprintln(os.stderr, "Arena out of memory");
			return nil;
		}

		#no_bounds_check var end = &arena.memory[arena.offset];

		var ptr = align_forward(end, alignment);
		arena.offset += total_size;
		return zero(ptr, size);

	case Free:
		// NOTE(bill): Free all at once
		// Use ArenaTempMemory if you want to free a block

	case FreeAll:
		arena.offset = 0;

	case Resize:
		return default_resize_align(old_memory, old_size, size, alignment);
	}

	return nil;
}

const begin_arena_temp_memory = proc(a: ^Arena) -> ArenaTempMemory {
	var tmp: ArenaTempMemory;
	tmp.arena = a;
	tmp.original_count = len(a.memory);
	a.temp_count++;
	return tmp;
}

const end_arena_temp_memory = proc(using tmp: ArenaTempMemory) {
	assert(len(arena.memory) >= original_count);
	assert(arena.temp_count > 0);
	arena.memory = arena.memory[0..<original_count];
	arena.temp_count--;
}







const align_of_type_info = proc(type_info: ^TypeInfo) -> int {
	const prev_pow2 = proc(n: i64) -> i64 {
		if n <= 0 {
			return 0;
		}
		n |= n >> 1;
		n |= n >> 2;
		n |= n >> 4;
		n |= n >> 8;
		n |= n >> 16;
		n |= n >> 32;
		return n - (n >> 1);
	}

	const WORD_SIZE = size_of(int);
	const MAX_ALIGN = size_of([vector 64]f64); // TODO(bill): Should these constants be builtin constants?
	using TypeInfo;
	match info in type_info {
	case Named:
		return align_of_type_info(info.base);
	case Integer:
		return info.size;
	case Float:
		return info.size;
	case String:
		return WORD_SIZE;
	case Boolean:
		return 1;
	case Any:
		return WORD_SIZE;
	case Pointer:
		return WORD_SIZE;
	case Procedure:
		return WORD_SIZE;
	case Array:
		return align_of_type_info(info.elem);
	case DynamicArray:
		return WORD_SIZE;
	case Slice:
		return WORD_SIZE;
	case Vector:
		var size = size_of_type_info(info.elem);
		var count = int(max(prev_pow2(i64(info.count)), 1));
		var total = size * count;
		return clamp(total, 1, MAX_ALIGN);
	case Tuple:
		return info.align;
	case Struct:
		return info.align;
	case Union:
		return info.align;
	case RawUnion:
		return info.align;
	case Enum:
		return align_of_type_info(info.base);
	case Map:
		return align_of_type_info(info.generated_struct);
	}

	return 0;
}

const align_formula = proc(size, align: int) -> int {
	var result = size + align-1;
	return result - result%align;
}

const size_of_type_info = proc(type_info: ^TypeInfo) -> int {
	const WORD_SIZE = size_of(int);
	using TypeInfo;
	match info in type_info {
	case Named:
		return size_of_type_info(info.base);
	case Integer:
		return info.size;
	case Float:
		return info.size;
	case String:
		return 2*WORD_SIZE;
	case Boolean:
		return 1;
	case Any:
		return 2*WORD_SIZE;
	case Pointer:
		return WORD_SIZE;
	case Procedure:
		return WORD_SIZE;
	case Array:
		var count = info.count;
		if count == 0 {
			return 0;
		}
		var size      = size_of_type_info(info.elem);
		var align     = align_of_type_info(info.elem);
		var alignment = align_formula(size, align);
		return alignment*(count-1) + size;
	case DynamicArray:
		return size_of(rawptr) + 2*size_of(int) + size_of(Allocator);
	case Slice:
		return 2*WORD_SIZE;
	case Vector:
		var count = info.count;
		if count == 0 {
			return 0;
		}
		var size      = size_of_type_info(info.elem);
		var align     = align_of_type_info(info.elem);
		var alignment = align_formula(size, align);
		return alignment*(count-1) + size;
	case Struct:
		return info.size;
	case Union:
		return info.size;
	case RawUnion:
		return info.size;
	case Enum:
		return size_of_type_info(info.base);
	case Map:
		return size_of_type_info(info.generated_struct);
	}

	return 0;
}

