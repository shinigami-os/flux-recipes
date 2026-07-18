#ifndef MUSL_FGETSPENT_SHIM_H
#define MUSL_FGETSPENT_SHIM_H

#include <shadow.h>
#include <stdio.h>

int fgetspent_r(FILE *fp, struct spwd *spbuf, char *buf, size_t buflen, struct spwd **spbufp);

#endif
