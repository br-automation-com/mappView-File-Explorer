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

#ifndef _IEC_CONST
#define _IEC_CONST _WEAK const
#endif

/* Constants */
#ifdef _REPLACE_CONST
 #define icmpERR_NO_RESPONSE 32750U
 #define icmpERR_PARAMETER 32751U
 #define icmpERR_SOCKET_CREATE 32752U
 #define icmpERR_SYSTEM 32799U
#else
 _IEC_CONST unsigned short icmpERR_NO_RESPONSE = 32750U;
 _IEC_CONST unsigned short icmpERR_PARAMETER = 32751U;
 _IEC_CONST unsigned short icmpERR_SOCKET_CREATE = 32752U;
 _IEC_CONST unsigned short icmpERR_SYSTEM = 32799U;
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
void IcmpPing(struct IcmpPing* inst);


#ifdef __cplusplus
};
#endif
#endif /* _ASICMP_ */

                                                           
