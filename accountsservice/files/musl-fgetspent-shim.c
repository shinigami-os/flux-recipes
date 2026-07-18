/* musl doesn't implement fgetspent_r() (only the non-reentrant fgetspent()),
 * but accounts-daemon needs the _r variant to parse /etc/shadow into a
 * caller-owned buffer. Reimplement it directly against the same line
 * format glibc uses, rather than wrapping fgetspent() (whose static
 * internal buffer would get clobbered by later calls in the same loop). */
#include "musl-fgetspent-shim.h"

#include <errno.h>
#include <stdlib.h>
#include <string.h>

int
fgetspent_r (FILE *fp, struct spwd *spbuf, char *buf, size_t buflen, struct spwd **spbufp)
{
        char *line = NULL;
        size_t linecap = 0;
        ssize_t len;

        *spbufp = NULL;

        while ((len = getline (&line, &linecap, fp)) != -1) {
                char *save, *name, *pass, *lstchg, *min, *max, *warn, *inact, *expire, *flag;

                if (len > 0 && line[len - 1] == '\n')
                        line[--len] = '\0';

                if ((size_t) (len + 1) > buflen) {
                        free (line);
                        return ERANGE;
                }
                memcpy (buf, line, (size_t) len + 1);
                free (line);
                line = NULL;
                linecap = 0;

                name = strtok_r (buf, ":", &save);
                pass = strtok_r (NULL, ":", &save);
                lstchg = strtok_r (NULL, ":", &save);
                min = strtok_r (NULL, ":", &save);
                max = strtok_r (NULL, ":", &save);
                warn = strtok_r (NULL, ":", &save);
                inact = strtok_r (NULL, ":", &save);
                expire = strtok_r (NULL, ":", &save);
                flag = strtok_r (NULL, ":", &save);

                if (name == NULL || pass == NULL)
                        continue;

                spbuf->sp_namp = name;
                spbuf->sp_pwdp = pass;
                spbuf->sp_lstchg = (lstchg && *lstchg) ? atol (lstchg) : -1;
                spbuf->sp_min = (min && *min) ? atol (min) : -1;
                spbuf->sp_max = (max && *max) ? atol (max) : -1;
                spbuf->sp_warn = (warn && *warn) ? atol (warn) : -1;
                spbuf->sp_inact = (inact && *inact) ? atol (inact) : -1;
                spbuf->sp_expire = (expire && *expire) ? atol (expire) : -1;
                spbuf->sp_flag = (flag && *flag) ? strtoul (flag, NULL, 10) : (unsigned long) -1;

                *spbufp = spbuf;
                return 0;
        }

        free (line);
        return errno ? errno : ENOENT;
}
