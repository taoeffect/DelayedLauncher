/*
 *  Common.h
 *  DelayedLauncher
 *
 *  Created by Greg Slepak on 12/5/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef COMMON_H
#define COMMON_H

// -- logging --

#ifdef DEBUG
#	define log_debug(msg, ...) NSLog(@"DEBUG: " msg, ## __VA_ARGS__)
#else
#	define log_debug(msg, ...) /* nothing */
#endif

#define log_info(msg, ...) NSLog(@"INFO: " msg, ## __VA_ARGS__)
#define log_warn(msg, ...) NSLog(@"WARN (%s:%d): "  msg, __func__, __LINE__, ## __VA_ARGS__)
#define log_err(msg, ...)  NSLog(@"ERROR (%s:%d): " msg, __func__, __LINE__, ## __VA_ARGS__)
#define log_errp(msg, ...) NSLog(@"ERROR (%s:%d): " msg ": %s", __func__, __LINE__, ## __VA_ARGS__, strerror(errno))

// -- variable conveniences --

#define NSRGBA(r,g,b,a)						[NSColor colorWithCalibratedRed:r green:g blue:b alpha:a]
#define NSARY(...)							[NSArray arrayWithObjects:__VA_ARGS__, nil]
#define NSDCT(...)							[NSDictionary dictionaryWithObjectsAndKeys:__VA_ARGS__, nil]
#define NSINT(_n)							[NSNumber numberWithInt:_n]
#define NSYES								[NSNumber numberWithBool:YES]
#define NSNO								[NSNumber numberWithBool:NO]
#define NSSTR_FMT(_fmt, ...)				[NSString stringWithFormat:@_fmt, ## __VA_ARGS__]
#define NSERR(_msg, ...)					[NSError errorWithDomain:@"DLDomain" code:-1 userInfo:NSDCT(NSSTR_FMT(_msg, ## __VA_ARGS__), NSLocalizedDescriptionKey)]
#define ASSIGN(old, new)					do { id _old = (id)(old); (old) = [(new) retain]; [_old release]; } while (0)
#define DESTROY(var)						do { [(var) release]; (var) = nil; } while (0)
#define OBSERVE_NOTIF(_who, _what, _where)	[[NSNotificationCenter defaultCenter] addObserver:_who selector:_where name:_what object:nil]

// atomic ASSIGN and DESTROY

#define ASSIGN_ATOMIC(old, new) do { \
	id _o=(id)old, _n=[(id)new retain]; \
	while ( !OSAtomicCompareAndSwapPtr((void*)_o, (void*)_n, (void**)&old) ) \
		_o=(id)old; \
	[_o release]; \
} while (0)

#define DESTROY_ATOMIC(var)	do { \
	id _v=(id)var; \
	if ( OSAtomicCompareAndSwapPtr((void*)_v, NULL, (void**)&var) ) \
		[_v release]; \
} while (0)


#define JOIN_XY(a, b)						a##b
#define ACC_RETURN_H(type, var)				- (type)var;
#define ACC_RETURN_M(type, var)				- (type)var { return var; }
#define ACC_SET_H(type, var, Var)			- (void)JOIN_XY(set, Var):(type)JOIN_XY(a, Var);
#define ACC_SET_M(type, var, Var)			- (void)JOIN_XY(set, Var):(type)JOIN_XY(a, Var) { ASSIGN(var, JOIN_XY(a, Var)); }
#define ACC_SETP_M(type, var, Var)			- (void)JOIN_XY(set, Var):(type)JOIN_XY(a, Var) { var = JOIN_XY(a, Var); }
#define ACC_COMBO_H(type, var, Var)			ACC_RETURN_H(type, var) ACC_SET_H(type, var, Var)
#define ACC_COMBO_M(type, var, Var)			ACC_RETURN_M(type, var) ACC_SET_M(type, var, Var)
#define ACC_COMBOP_M(type, var, Var)		ACC_RETURN_M(type, var) ACC_SETP_M(type, var, Var)

// -- optimizations --

#ifndef __unlikely
#define __unlikely(cond) __builtin_expect(!!(cond), 0)
#endif
#ifndef __likely
#define __likely(cond) __builtin_expect(!!(cond), 1)
#endif

// -- lists --

// close to speed of obj-c 2.0's fast enum.
#define ENUMERATE(type, var, enumeratorMethod) \
	for (type e = (id)enumeratorMethod, \
		*imp = (id)[(NSEnumerator*)e methodForSelector:@selector(nextObject)], \
		*var = e ? ((IMP)imp)(e, @selector(nextObject)) : nil; \
		var; \
		var = ((IMP)imp)(e, @selector(nextObject)) \
	)

#define ENUMERID(var, enumeratorMethod) \
	for (id e = (id)enumeratorMethod, \
		imp = (id)[(NSEnumerator*)e methodForSelector:@selector(nextObject)], \
		var = e ? ((IMP)imp)(e, @selector(nextObject)) : nil; \
		var; \
		var = ((IMP)imp)(e, @selector(nextObject)) \
	)

// -- exception hanlding --

#define CATCH_EXCEPTION @catch (NSException *e) { log_warn("*** Caught %@! *** %@", [e name], [e reason]); }
#define TRY(...) @try { __VA_ARGS__; } CATCH_EXCEPTION

// -- error handling --

#define DO_FAILABLE(_errVar, _func, args...) do { \
	if ( __unlikely((_errVar = _func(args)) != 0) ) { \
		log_err(#_func " returned: %d", (int)_errVar); \
		goto fail_label; \
	} \
} while (0)

#define DO_FAILABLE_SUB(_errVar, _subst, _func, args...) do { \
	if ( __unlikely((_errVar = _func(args)) != 0) ) { \
		_errVar = _subst; log_err(#_func " resulted in: %d", (int)_errVar); \
		goto fail_label; \
	} \
} while (0)

#define FAILABLE(_errVar, _func, args...) do { \
	if ( __unlikely((_errVar = _func(args)) != 0) ) { \
		log_err(#_func " returned: %d", (int)_errVar); \
	} \
} while (0)

#define FAIL_IF(_cond, args...) do { \
	if ( __unlikely((_cond) != 0) ) { log_err("failed because: " #_cond); args; goto fail_label; } \
} while (0)

#define FAIL_IFQ(_cond, args...) do { \
	if ( __unlikely((_cond) != 0) ) { args; goto fail_label; } \
} while (0)

#endif /* COMMON_H */
