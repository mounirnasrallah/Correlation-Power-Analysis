#ifndef LIBCPA_H
#define LIBCPA_H

#include <stdint.h>

void write_CPA_result_all (FILE *stream, double **correlations,
                           unsigned int nb_words, unsigned int ncy);
void write_CPA_result (FILE *stream, double *correlations,
                       unsigned int nb_words);

#endif  /* LIBCPA_H */
