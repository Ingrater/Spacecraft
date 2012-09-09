module base.c_types;

// cint_t: variable length signed integer types for system calls on 64bit POSIX
// systems.
static if(size_t.sizeof == 4) {
	alias int cint_t;
} else {
	alias long cint_t;
}
