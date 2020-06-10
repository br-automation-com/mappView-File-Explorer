/* Automation Studio generated header file */
/* Do not edit ! */

#ifndef _ASICMP_
#define _ASICMP_
#ifdef __cplusplus
extern "C" 
{
#endif

#include <bur/plctypes.h>

#include <runtime.h>

#ifndef _BUR_PUBLIC
#define _BUR_PUBLIC
#endif
/* Constants */
#ifdef _REPLACE_CONST
 #define icmpERR_SYSTEM 32799U
 #define icmpERR_FIREWALL 32754U
 #define icmpERR_UNREACHABLE 32753U
 #define icmpERR_SOCKET_CREATE 32752U
 #define icmpERR_PARAMETER 32751U
 #define icmpERR_NO_RESPONSE 32750U
#else
 #ifndef _GLOBAL_CONST
   #define _GLOBAL_CONST _WEAK const
 #endif
 _GLOBAL_CONST unsigned short icmpERR_SYSTEM;
 _GLOBAL_CONST unsigned short icmpERR_FIREWALL;
 _GLOBAL_CONST unsigned short icmpERR_UNREACHABLE;
 _GLOBAL_CONST unsigned short icmpERR_SOCKET_CREATE;
 _GLOBAL_CONST unsigned short icmpERR_PARAMETER;
 _GLOBAL_CONST unsigned short icmpERR_NO_RESPONSE;
#endif




/* Datatypes and datatypes of function blocks */
typedef struct IcmpPing
{
	/* VAR_INPUT (analog) */
	unsigned long pHost;
	unsigned short timeout;
	/* VAR_OUTPUT (analog) */
	unsigned short status;
	/* VAR (analog) */
	unsigned short i_state;
	unsigned short i_result;
	unsigned long i_tmp;
	/* VAR_INPUT (digital) */
	plcbit enable;
} IcmpPing_typ;



/* Prototyping of functions and function blocks */
_BUR_PUBLIC void IcmpPing(struct IcmpPing* inst);


#ifdef __cplusplus
};
#endif
#endif /* _ASICMP_ */

